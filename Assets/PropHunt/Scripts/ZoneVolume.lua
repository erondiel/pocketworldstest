--[[
    ZoneVolume Component

    Attach to GameObjects with trigger colliders to define scoring zones.
    Players entering these zones will have their zone weight tracked by ZoneManager.

    Setup:
    1. Add BoxCollider (or other collider) component with "Is Trigger" enabled
    2. Set GameObject layer to "CharacterTrigger"
    3. Attach this ZoneVolume script
    4. Configure zoneName and zoneWeight in Unity Inspector

    Zone Types:
    - NearSpawn: 1.5x multiplier (default)
    - Mid: 1.0x multiplier (default)
    - Far: 0.6x multiplier (default)
]]

--!Type(Server)

local ZoneManager = require("Modules.ZoneManager")

--!Tooltip("Name of the zone: NearSpawn, Mid, or Far")
--!SerializeField
local zoneName : string = "Mid"

--!Tooltip("Score multiplier for this zone (NearSpawn=1.5, Mid=1.0, Far=0.6)")
--!SerializeField
local zoneWeight : number = 1.0

--!Tooltip("Enable debug logging for this zone")
--!SerializeField
local enableDebug : boolean = false

-- Track which players are currently in this zone
local playersInZone : { [Player]: boolean } = {}

-- Debug logging
local function DebugLog(message : string)
    if enableDebug then
        print("[ZoneVolume:" .. zoneName .. "] " .. message)
    end
end

-- Validate zone configuration
local function ValidateZone()
    if zoneName ~= "NearSpawn" and zoneName ~= "Mid" and zoneName ~= "Far" then
        print("[ZoneVolume] WARNING: Invalid zoneName '" .. zoneName .. "'. Should be NearSpawn, Mid, or Far")
    end

    if zoneWeight <= 0 then
        print("[ZoneVolume] WARNING: zoneWeight must be positive, got: " .. tostring(zoneWeight))
        zoneWeight = 1.0
    end
end

-- Handle player entering zone
function self:OnTriggerEnter(other : Collider)
    -- Get the Character component from the collider
    local character = other.gameObject:GetComponent(Character)
    if not character then
        character = other.gameObject.transform:GetComponentInParent(Character)
    end

    if not character or not character.player then
        DebugLog("OnTriggerEnter: No valid player character detected")
        return
    end

    local player = character.player

    -- Skip if player is already tracked in this zone
    if playersInZone[player] then
        DebugLog("Player " .. player.name .. " already in zone")
        return
    end

    playersInZone[player] = true
    DebugLog("Player " .. player.name .. " entered zone (weight: " .. tostring(zoneWeight) .. ")")

    -- Notify ZoneManager
    ZoneManager.OnPlayerEnterZone(player, zoneName, zoneWeight, self.gameObject)
end

-- Handle player exiting zone
function self:OnTriggerExit(other : Collider)
    -- Get the Character component from the collider
    local character = other.gameObject:GetComponent(Character)
    if not character then
        character = other.gameObject.transform:GetComponentInParent(Character)
    end

    if not character or not character.player then
        DebugLog("OnTriggerExit: No valid player character detected")
        return
    end

    local player = character.player

    -- Skip if player is not tracked in this zone
    if not playersInZone[player] then
        DebugLog("Player " .. player.name .. " not tracked in zone")
        return
    end

    playersInZone[player] = nil
    DebugLog("Player " .. player.name .. " exited zone")

    -- Notify ZoneManager
    ZoneManager.OnPlayerExitZone(player, self.gameObject)
end

-- Clear all players from zone (useful for cleanup/reset)
function ClearZone()
    local count = 0
    for player, _ in pairs(playersInZone) do
        count = count + 1
    end

    if count > 0 then
        DebugLog("Clearing " .. tostring(count) .. " players from zone")
    end

    playersInZone = {}
end

-- Get players currently in this zone
function GetPlayersInZone() : { [Player]: boolean }
    return playersInZone
end

-- Get zone info
function GetZoneName() : string
    return zoneName
end

function GetZoneWeight() : number
    return zoneWeight
end

-- Lifecycle
function self:ServerAwake()
    ValidateZone()
    DebugLog("Zone initialized: " .. zoneName .. " (weight: " .. tostring(zoneWeight) .. ")")

    -- Register with ZoneManager
    ZoneManager.RegisterZone(self.gameObject, zoneName, zoneWeight)
end

function self:OnDestroy()
    DebugLog("Zone destroyed, clearing players")
    ClearZone()

    -- Unregister from ZoneManager
    ZoneManager.UnregisterZone(self.gameObject)
end
