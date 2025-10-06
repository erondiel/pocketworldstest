--[[
    PropDisguiseSystem (Client)
    Tap-to-select a prop during Hide phase, with confirm entry point.
]]

--!Type(Client)

-- limit selection distance (meters)
--!SerializeField
--!Tooltip("Max distance to select a prop")
local maxSelectDistance = 50

local selectedProp = nil
local disguiseRequest = nil

local function IsHidePhase()
    -- TODO: Wire to server state via RemoteFunction/state sync
    return true
end

local function IsValidProp(go)
    -- TODO: Replace with layer/tag checks
    return go ~= nil
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
    local hit = RaycastHit()
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
        if not disguiseRequest then
            disguiseRequest = RemoteFunction.new("PH_DisguiseRequest")
        end
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
end
