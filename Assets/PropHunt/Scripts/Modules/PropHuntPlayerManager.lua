--!Type(Module)

local Config = require("PropHuntConfig")

-- Forward declaration - will be set by GameManager
local OnSpectatorToggleCallback = nil

type PlayerInfo = {
    player: Player,
    isReady: BoolValue,
    isSpectator: BoolValue,
    role: StringValue,
    gameState: NumberValue,
    score: NumberValue,
}

local players : { [Player]: PlayerInfo } = {}
local readyPlayers : TableValue = TableValue.new("PH_ReadyPlayers", {})
local spectatorPlayers : TableValue = TableValue.new("PH_SpectatorPlayers", {})

-- Network events
ReadyUpRequest = Event.new("PH_ReadyUpRequest")
SpectatorToggleRequest = Event.new("PH_SpectatorToggleRequest")

-------------------------- SHARED --------------------------
------------------------------------------------------------
function GetReadyPlayersEvent()
    return readyPlayers
end

function GetReadyPlayers()
    return readyPlayers.value
end

function GetPlayerInfo(player : Player) : PlayerInfo
    return players[player]
end

function GetReadyPlayerCount() : number
    local count = 0
    for player, _ in pairs(readyPlayers.value) do
        count = count + 1
    end
    return count
end

function GetSpectatorPlayers()
    return spectatorPlayers.value
end

function GetSpectatorPlayerCount() : number
    local count = 0
    for player, _ in pairs(spectatorPlayers.value) do
        count = count + 1
    end
    return count
end

function IsPlayerSpectator(player : Player) : boolean
    if not players[player] then
        return false
    end
    return players[player].isSpectator.value
end

-------------------------- CLIENT --------------------------
------------------------------------------------------------
local function TrackPlayersClient()
    scene.PlayerJoined:Connect(function(sceneObj : Scene, player : Player)
        print("[PlayerManager] Client tracking: " .. player.name)

        players[player] = {
            player = player,
            isReady = BoolValue.new("IsReady" .. player.user.id, false, player),
            isSpectator = BoolValue.new("IsSpectator" .. player.user.id, false, player),
            role = StringValue.new("Role" .. player.user.id, "spectator", player),
            gameState = NumberValue.new("GameState" .. player.user.id, 1, player),
            score = NumberValue.new("PH_Score_" .. player.user.id, 0, player),
        }
    end)

    client.PlayerDisconnected:Connect(function(player : Player)
        print("[PlayerManager] Client untracking: " .. player.name)
        players[player] = nil
    end)
end

function self:ClientAwake()
    TrackPlayersClient()
end

-------------------------- SERVER --------------------------
------------------------------------------------------------
local function TrackPlayersServer()
    scene.PlayerJoined:Connect(function(sceneObj : Scene, player : Player)
        print("[PlayerManager] Server tracking: " .. player.name)

        players[player] = {
            player = player,
            isReady = BoolValue.new("IsReady" .. player.user.id, false, player),
            isSpectator = BoolValue.new("IsSpectator" .. player.user.id, false, player),
            role = StringValue.new("Role" .. player.user.id, "spectator", player),
            gameState = NumberValue.new("GameState" .. player.user.id, 1, player),
            score = NumberValue.new("PH_Score_" .. player.user.id, 0, player),
        }
    end)

    server.PlayerDisconnected:Connect(function(player : Player)
        print("[PlayerManager] Server untracking: " .. player.name)

        players[player] = nil

        -- Remove from ready list
        local readyPlayersTable = readyPlayers.value
        readyPlayersTable[player] = nil
        readyPlayers.value = readyPlayersTable

        -- Remove from spectator list
        local spectatorPlayersTable = spectatorPlayers.value
        spectatorPlayersTable[player] = nil
        spectatorPlayers.value = spectatorPlayersTable
    end)
end

function ResetAllPlayers()
    for player, playerInfo in pairs(players) do
        if playerInfo.isReady.value then
            playerInfo.isReady.value = false
        end
        -- Reset role to spectator when returning to lobby
        playerInfo.role.value = "spectator"
    end

    readyPlayers.value = {}
    print("[PlayerManager] All players reset to not ready")
end

-- Server-side function to set player role
function SetPlayerRole(player : Player, role : string)
    if not players[player] then
        print("[PlayerManager] Cannot set role - player not tracked: " .. player.name)
        return false
    end

    players[player].role.value = role
    print(string.format("[PlayerManager] %s role set to: %s", player.name, role))
    return true
end

-- Server-side function to broadcast game state to all players
function BroadcastGameState(newState : number)
    local count = 0
    for player, playerInfo in pairs(players) do
        if playerInfo.gameState then
            playerInfo.gameState.value = newState
            count = count + 1
        end
    end
    print(string.format("[PlayerManager] Broadcast state %d to %d players", newState, count))
end

function ReadyUpPlayerRequest(player : Player)
    if not players[player] then
        print("[PlayerManager] Player not tracked: " .. player.name)
        return
    end

    -- Can't ready up if spectator
    if players[player].isSpectator.value then
        print("[PlayerManager] Spectators cannot ready up: " .. player.name)
        return
    end

    -- Toggle ready state
    local wasReady = players[player].isReady.value
    players[player].isReady.value = not wasReady

    local readyPlayersTable = readyPlayers.value

    if not wasReady then
        -- Player is now ready
        print("[PlayerManager] Player ready: " .. player.name)
        readyPlayersTable[player] = true
    else
        -- Player is now unready
        print("[PlayerManager] Player unready: " .. player.name)
        readyPlayersTable[player] = nil
    end

    readyPlayers.value = readyPlayersTable
end

function ToggleSpectatorRequest(player : Player)
    if not players[player] then
        print("[PlayerManager] Player not tracked: " .. player.name)
        return false
    end

    local wasSpectator = players[player].isSpectator.value

    -- Toggle spectator state
    players[player].isSpectator.value = not wasSpectator

    local spectatorPlayersTable = spectatorPlayers.value

    if not wasSpectator then
        -- Becoming spectator
        print("[PlayerManager] Player became spectator: " .. player.name)

        -- Un-ready if they were ready
        if players[player].isReady.value then
            players[player].isReady.value = false
            local readyPlayersTable = readyPlayers.value
            readyPlayersTable[player] = nil
            readyPlayers.value = readyPlayersTable
        end

        -- Add to spectator list
        spectatorPlayersTable[player] = true
        spectatorPlayers.value = spectatorPlayersTable

        -- Notify GameManager for teleportation
        if OnSpectatorToggleCallback then
            OnSpectatorToggleCallback(player, true)
        end

        return true -- Now spectator
    else
        -- Leaving spectator mode
        print("[PlayerManager] Player left spectator mode: " .. player.name)

        -- Remove from spectator list
        spectatorPlayersTable[player] = nil
        spectatorPlayers.value = spectatorPlayersTable

        -- Notify GameManager for teleportation
        if OnSpectatorToggleCallback then
            OnSpectatorToggleCallback(player, false)
        end

        return false -- No longer spectator
    end
end

-- Public function to register callback from GameManager
function RegisterSpectatorToggleCallback(callback)
    OnSpectatorToggleCallback = callback
end

-- Server-side function to force a player into spectator mode (for mid-game joins)
function ForceSpectatorMode(player : Player)
    if not players[player] then
        print("[PlayerManager] Cannot force spectator - player not tracked: " .. player.name)
        return false
    end

    if players[player].isSpectator.value then
        print("[PlayerManager] Player already spectator: " .. player.name)
        return true
    end

    print("[PlayerManager] Forcing spectator mode: " .. player.name)

    -- Set spectator state
    players[player].isSpectator.value = true

    -- Un-ready if they were ready
    if players[player].isReady.value then
        players[player].isReady.value = false
        local readyPlayersTable = readyPlayers.value
        readyPlayersTable[player] = nil
        readyPlayers.value = readyPlayersTable
    end

    -- Add to spectator list
    local spectatorPlayersTable = spectatorPlayers.value
    spectatorPlayersTable[player] = true
    spectatorPlayers.value = spectatorPlayersTable

    -- Notify GameManager callback
    if OnSpectatorToggleCallback then
        OnSpectatorToggleCallback(player, true)
    end

    return true
end

function self:ServerAwake()
    TrackPlayersServer()
    ReadyUpRequest:Connect(ReadyUpPlayerRequest)
    SpectatorToggleRequest:Connect(ToggleSpectatorRequest)
end

-- ========== MODULE EXPORTS ==========

return {
    -- Public API
    GetReadyPlayersEvent = GetReadyPlayersEvent,
    GetReadyPlayers = GetReadyPlayers,
    GetPlayerInfo = GetPlayerInfo,
    GetReadyPlayerCount = GetReadyPlayerCount,
    GetSpectatorPlayers = GetSpectatorPlayers,
    GetSpectatorPlayerCount = GetSpectatorPlayerCount,
    IsPlayerSpectator = IsPlayerSpectator,
    ResetAllPlayers = ResetAllPlayers,
    RegisterSpectatorToggleCallback = RegisterSpectatorToggleCallback,
    ForceSpectatorMode = ForceSpectatorMode,
    SetPlayerRole = SetPlayerRole,
    BroadcastGameState = BroadcastGameState,

    -- Network events (for client-side usage)
    ReadyUpRequest = ReadyUpRequest,
    SpectatorToggleRequest = SpectatorToggleRequest
}

