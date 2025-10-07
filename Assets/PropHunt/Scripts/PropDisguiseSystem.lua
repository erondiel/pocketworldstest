--[[
    PropDisguiseSystem (Client)
    Tap-to-select a prop during Hide phase, with confirm entry point.
]]

--!Type(Module)

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
    if selectedProp then
        -- For now send a basic identifier (name). Replace with a stable ID if available.
        local identifier = selectedProp.name or tostring(selectedProp)
        disguiseRequest:InvokeServer(identifier, function(ok, msg)
            print("[PropDisguiseSystem] Disguise result:", ok, msg)
        end)
    end
end

function self:ClientStart()
    print("[PropDisguiseSystem] ClientStart")
    Input.Tapped:Connect(OnTapToSelect)

    -- Listen for state/role updates
    stateChangedEvent:Connect(function(newState, timer)
        currentState = NormalizeState(newState)
    end)

    roleAssignedEvent:Connect(function(role)
        localRole = tostring(role)
        print("[PropDisguiseSystem] Role:", localRole)
    end)
end
