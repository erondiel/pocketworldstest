--!Type(UI)

--!Bind
local _headerLabel : Label = nil
--!Bind
local _subHeaderLabel : Label = nil

local Config = require("mkConfig")
local GameState = require("mkGameState")
local MatchmakingManager = require("mkMatchmakingManager")

function Init()
  local MinPlayersToStart = Config.GetMinPlayersToStart()
  _subHeaderLabel.text = "Players ready: " .. MatchmakingManager.GetReadyPlayerCount() .. "/" .. MinPlayersToStart
end

function SetHeaderText(text: string)
  _headerLabel.text = text
end

function SetSubHeaderText(text: string | nil)
  if text == nil then
    _subHeaderLabel.text = ""
  else
    _subHeaderLabel.text = text
  end
end

function UpdateHud(header: string, subHeader: string | nil)
  SetHeaderText(header)
  SetSubHeaderText(subHeader)
end

function self:Start()
  -- Initial HUD setup - UI Manager will handle all updates via timer
  Init()
end