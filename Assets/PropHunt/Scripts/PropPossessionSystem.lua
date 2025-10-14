--!Type(Module)

--[[
    PropPossessionSystem.lua

    Handles prop possession mechanics for PropHunt.
    Now a Module type with both client and server logic.

    FEATURES:
    HIDING PHASE (Props):
    - Click-to-possess interaction using TapHandler
    - Automatic player movement via TapHandler (moveTo = true)
    - Avatar hidden by disabling Rig GameObject (remote execution)
    - Player's character GameObject remains active for network sync
    - Prop emission turned off (blends in)
    - Prop outline disabled
    - One-Prop Rule: Can only possess once per round
    - Server tracks prop-to-player mapping

    HUNTING PHASE (Hunters):
    - Hunters tap on props to find possessed players
    - Server validates and finds which player possessed the prop
    - Calls GameManager.OnPlayerTagged for scoring
    - Tagged prop revelation: restore avatar, convert to spectator

    All validations via server for cheat prevention

    SETUP:
    1. Attach this script to PropHuntModules GameObject (as Module)
    2. For each possessable prop:
       - Add TapHandler component
       - Enable "Move To" checkbox
       - Set "Distance" to interaction range (e.g., 3.0)
       - Tag: "Possessable"
       - Material with _EmissionStrength property
       - Optional: Outline child GameObject (PropName_Outline)

    ARCHITECTURE:
    This Module dynamically finds all props with "Possessable" tag and
    sets up tap handlers for them. All Event code (client + server)
    lives in this single file to avoid module loading order issues.
    
    REMOTE EXECUTION:
    Avatar visibility changes use the same pattern as ReadyUpButton:
    1. Client requests via Event:FireServer()
    2. Server validates (role, game state)
    3. Server executes on target client via Event:Connect()
    This prevents unauthorized GameObject manipulation.

    GAME FLOW:
    HIDING PHASE:
    1. Prop player taps prop → OnPropTapped(propName)
    2. Client sends possessionRequestEvent:FireServer(propName)
    3. Server validates and stores possessedProps[propName] = playerId
    4. Server broadcasts possessionResultEvent:FireAllClients()
    5. All clients hide prop visuals
    6. Possessed player's avatar hidden via hideAvatarCommand

    HUNTING PHASE:
    1. Hunter taps prop → OnPropTapped(propName)
    2. Client sends tagPropRequest:FireServer(propName)
    3. Server finds playerId from possessedProps[propName]
    4. Server calls GameManager.OnPlayerTagged(hunter, propPlayer)
    5. GameManager fires PH_PlayerTagged event
    6. PropPossessionSystem restores avatar via restoreAvatarCommand
    7. PropPossessionSystem sets role to spectator
]]

local VFXManager = require("PropHuntVFXManager")
local PlayerManager = require("PropHuntPlayerManager")
local GameManager = require("PropHuntGameManager")

-- Network Events (Module-scoped, accessible within this file only)
local possessionRequestEvent = Event.new("PH_PossessionRequest")
local possessionResultEvent = Event.new("PH_PossessionResult")
local hideAvatarRequest = Event.new("PH_HideAvatarRequest")
local restoreAvatarRequest = Event.new("PH_RestoreAvatarRequest")
local hideAvatarCommand = Event.new("PH_HideAvatarCommand")
local restoreAvatarCommand = Event.new("PH_RestoreAvatarCommand")
local playerTaggedEvent = Event.new("PH_PlayerTagged")  -- Listen for tag events from GameManager
local tagPropRequest = Event.new("PH_TagPropRequest")  -- Hunter taps prop during HUNTING
local postTeleportEvent = Event.new("PH_PostTeleport")  -- Listen for teleport completion

-- Server-side prop tracking (One-Prop Rule)
-- Maps propName -> playerId
local possessedProps = {}

-- Client-side state tracking (per-player)
local currentStateValue = nil
local currentState = "LOBBY"
local localRole = "unknown"
local hasPossessedThisRound = false
local navMeshGameObject = nil
local shouldBeVisible = true  -- Track if local player's avatar should be visible

-- Client-side prop tracking (per-prop data)
-- Maps propName -> { gameObject, renderer, outlineRenderer, savedEmission, isPossessed }
local propsData = {}

--[[
    STATE NORMALIZATION
]]
local function NormalizeState(value)
    if type(value) == "number" then
        if value == 1 then return "LOBBY"
        elseif value == 2 then return "HIDING"
        elseif value == 3 then return "HUNTING"
        elseif value == 4 then return "ROUND_END"
        end
    end
    return tostring(value)
end

--[[
    CLIENT - Prop Discovery and TapHandler Setup
]]
local function SetupProp(propGameObject)
    local propName = propGameObject.name

    -- Initialize prop data
    local propData = {
        gameObject = propGameObject,
        renderer = nil,
        outlineRenderer = nil,
        savedEmission = 2.0,
        isPossessed = false
    }

    -- Get renderer for emission control
    propData.renderer = propGameObject:GetComponent(MeshRenderer)
    if propData.renderer then
        local material = propData.renderer.sharedMaterial
        if material and material:HasProperty("_EmissionStrength") then
            local success, emissionValue = pcall(function()
                return material:GetFloat("_EmissionStrength")
            end)
            if success then
                propData.savedEmission = emissionValue
            end
        end
    end

    -- Find outline renderer
    local outlineChild = propGameObject.transform:Find(propName .. "_Outline")
    if outlineChild then
        propData.outlineRenderer = outlineChild:GetComponent(MeshRenderer)
    end

    -- Setup tap handler
    local tapHandler = propGameObject:GetComponent(TapHandler)
    if tapHandler then
        tapHandler.Tapped:Connect(function()
            OnPropTapped(propName)
        end)
    end

    -- Store prop data
    propsData[propName] = propData
end

local function DiscoverAndSetupProps()
    local possessableProps = GameObject.FindGameObjectsWithTag("Possessable")
    if possessableProps and #possessableProps > 0 then
        for i = 1, #possessableProps do
            if possessableProps[i] then
                SetupProp(possessableProps[i])
            end
        end
    end
end

--[[
    CLIENT - Avatar Visibility Control (Request)
    Forward declaration - defined here before OnPossessionResult uses it
]]
local function RequestHideAvatar()
    local player = client.localPlayer
    if not player then
        print("[PropPossessionSystem] CLIENT: No local player to hide")
        return
    end
    print("[PropPossessionSystem] CLIENT: Requesting hide avatar for " .. player.name)
    -- FireServer automatically passes the calling player as first parameter to server
    hideAvatarRequest:FireServer()
end

local function RequestRestoreAvatar()
    local player = client.localPlayer
    if not player then
        print("[PropPossessionSystem] CLIENT: No local player to restore")
        return
    end
    print("[PropPossessionSystem] CLIENT: Requesting restore avatar for " .. player.name)
    -- FireServer automatically passes the calling player as first parameter to server
    restoreAvatarRequest:FireServer()
end

--[[
    CLIENT - Tap Handler
    Handles both HIDING phase (possession) and HUNTING phase (tagging)
]]
function OnPropTapped(propName)
    -- Lazy read: Check current state value right when tapped (most up-to-date)
    if currentStateValue then
        local liveState = NormalizeState(currentStateValue.value)
        if liveState ~= currentState then
            print("[PropPossessionSystem] State updated on tap: " .. currentState .. " -> " .. liveState)
            currentState = liveState
        end
    end

    print("[PropPossessionSystem] Prop tapped: " .. propName .. " (state=" .. currentState .. ", role=" .. localRole .. ")")

    -- HUNTING PHASE: Hunter tapping on prop to tag the possessed player
    if currentState == "HUNTING" then
        if localRole == "hunter" then
            print("[PropPossessionSystem] Hunter tapped prop during HUNTING - requesting tag")
            -- Send tag request to server with prop name
            tagPropRequest:FireServer(propName)
            print("[PropPossessionSystem] Sent tag prop request to server: " .. propName)
        else
            print("[PropPossessionSystem] Only hunters can tag props during HUNTING phase")
        end
        return
    end

    -- HIDING PHASE: Prop player possessing a prop
    if currentState ~= "HIDING" then
        print("[PropPossessionSystem] Cannot possess outside HIDING phase (current: " .. currentState .. ")")
        return
    end

    -- Only props can possess
    if localRole ~= "prop" then
        print("[PropPossessionSystem] Only props can possess objects")
        return
    end

    -- One-Prop Rule: Can only possess once per round
    if hasPossessedThisRound then
        print("[PropPossessionSystem] Already possessed a prop this round!")
        local propData = propsData[propName]
        if propData then
            VFXManager.RejectionVFX(propData.gameObject.transform.position, propData.gameObject)
        end
        return
    end

    -- Check if already possessed by someone (client-side check)
    local propData = propsData[propName]
    if propData and propData.isPossessed then
        print("[PropPossessionSystem] This prop is already possessed!")
        VFXManager.RejectionVFX(propData.gameObject.transform.position, propData.gameObject)
        return
    end

    print("[PropPossessionSystem] Attempting to possess: " .. propName)

    -- Fire possession request to server
    possessionRequestEvent:FireServer(propName)
    print("[PropPossessionSystem] Sent possession request to server")
end

--[[
    CLIENT - Possession Result Handler
]]
local function OnPossessionResult(playerId, propName, success, message)
    local propData = propsData[propName]
    if not propData then
        return  -- Prop not tracked on this client
    end

    -- Only process successful possessions
    if not success then
        -- Check if this was our failed attempt
        local localPlayer = client.localPlayer
        if localPlayer and playerId == localPlayer.id then
            print("[PropPossessionSystem] Possession rejected: " .. tostring(message))
            VFXManager.RejectionVFX(propData.gameObject.transform.position, propData.gameObject)
        end
        return
    end

    -- Success - mark prop as possessed on all clients
    propData.isPossessed = true

    -- Check if this is our player's possession
    local localPlayer = client.localPlayer
    local isLocalPlayer = localPlayer and playerId == localPlayer.id

    if isLocalPlayer then
        -- This is our player's successful possession
        print("[PropPossessionSystem] Possession response for " .. propName .. ": SUCCESS")
        hasPossessedThisRound = true

        -- Visual effects for local player
        local playerPos = localPlayer.character.transform.position
        VFXManager.PlayerVanishVFX(playerPos, localPlayer.character)
        VFXManager.PropInfillVFX(propData.gameObject.transform.position, propData.gameObject)

        -- Server will broadcast hide command directly - no need to request

        print("[PropPossessionSystem] ✓✓✓ POSSESSION COMPLETE: " .. propName .. " ✓✓✓")
    else
        -- Another player possessed this prop
        print("[PropPossessionSystem] Prop " .. propName .. " possessed by player: " .. tostring(playerId))
    end

    -- Hide prop visuals for ALL clients (so everyone sees the prop blend in)
    HidePropVisuals(propName)
end

--[[
    SERVER - Avatar Visibility Control (Authorization)
    Server validates and broadcasts command to ALL clients
]]
local function HandleHideAvatarRequest(player)
    -- Validate player is a prop
    local playerInfo = PlayerManager.GetPlayerInfo(player)
    if not playerInfo or playerInfo.role.value ~= "prop" then
        return
    end

    -- Validate game state (2 = HIDING)
    local gameState = GameManager.GetCurrentState()
    if gameState ~= 2 then
        return
    end

    -- Broadcast command to ALL clients
    hideAvatarCommand:FireAllClients(player.user.id)
end

local function HandleRestoreAvatarRequest(player)
    -- Broadcast command to ALL clients
    restoreAvatarCommand:FireAllClients(player.user.id)
end

--[[
    CLIENT - Avatar Visibility Execution
    Called by server command after authorization
    Receives userId and hides that player's avatar on ALL clients
]]
local function HidePlayerAvatarExecute(userId)
    print("[PropPossessionSystem] HidePlayerAvatarExecute called for userId: " .. tostring(userId))

    -- Find the player with this userId
    local targetPlayer = nil
    for _, player in ipairs(scene.players) do
        if player.user.id == userId then
            targetPlayer = player
            break
        end
    end

    if not targetPlayer then
        print("[PropPossessionSystem] ERROR: Could not find player with userId: " .. tostring(userId))
        return
    end

    if not targetPlayer.character then
        print("[PropPossessionSystem] ERROR: Player has no character: " .. targetPlayer.name)
        return
    end

    print("[PropPossessionSystem] Hiding avatar for player: " .. targetPlayer.name)

    -- Track visibility state for local player
    if targetPlayer == client.localPlayer then
        shouldBeVisible = false
    end

    local success, errorMsg = pcall(function()
        local character = targetPlayer.character
        local characterGameObject = character.gameObject

        -- Only disable NavMesh for local player (movement control)
        if targetPlayer == client.localPlayer then
            if not navMeshGameObject then
                navMeshGameObject = GameObject.Find("NavMesh")
            end
            if navMeshGameObject then
                print("[PropPossessionSystem] Disabling NavMesh for local player")
                navMeshGameObject:SetActive(false)
            else
                print("[PropPossessionSystem] ERROR: NavMesh GameObject not found")
            end
        end

        -- Find and disable the Rig GameObject (keeps network sync but hides avatar)
        local rigTransform = characterGameObject.transform:Find("Rig")
        if rigTransform then
            print("[PropPossessionSystem] Disabling Rig GameObject for " .. targetPlayer.name)
            rigTransform.gameObject:SetActive(false)
        else
            print("[PropPossessionSystem] ERROR: Could not find Rig child for " .. targetPlayer.name)
        end
    end)

    if not success then
        print("[PropPossessionSystem] ERROR hiding avatar: " .. tostring(errorMsg))
    else
        print("[PropPossessionSystem] Successfully hid avatar for " .. targetPlayer.name)
    end
end

local function RestorePlayerAvatarExecute(userId)
    print("[PropPossessionSystem] RestorePlayerAvatarExecute called for userId: " .. tostring(userId))

    -- Find the player with this userId
    local targetPlayer = nil
    for _, player in ipairs(scene.players) do
        if player.user.id == userId then
            targetPlayer = player
            break
        end
    end

    if not targetPlayer then
        print("[PropPossessionSystem] ERROR: Could not find player with userId: " .. tostring(userId))
        return
    end

    if not targetPlayer.character then
        print("[PropPossessionSystem] ERROR: Player has no character: " .. targetPlayer.name)
        return
    end

    local isLocalPlayer = targetPlayer == client.localPlayer
    print("[PropPossessionSystem] Restoring avatar for player: " .. targetPlayer.name .. " (isLocal: " .. tostring(isLocalPlayer) .. ")")

    -- Track visibility state for local player
    if isLocalPlayer then
        shouldBeVisible = true
    end

    local function AttemptRestore()
        local success, errorMsg = pcall(function()
            local character = targetPlayer.character
            local characterGameObject = character.gameObject

            -- CRITICAL FIX: Reset character scale (VFX scaled it to 0)
            local currentScale = characterGameObject.transform.localScale
            print("[PropPossessionSystem] Current character scale: " .. tostring(currentScale.x) .. ", " .. tostring(currentScale.y) .. ", " .. tostring(currentScale.z))

            if currentScale.x < 0.1 or currentScale.y < 0.1 or currentScale.z < 0.1 then
                print("[PropPossessionSystem] Character was scaled to ~0 by VFX - resetting to (1,1,1)")
                characterGameObject.transform.localScale = Vector3.new(1, 1, 1)
            end

            -- Find and re-enable the Rig GameObject
            local rigTransform = characterGameObject.transform:Find("Rig")
            if rigTransform then
                local wasActive = rigTransform.gameObject.activeSelf
                print("[PropPossessionSystem] Re-enabling Rig GameObject for " .. targetPlayer.name .. " (was active: " .. tostring(wasActive) .. ")")
                rigTransform.gameObject:SetActive(true)

                -- Verify it's actually active now
                Timer.After(0.1, function()
                    if rigTransform and rigTransform.gameObject then
                        local nowActive = rigTransform.gameObject.activeSelf
                        print("[PropPossessionSystem] Rig active state after 0.1s: " .. tostring(nowActive) .. " for " .. targetPlayer.name)

                        if not nowActive then
                            print("[PropPossessionSystem] WARNING: Rig still inactive, retrying...")
                            rigTransform.gameObject:SetActive(true)
                        end
                    end
                end)
            else
                print("[PropPossessionSystem] ERROR: Could not find Rig child for " .. targetPlayer.name)
            end

            -- Only re-enable NavMesh for local player (movement control)
            if isLocalPlayer then
                print("[PropPossessionSystem] Re-enabling NavMesh for local player")
                if navMeshGameObject then
                    navMeshGameObject:SetActive(true)
                else
                    print("[PropPossessionSystem] ERROR: NavMesh GameObject not found")
                end
            end
        end)

        if not success then
            print("[PropPossessionSystem] ERROR restoring avatar: " .. tostring(errorMsg))
        else
            print("[PropPossessionSystem] Successfully restored avatar for " .. targetPlayer.name)
        end
    end

    -- Try immediately
    AttemptRestore()

    -- For local player, add a delayed retry to handle race conditions with teleportation
    if isLocalPlayer then
        Timer.After(0.5, function()
            print("[PropPossessionSystem] Delayed restore check for local player")
            if targetPlayer and targetPlayer.character then
                local characterGameObject = targetPlayer.character.gameObject
                local rigTransform = characterGameObject.transform:Find("Rig")
                if rigTransform and not rigTransform.gameObject.activeSelf then
                    print("[PropPossessionSystem] Local player Rig still inactive after 0.5s - forcing re-enable")
                    rigTransform.gameObject:SetActive(true)
                end
            end
        end)
    end
end

--[[
    CLIENT - Prop Visuals Control
]]
function HidePropVisuals(propName)
    local propData = propsData[propName]
    if not propData then return end

    -- Turn off emission (blend in with environment)
    if propData.renderer and propData.savedEmission then
        local material = propData.renderer.material
        if material and material:HasProperty("_EmissionStrength") then
            local success, errorMsg = pcall(function()
                material:SetFloat("_EmissionStrength", 0.0)
            end)

            if success then
                print("[PropPossessionSystem] ✓ Disabled emission on " .. propName)
            else
                print("[PropPossessionSystem] WARNING: Could not disable emission on " .. propName .. " - " .. tostring(errorMsg))
            end
        end
    end

    -- Hide outline
    if propData.outlineRenderer then
        propData.outlineRenderer.enabled = false
        print("[PropPossessionSystem] ✓ Disabled outline on " .. propName)
    end
end

function RestorePropVisuals(propName)
    local propData = propsData[propName]
    if not propData then return end

    -- Restore emission (only if we saved one)
    if propData.renderer and propData.savedEmission then
        local material = propData.renderer.material
        if material and material:HasProperty("_EmissionStrength") then
            local success, errorMsg = pcall(function()
                material:SetFloat("_EmissionStrength", propData.savedEmission)
            end)
            
            if success then
                print("[PropPossessionSystem] ✓ Restored emission on " .. propName)
            else
                print("[PropPossessionSystem] WARNING: Could not restore emission on " .. propName .. " - " .. tostring(errorMsg))
            end
        end
    end

    -- Show outline
    if propData.outlineRenderer then
        propData.outlineRenderer.enabled = true
        print("[PropPossessionSystem] ✓ Enabled outline on " .. propName)
    end
end

function RestoreAllPropVisuals()
    for propName, propData in pairs(propsData) do
        RestorePropVisuals(propName)
    end
end

--[[
    CLIENT - State Tracking
]]
local function SetupStateTracking()
    local localPlayer = client.localPlayer
    if localPlayer then
        local playerInfo = PlayerManager.GetPlayerInfo(localPlayer)
        if playerInfo then
            -- Track game state via per-player NetworkValue
            if playerInfo.gameState then
                currentStateValue = playerInfo.gameState
                currentState = NormalizeState(currentStateValue.value)

                currentStateValue.Changed:Connect(function(newStateNum, oldStateNum)
                    local oldState = currentState
                    currentState = NormalizeState(newStateNum)

                    -- Reset possession tracking when entering HIDING phase
                    if currentState == "HIDING" and oldState ~= "HIDING" then
                        hasPossessedThisRound = false

                        -- Reset all props' isPossessed flags
                        for propName, propData in pairs(propsData) do
                            propData.isPossessed = false
                        end

                        RestoreAllPropVisuals()
                    end

                    -- Show prop visuals during HIDING phase
                    if currentState == "HIDING" then
                        RestoreAllPropVisuals()
                    end
                end)
            end

            -- Track player role
            if playerInfo.role then
                localRole = playerInfo.role.value

                playerInfo.role.Changed:Connect(function(newRole, oldRole)
                    localRole = newRole
                end)
            end
        end
    end
end

--[[
    SERVER - Possession Request Handler
]]
local function HandlePossessionRequest(player, propName)
    local success = false
    local message = ""

    -- Get current game state
    local gameState = GameManager.GetCurrentState()

    -- Validate game phase (2 = HIDING)
    if gameState ~= 2 then
        success = false
        message = "Not hiding phase"
    else
        -- Get player info to check role
        local playerInfo = PlayerManager.GetPlayerInfo(player)
        if not playerInfo or playerInfo.role.value ~= "prop" then
            success = false
            message = "Not a prop"
        -- Check if prop already possessed by another player
        elseif possessedProps[propName] and possessedProps[propName] ~= player.id then
            success = false
            message = "Prop already possessed"
        else
            -- Check if player has already possessed a different prop (One-Prop Rule)
            local hasOtherProp = false
            for propID, playerID in pairs(possessedProps) do
                if playerID == player.id and propID ~= propName then
                    hasOtherProp = true
                    break
                end
            end

            if hasOtherProp then
                success = false
                message = "Already possessed another prop"
            else
                -- All validations passed - mark prop as possessed
                possessedProps[propName] = player.id
                success = true
                message = "Possessed successfully"

                -- Notify GameManager that a prop has hidden (for auto-transition check)
                GameManager.OnPropHidden()

                -- SERVER: Directly broadcast hide command to ALL clients
                hideAvatarCommand:FireAllClients(player.user.id)
            end
        end
    end

    -- Broadcast result to all clients
    possessionResultEvent:FireAllClients(player.id, propName, success, message)
end

--[[
    CLIENT LIFECYCLE
]]
function self:ClientStart()
    -- Discover and setup all possessable props (increased delay to ensure scene is loaded)
    Timer.After(1.0, function()
        DiscoverAndSetupProps()
    end)

    -- Setup state tracking
    Timer.After(1.2, function()
        SetupStateTracking()
    end)

    -- Listen for possession results
    possessionResultEvent:Connect(OnPossessionResult)

    -- Listen for avatar visibility commands from server
    hideAvatarCommand:Connect(HidePlayerAvatarExecute)
    restoreAvatarCommand:Connect(RestorePlayerAvatarExecute)

    -- Listen for player tagged events (to reveal tagged props)
    playerTaggedEvent:Connect(function(hunterId, propId)
        -- Check if the tagged player is the local player
        local localPlayer = client.localPlayer
        if localPlayer and localPlayer.id == propId then
            -- Just reset local state (server sends restore command)
            hasPossessedThisRound = false
        end
    end)

    -- Listen for post-teleport event to fix Rig visibility issues
    postTeleportEvent:Connect(function()
        print("[PropPossessionSystem] Post-teleport check triggered")

        -- If we should be visible, double-check that the Rig is actually enabled
        if shouldBeVisible then
            local localPlayer = client.localPlayer
            if localPlayer and localPlayer.character then
                local characterGameObject = localPlayer.character.gameObject
                local rigTransform = characterGameObject.transform:Find("Rig")

                if rigTransform then
                    local isActive = rigTransform.gameObject.activeSelf
                    print("[PropPossessionSystem] Post-teleport: Rig is " .. (isActive and "ACTIVE" or "INACTIVE") .. " (should be ACTIVE)")

                    if not isActive then
                        print("[PropPossessionSystem] Post-teleport: FORCING Rig to active")
                        rigTransform.gameObject:SetActive(true)

                        -- Verify again after a moment
                        Timer.After(0.1, function()
                            if rigTransform and rigTransform.gameObject then
                                local nowActive = rigTransform.gameObject.activeSelf
                                print("[PropPossessionSystem] Post-teleport verification: Rig is now " .. (nowActive and "ACTIVE" or "INACTIVE"))
                            end
                        end)
                    end
                end
            end
        end
    end)
end

--[[
    SERVER - Public API for GameManager
]]

-- Called by GameManager when transitioning to LOBBY or ROUND_END to restore all possessed props
function RestoreAllPossessedPlayers()
    print("[PropPossessionSystem] SERVER: RestoreAllPossessedPlayers called")
    local count = 0

    for propName, playerId in pairs(possessedProps) do
        print("[PropPossessionSystem] SERVER: Restoring player with ID: " .. tostring(playerId) .. " (prop: " .. tostring(propName) .. ")")

        -- Find the player
        for _, player in ipairs(scene.players) do
            if player.id == playerId then
                print("[PropPossessionSystem] SERVER: Found player " .. player.name .. " - firing restore command")
                restoreAvatarCommand:FireAllClients(player.user.id)
                count = count + 1
                break
            end
        end
    end

    print("[PropPossessionSystem] SERVER: Restored " .. count .. " possessed players")
end

-- Called by GameManager when entering HIDING phase to reset possession tracking
function ResetPossessions()
    print("[PropPossessionSystem] SERVER: ResetPossessions called - clearing possessedProps table")
    possessedProps = {}
end

--[[
    SERVER LIFECYCLE
]]
function self:ServerAwake()
    -- Handle possession requests from clients
    possessionRequestEvent:Connect(HandlePossessionRequest)

    -- Handle avatar visibility requests from clients
    hideAvatarRequest:Connect(HandleHideAvatarRequest)
    restoreAvatarRequest:Connect(HandleRestoreAvatarRequest)

    -- Handle tag prop requests (hunter tapping prop during HUNTING phase)
    tagPropRequest:Connect(function(hunter, propName)
        -- Validate game state (3 = HUNTING)
        local gameState = GameManager.GetCurrentState()
        if gameState ~= 3 then
            return
        end

        -- Validate hunter role
        local hunterInfo = PlayerManager.GetPlayerInfo(hunter)
        if not hunterInfo or hunterInfo.role.value ~= "hunter" then
            return
        end

        -- Find which player possessed this prop
        local possessingPlayerId = possessedProps[propName]
        if not possessingPlayerId then
            return
        end

        -- Find the prop player
        local propPlayer = nil
        for _, player in ipairs(scene.players) do
            if player.id == possessingPlayerId then
                propPlayer = player
                break
            end
        end

        if not propPlayer then
            return
        end

        -- Call GameManager's tag handler to process the tag (scoring, etc.)
        GameManager.OnPlayerTagged(hunter, propPlayer)

        -- IMMEDIATELY restore the tagged player's avatar
        print("[PropPossessionSystem] SERVER: Restoring avatar for tagged player: " .. propPlayer.name)
        restoreAvatarCommand:FireAllClients(propPlayer.user.id)

        -- Change role to spectator
        PlayerManager.SetPlayerRole(propPlayer, "spectator")
    end)
end

