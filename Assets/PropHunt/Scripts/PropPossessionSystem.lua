--!Type(Module)

--[[
    PropPossessionSystem.lua

    Handles prop possession mechanics for PropHunt.
    Now a Module type with both client and server logic.

    FEATURES:
    - Click-to-possess interaction using TapHandler
    - Automatic player movement via TapHandler (moveTo = true)
    - Avatar hidden and movement disabled (remote execution)
    - Prop emission turned off (blends in)
    - Prop outline disabled
    - One-Prop Rule: Can only possess once per round
    - Network validation via server

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
]]

print("[PropPossessionSystem] ===== MODULE LOADING =====")

local VFXManager = require("PropHuntVFXManager")
local PlayerManager = require("PropHuntPlayerManager")
local GameManager = require("PropHuntGameManager")

print("[PropPossessionSystem] Dependencies loaded successfully")

-- Network Events (Module-scoped, accessible within this file only)
local possessionRequestEvent = Event.new("PH_PossessionRequest")
local possessionResultEvent = Event.new("PH_PossessionResult")
local hideAvatarRequest = Event.new("PH_HideAvatarRequest")
local restoreAvatarRequest = Event.new("PH_RestoreAvatarRequest")
local hideAvatarCommand = Event.new("PH_HideAvatarCommand")
local restoreAvatarCommand = Event.new("PH_RestoreAvatarCommand")

print("[PropPossessionSystem] Events created successfully")

-- Server-side prop tracking (One-Prop Rule)
-- Maps propName -> playerId
local possessedProps = {}

-- Client-side state tracking (per-player)
local currentStateValue = nil
local currentState = "LOBBY"
local localRole = "unknown"
local hasPossessedThisRound = false
local navMeshGameObject = nil

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
    print("[PropPossessionSystem] Setting up prop: " .. propName)

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
        local success = pcall(function()
            local material = propData.renderer.sharedMaterial
            if material then
                propData.savedEmission = material:GetFloat("_EmissionStrength")
                print("[PropPossessionSystem] " .. propName .. " saved emission: " .. propData.savedEmission)
            end
        end)
    end

    -- Find outline renderer
    local outlineChild = propGameObject.transform:Find(propName .. "_Outline")
    if outlineChild then
        propData.outlineRenderer = outlineChild:GetComponent(MeshRenderer)
        if propData.outlineRenderer then
            print("[PropPossessionSystem] " .. propName .. " found outline renderer")
        end
    end

    -- Setup tap handler
    local tapHandler = propGameObject:GetComponent(TapHandler)
    if tapHandler then
        tapHandler.Tapped:Connect(function()
            OnPropTapped(propName)
        end)
        print("[PropPossessionSystem] " .. propName .. " TapHandler connected")
    else
        print("[PropPossessionSystem] WARNING: " .. propName .. " has no TapHandler component!")
    end

    -- Store prop data
    propsData[propName] = propData
end

local function DiscoverAndSetupProps()
    print("[PropPossessionSystem] Discovering possessable props...")

    local possessableProps = GameObject.FindGameObjectsWithTag("Possessable")

    if possessableProps then
        -- FindGameObjectsWithTag returns a Lua table, use # operator for length
        local count = #possessableProps
        print("[PropPossessionSystem] Found " .. count .. " possessable props")

        if count > 0 then
            -- Lua tables are 1-indexed
            for i = 1, count do
                local propObj = possessableProps[i]
                if propObj then
                    print("[PropPossessionSystem] Processing prop " .. i .. "/" .. count .. ": " .. propObj.name)
                    SetupProp(propObj)
                else
                    print("[PropPossessionSystem] WARNING: Prop at index " .. i .. " is nil")
                end
            end
            print("[PropPossessionSystem] ✓ Setup complete for " .. count .. " props")
        else
            print("[PropPossessionSystem] WARNING: No props found with 'Possessable' tag!")
            print("[PropPossessionSystem] Make sure props have the 'Possessable' tag in Unity")
        end
    else
        print("[PropPossessionSystem] ERROR: FindGameObjectsWithTag returned nil!")
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

    -- Only allow possession during HIDING phase
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

        -- Request server to hide player avatar (remote execution)
        RequestHideAvatar()

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
    print("[PropPossessionSystem] SERVER: Hide avatar request from " .. player.name)
    
    -- Validate player is a prop
    local playerInfo = PlayerManager.GetPlayerInfo(player)
    if not playerInfo or playerInfo.role.value ~= "prop" then
        print("[PropPossessionSystem] SERVER: Denied - player is not a prop")
        return
    end
    
    -- Validate game state (2 = HIDING)
    local gameState = GameManager.GetCurrentState()
    if gameState ~= 2 then
        print("[PropPossessionSystem] SERVER: Denied - not HIDING phase")
        return
    end
    
    -- Broadcast command to ALL clients so everyone hides this player's avatar
    print("[PropPossessionSystem] SERVER: Authorized - broadcasting hide command for " .. player.name)
    hideAvatarCommand:FireAllClients(player.user.id)
end

local function HandleRestoreAvatarRequest(player)
    print("[PropPossessionSystem] SERVER: Restore avatar request from " .. player.name)
    
    -- Broadcast command to ALL clients so everyone restores this player's avatar
    print("[PropPossessionSystem] SERVER: Broadcasting restore command for " .. player.name)
    restoreAvatarCommand:FireAllClients(player.user.id)
end

--[[
    CLIENT - Avatar Visibility Execution
    Called by server command after authorization
    Receives userId and hides that player's avatar on ALL clients
]]
local function HidePlayerAvatarExecute(userId)
    print("[PropPossessionSystem] CLIENT: Received hide command for userId: " .. tostring(userId))
    
    -- Find the player with this userId
    local targetPlayer = nil
    for _, player in ipairs(scene.players) do
        if player.user.id == userId then
            targetPlayer = player
            break
        end
    end
    
    if not targetPlayer then
        print("[PropPossessionSystem] CLIENT: Player not found for userId: " .. tostring(userId))
        return
    end
    
    if not targetPlayer.character then
        print("[PropPossessionSystem] CLIENT: No character to hide for " .. targetPlayer.name)
        return
    end

    local success, errorMsg = pcall(function()
        local character = targetPlayer.character

        -- Only disable NavMesh for local player (movement control)
        if targetPlayer == client.localPlayer then
            if not navMeshGameObject then
                navMeshGameObject = GameObject.Find("NavMesh")
            end

            if navMeshGameObject then
                navMeshGameObject:SetActive(false)
                print("[PropPossessionSystem] CLIENT: ✓ Disabled NavMesh for local player")
            end
        end

        -- Disable character GameObject (visible to all clients)
        local characterGameObject = character.gameObject
        if characterGameObject then
            characterGameObject:SetActive(false)
            print("[PropPossessionSystem] CLIENT: ✓ Hidden avatar for " .. targetPlayer.name)
        end
    end)

    if not success then
        print("[PropPossessionSystem] CLIENT: ERROR hiding avatar: " .. tostring(errorMsg))
    end
end

local function RestorePlayerAvatarExecute(userId)
    print("[PropPossessionSystem] CLIENT: Received restore command for userId: " .. tostring(userId))
    
    -- Find the player with this userId
    local targetPlayer = nil
    for _, player in ipairs(scene.players) do
        if player.user.id == userId then
            targetPlayer = player
            break
        end
    end
    
    if not targetPlayer then
        print("[PropPossessionSystem] CLIENT: Player not found for userId: " .. tostring(userId))
        return
    end
    
    if not targetPlayer.character then
        print("[PropPossessionSystem] CLIENT: No character to restore for " .. targetPlayer.name)
        return
    end

    local success, errorMsg = pcall(function()
        local character = targetPlayer.character

        -- Re-enable character GameObject (visible to all clients)
        local characterGameObject = character.gameObject
        if characterGameObject and not characterGameObject.activeSelf then
            characterGameObject:SetActive(true)
            print("[PropPossessionSystem] CLIENT: ✓ Restored avatar for " .. targetPlayer.name)
        end

        -- Only re-enable NavMesh for local player (movement control)
        if targetPlayer == client.localPlayer then
            if navMeshGameObject then
                navMeshGameObject:SetActive(true)
                print("[PropPossessionSystem] CLIENT: ✓ Enabled NavMesh for local player")
            end
        end
    end)

    if not success then
        print("[PropPossessionSystem] CLIENT: ERROR restoring avatar: " .. tostring(errorMsg))
    end
end

--[[
    CLIENT - Prop Visuals Control
]]
function HidePropVisuals(propName)
    local propData = propsData[propName]
    if not propData then return end

    -- Turn off emission (blend in with environment)
    if propData.renderer then
        local success = pcall(function()
            local material = propData.renderer.material
            material:SetFloat("_EmissionStrength", 0.0)
            print("[PropPossessionSystem] ✓ Disabled emission on " .. propName)
        end)

        if not success then
            print("[PropPossessionSystem] WARNING: Could not disable emission on " .. propName)
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

    -- Restore emission
    if propData.renderer then
        local success = pcall(function()
            local material = propData.renderer.material
            material:SetFloat("_EmissionStrength", propData.savedEmission)
            print("[PropPossessionSystem] ✓ Restored emission on " .. propName)
        end)
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
    print("[PropPossessionSystem] Setting up state tracking...")

    local localPlayer = client.localPlayer
    if localPlayer then
        local playerInfo = PlayerManager.GetPlayerInfo(localPlayer)
        if playerInfo then
            -- Track game state via per-player NetworkValue
            if playerInfo.gameState then
                currentStateValue = playerInfo.gameState
                currentState = NormalizeState(currentStateValue.value)
                print("[PropPossessionSystem] Initial state: " .. currentState)

                currentStateValue.Changed:Connect(function(newStateNum, oldStateNum)
                    local oldState = currentState
                    currentState = NormalizeState(newStateNum)
                    print("[PropPossessionSystem] State changed: " .. oldState .. " -> " .. currentState)

                    -- Reset possession tracking when entering HIDING phase
                    if currentState == "HIDING" and oldState ~= "HIDING" then
                        hasPossessedThisRound = false

                        -- Reset all props' isPossessed flags
                        for propName, propData in pairs(propsData) do
                            propData.isPossessed = false
                        end

                        RestoreAllPropVisuals()
                        print("[PropPossessionSystem] Reset for new HIDING phase")
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
                print("[PropPossessionSystem] Initial role: " .. localRole)

                playerInfo.role.Changed:Connect(function(newRole, oldRole)
                    localRole = newRole
                    print("[PropPossessionSystem] Role changed: " .. oldRole .. " -> " .. localRole)
                end)
            end
        else
            print("[PropPossessionSystem] WARNING: Could not get player info")
        end
    end
end

--[[
    SERVER - Possession Request Handler
]]
local function HandlePossessionRequest(player, propName)
    print(string.format("[PropPossessionSystem] SERVER: Possession request from %s for prop %s", player.name, tostring(propName)))

    local success = false
    local message = ""

    -- Get current game state
    local gameState = GameManager.GetCurrentState()

    -- Validate game phase (2 = HIDING)
    if gameState ~= 2 then
        print(string.format("[PropPossessionSystem] SERVER: Denied - not HIDING phase (current: %d)", gameState))
        success = false
        message = "Not hiding phase"
    else
        -- Get player info to check role
        local playerInfo = PlayerManager.GetPlayerInfo(player)
        if not playerInfo or playerInfo.role.value ~= "prop" then
            print(string.format("[PropPossessionSystem] SERVER: Denied - %s is not a prop", player.name))
            success = false
            message = "Not a prop"
        -- Check if prop already possessed by another player
        elseif possessedProps[propName] and possessedProps[propName] ~= player.id then
            local ownerPlayerId = possessedProps[propName]
            print(string.format("[PropPossessionSystem] SERVER: Denied - prop %s owned by player %s", propName, tostring(ownerPlayerId)))
            success = false
            message = "Prop already possessed"
        else
            -- Check if player has already possessed a different prop (One-Prop Rule)
            local hasOtherProp = false
            for propID, playerID in pairs(possessedProps) do
                if playerID == player.id and propID ~= propName then
                    print(string.format("[PropPossessionSystem] SERVER: Denied - %s already possessed prop %s (One-Prop Rule)", player.name, tostring(propID)))
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
                print(string.format("[PropPossessionSystem] SERVER: ✓ SUCCESS - %s -> prop %s", player.name, propName))
                success = true
                message = "Possessed successfully"
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
    print("[PropPossessionSystem] ClientStart - Initializing client-side system")

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
    print("[PropPossessionSystem] Client listening for possession results")
    
    -- Listen for avatar visibility commands from server
    hideAvatarCommand:Connect(HidePlayerAvatarExecute)
    restoreAvatarCommand:Connect(RestorePlayerAvatarExecute)
    print("[PropPossessionSystem] Client listening for avatar visibility commands")
end

--[[
    SERVER LIFECYCLE
]]
function self:ServerAwake()
    print("[PropPossessionSystem] ServerAwake - Initializing server-side system")

    -- Handle possession requests from clients
    possessionRequestEvent:Connect(HandlePossessionRequest)
    print("[PropPossessionSystem] Server listening for possession requests")
    
    -- Handle avatar visibility requests from clients
    hideAvatarRequest:Connect(HandleHideAvatarRequest)
    restoreAvatarRequest:Connect(HandleRestoreAvatarRequest)
    print("[PropPossessionSystem] Server listening for avatar visibility requests")

    -- Listen for state changes to reset prop tracking
    local stateChangedEvent = Event.new("PH_StateChanged")
    stateChangedEvent:Connect(function(newState, timer)
        -- Reset prop possession tracking when entering HIDING phase (2 = HIDING)
        if newState == 2 then
            possessedProps = {}
            print("[PropPossessionSystem] SERVER: Reset possession tracking for new HIDING phase")
        end
    end)
end

