--!Type(Module)

--!SerializeField
local _HUD : GameObject = nil
--!SerializeField
local _JoinButton : GameObject = nil


local Config = require("mkConfig")
local GameState = require("mkGameState")
local MatchmakingManager = require("mkMatchmakingManager")

local _HudScript : mkhud = nil
local _JoinButtonScript : mkjoinbutton = nil
local _hudUpdateTimer : Timer | nil = nil

function InitGUI()
  if _HudScript == nil then _HudScript = _HUD:GetComponent(mkhud) end
  if _JoinButtonScript == nil then _JoinButtonScript = _JoinButton:GetComponent(mkjoinbutton) end
end

function self:ClientAwake()
  InitGUI()
end

function EnableDisableJoinButton(state: boolean)
  _JoinButton:SetActive(state)
end

local function StopHUDTimer()
  if _hudUpdateTimer then
    _hudUpdateTimer:Stop()
    _hudUpdateTimer = nil
  end
end

local function FormatTime(seconds: number): string
  if seconds <= 0 then return "0s" end
  
  local minutes = math.floor(seconds / 60)
  local remainingSeconds = seconds % 60
  
  if minutes > 0 then
    return tostring(minutes) .. "m " .. tostring(remainingSeconds) .. "s"
  else
    return tostring(remainingSeconds) .. "s"
  end
end

local function StartHUDTimer()
  StopHUDTimer() -- Stop any existing timer
  
  _hudUpdateTimer = Timer.Every(Config.GetHUDUpdateInterval(), function()
    local gameState = GameState.GetGameState()
    local currentRound = GameState.GetCurrentRound()
    local maxRounds = Config.GetMaxRounds()
    
    if gameState == GameState.GetGameStateMap().Waiting then
      local readyPlayerCount = MatchmakingManager.GetReadyPlayerCount()
      local roundText = currentRound > 0 and " (Round " .. currentRound .. "/" .. maxRounds .. ")" or ""
      _HudScript.UpdateHud("Waiting for players..." .. roundText, "Players ready: " .. tostring(readyPlayerCount) .. "/" .. Config.GetMinPlayersToStart())
      
    elseif gameState == GameState.GetGameStateMap().Starting then
      local timeLeftToStart = GameState.GetTimeLeftToStart()
      local readyPlayerCount = MatchmakingManager.GetReadyPlayerCount()
      local roundText = " (Round " .. currentRound .. "/" .. maxRounds .. ")"
      _HudScript.UpdateHud("Starting in " .. FormatTime(timeLeftToStart) .. "..." .. roundText, "Players ready: " .. tostring(readyPlayerCount) .. "/" .. Config.GetMinPlayersToStart())
      
    elseif gameState == GameState.GetGameStateMap().InProgress then
      local timeLeftToEnd = GameState.GetTimeLeftToEnd()
      local roundText = " (Round " .. currentRound .. "/" .. maxRounds .. ")"
      _HudScript.UpdateHud("In Progress..." .. roundText, "Time left: " .. FormatTime(timeLeftToEnd))
    end
  end)
end

function self:ClientStart()
  -- Start the HUD timer immediately
  StartHUDTimer()
  
  GameState.GetGameStateEvent().Changed:Connect(function(gameState)
    local currentRound = GameState.GetCurrentRound()
    local maxRounds = Config.GetMaxRounds()
    
    if gameState == GameState.GetGameStateMap().Waiting then
      EnableDisableJoinButton(true)
      -- Timer will handle HUD updates
    elseif gameState == GameState.GetGameStateMap().Starting then
      EnableDisableJoinButton(true) -- Allow joining during countdown
      -- Timer will handle HUD updates
    elseif gameState == GameState.GetGameStateMap().InProgress then
      -- Enable button if mid-game joining is allowed
      EnableDisableJoinButton(Config.AllowMidGameJoin())
      -- Timer will handle HUD updates
    end
  end)

  MatchmakingManager.GetReadyPlayersEvent().Changed:Connect(function(readyPlayers)
    -- Timer will handle HUD updates for player count changes
  end)

  GameState.GetGameTimeEvent().Changed:Connect(function(gameTime)
    -- Timer will handle HUD updates for time changes
  end)
end

function self:OnDestroy()
  StopHUDTimer()
end