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
    - NavMesh stays active so player can see other players
    - Prop emission turned off (blends in)
    - Prop outline disabled
    - One-Prop Rule: Can only possess once per round
    - Server tracks prop-to-player mapping

    TODO: Movement prevention for possessed props
    - NavMesh disable breaks visibility of other players
    - CharacterController doesn't exist in Highrise SDK
    - Need alternative approach (input blocking, position locking, etc.)

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

local Logger = require("PropHuntLogger")
local VFXManager = require("PropHuntVFXManager")
local PlayerManager = require("PropHuntPlayerManager")
local GameManager = require("PropHuntGameManager")
local ScoringSystem = require("PropHuntScoringSystem")
local Teleporter = require("PropHuntTeleporter")

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

-- VFX Network Events
local playerVanishVFXEvent = Event.new("PH_PlayerVanishVFX")  -- Broadcast player vanish VFX to all clients
local propInfillVFXEvent = Event.new("PH_PropInfillVFX")  -- Broadcast prop infill VFX to all clients

-- Server-side prop tracking (One-Prop Rule)
-- Maps propName -> playerId
local possessedProps = {}

-- Client-side state tracking (per-player)
local currentStateValue = nil
local currentState = "LOBBY"
local localRole = "unknown"
local hasPossessedThisRound = false
local shouldBeVisible = true  -- Track if local player's avatar should be visible

-- Client-side prop tracking (per-prop data)
-- Maps propName -> { gameObject, renderer, outlineRenderer, savedEmission, isPossessed }
local propsData = {}

-- Client-side pulse tween tracking (per-prop)
-- Maps propName -> tween object
local propPulseTweens = {}

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
        Logger.Warn("PropPossessionSystem", "CLIENT: No local player to hide")
        return
    end
    Logger.Log("PropPossessionSystem", "CLIENT: Requesting hide avatar for " .. player.name)
    -- FireServer automatically passes the calling player as first parameter to server
    hideAvatarRequest:FireServer()
end

local function RequestRestoreAvatar()
    local player = client.localPlayer
    if not player then
        Logger.Warn("PropPossessionSystem", "CLIENT: No local player to restore")
        return
    end
    Logger.Log("PropPossessionSystem", "CLIENT: Requesting restore avatar for " .. player.name)
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
            Logger.Log("PropPossessionSystem", "State updated on tap: " .. currentState .. " -> " .. liveState)
            currentState = liveState
        end
    end

    Logger.Log("PropPossessionSystem", "Prop tapped: " .. propName .. " (state=" .. currentState .. ", role=" .. localRole .. ")")

    -- HUNTING PHASE: Hunter tapping on prop to tag the possessed player
    if currentState == "HUNTING" then
        if localRole == "hunter" then
            Logger.Log("PropPossessionSystem", "Hunter tapped prop during HUNTING - requesting tag")
            -- Send tag request to server with prop name
            tagPropRequest:FireServer(propName)
            Logger.Log("PropPossessionSystem", "Sent tag prop request to server: " .. propName)
        else
            Logger.Log("PropPossessionSystem", "Only hunters can tag props during HUNTING phase")
        end
        return
    end

    -- HIDING PHASE: Prop player possessing a prop
    if currentState ~= "HIDING" then
        Logger.Log("PropPossessionSystem", "Cannot possess outside HIDING phase (current: " .. currentState .. ")")
        return
    end

    -- Only props can possess
    if localRole ~= "prop" then
        Logger.Log("PropPossessionSystem", "Only props can possess objects")
        return
    end

    -- One-Prop Rule: Can only possess once per round
    if hasPossessedThisRound then
        Logger.Log("PropPossessionSystem", "Already possessed a prop this round!")
        local propData = propsData[propName]
        if propData then
            VFXManager.RejectionVFX(propData.gameObject.transform.position, propData.gameObject)
        end
        return
    end

    -- Check if already possessed by someone (client-side check)
    local propData = propsData[propName]
    if propData and propData.isPossessed then
        Logger.Log("PropPossessionSystem", "This prop is already possessed!")
        VFXManager.RejectionVFX(propData.gameObject.transform.position, propData.gameObject)
        return
    end

    Logger.Log("PropPossessionSystem", "Attempting to possess: " .. propName)

    -- Fire possession request to server
    possessionRequestEvent:FireServer(propName)
    Logger.Log("PropPossessionSystem", "Sent possession request to server")
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
            Logger.Log("PropPossessionSystem", "Possession rejected: " .. tostring(message))
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
        Logger.Log("PropPossessionSystem", "Possession response for " .. propName .. ": SUCCESS")
        hasPossessedThisRound = true

        -- NOTE: VFX will be triggered by network events broadcast from server
        -- This ensures all clients see the VFX, not just the local player

        Logger.Log("PropPossessionSystem", "✓✓✓ POSSESSION COMPLETE: " .. propName .. " ✓✓✓")
    else
        -- Another player possessed this prop
        Logger.Log("PropPossessionSystem", "Prop " .. propName .. " possessed by player: " .. tostring(playerId))
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
    Logger.Log("PropPossessionSystem", "HidePlayerAvatarExecute called for userId: " .. tostring(userId))

    -- Find the player with this userId
    local targetPlayer = nil
    for _, player in ipairs(scene.players) do
        if player.user.id == userId then
            targetPlayer = player
            break
        end
    end

    if not targetPlayer then
        Logger.Log("PropPossessionSystem", "ERROR: Could not find player with userId: " .. tostring(userId))
        return
    end

    if not targetPlayer.character then
        Logger.Log("PropPossessionSystem", "ERROR: Player has no character: " .. targetPlayer.name)
        return
    end

    Logger.Log("PropPossessionSystem", "Hiding avatar for player: " .. targetPlayer.name)

    -- Track visibility state for local player
    if targetPlayer == client.localPlayer then
        shouldBeVisible = false
    end

    local success, errorMsg = pcall(function()
        local character = targetPlayer.character
        local characterGameObject = character.gameObject

        -- TODO: Disable movement for possessed props
        -- NavMesh cannot be disabled (breaks visibility of other players)
        -- CharacterController doesn't exist in Highrise SDK
        -- Need alternative approach for movement prevention

        -- Find and disable the Rig GameObject (keeps network sync but hides avatar)
        local rigTransform = characterGameObject.transform:Find("Rig")
        if rigTransform then
            Logger.Log("PropPossessionSystem", "Disabling Rig GameObject for " .. targetPlayer.name)
            rigTransform.gameObject:SetActive(false)
        else
            Logger.Log("PropPossessionSystem", "ERROR: Could not find Rig child for " .. targetPlayer.name)
        end
    end)

    if not success then
        Logger.Log("PropPossessionSystem", "ERROR hiding avatar: " .. tostring(errorMsg))
    else
        Logger.Log("PropPossessionSystem", "Successfully hid avatar for " .. targetPlayer.name)
    end
end

local function RestorePlayerAvatarExecute(userId)
    Logger.Log("PropPossessionSystem", "RestorePlayerAvatarExecute called for userId: " .. tostring(userId))

    -- Find the player with this userId
    local targetPlayer = nil
    for _, player in ipairs(scene.players) do
        if player.user.id == userId then
            targetPlayer = player
            break
        end
    end

    if not targetPlayer then
        Logger.Log("PropPossessionSystem", "ERROR: Could not find player with userId: " .. tostring(userId))
        return
    end

    if not targetPlayer.character then
        Logger.Log("PropPossessionSystem", "ERROR: Player has no character: " .. targetPlayer.name)
        return
    end

    local isLocalPlayer = targetPlayer == client.localPlayer
    Logger.Log("PropPossessionSystem", "Restoring avatar for player: " .. targetPlayer.name .. " (isLocal: " .. tostring(isLocalPlayer) .. ")")

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
            Logger.Log("PropPossessionSystem", "Current character scale: " .. tostring(currentScale.x) .. ", " .. tostring(currentScale.y) .. ", " .. tostring(currentScale.z))

            if currentScale.x < 0.1 or currentScale.y < 0.1 or currentScale.z < 0.1 then
                Logger.Log("PropPossessionSystem", "Character was scaled to ~0 by VFX - resetting to (1,1,1)")
                characterGameObject.transform.localScale = Vector3.new(1, 1, 1)
            end

            -- Find and re-enable the Rig GameObject
            local rigTransform = characterGameObject.transform:Find("Rig")
            if rigTransform then
                local wasActive = rigTransform.gameObject.activeSelf
                Logger.Log("PropPossessionSystem", "Re-enabling Rig GameObject for " .. targetPlayer.name .. " (was active: " .. tostring(wasActive) .. ")")
                rigTransform.gameObject:SetActive(true)

                -- Verify it's actually active now
                Timer.After(0.1, function()
                    if rigTransform and rigTransform.gameObject then
                        local nowActive = rigTransform.gameObject.activeSelf
                        Logger.Log("PropPossessionSystem", "Rig active state after 0.1s: " .. tostring(nowActive) .. " for " .. targetPlayer.name)

                        if not nowActive then
                            Logger.Log("PropPossessionSystem", "WARNING: Rig still inactive, retrying...")
                            rigTransform.gameObject:SetActive(true)
                        end
                    end
                end)
            else
                Logger.Log("PropPossessionSystem", "ERROR: Could not find Rig child for " .. targetPlayer.name)
            end

            -- TODO: Re-enable movement (no CharacterController or NavMesh approach works)

        end)

        if not success then
            Logger.Log("PropPossessionSystem", "ERROR restoring avatar: " .. tostring(errorMsg))
        else
            Logger.Log("PropPossessionSystem", "Successfully restored avatar for " .. targetPlayer.name)
        end
    end

    -- Try immediately
    AttemptRestore()

    -- For local player, add a delayed retry to handle race conditions with teleportation
    if isLocalPlayer then
        Timer.After(0.5, function()
            Logger.Log("PropPossessionSystem", "Delayed restore check for local player")
            if targetPlayer and targetPlayer.character then
                local characterGameObject = targetPlayer.character.gameObject
                local rigTransform = characterGameObject.transform:Find("Rig")
                if rigTransform and not rigTransform.gameObject.activeSelf then
                    Logger.Log("PropPossessionSystem", "Local player Rig still inactive after 0.5s - forcing re-enable")
                    rigTransform.gameObject:SetActive(true)
                end
            end
        end)
    end
end

--[[
    CLIENT - Emissive Pulse Control
]]
--[[
    StartPropPulse: Creates pulsing emissive effect during hiding phase
    @param propName: string - Name of the prop to pulse

    Creates a ping-pong tween that pulses emission from current strength down to 10%.
    Automatically loops until stopped (when prop is possessed).
]]
function StartPropPulse(propName)
    local propData = propsData[propName]
    if not propData or not propData.renderer then return end

    local material = propData.renderer.material
    if not material or not material:HasProperty("_EmissionStrength") then return end

    -- Stop any existing pulse for this prop
    if propPulseTweens[propName] then
        propPulseTweens[propName]:stop()
        propPulseTweens[propName] = nil
    end

    local savedStrength = propData.savedEmission  -- Original value (e.g., 2.0)
    local minStrength = savedStrength * 0.1       -- 10% of original (e.g., 0.2)

    -- Import tween classes
    local TweenModule = require("devx_tweens")
    local Tween = TweenModule.Tween
    local Easing = TweenModule.Easing

    -- Create ping-pong pulsing tween (full -> 10% -> full -> ...)
    local pulseTween = Tween:new(
        savedStrength,  -- Start at full strength
        minStrength,    -- Pulse down to 10%
        1.5,            -- Duration: 1.5 seconds per half-cycle
        true,           -- loop = true (infinite)
        true,           -- pingPong = true (reverses direction each cycle)
        Easing.easeInOutQuad,  -- Smooth ease in/out
        function(value, t)
            -- Update material emission strength each frame
            material:SetFloat("_EmissionStrength", value)
        end,
        nil  -- No onComplete callback (loops forever)
    )

    pulseTween:start()
    propPulseTweens[propName] = pulseTween

    Logger.Log("PropPossessionSystem", "Started emissive pulse for " .. propName .. " (" .. savedStrength .. " -> " .. minStrength .. ")")
end

--[[
    StopPropPulse: Stops pulsing animation for a prop
    @param propName: string - Name of the prop
]]
function StopPropPulse(propName)
    if propPulseTweens[propName] then
        propPulseTweens[propName]:stop()
        propPulseTweens[propName] = nil
        Logger.Log("PropPossessionSystem", "Stopped emissive pulse for " .. propName)
    end
end

--[[
    CLIENT - Prop Visuals Control
]]
function HidePropVisuals(propName)
    local propData = propsData[propName]
    if not propData then return end

    -- Stop any active pulse tween
    StopPropPulse(propName)

    -- Turn off emission with LERP transition (smooth fade out)
    if propData.renderer and propData.savedEmission then
        local material = propData.renderer.material
        if material and material:HasProperty("_EmissionStrength") then
            local success, errorMsg = pcall(function()
                -- Get current emission value (might be mid-pulse)
                local currentEmission = material:GetFloat("_EmissionStrength")

                -- Import tween classes
                local TweenModule = require("devx_tweens")
                local Tween = TweenModule.Tween
                local Easing = TweenModule.Easing

                -- Lerp from current emission to 0 over 0.3 seconds
                local fadeOutTween = Tween:new(
                    currentEmission,  -- Start from wherever pulse left off
                    0.0,              -- Fade to 0
                    0.3,              -- Duration: 0.3 seconds
                    false,            -- loop = false
                    false,            -- pingPong = false
                    Easing.easeOutQuad,  -- Smooth deceleration
                    function(value, t)
                        material:SetFloat("_EmissionStrength", value)
                    end,
                    function()
                        Logger.Log("PropPossessionSystem", "✓ Emission fade-out complete on " .. propName)
                    end
                )

                fadeOutTween:start()
            end)

            if success then
                Logger.Log("PropPossessionSystem", "✓ Started emission fade-out on " .. propName)
            else
                Logger.Log("PropPossessionSystem", "WARNING: Could not fade emission on " .. propName .. " - " .. tostring(errorMsg))
            end
        end
    end

    -- Hide outline
    if propData.outlineRenderer then
        propData.outlineRenderer.enabled = false
        Logger.Log("PropPossessionSystem", "✓ Disabled outline on " .. propName)
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
                Logger.Log("PropPossessionSystem", "✓ Restored emission on " .. propName)
            else
                Logger.Log("PropPossessionSystem", "WARNING: Could not restore emission on " .. propName .. " - " .. tostring(errorMsg))
            end
        end
    end

    -- Show outline
    if propData.outlineRenderer then
        propData.outlineRenderer.enabled = true
        Logger.Log("PropPossessionSystem", "✓ Enabled outline on " .. propName)
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

                        -- Start pulsing effect on all props
                        for propName, propData in pairs(propsData) do
                            StartPropPulse(propName)
                        end

                        Logger.Log("PropPossessionSystem", "Entering HIDING phase - all prop visuals restored and pulsing started")
                    end

                    -- Show prop visuals during HIDING phase
                    if currentState == "HIDING" then
                        RestoreAllPropVisuals()

                        -- Start pulsing effect on all props (if not already pulsing)
                        for propName, propData in pairs(propsData) do
                            if not propPulseTweens[propName] then
                                StartPropPulse(propName)
                            end
                        end

                        Logger.Log("PropPossessionSystem", "HIDING phase - prop visuals visible and pulsing")
                    end

                    -- Hide ALL prop visuals during HUNTING phase (so hunters can't tell which are possessed)
                    if currentState == "HUNTING" then
                        for propName, propData in pairs(propsData) do
                            HidePropVisuals(propName)  -- This already calls StopPropPulse internally
                        end
                        Logger.Log("PropPossessionSystem", "Entering HUNTING phase - all prop visuals hidden and pulses stopped")
                    end

                    -- Restore prop visuals when returning to LOBBY
                    if currentState == "LOBBY" and oldState ~= "LOBBY" then
                        -- Stop all pulses when returning to lobby
                        for propName, propData in pairs(propsData) do
                            StopPropPulse(propName)
                        end

                        RestoreAllPropVisuals()
                        Logger.Log("PropPossessionSystem", "Returning to LOBBY - all prop visuals restored and pulses stopped")
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

                -- SERVER: Broadcast VFX to ALL clients
                local playerPos = player.character.transform.position
                local propPos = GameObject.Find(propName).transform.position
                playerVanishVFXEvent:FireAllClients(playerPos.x, playerPos.y, playerPos.z, player.id)
                propInfillVFXEvent:FireAllClients(propPos.x, propPos.y, propPos.z, propName)

                -- SERVER: Delay hide command until AFTER VFX completes
                -- This allows the scale-down animation to be visible before Rig is disabled
                local VFXManager = require("PropHuntVFXManager")
                -- Use PlayerVanish duration + small buffer to ensure VFX completes
                Timer.After(3.7, function()
                    hideAvatarCommand:FireAllClients(player.user.id)
                    Logger.Log("PropPossessionSystem", "SERVER: Hide avatar command sent after VFX duration")
                end)
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

    -- Listen for VFX events from server
    playerVanishVFXEvent:Connect(function(posX, posY, posZ, playerId)
        local position = Vector3.new(posX, posY, posZ)

        -- Find the player character if available
        local playerCharacter = nil
        for _, player in ipairs(scene.players) do
            if player.id == playerId and player.character then
                playerCharacter = player.character
                break
            end
        end

        VFXManager.PlayerVanishVFX(position, playerCharacter)
        Logger.Log("PropPossessionSystem", "PlayerVanish VFX triggered at " .. tostring(position))
    end)

    propInfillVFXEvent:Connect(function(posX, posY, posZ, propName)
        local position = Vector3.new(posX, posY, posZ)
        local propData = propsData[propName]
        local propObject = propData and propData.gameObject or nil

        VFXManager.PropInfillVFX(position, propObject)
        Logger.Log("PropPossessionSystem", "PropInfill VFX triggered at " .. tostring(position))
    end)

    -- Listen for post-teleport event to fix Rig visibility issues
    postTeleportEvent:Connect(function()
        Logger.Log("PropPossessionSystem", "Post-teleport check triggered")

        -- If we should be visible, double-check that the Rig is actually enabled
        if shouldBeVisible then
            local localPlayer = client.localPlayer
            if localPlayer and localPlayer.character then
                local characterGameObject = localPlayer.character.gameObject
                local rigTransform = characterGameObject.transform:Find("Rig")

                if rigTransform then
                    local isActive = rigTransform.gameObject.activeSelf
                    Logger.Log("PropPossessionSystem", "Post-teleport: Rig is " .. (isActive and "ACTIVE" or "INACTIVE") .. " (should be ACTIVE)")

                    if not isActive then
                        Logger.Log("PropPossessionSystem", "Post-teleport: FORCING Rig to active")
                        rigTransform.gameObject:SetActive(true)

                        -- Verify again after a moment
                        Timer.After(0.1, function()
                            if rigTransform and rigTransform.gameObject then
                                local nowActive = rigTransform.gameObject.activeSelf
                                Logger.Log("PropPossessionSystem", "Post-teleport verification: Rig is now " .. (nowActive and "ACTIVE" or "INACTIVE"))
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
    Logger.Log("PropPossessionSystem", "SERVER: RestoreAllPossessedPlayers called")
    local count = 0

    for propName, playerId in pairs(possessedProps) do
        Logger.Log("PropPossessionSystem", "SERVER: Restoring player with ID: " .. tostring(playerId) .. " (prop: " .. tostring(propName) .. ")")

        -- Find the player
        for _, player in ipairs(scene.players) do
            if player.id == playerId then
                Logger.Log("PropPossessionSystem", "SERVER: Found player " .. player.name .. " - firing restore command")
                restoreAvatarCommand:FireAllClients(player.user.id)
                count = count + 1
                break
            end
        end
    end

    Logger.Log("PropPossessionSystem", "SERVER: Restored " .. count .. " possessed players")
end

-- Called by GameManager when entering HIDING phase to reset possession tracking
function ResetPossessions()
    Logger.Log("PropPossessionSystem", "SERVER: ResetPossessions called - clearing possessedProps table")
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
            -- MISS: Hunter tapped a non-possessed prop - apply penalty
            Logger.Log("PropPossessionSystem", "SERVER: Hunter " .. hunter.name .. " tapped non-possessed prop: " .. propName .. " - applying miss penalty")
            ScoringSystem.ApplyHunterMissPenalty(hunter)
            ScoringSystem.TrackHunterMiss(hunter)
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
            Logger.Log("PropPossessionSystem", "SERVER: ERROR - Could not find prop player with ID: " .. tostring(possessingPlayerId))
            return
        end

        -- HIT: Valid tag on possessed prop
        Logger.Log("PropPossessionSystem", "SERVER: Hunter " .. hunter.name .. " successfully tagged prop: " .. propName .. " (player: " .. propPlayer.name .. ")")

        -- Call GameManager's tag handler to process the tag (scoring, etc.)
        GameManager.OnPlayerTagged(hunter, propPlayer)

        -- IMMEDIATELY restore the tagged player's avatar
        Logger.Log("PropPossessionSystem", "SERVER: Restoring avatar for tagged player: " .. propPlayer.name)
        restoreAvatarCommand:FireAllClients(propPlayer.user.id)

        -- Teleport tagged prop to arena spawn position
        -- This prevents NavMesh/input issues with hidden player
        Logger.Log("PropPossessionSystem", "SERVER: Teleporting tagged player to Arena spawn: " .. propPlayer.name)
        Teleporter.TeleportToArena(propPlayer)

        -- Change role to spectator
        PlayerManager.SetPlayerRole(propPlayer, "spectator")
    end)
end

