--[[
    HunterTagSystem (Client)
    Tap-to-tag logic with cooldown and raycast. Remote call is scaffolded.
]]

--!Type(Module)

-- Cooldown between tag attempts (seconds)
--!SerializeField
--!Tooltip("Seconds between tag attempts")
local shootCooldown = 2.0

-- Network events (must match server names)
local stateChangedEvent = Event.new("PH_StateChanged")
local roleAssignedEvent = Event.new("PH_RoleAssigned")
local playerTaggedEvent = Event.new("PH_PlayerTagged")
local tagRequest = RemoteFunction.new("PH_TagRequest")
local lastShotTime = -9999
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

local function IsHuntPhase()
    return localRole == "hunter" and currentState == "HUNTING"
end

local function TryInvokeServerTag(hitObject)
    -- Attempt to resolve a player id from the hit object
    local targetId = nil
    if hitObject then
        local character = hitObject:GetComponent(Character)
        if (not character) and hitObject.transform then
            character = hitObject.transform:GetComponentInParent(Character)
        end
        if character and character.player then
            targetId = character.player.id
        end
    end

    if not targetId then
        print("[HunterTagSystem] No valid target player on hit object")
        return
    end

    tagRequest:InvokeServer(targetId, function(ok, msg)
        print("[HunterTagSystem] Tag result:", ok, msg)
    end)
end

local function SpawnHitEffect(point)
    -- TODO: Hook VFX system; placeholder log
    print(string.format("[HunterTagSystem] Hit @ (%.2f, %.2f, %.2f)", point.x, point.y, point.z))
end

local function OnTapToShoot(tap)
    if not IsHuntPhase() then
        return
    end

    if Time.time < lastShotTime + shootCooldown then
        return
    end

    local cam = Camera.main
    if cam == nil then
        print("[HunterTagSystem] No main camera available")
        return
    end

    local ray = cam:ScreenPointToRay(tap.position)
    local hit : RaycastHit
    local didHit = Physics.Raycast(ray, hit, 100)
    if didHit then
        TryInvokeServerTag(hit.collider and hit.collider.gameObject or nil)
        SpawnHitEffect(hit.point)
        lastShotTime = Time.time
    end
end

function self:ClientStart()
    print("[HunterTagSystem] ClientStart")
    Input.Tapped:Connect(OnTapToShoot)

    -- Listen for tag events (for VFX feedback)
    playerTaggedEvent:Connect(function(hunterId, propId)
        print("[HunterTagSystem] Player tagged -> hunter:", tostring(hunterId), "prop:", tostring(propId))
    end)

    -- Listen for state/role updates
    stateChangedEvent:Connect(function(newState, timer)
        currentState = NormalizeState(newState)
    end)

    roleAssignedEvent:Connect(function(role)
        localRole = tostring(role)
        print("[HunterTagSystem] Role:", localRole)
    end)
end
