--!Type(UI)

--!Bind
local _stateLabel : Label = nil
--!Bind
local _timerLabel : Label = nil
--!Bind
local _playersLabel : Label = nil

function UpdateHud(stateText, timerText, playersText)
  if _stateLabel then
    _stateLabel.text = stateText
  end
  if _timerLabel then
    _timerLabel.text = timerText
  end
  if _playersLabel then
    _playersLabel.text = playersText
  end
end

function self:Start()
  print("[PropHuntHUD] Started.")
  -- Initial text
  UpdateHud("State: LOBBY", "Time: 0s", "Players: 0/0")
end