--[[
    PropHunt Teleporter Module
    Wraps the Scene Teleporter asset for PropHunt-specific Lobby <-> Arena transitions

    Dependencies:
    - Scene Teleporter asset (SceneManager.lua)
    - Requires scene names to be configured in SceneManager GameObject

    Usage:
    local Teleporter = require("PropHuntTeleporter")
    Teleporter.TeleportToArena(player)
    Teleporter.TeleportAllToLobby(playersList)
]]

--!Type(Module)

-- Configuration: Scene names (must match SceneManager configuration in Unity)
local LOBBY_SCENE_NAME = "Lobby"
local ARENA_SCENE_NAME = "Arena"

-- Import the Scene Teleporter system
local SceneManager = require("SceneManager")

--[[
    Debug logging
]]
local function Log(msg)
    print("[PropHunt Teleporter] " .. tostring(msg))
end

--[[
    Core Teleportation Functions
]]

-- Teleport a single player to the Arena scene
function TeleportToArena(player)
    if player == nil then
        Log("ERROR: Cannot teleport nil player to Arena")
        return false
    end

    Log(string.format("Teleporting %s to Arena", player.name))
    SceneManager.movePlayerToScene(ARENA_SCENE_NAME)
    return true
end

-- Teleport a single player to the Lobby scene
function TeleportToLobby(player)
    if player == nil then
        Log("ERROR: Cannot teleport nil player to Lobby")
        return false
    end

    Log(string.format("Teleporting %s to Lobby", player.name))
    SceneManager.movePlayerToScene(LOBBY_SCENE_NAME)
    return true
end

-- Teleport multiple players to the Arena scene
function TeleportAllToArena(players)
    if players == nil or #players == 0 then
        Log("WARN: No players to teleport to Arena")
        return 0
    end

    local count = 0
    for _, player in ipairs(players) do
        if player ~= nil then
            -- Note: SceneManager.movePlayerToScene is client-side (FireServer)
            -- For server-side bulk teleports, we need to call server.MovePlayerToScene directly
            -- This function assumes it's called from client context or per-player
            TeleportToArena(player)
            count = count + 1
        end
    end

    Log(string.format("Teleported %d players to Arena", count))
    return count
end

-- Teleport multiple players to the Lobby scene
function TeleportAllToLobby(players)
    if players == nil or #players == 0 then
        Log("WARN: No players to teleport to Lobby")
        return 0
    end

    local count = 0
    for _, player in ipairs(players) do
        if player ~= nil then
            TeleportToLobby(player)
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
    Configuration Helpers
]]

-- Set custom scene names (call this in ServerAwake if using different names)
function SetSceneNames(lobbyName, arenaName)
    LOBBY_SCENE_NAME = lobbyName
    ARENA_SCENE_NAME = arenaName
    Log(string.format("Scene names updated: Lobby='%s', Arena='%s'", lobbyName, arenaName))
end

-- Get current scene name configuration
function GetLobbySceneName()
    return LOBBY_SCENE_NAME
end

function GetArenaSceneName()
    return ARENA_SCENE_NAME
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

    -- Configuration
    SetSceneNames = SetSceneNames,
    GetLobbySceneName = GetLobbySceneName,
    GetArenaSceneName = GetArenaSceneName
}
