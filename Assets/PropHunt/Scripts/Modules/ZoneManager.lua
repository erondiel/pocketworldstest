--[[
    ZoneManager Module

    Centralized zone tracking system for PropHunt scoring.
    Tracks which zone each player is currently in and provides zone weight lookup.

    Usage:
    - ZoneVolume components automatically register/unregister zones
    - Call GetPlayerZone(player) to get current zone weight (for scoring)
    - Call GetPlayerZoneName(player) to get current zone name (for UI)

    Default Behavior:
    - Players not in any zone default to weight 1.0
    - Players in multiple overlapping zones use the FIRST zone they entered
]]

--!Type(Module)

local Config = require("PropHuntConfig")

-- Zone registry: { GameObject -> { name, weight } }
local registeredZones : { [GameObject]: { name: string, weight: number } } = {}

-- Player zone tracking: { Player -> { zoneName, zoneWeight, zoneObject } }
local playerZones : { [Player]: { zoneName: string, zoneWeight: number, zoneObject: GameObject } } = {}

-- Debug mode
local debugEnabled : boolean = false

-------------------------- INTERNAL --------------------------
------------------------------------------------------------

local function DebugLog(message : string)
    if debugEnabled then
        print("[ZoneManager] " .. message)
    end
end

-------------------------- PUBLIC API --------------------------
------------------------------------------------------------

-- Register a zone volume
function RegisterZone(zoneObject : GameObject, zoneName : string, zoneWeight : number)
    if not zoneObject then
        print("[ZoneManager] ERROR: Cannot register nil zone object")
        return
    end

    if registeredZones[zoneObject] then
        DebugLog("Zone already registered: " .. zoneName)
        return
    end

    registeredZones[zoneObject] = {
        name = zoneName,
        weight = zoneWeight
    }

    DebugLog("Registered zone: " .. zoneName .. " (weight: " .. tostring(zoneWeight) .. ")")
end

-- Unregister a zone volume
function UnregisterZone(zoneObject : GameObject)
    if not zoneObject then
        return
    end

    local zoneInfo = registeredZones[zoneObject]
    if zoneInfo then
        DebugLog("Unregistered zone: " .. zoneInfo.name)

        -- Clear any players in this zone
        for player, playerZone in pairs(playerZones) do
            if playerZone.zoneObject == zoneObject then
                playerZones[player] = nil
                DebugLog("Removed player " .. player.name .. " from unregistered zone")
            end
        end

        registeredZones[zoneObject] = nil
    end
end

-- Player enters a zone
function OnPlayerEnterZone(player : Player, zoneName : string, zoneWeight : number, zoneObject : GameObject)
    if not player then
        DebugLog("ERROR: OnPlayerEnterZone called with nil player")
        return
    end

    -- If player is already in a zone, ignore (first zone priority)
    if playerZones[player] then
        local currentZone = playerZones[player].zoneName
        DebugLog("Player " .. player.name .. " already in zone '" .. currentZone .. "', ignoring new zone '" .. zoneName .. "'")
        return
    end

    -- Track player in new zone
    playerZones[player] = {
        zoneName = zoneName,
        zoneWeight = zoneWeight,
        zoneObject = zoneObject
    }

    DebugLog("Player " .. player.name .. " entered zone: " .. zoneName .. " (weight: " .. tostring(zoneWeight) .. ")")
end

-- Player exits a zone
function OnPlayerExitZone(player : Player, zoneObject : GameObject)
    if not player then
        DebugLog("ERROR: OnPlayerExitZone called with nil player")
        return
    end

    local playerZone = playerZones[player]

    -- Only clear if exiting the current tracked zone
    if playerZone and playerZone.zoneObject == zoneObject then
        local zoneName = playerZone.zoneName
        playerZones[player] = nil
        DebugLog("Player " .. player.name .. " exited zone: " .. zoneName)
    else
        DebugLog("Player " .. player.name .. " exited non-tracked zone, ignoring")
    end
end

-- Get player's current zone weight (for scoring calculations)
function GetPlayerZone(player : Player) : number
    if not player then
        return 1.0  -- Default weight
    end

    local playerZone = playerZones[player]
    if playerZone then
        return playerZone.zoneWeight
    end

    -- Default to 1.0 if not in any zone
    return 1.0
end

-- Get player's current zone name (for UI/debugging)
function GetPlayerZoneName(player : Player) : string
    if not player then
        return "None"
    end

    local playerZone = playerZones[player]
    if playerZone then
        return playerZone.zoneName
    end

    return "None"
end

-- Get all players currently in zones (debugging/stats)
function GetAllPlayerZones() : { [Player]: { zoneName: string, zoneWeight: number, zoneObject: GameObject } }
    return playerZones
end

-- Get zone info by GameObject
function GetZoneInfo(zoneObject : GameObject) : { name: string, weight: number }
    if not zoneObject then
        return nil
    end

    return registeredZones[zoneObject]
end

-- Clear all player zone tracking (useful for round reset)
function ClearAllPlayerZones()
    local count = 0
    for player, _ in pairs(playerZones) do
        count = count + 1
    end

    if count > 0 then
        DebugLog("Clearing " .. tostring(count) .. " players from all zones")
    end

    playerZones = {}
end

-- Remove specific player from tracking (useful for disconnections)
function RemovePlayer(player : Player)
    if playerZones[player] then
        local zoneName = playerZones[player].zoneName
        DebugLog("Removed player " .. player.name .. " from zone: " .. zoneName)
        playerZones[player] = nil
    end
end

-- Get stats for debugging
function GetZoneStats() : { totalZones: number, playersInZones: number }
    local zoneCount = 0
    local playerCount = 0

    for _, _ in pairs(registeredZones) do
        zoneCount = zoneCount + 1
    end

    for _, _ in pairs(playerZones) do
        playerCount = playerCount + 1
    end

    return {
        totalZones = zoneCount,
        playersInZones = playerCount
    }
end

-- Enable/disable debug logging
function SetDebugEnabled(enabled : boolean)
    debugEnabled = enabled
    DebugLog("Debug logging " .. (enabled and "enabled" or "disabled"))
end

-- Get zone weights from config (helper for other systems)
function GetZoneWeightByName(zoneName : string) : number
    if zoneName == "NearSpawn" then
        return Config.GetZoneWeightNearSpawn()
    elseif zoneName == "Mid" then
        return Config.GetZoneWeightMid()
    elseif zoneName == "Far" then
        return Config.GetZoneWeightFar()
    else
        print("[ZoneManager] WARNING: Unknown zone name '" .. zoneName .. "', returning 1.0")
        return 1.0
    end
end

-- Print debug info
function PrintDebugInfo()
    print("[ZoneManager] === Zone Debug Info ===")

    local stats = GetZoneStats()
    print("[ZoneManager] Total zones: " .. tostring(stats.totalZones))
    print("[ZoneManager] Players in zones: " .. tostring(stats.playersInZones))

    print("[ZoneManager] Registered zones:")
    for zoneObject, info in pairs(registeredZones) do
        print("[ZoneManager]   - " .. info.name .. " (weight: " .. tostring(info.weight) .. ")")
    end

    print("[ZoneManager] Player zones:")
    for player, zone in pairs(playerZones) do
        print("[ZoneManager]   - " .. player.name .. " in " .. zone.zoneName .. " (weight: " .. tostring(zone.zoneWeight) .. ")")
    end

    print("[ZoneManager] =====================")
end

-- ========== MODULE EXPORTS ==========

return {
    -- Zone registration
    RegisterZone = RegisterZone,
    UnregisterZone = UnregisterZone,

    -- Player zone tracking
    OnPlayerEnterZone = OnPlayerEnterZone,
    OnPlayerExitZone = OnPlayerExitZone,

    -- Zone queries
    GetPlayerZone = GetPlayerZone,
    GetPlayerZoneName = GetPlayerZoneName,
    GetAllPlayerZones = GetAllPlayerZones,
    GetZoneInfo = GetZoneInfo,

    -- Zone management
    ClearAllPlayerZones = ClearAllPlayerZones,
    RemovePlayer = RemovePlayer,

    -- Utilities
    GetZoneStats = GetZoneStats,
    GetZoneWeightByName = GetZoneWeightByName,
    SetDebugEnabled = SetDebugEnabled,
    PrintDebugInfo = PrintDebugInfo
}
