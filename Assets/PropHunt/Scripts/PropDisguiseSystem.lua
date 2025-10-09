--[[
    PropDisguiseSystem (Client)
    Tap-to-select a prop during Hide phase, with confirm entry point.
]]

--!Type(Module)

-- Import VFXManager for visual effects
local VFXManager = require("Modules.PropHuntVFXManager")

-- limit selection distance (meters)
--!SerializeField
--!Tooltip("Max distance to select a prop")
local maxSelectDistance = 50

-- Network events (must match server names)
local stateChangedEvent = Event.new("PH_StateChanged")
local roleAssignedEvent = Event.new("PH_RoleAssigned")
local disguiseRequest = RemoteFunction.new("PH_DisguiseRequest")
local selectedProp = nil
local currentState = "LOBBY"
local localRole = "unknown"

-- One-Prop Rule tracking: prevent unpossess after first possession
local hasPossessedThisRound = false

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

local function IsHidePhase()
    return localRole == "prop" and currentState == "HIDING"
end

local function IsValidProp(go)
    if not go then return false end
    -- Check for Possessable marker on self or parent
    local poss = go:GetComponent(Possessable)
    if (not poss) and go.transform then
        poss = go.transform:GetComponentInParent(Possessable)
    end
    return poss ~= nil
end

local function ShowConfirmationUI(go)
    -- TODO: Hook UI service; placeholder log
    print("[PropDisguiseSystem] Selected prop candidate:", tostring(go))
    print("[PropDisguiseSystem] Call OnConfirmDisguise() to confirm")
end

local function OnTapToSelect(tap)
    if not IsHidePhase() then return end

    local cam = Camera.main
    if cam == nil then
        print("[PropDisguiseSystem] No main camera available")
        return
    end

    local ray = cam:ScreenPointToRay(tap.position)
    local hit : RaycastHit
    local didHit = Physics.Raycast(ray, hit, maxSelectDistance)
    if didHit then
        local hitObject = hit.collider and hit.collider.gameObject or nil
        if IsValidProp(hitObject) then
            selectedProp = hitObject
            ShowConfirmationUI(hitObject)
        end
    end
end

function OnConfirmDisguise()
    -- Check if player has already possessed a prop this round (One-Prop Rule)
    if hasPossessedThisRound then
        print("[PropDisguiseSystem] Already possessed a prop this round - unpossess disabled")
        -- Show rejection VFX on the selected prop
        if selectedProp then
            local propPos = selectedProp.transform.position
            VFXManager.RejectionVFX(propPos, selectedProp)
        end
        return
    end

    if selectedProp then
        -- Get player position for vanish VFX
        local playerCharacter = client.localPlayer and client.localPlayer.character
        local playerPos = playerCharacter and playerCharacter.transform.position or Vector3.zero

        -- For now send a basic identifier (name). Replace with a stable ID if available.
        local identifier = selectedProp.name or tostring(selectedProp)
        disguiseRequest:InvokeServer(identifier, function(ok, msg)
            print("[PropDisguiseSystem] Disguise result:", ok, msg)

            if ok then
                -- Mark that we've possessed a prop this round (One-Prop Rule)
                hasPossessedThisRound = true

                -- Trigger possession VFX
                VFXManager.PlayerVanishVFX(playerPos, playerCharacter)
                VFXManager.PropInfillVFX(selectedProp.transform.position, selectedProp)
            else
                -- Server rejected (e.g., prop already taken by another player)
                print("[PropDisguiseSystem] Possession rejected: " .. tostring(msg))
                VFXManager.RejectionVFX(selectedProp.transform.position, selectedProp)
            end
        end)
    end
end

function self:ClientStart()
    print("[PropDisguiseSystem] ClientStart")
    Input.Tapped:Connect(OnTapToSelect)

    -- Listen for state/role updates
    stateChangedEvent:Connect(function(newState, timer)
        local oldState = currentState
        currentState = NormalizeState(newState)

        -- Reset possession tracking when entering HIDING phase
        if currentState == "HIDING" and oldState ~= "HIDING" then
            hasPossessedThisRound = false
            print("[PropDisguiseSystem] Entered HIDING phase - possession tracking reset")
        end
    end)

    roleAssignedEvent:Connect(function(role)
        localRole = tostring(role)
        print("[PropDisguiseSystem] Role:", localRole)
    end)
end
