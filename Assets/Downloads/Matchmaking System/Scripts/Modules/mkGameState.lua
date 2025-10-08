--!Type(Module)

local Config = require("mkConfig")

local GameState = NumberValue.new("GameState", 1) -- 1 = Waiting for players, 2 = Starting in x seconds, 3 = In Progress
local GameTime = NumberValue.new("GameTime", 0) -- Time in seconds
local CurrentRound = NumberValue.new("CurrentRound", 0) -- Current round number (0 = no rounds played)

type GameStateMap = {
  Waiting: number,
  Starting: number,
  InProgress: number
}

local GameStateMap : GameStateMap = {
  Waiting = 1,
  Starting = 2,
  InProgress = 3
}

-------------------------- SHARED --------------------------
------------------------------------------------------------
function GetGameStateMap(): GameStateMap
  return GameStateMap
end

function GetGameState(): number
  return GameState.value
end

function GetGameStateEvent(): NumberValue
  return GameState
end

function GetGameTime(): number
  return GameTime.value
end

function GetGameTimeEvent(): NumberValue
  return GameTime
end

function GetCurrentRound(): number
  return CurrentRound.value
end

function GetCurrentRoundEvent(): NumberValue
  return CurrentRound
end

function SetGameState(state: number)
  GameState.value = state
  Config.Debug("GameState", "State changed to: " .. state)
end

function SetGameTime(time: number)
  GameTime.value = time
end

function SetCurrentRound(round: number)
  CurrentRound.value = round
  Config.Debug("GameState", "Round changed to: " .. round)
end

function IsGameInProgress(): boolean
  return GetGameState() == GameStateMap.InProgress
end

function IsGameStarting(): boolean
  return GetGameState() == GameStateMap.Starting
end

function IsGameWaiting(): boolean
  return GetGameState() == GameStateMap.Waiting
end

function GetTimeLeftToStart(): number
  if not IsGameStarting() then return 0 end
  return Config.GetStartingTime() - GetGameTime()
end

function GetTimeLeftToEnd(): number
  if not IsGameInProgress() then return 0 end
  return Config.GetRoundTime() - GetGameTime()
end

function IsGameFinished(): boolean
  return GetCurrentRound() >= Config.GetMaxRounds()
end