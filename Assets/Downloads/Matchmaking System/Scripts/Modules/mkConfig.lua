--!Type(Module)

--!Tooltip("Enable debug mode")
--!SerializeField
local _EnableDebug : boolean = false

--!Tooltip("Minimum number of players to start the game")
--!SerializeField
local _MinPlayersToStart : number = 1

--!Tooltip("Time in seconds before the game starts")
--!SerializeField
local _StartingTime : number = 5 -- Time in seconds

--!Tooltip("Time in seconds for each round")
--!SerializeField
local _RoundTime : number = 10 -- Time in seconds

--!Tooltip("Maximum number of rounds to play")
--!SerializeField
local _MaxRounds : number = 3 -- Maximum rounds

--!Tooltip("HUD update interval in seconds")
--!SerializeField
local _HUDUpdateInterval : number = 1 -- Update HUD every second

--!Tooltip("Allow players to join mid-game")
--!SerializeField
local _AllowMidGameJoin : boolean = true -- Allow joining during rounds

function GetMinPlayersToStart(): number
  return _MinPlayersToStart
end

function GetStartingTime(): number
  return _StartingTime
end

function GetRoundTime(): number
  return _RoundTime
end

function GetMaxRounds(): number
  return _MaxRounds
end

function GetHUDUpdateInterval(): number
  return _HUDUpdateInterval
end

function AllowMidGameJoin(): boolean
  return _AllowMidGameJoin
end

function Debug(func: string, message: string)
  if not _EnableDebug then return end

  print(func .. ": " .. message)
end