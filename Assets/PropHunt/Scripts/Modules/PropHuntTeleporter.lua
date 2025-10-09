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

-- ========== SERIALIZE FIELDS: SPAWN POINTS ==========
--!Tooltip("Lobby spawn position - drag LobbySpawn GameObject here")
--!SerializeField
local _lobbySpawnPosition : GameObject = nil

--!Tooltip("Arena spawn position - drag ArenaSpawn GameObject here")
--!SerializeField
local _arenaSpawnPosition : GameObject = nil

-- ========== NETWORK EVENTS ==========
local teleportEvent = Event.new("PH_TeleportPlayer")

--[[
    Debug logging
]]
local function Log(msg)
    print("[PropHunt Teleporter] " .. tostring(msg))
end

--[[
    Helper: Teleport player to a position
    Uses server-to-client event to trigger client-side Teleport() call
    Server sets position, then broadcasts to all clients for sync
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

    -- Server-side: Set transform position for server authority
    player.character.transform.position = pos

    -- Broadcast to ALL clients so everyone sees the teleport
    -- Each client will call player.character:Teleport(pos)
    teleportEvent:FireAllClients(player, pos)

    return true
end

--[[
    Core Teleportation Functions
]]

-- Teleport a single player to the Arena
function TeleportToArena(player)
    if player == nil then
        Log("ERROR: Cannot teleport nil player to Arena")
        return false
    end

    -- Get arena spawn from SerializeField
    local arenaSpawn = nil
    if _arenaSpawnPosition ~= nil then
        arenaSpawn = _arenaSpawnPosition.transform
    else
        -- Fallback: Try to find by name if SerializeField is not configured
        Log("WARNING: Arena spawn not configured, attempting GameObject.Find(\"ArenaSpawn\")...")
        local arenaGO = GameObject.Find("ArenaSpawn")
        if arenaGO ~= nil then
            arenaSpawn = arenaGO.transform
            Log("Found ArenaSpawn via GameObject.Find")
        else
            Log("ERROR: Arena spawn position not configured and GameObject.Find(\"ArenaSpawn\") failed!")
            Log("SOLUTION: In Unity, select PropHuntModules → PropHuntTeleporter component → Drag 'ArenaSpawn' GameObject to Arena Spawn Position field")
            return false
        end
    end

    Log(string.format("Teleporting %s to Arena", player.name))
    return TeleportPlayerToPosition(player, arenaSpawn)
end

-- Teleport a single player to the Lobby
function TeleportToLobby(player)
    if player == nil then
        Log("ERROR: Cannot teleport nil player to Lobby")
        return false
    end

    -- Get lobby spawn from SerializeField
    local lobbySpawn = nil
    if _lobbySpawnPosition ~= nil then
        lobbySpawn = _lobbySpawnPosition.transform
    else
        -- Fallback: Try to find by name if SerializeField is not configured
        Log("WARNING: Lobby spawn not configured, attempting GameObject.Find(\"LobbySpawn\")...")
        local lobbyGO = GameObject.Find("LobbySpawn")
        if lobbyGO ~= nil then
            lobbySpawn = lobbyGO.transform
            Log("Found LobbySpawn via GameObject.Find")
        else
            Log("ERROR: Lobby spawn position not configured and GameObject.Find(\"LobbySpawn\") failed!")
            Log("SOLUTION: In Unity, select PropHuntModules → PropHuntTeleporter component → Drag 'LobbySpawn' GameObject to Lobby Spawn Position field")
            return false
        end
    end

    Log(string.format("Teleporting %s to Lobby", player.name))
    return TeleportPlayerToPosition(player, lobbySpawn)
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
    Client-Side Teleport Handler
    Listens for server teleport events and executes client-side Teleport() call
    Receives player object and position, so all clients see the movement
]]
function self:ClientStart()
    teleportEvent:Connect(function(player, position)
        -- Execute client-side teleport for the specified player
        if player and player.character then
            player.character:Teleport(position)

            -- If this is the local player, also recenter the camera
            if player == client.localPlayer then
                Log(string.format("Client teleported to (%.1f, %.1f, %.1f)", position.x, position.y, position.z))

                -- Trigger camera reset to snap to new position
                -- The client.Reset event tells the RTS camera to recenter on the player
                client.Reset:Fire()
                Log("Camera reset triggered")
            end
        end
    end)
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
