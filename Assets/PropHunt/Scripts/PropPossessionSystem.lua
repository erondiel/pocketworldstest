--!Type(Client)

--[[
    PropPossessionSystem.lua

    Handles prop possession mechanics for PropHunt.
    Attached to each possessable prop GameObject.

    FEATURES:
    - Click-to-possess interaction using TapHandler
    - Automatic player movement via TapHandler (moveTo = true)
    - Avatar hidden and movement disabled
    - Prop emission turned off (blends in)
    - Prop outline disabled
    - One-Prop Rule: Can only possess once per round
    - Network validation via server

    SETUP:
    1. Add TapHandler component to prop GameObject
       - Enable "Move To" checkbox
       - Set "Move Target" to prop position (or leave default)
       - Set "Distance" to interaction range (e.g., 3.0)
    2. Attach this script to the prop GameObject
    3. Ensure prop has:
       - Tag: "Possessable"
       - Material with _EmissionStrength property
       - Optional: Outline child GameObject (PropName_Outline)

    TAPHANDLER CONFIGURATION:
    The TapHandler component automatically handles player movement:
    - moveTo = true: Player walks to prop before Tapped event fires
    - moveTarget: Position to move to (defaults to GameObject position)
    - distance: Required distance to trigger (recommend 2-3 meters)

    INTEGRATION:
    Works with PropHuntGameManager state system.
    Only active during HIDING phase for players with "prop" role.
]]

local VFXManager = require("PropHuntVFXManager")
local PlayerManager = require("PropHuntPlayerManager")

-- Network events (kept for backward compatibility)
local stateChangedEvent = Event.new("PH_StateChanged")
local roleAssignedEvent = Event.new("PH_RoleAssigned")
local possessionRequest = RemoteFunction.new("PH_PossessionRequest")

-- Network values for persistent state
local currentStateValue = nil
local playerRoleValue = nil

-- Local state
local currentState = "LOBBY"
local localRole = "unknown"
local hasPossessedThisRound = false
local isPossessed = false
local savedEmissionStrength = 2.0
local navMeshGameObject = nil

-- Prop references
local propGameObject = nil
local propRenderer = nil
local outlineRenderer = nil

function self:Awake()
    propGameObject = self.gameObject

    print("[PropPossessionSystem] ===== AWAKE CALLED ===== Prop: " .. propGameObject.name)

    -- Get renderer for emission control
    propRenderer = propGameObject:GetComponent(MeshRenderer)
    if propRenderer then
        -- Read initial emission strength
        local success = pcall(function()
            local material = propRenderer.sharedMaterial
            if material then
                savedEmissionStrength = material:GetFloat("_EmissionStrength")
                print("[PropPossessionSystem] Saved emission strength: " .. savedEmissionStrength)
            end
        end)
    end

    -- Find outline renderer
    local outlineChild = propGameObject.transform:Find(propGameObject.name .. "_Outline")
    if outlineChild then
        outlineRenderer = outlineChild:GetComponent(MeshRenderer)
        if outlineRenderer then
            print("[PropPossessionSystem] Found outline renderer")
        end
    end

    -- Setup tap handler
    local tapHandler = propGameObject:GetComponent(TapHandler)
    if tapHandler then
        tapHandler.Tapped:Connect(function()
            OnPropTapped()
        end)
        print("[PropPossessionSystem] TapHandler connected")
    else
        print("[PropPossessionSystem] WARNING: No TapHandler component found!")
    end

    -- Setup NetworkValue tracking for game state
    Timer.After(0.5, function()
        print("[PropPossessionSystem] Setting up NetworkValue tracking for: " .. propGameObject.name)

        -- Track game state via NetworkValue
        currentStateValue = NumberValue.new("PH_CurrentState", 1)
        if currentStateValue then
            -- Read initial state
            currentState = NormalizeState(currentStateValue.value)
            print("[PropPossessionSystem] Initial state from NetworkValue: " .. currentState)

            -- Listen for state changes
            currentStateValue.Changed:Connect(function(newStateNum, oldStateNum)
                local oldState = currentState
                currentState = NormalizeState(newStateNum)
                print("[PropPossessionSystem] State changed via NetworkValue: " .. oldState .. " -> " .. currentState)

                -- Reset possession tracking when entering HIDING phase
                if currentState == "HIDING" and oldState ~= "HIDING" then
                    hasPossessedThisRound = false
                    isPossessed = false
                    RestorePropVisuals()
                    print("[PropPossessionSystem] Reset for new HIDING phase")
                end

                -- Show prop visuals during HIDING phase
                if currentState == "HIDING" then
                    RestorePropVisuals()
                end
            end)
        else
            print("[PropPossessionSystem] ERROR: Could not create state NetworkValue")
        end

        -- Track player role via PlayerManager
        local localPlayer = client.localPlayer
        if localPlayer then
            local playerInfo = PlayerManager.GetPlayerInfo(localPlayer)
            if playerInfo and playerInfo.role then
                -- Read initial role
                localRole = playerInfo.role.value
                print("[PropPossessionSystem] Initial role from NetworkValue: " .. localRole)

                -- Listen for role changes
                playerInfo.role.Changed:Connect(function(newRole, oldRole)
                    localRole = newRole
                    print("[PropPossessionSystem] Role changed via NetworkValue: " .. oldRole .. " -> " .. localRole)
                end)
            else
                print("[PropPossessionSystem] WARNING: Could not get player info for role tracking")
            end
        end
    end)

    -- Listen for state changes (backup event system)
    stateChangedEvent:Connect(function(newState, timer)
        print("[PropPossessionSystem] STATE EVENT RECEIVED: " .. tostring(newState) .. " (timer: " .. tostring(timer) .. ")")
        local oldState = currentState
        currentState = NormalizeState(newState)
        print("[PropPossessionSystem] State updated via event: " .. oldState .. " -> " .. currentState)

        -- Reset possession tracking when entering HIDING phase
        if currentState == "HIDING" and oldState ~= "HIDING" then
            hasPossessedThisRound = false
            isPossessed = false
            RestorePropVisuals()
            print("[PropPossessionSystem] Reset for new HIDING phase")
        end

        -- Show prop visuals during HIDING phase
        if currentState == "HIDING" then
            RestorePropVisuals()
        end
    end)

    -- Listen for role assignment (backup event system)
    roleAssignedEvent:Connect(function(role)
        print("[PropPossessionSystem] ROLE EVENT RECEIVED: " .. tostring(role))
        localRole = tostring(role)
        print("[PropPossessionSystem] Local role updated via event: " .. localRole)
    end)
end

function NormalizeState(value)
    if type(value) == "number" then
        if value == 1 then return "LOBBY"
        elseif value == 2 then return "HIDING"
        elseif value == 3 then return "HUNTING"
        elseif value == 4 then return "ROUND_END"
        end
    end
    return tostring(value)
end

function OnPropTapped()
    print("[PropPossessionSystem] Prop tapped! currentState=" .. currentState .. ", localRole=" .. localRole)

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
        VFXManager.RejectionVFX(propGameObject.transform.position, propGameObject)
        return
    end

    -- Check if already possessed by someone
    if isPossessed then
        print("[PropPossessionSystem] This prop is already possessed!")
        VFXManager.RejectionVFX(propGameObject.transform.position, propGameObject)
        return
    end

    print("[PropPossessionSystem] Attempting to possess: " .. propGameObject.name)

    -- TapHandler has already moved player to prop (if moveTo = true)
    -- Player is now at the prop, request possession immediately
    RequestPossession()
end

function RequestPossession()
    -- Use GameObject name as unique identifier (scene prop names should be unique)
    local propIdentifier = propGameObject.name

    possessionRequest:InvokeServer(propIdentifier, function(ok, msg)
        print("[PropPossessionSystem] Possession response: " .. tostring(ok) .. ", " .. tostring(msg))

        if ok then
            -- Success! Possess the prop
            hasPossessedThisRound = true
            isPossessed = true

            -- Visual effects
            local player = client.localPlayer
            local playerPos = player.character.transform.position
            VFXManager.PlayerVanishVFX(playerPos, player.character)
            VFXManager.PropInfillVFX(propGameObject.transform.position, propGameObject)

            -- Hide player avatar and disable movement
            HidePlayerAvatar()

            -- Hide prop visuals (blend in)
            HidePropVisuals()

            print("[PropPossessionSystem] ✓✓✓ POSSESSION COMPLETE ✓✓✓")
        else
            -- Server rejected
            print("[PropPossessionSystem] Possession rejected: " .. tostring(msg))
            VFXManager.RejectionVFX(propGameObject.transform.position, propGameObject)
        end
    end)
end

function HidePlayerAvatar()
    local player = client.localPlayer
    if not player or not player.character then return end

    local success, errorMsg = pcall(function()
        local character = player.character

        -- Find and disable NavMesh GameObject
        if not navMeshGameObject then
            navMeshGameObject = GameObject.Find("NavMesh")
        end

        if navMeshGameObject then
            navMeshGameObject:SetActive(false)
            print("[PropPossessionSystem] ✓ Disabled NavMesh (movement disabled)")
        else
            print("[PropPossessionSystem] WARNING: NavMesh GameObject not found")
        end

        -- Disable character GameObject
        local characterGameObject = character.gameObject
        if characterGameObject then
            characterGameObject:SetActive(false)
            print("[PropPossessionSystem] ✓ Hidden player avatar")
        end
    end)

    if not success then
        print("[PropPossessionSystem] ERROR hiding avatar: " .. tostring(errorMsg))
    end
end

function RestorePlayerAvatar()
    local player = client.localPlayer
    if not player or not player.character then return end

    local success, errorMsg = pcall(function()
        local character = player.character

        -- Re-enable character GameObject
        local characterGameObject = character.gameObject
        if characterGameObject and not characterGameObject.activeSelf then
            characterGameObject:SetActive(true)
            print("[PropPossessionSystem] ✓ Restored player avatar")
        end

        -- Re-enable NavMesh GameObject
        if navMeshGameObject then
            navMeshGameObject:SetActive(true)
            print("[PropPossessionSystem] ✓ Enabled NavMesh (movement restored)")
        end
    end)

    if not success then
        print("[PropPossessionSystem] ERROR restoring avatar: " .. tostring(errorMsg))
    end
end

function HidePropVisuals()
    -- Turn off emission (blend in with environment)
    if propRenderer then
        local success = pcall(function()
            local material = propRenderer.material
            material:SetFloat("_EmissionStrength", 0.0)
            print("[PropPossessionSystem] ✓ Disabled prop emission")
        end)

        if not success then
            print("[PropPossessionSystem] WARNING: Could not disable emission")
        end
    end

    -- Hide outline
    if outlineRenderer then
        outlineRenderer.enabled = false
        print("[PropPossessionSystem] ✓ Disabled prop outline")
    end
end

function RestorePropVisuals()
    -- Restore emission
    if propRenderer then
        local success = pcall(function()
            local material = propRenderer.material
            material:SetFloat("_EmissionStrength", savedEmissionStrength)
            print("[PropPossessionSystem] ✓ Restored prop emission")
        end)
    end

    -- Show outline
    if outlineRenderer then
        outlineRenderer.enabled = true
        print("[PropPossessionSystem] ✓ Enabled prop outline")
    end
end

--[[
    INTEGRATION NOTES:

    Server-side requirements (PropHuntGameManager or separate module):
    1. RemoteFunction "PH_PossessionRequest" handler
    2. Validate prop is available (not already possessed)
    3. Validate player is prop role and in HIDING phase
    4. Track which props are possessed
    5. Return (true, "Success") or (false, "Reason")

    Example server handler:

    local possessionRequest = RemoteFunction.new("PH_PossessionRequest")
    possessionRequest.OnInvokeServer = function(player, propInstanceID)
        -- Validate player role and phase
        if currentPhase ~= HIDING then
            return false, "Not in hiding phase"
        end

        if playerRole[player] ~= "prop" then
            return false, "Only props can possess"
        end

        -- Check if prop already possessed
        if possessedProps[propInstanceID] then
            return false, "Prop already taken"
        end

        -- Mark as possessed
        possessedProps[propInstanceID] = player

        return true, "Possessed successfully"
    end
]]
