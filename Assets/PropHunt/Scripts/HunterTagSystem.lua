--[[
    HunterTagSystem (Client)
    Tap-to-tag logic with cooldown and raycast. Remote call is scaffolded.
]]

--!Type(Module)

-- Import required modules
local Config = require("PropHuntConfig")
local VFXManager = require("PropHuntVFXManager")

-- Cooldown between tag attempts (seconds) - Now uses Config
--!SerializeField
--!Tooltip("Seconds between tag attempts (overridden by Config)")
local shootCooldown = 2.0

-- Network events (must match server names)
local stateChangedEvent = Event.new("PH_StateChanged")
local roleAssignedEvent = Event.new("PH_RoleAssigned")
local playerTaggedEvent = Event.new("PH_PlayerTagged")

-- Remote functions
local tagRequest = RemoteFunction.new("PH_TagRequest")
local tagMissedRequest = RemoteFunction.new("PH_TagMissed")
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

local function TryInvokeServerTag(hitObject, hitPoint)
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
        -- Report miss to server for scoring
        tagMissedRequest:InvokeServer(function(ok, msg)
            print("[HunterTagSystem] Miss recorded:", ok, msg)
        end)
        -- Trigger miss VFX
        if hitPoint then
            VFXManager.TagMissVFX(hitPoint, nil)
        end
        return
    end

    -- Client-side distance validation (V1 SPEC: R_tag = 4.0m)
    local localPlayer = client.localPlayer
    if localPlayer and localPlayer.character then
        local playerPos = localPlayer.character.transform.position
        local distance = Vector3.Distance(playerPos, hitPoint)

        if distance > Config.GetTagRange() then
            print(string.format("[HunterTagSystem] Target too far: %.2fm (max %.2fm)", distance, Config.GetTagRange()))
            -- Report miss to server for scoring
            tagMissedRequest:InvokeServer(function(ok, msg)
                print("[HunterTagSystem] Miss recorded:", ok, msg)
            end)
            -- Trigger miss VFX
            VFXManager.TagMissVFX(hitPoint, nil)
            return
        end
    end

    tagRequest:InvokeServer(targetId, function(ok, msg)
        print("[HunterTagSystem] Tag result:", ok, msg)

        -- Trigger appropriate VFX based on result
        if ok then
            VFXManager.TagHitVFX(hitPoint, hitObject)
        else
            VFXManager.TagMissVFX(hitPoint, nil)
            -- Report miss to server for failed tags
            tagMissedRequest:InvokeServer(function(missOk, missMsg)
                print("[HunterTagSystem] Miss recorded:", missOk, missMsg)
            end)
        end
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

    -- Use cooldown from Config (V1 SPEC: 0.5s)
    local cooldown = Config.GetTagCooldown()
    if Time.time < lastShotTime + cooldown then
        return
    end

    local cam = Camera.main
    if cam == nil then
        print("[HunterTagSystem] No main camera available")
        return
    end

    local localPlayer = client.localPlayer
    if not localPlayer or not localPlayer.character then
        print("[HunterTagSystem] No local player character")
        return
    end

    -- V1 SPEC REQUIREMENT: Raycast from player body origin (NOT camera) toward tap world point
    -- Get the world position that the player tapped on screen
    local tapRay = cam:ScreenPointToRay(tap.position)
    local tapHit : RaycastHit
    local tapDidHit = Physics.Raycast(tapRay, tapHit, 1000)

    if not tapDidHit then
        print("[HunterTagSystem] Tap didn't hit anything in world")
        return
    end

    -- Calculate direction from player position to tap point
    local playerPos = localPlayer.character.transform.position
    local tapWorldPos = tapHit.point
    local direction = (tapWorldPos - playerPos).normalized

    -- Raycast from player body origin toward the tap point
    local ray = Ray.new(playerPos, direction)
    local hit : RaycastHit
    local didHit = Physics.Raycast(ray, hit, Config.GetTagRange())

    if didHit then
        TryInvokeServerTag(hit.collider and hit.collider.gameObject or nil, hit.point)
        SpawnHitEffect(hit.point)
        lastShotTime = Time.time
    else
        -- Miss - raycast didn't hit anything within range
        print("[HunterTagSystem] Miss - no hit within range")
        -- Report miss to server for scoring
        tagMissedRequest:InvokeServer(function(ok, msg)
            print("[HunterTagSystem] Miss recorded:", ok, msg)
        end)
        -- Use the tap world position for miss VFX (visual feedback where they aimed)
        VFXManager.TagMissVFX(tapWorldPos, nil)
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
