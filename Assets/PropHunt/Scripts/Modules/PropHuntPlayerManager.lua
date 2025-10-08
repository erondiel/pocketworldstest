--!Type(Module)

local Config = require("PropHuntConfig")

type PlayerInfo = {
    player: Player,
    isReady: BoolValue,
}

local players : { [Player]: PlayerInfo } = {}
local readyPlayers : TableValue = TableValue.new("PH_ReadyPlayers", {})

-- Ready up event
ReadyUpRequest = Event.new("PH_ReadyUpRequest")

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

-------------------------- CLIENT --------------------------
------------------------------------------------------------
local function TrackPlayersClient()
    scene.PlayerJoined:Connect(function(sceneObj : Scene, player : Player)
        print("[PlayerManager] Client tracking: " .. player.name)
        
        players[player] = {
            player = player,
            isReady = BoolValue.new("IsReady" .. player.user.id, false, player),
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
        }
    end)
    
    server.PlayerDisconnected:Connect(function(player : Player)
        print("[PlayerManager] Server untracking: " .. player.name)
        
        players[player] = nil
        
        -- Remove from ready list
        local readyPlayersTable = readyPlayers.value
        readyPlayersTable[player] = nil
        readyPlayers.value = readyPlayersTable
    end)
end

function ResetAllPlayers()
    for player, playerInfo in pairs(players) do
        if playerInfo.isReady.value then
            playerInfo.isReady.value = false
        end
    end
    
    readyPlayers.value = {}
    print("[PlayerManager] All players reset to not ready")
end

function ReadyUpPlayerRequest(player : Player)
    if not players[player] then
        print("[PlayerManager] Player not tracked: " .. player.name)
        return
    end
    
    -- Skip if already ready
    if players[player].isReady.value then
        print("[PlayerManager] Player already ready: " .. player.name)
        return
    end
    
    print("[PlayerManager] Player ready: " .. player.name)
    
    players[player].isReady.value = true
    
    local readyPlayersTable = readyPlayers.value
    readyPlayersTable[player] = true
    readyPlayers.value = readyPlayersTable
end

function self:ServerAwake()
    TrackPlayersServer()
    ReadyUpRequest:Connect(ReadyUpPlayerRequest)
end

