--[[
    HunterTagSystem (Client)
    Tap-to-tag logic with cooldown and raycast. Remote call is scaffolded.
]]

--!Type(Client)

-- Cooldown between tag attempts (seconds)
--!SerializeField
--!Tooltip("Seconds between tag attempts")
local shootCooldown = 2.0

local lastShotTime = -9999
local tagRequest = nil
local playerTaggedEvent = nil

local function IsHuntPhase()
    -- TODO: Wire to server state via RemoteFunction/state sync
    -- For now, allow always; change to check a cached state set by server
    return true
end

local function TryInvokeServerTag(hitObject)
    if not tagRequest then
        tagRequest = RemoteFunction.new("PH_TagRequest")
    end

    -- Attempt to resolve a player id from the hit object
    local targetId = nil
    if hitObject then
        local character = hitObject:GetComponent(Character)
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
    local hit = RaycastHit()
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
    playerTaggedEvent = Event.new("PH_PlayerTagged")
    playerTaggedEvent:Connect(function(hunterId, propId)
        print("[HunterTagSystem] Player tagged -> hunter:", tostring(hunterId), "prop:", tostring(propId))
    end)
end
