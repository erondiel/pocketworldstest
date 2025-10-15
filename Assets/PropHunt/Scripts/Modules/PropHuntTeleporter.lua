--[[
    PropHunt Teleporter Module
    Single-scene position-based teleportation (mobile-friendly)

    Usage:
    1. In Unity, create two empty GameObjects:
       - LobbySpawn (position where lobby is, e.g. 0,0,0)
       - ArenaSpawn (position where arena is, e.g. 100,0,0)
    2. Attach this script to PropHuntModules GameObject
    3. System automatically finds spawn points by name at runtime

    local Teleporter = require("PropHuntTeleporter")
    Teleporter.TeleportToArena(player)
    Teleporter.TeleportAllToLobby(playersList)
]]

--!Type(Module)

local VFXManager = require("PropHuntVFXManager")

-- ========== NETWORK EVENTS ==========
local teleportEvent = Event.new("PH_TeleportPlayer")
local postTeleportEvent = Event.new("PH_PostTeleport")  -- Fired after teleport complete

-- ========== CACHED SPAWN REFERENCES ==========
local lobbySpawn = nil
local arenaSpawn = nil

--[[
    Debug logging
]]
local function Log(msg)
    print("[PropHunt Teleporter] " .. tostring(msg))
end

--[[
    Find and cache spawn points
]]
local function GetLobbySpawn()
    if not lobbySpawn then
        local lobbyGO = GameObject.Find("LobbySpawn")
        if lobbyGO then
            lobbySpawn = lobbyGO.transform
            Log("Found LobbySpawn GameObject")
        else
            Log("ERROR: LobbySpawn GameObject not found in scene!")
        end
    end
    return lobbySpawn
end

local function GetArenaSpawn()
    if not arenaSpawn then
        local arenaGO = GameObject.Find("ArenaSpawn")
        if arenaGO then
            arenaSpawn = arenaGO.transform
            Log("Found ArenaSpawn GameObject")
        else
            Log("ERROR: ArenaSpawn GameObject not found in scene!")
        end
    end
    return arenaSpawn
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

    local spawn = GetArenaSpawn()
    if not spawn then
        Log("ERROR: Arena spawn not found - make sure 'ArenaSpawn' GameObject exists in scene")
        return false
    end

    Log(string.format("Teleporting %s to Arena", player.name))
    return TeleportPlayerToPosition(player, spawn)
end

-- Teleport a single player to the Lobby
function TeleportToLobby(player)
    if player == nil then
        Log("ERROR: Cannot teleport nil player to Lobby")
        return false
    end

    local spawn = GetLobbySpawn()
    if not spawn then
        Log("ERROR: Lobby spawn not found - make sure 'LobbySpawn' GameObject exists in scene")
        return false
    end

    Log(string.format("Teleporting %s to Lobby", player.name))
    return TeleportPlayerToPosition(player, spawn)
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

    FADE TRANSITION:
    - Fade to black (0.3s)
    - Teleport during black screen
    - Fade from black (0.3s)
    - Total duration: ~0.7s
]]
function self:ClientStart()
    teleportEvent:Connect(function(player, position)
        -- Only apply fade transition for local player
        if player == client.localPlayer then
            Log(string.format("Local player teleporting to (%.1f, %.1f, %.1f) with fade", position.x, position.y, position.z))

            -- Use ScreenFadeTransition to hide camera movement
            VFXManager.ScreenFadeTransition(
                0.3,  -- Fade out duration
                0.1,  -- Wait duration (stay black)
                0.3,  -- Fade in duration
                function()
                    -- Execute teleport during black screen
                    if player and player.character then
                        player.character:Teleport(position)

                        -- Trigger camera reset to snap to new position
                        client.Reset:Fire()
                        Log("Camera reset triggered during fade")
                    end
                end,
                function()
                    -- Fade complete - fire post-teleport event
                    postTeleportEvent:FireClient()
                    Log("Fade transition complete")
                end
            )
        else
            -- Other players teleport without fade (we just see them move)
            if player and player.character then
                player.character:Teleport(position)
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
