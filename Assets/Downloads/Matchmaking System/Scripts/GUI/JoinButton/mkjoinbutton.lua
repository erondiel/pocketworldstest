--!Type(UI)

local Events = require("mkEvents")
local GameState = require("mkGameState")
local Config = require("mkConfig")
local MatchmakingManager = require("mkMatchmakingManager")

--!Bind
local _button : VisualElement = nil
--!Bind
local _label : Label = nil

function ReadyUpButton()
  local gameState = GameState.GetGameState()
  
  -- Allow joining if mid-game join is enabled, or if game is not in progress
  if gameState == GameState.GetGameStateMap().InProgress and not Config.AllowMidGameJoin() then 
    return 
  end
  
  Events.ReadyUpRequest:FireServer()
end

_button:RegisterPressCallback(ReadyUpButton)

function self:Start()
  local playerInfo = MatchmakingManager.GetPlayerInfo(client.localPlayer)
  playerInfo.isReady.Changed:Connect(function(newValue, oldValue)
    if newValue then
      _button:SetEnabled(false)
    else
      _button:SetEnabled(true)
    end
  end)
end