--!Type(Module)

local Config = require("mkConfig")
local Events = require("mkEvents")
local GameState = require("mkGameState")

type PlayerInfo = {
  player: Player,
  score: IntValue,
  isReady: BoolValue,
  isInGame: BoolValue,
}

local players : { [Player]: PlayerInfo } = {}
local readyPlayers : TableValue = TableValue.new("readyPlayers", {})

-------------------------- SHARED --------------------------
------------------------------------------------------------
function GetReadyPlayersEvent()
  return readyPlayers
end

function GetReadyPlayers()
  return readyPlayers.value
end

function GetPlayerInfo(player: Player): PlayerInfo
  return players[player]
end

function GetReadyPlayerCount(): number
  local count = 0
  for player, _ in pairs(readyPlayers.value) do
    count = count + 1
  end

  return count
end

-------------------------- CLIENT --------------------------
------------------------------------------------------------
local function TrackPlayers(game, cb)
  scene.PlayerJoined:Connect(function(scene: Scene, player: Player)
    Config.Debug("TrackPlayers", "Player joined: " .. player.user.id)

    players[player] = {
      player = player,
      score = IntValue.new("Score" .. player.user.id, 0, player),
      isReady = BoolValue.new("IsReady" .. player.user.id, false, player),
      isInGame = BoolValue.new("IsInGame" .. player.user.id, false, player),
    }

    player.CharacterChanged:Connect(function(_, character)
      local playerInfo = players[player]
      if not character or character == nil then return end

      if cb then
        cb(playerInfo)
      end
    end)
  end)

  game.PlayerDisconnected:Connect(function(player: Player)
    Config.Debug("TrackPlayers", "Player disconnected: " .. player.user.id)

    players[player] = nil
    
    if game == server then
      local readyPlayersTable = readyPlayers.value
      readyPlayersTable[player] = nil
      readyPlayers.value = readyPlayersTable
    end
  end)
end

function self:ClientAwake()
  function OnCharacterInstantiate(playerinfo)
      local player = playerinfo.player
      local character = playerinfo.player.character
  end

  TrackPlayers(client, OnCharacterInstantiate)
end

-------------------------- SERVER --------------------------
------------------------------------------------------------
local function ResetAllPlayers()
  for player, playerInfo in pairs(players) do
    if playerInfo.isReady.value then
      playerInfo.isReady.value = false
    end
  end
  
  readyPlayers.value = {}
  Config.Debug("ResetAllPlayers", "All players reset to not ready")
end

local function ResetPlayersBetweenRounds()
  -- Don't reset ready players between rounds - keep them ready for next round
  Config.Debug("ResetPlayersBetweenRounds", "Players kept ready for next round")
end

local function StartGame()
  GameState.SetGameState(GameState.GetGameStateMap().InProgress)

  local roundTime = Config.GetRoundTime()
  GameState.SetGameTime(0) -- Start at 0 and count up

  -- Count up the game time every second
  local gameTimeTimer = Timer.Every(1, function()
    local currentTime = GameState.GetGameTime()
    GameState.SetGameTime(currentTime + 1)
  end)

  Timer.After(roundTime, function()
    gameTimeTimer:Stop() -- Stop the count-up timer
    EndGame()
  end)

  local currentRound = GameState.GetCurrentRound()
  Config.Debug("StartGame", "Round " .. currentRound .. " started")
end

function EndGame()
  local currentRound = GameState.GetCurrentRound()
  local maxRounds = Config.GetMaxRounds()
  
  -- Increment round counter
  GameState.SetCurrentRound(currentRound + 1)
  
  -- Check if we've reached max rounds
  if GameState.IsGameFinished() then
    -- Game is completely finished, reset everything
    GameState.SetGameState(GameState.GetGameStateMap().Waiting)
    GameState.SetGameTime(0)
    GameState.SetCurrentRound(0)
    ResetAllPlayers()
    
    Config.Debug("EndGame", "Game completely finished after " .. maxRounds .. " rounds")
  else
    -- More rounds to go, start next round
    GameState.SetGameState(GameState.GetGameStateMap().Starting)
    GameState.SetGameTime(0)
    ResetPlayersBetweenRounds() -- Keep players ready between rounds
    
    local nextRound = GameState.GetCurrentRound()
    Config.Debug("EndGame", "Round " .. currentRound .. " ended, starting round " .. nextRound)
    
    -- Set up countdown timer for next round
    local startingTime = Config.GetStartingTime()
    
    -- Count up the starting time every second
    local startTimeTimer = Timer.Every(1, function()
      local currentTime = GameState.GetGameTime()
      GameState.SetGameTime(currentTime + 1)
    end)
    
    Timer.After(startingTime, function()
      startTimeTimer:Stop() -- Stop the count-up timer
      StartGame()
    end)
  end
end

local function InitializeGameStart()
  if GameState.GetGameState() ~= GameState.GetGameStateMap().Waiting then return end
  
  -- Set initial round to 1 when starting the first round
  GameState.SetCurrentRound(1)
  GameState.SetGameState(GameState.GetGameStateMap().Starting)

  local startingTime = Config.GetStartingTime()
  GameState.SetGameTime(0) -- Start countdown at 0

  -- Count up the starting time every second
  local startTimeTimer = Timer.Every(1, function()
    local currentTime = GameState.GetGameTime()
    GameState.SetGameTime(currentTime + 1)
  end)

  Timer.After(startingTime, function()
    startTimeTimer:Stop() -- Stop the count-up timer
    StartGame()
  end)
  
  Config.Debug("InitializeGameStart", "Round 1 starting in " .. startingTime .. " seconds")
end

function ReadyUpPlayerRequest(player: Player)
  local gameState = GameState.GetGameState()
  
  -- Check if mid-game joining is allowed
  if gameState == GameState.GetGameStateMap().InProgress and not Config.AllowMidGameJoin() then
    return
  end

  -- Skip if player is already ready
  if players[player].isReady.value then
    return
  end

  Config.Debug("ReadyUpPlayerRequest", "Player ready up: " .. player.user.id)

  players[player].isReady.value = true

  local readyPlayersTable = readyPlayers.value
  readyPlayersTable[player] = true
  readyPlayers.value = readyPlayersTable

  -- Only start game if we're in waiting state and have enough players
  if gameState == GameState.GetGameStateMap().Waiting and GetReadyPlayerCount() >= Config.GetMinPlayersToStart() then
    InitializeGameStart()
  end

  Events.PlayerIsReady:FireAllClients(player.name, player.user.id)
end

function self:ServerAwake()
  TrackPlayers(server)
  Events.ReadyUpRequest:Connect(ReadyUpPlayerRequest)
end 