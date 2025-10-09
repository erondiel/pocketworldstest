--[[
    PropHunt Teleporter Module
    Single-scene position-based teleportation (mobile-friendly)

    Usage:
    1. In Unity, create two empty GameObjects:
       - LobbySpawn (position where lobby is, e.g. 0,0,0)
       - ArenaSpawn (position where arena is, e.g. 100,0,0)
    2. Attach this script to PropHuntModules GameObject
    3. In Inspector, drag spawn points to the fields

    local Teleporter = require("PropHuntTeleporter")
    Teleporter.TeleportToArena(player)
    Teleporter.TeleportAllToLobby(playersList)
]]

--!Type(Module)

-- SerializeFields for spawn positions
--!SerializeField
--!Tooltip("Lobby spawn position - drag LobbySpawn GameObject here")
local lobbySpawnPosition : Transform = nil

--!SerializeField
--!Tooltip("Arena spawn position - drag ArenaSpawn GameObject here")
local arenaSpawnPosition : Transform = nil

--[[
    Debug logging
]]
local function Log(msg)
    print("[PropHunt Teleporter] " .. tostring(msg))
end

--[[
    Helper: Teleport player to a position
]]
local function TeleportPlayerToPosition(player, targetPosition)
    if player == nil or player.character == nil then
        Log("ERROR: Cannot teleport nil player or character")
        return false
    end

    if targetPosition == nil then
        Log("ERROR: Target position is nil")
        return false
    end

    -- Get Vector3 position from Transform
    local pos = targetPosition.position

    -- Move player character to position
    player.character.transform.position = pos
    return true
end

--[[
    Core Teleportation Functions
]]

-- Teleport a single player to the Arena
function TeleportToArena(player)
    if arenaSpawnPosition == nil then
        Log("ERROR: Arena spawn position not configured!")
        return false
    end

    if player == nil then
        Log("ERROR: Cannot teleport nil player to Arena")
        return false
    end

    Log(string.format("Teleporting %s to Arena", player.name))
    return TeleportPlayerToPosition(player, arenaSpawnPosition)
end

-- Teleport a single player to the Lobby
function TeleportToLobby(player)
    if lobbySpawnPosition == nil then
        Log("ERROR: Lobby spawn position not configured!")
        return false
    end

    if player == nil then
        Log("ERROR: Cannot teleport nil player to Lobby")
        return false
    end

    Log(string.format("Teleporting %s to Lobby", player.name))
    return TeleportPlayerToPosition(player, lobbySpawnPosition)
end

-- Teleport multiple players to the Arena
function TeleportAllToArena(players)
    if players == nil or #players == 0 then
        Log("WARN: No players to teleport to Arena")
        return 0
    end

    local count = 0
    for _, player in ipairs(players) do
        if player ~= nil and TeleportToArena(player) then
            count = count + 1
        end
    end

    Log(string.format("Teleported %d players to Arena", count))
    return count
end

-- Teleport multiple players to the Lobby
function TeleportAllToLobby(players)
    if players == nil or #players == 0 then
        Log("WARN: No players to teleport to Lobby")
        return 0
    end

    local count = 0
    for _, player in ipairs(players) do
        if player ~= nil and TeleportToLobby(player) then
            count = count + 1
        end
    end

    Log(string.format("Teleported %d players to Lobby", count))
    return count
end

--[[
    Role-Based Teleportation Helpers
    For convenience when transitioning between game states
]]

-- Teleport Props and Spectators to Arena, Hunters stay in Lobby
-- Used during LOBBY -> HIDING transition
function TeleportPropsToArena(propsTeam)
    Log("Teleporting Props team to Arena for Hide phase")
    return TeleportAllToArena(propsTeam)
end

-- Teleport Hunters to Arena
-- Used during HIDING -> HUNTING transition
function TeleportHuntersToArena(huntersTeam)
    Log("Teleporting Hunters team to Arena for Hunt phase")
    return TeleportAllToArena(huntersTeam)
end

-- Teleport all players back to Lobby
-- Used during HUNTING/ROUND_END -> LOBBY transition
function TeleportAllPlayersToLobby(allPlayers)
    Log("Teleporting all players back to Lobby")
    return TeleportAllToLobby(allPlayers)
end

--[[
    Configuration Helpers (for backward compatibility)
]]

-- Get scene names (legacy - returns dummy values for single-scene setup)
function GetLobbySceneName()
    return "Lobby" -- Not used in single-scene mode
end

function GetArenaSceneName()
    return "Arena" -- Not used in single-scene mode
end

--[[
    Module Exports
    All public functions available to other scripts
]]
return {
    -- Core functions
    TeleportToArena = TeleportToArena,
    TeleportToLobby = TeleportToLobby,
    TeleportAllToArena = TeleportAllToArena,
    TeleportAllToLobby = TeleportAllToLobby,

    -- Role-based helpers
    TeleportPropsToArena = TeleportPropsToArena,
    TeleportHuntersToArena = TeleportHuntersToArena,
    TeleportAllPlayersToLobby = TeleportAllPlayersToLobby,

    -- Configuration (legacy compatibility)
    GetLobbySceneName = GetLobbySceneName,
    GetArenaSceneName = GetArenaSceneName
}
