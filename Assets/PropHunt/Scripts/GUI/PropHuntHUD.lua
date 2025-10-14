--!Type(UI)

--!Bind
local _stateLabel : Label = nil
--!Bind
local _timerLabel : Label = nil
--!Bind
local _playersLabel : Label = nil

local PlayerManager = require("PropHuntPlayerManager")

-- Current player role (default to Spectator in LOBBY)
local currentRole = "Spectator"

-- Network events (kept for backward compatibility)
local roleAssignedEvent = Event.new("PH_RoleAssigned")
local stateChangedEvent = Event.new("PH_StateChanged")

-- Helper function to format role display
local function FormatRole(roleStr)
  if roleStr == "hunter" then
    return "Hunter"
  elseif roleStr == "prop" then
    return "Prop"
  elseif roleStr == "spectator" then
    return "Spectator"
  else
    return "Spectator"
  end
end

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

  -- Get local player's role from PlayerManager NetworkValue
  local localPlayer = client.localPlayer
  if localPlayer then
    local playerInfo = PlayerManager.GetPlayerInfo(localPlayer)
    if playerInfo and playerInfo.role then
      -- Set initial role from NetworkValue
      currentRole = FormatRole(playerInfo.role.value)
      print("[PropHuntHUD] Initial role from NetworkValue: " .. currentRole)

      -- Listen for role changes via NetworkValue
      playerInfo.role.Changed:Connect(function(newRole, oldRole)
        currentRole = FormatRole(newRole)
        print("[PropHuntHUD] Role changed via NetworkValue: " .. currentRole)
      end)
    else
      print("[PropHuntHUD] WARNING: Could not get player info for role tracking")
    end
  end

  -- Listen for role assignments (backup event system)
  roleAssignedEvent:Connect(function(role)
    print("[PropHuntHUD] Role assigned via event: " .. tostring(role))
    currentRole = FormatRole(role)
  end)

  -- Listen for state changes to reset role to Spectator in LOBBY
  stateChangedEvent:Connect(function(newState, timer)
    if newState == 1 then -- LOBBY state
      currentRole = "Spectator"
      print("[PropHuntHUD] Returned to LOBBY - role reset to Spectator")
    end
  end)
end