--!Type(UI)

--!Bind
local _stateLabel : Label = nil
--!Bind
local _timerLabel : Label = nil
--!Bind
local _playersLabel : Label = nil

-- Current player role (default to Spectator in LOBBY)
local currentRole = "Spectator"

-- Network events
local roleAssignedEvent = Event.new("PH_RoleAssigned")
local stateChangedEvent = Event.new("PH_StateChanged")

function UpdateHud(stateText, timerText, playersText)
  if _stateLabel then
    -- Format: "LOBBY | Spectator" or "HUNTING | Hunter"
    _stateLabel.text = stateText .. " | " .. currentRole
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

  -- Initial text (LOBBY with Spectator role)
  currentRole = "Spectator"
  UpdateHud("LOBBY", "0s", "Players: 0/0")

  -- Listen for role assignments
  roleAssignedEvent:Connect(function(role)
    print("[PropHuntHUD] Role assigned: " .. tostring(role))
    if role == "hunter" then
      currentRole = "Hunter"
    elseif role == "prop" then
      currentRole = "Prop"
    elseif role == "spectator" then
      currentRole = "Spectator"
    end
  end)

  -- Listen for state changes to reset role to Spectator in LOBBY
  stateChangedEvent:Connect(function(newState, timer)
    if newState == 1 then -- LOBBY state
      currentRole = "Spectator"
      print("[PropHuntHUD] Returned to LOBBY - role reset to Spectator")
    end
  end)
end