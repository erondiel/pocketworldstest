--!Type(UI)

--!Bind
local _stateLabel : Label = nil
--!Bind
local _timerLabel : Label = nil
--!Bind
local _playersLabel : Label = nil
--!Bind
local _fadeOverlay : VisualElement = nil

local PlayerManager = require("PropHuntPlayerManager")
local VFXManager = require("PropHuntVFXManager")
local GameManager = require("PropHuntGameManager")

-- Current player role (default to Spectator in LOBBY)
local currentRole = "Spectator"
local currentPropsCount = 0  -- Track remaining props count

-- Network events (kept for backward compatibility)
local roleAssignedEvent = Event.new("PH_RoleAssigned")
local stateChangedEvent = Event.new("PH_StateChanged")

-- Global Event for props count (same pattern as EndRoundScores)
local propsCountEvent = _G.PH_PropsCountEvent

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

function UpdateHud(stateText, timerText, playersText, scoreText)
  -- Get current game state to determine what to display
  local currentState = GameManager.GetCurrentState()

  -- Modify playersText for HIDING/HUNTING phases to show remaining props
  local displayPlayersText = playersText
  if currentState == 2 or currentState == 3 then -- HIDING or HUNTING
    -- Use tracked props count from Global Event
    displayPlayersText = "Props: " .. tostring(currentPropsCount)
  end

  if _stateLabel then
    -- Line 1: State only
    _stateLabel.text = stateText
  end
  if _timerLabel then
    -- Line 2: Role
    -- Line 3: Timer
    _timerLabel.text = currentRole .. "\n" .. timerText
  end
  if _playersLabel then
    -- Line 4: Score
    -- Line 5: Players/Props count
    _playersLabel.text = (scoreText or "Score: 0") .. "\n" .. displayPlayersText
  end
end

function self:Start()
  print("[PropHuntHUD] Started.")

  -- Initialize fade overlay for screen transitions
  if _fadeOverlay then
    VFXManager.InitializeFadeOverlay(_fadeOverlay)
    print("[PropHuntHUD] Fade overlay initialized")
  else
    print("[PropHuntHUD] WARNING: Fade overlay element not found!")
  end

  -- Initial text (LOBBY with Spectator role)
  currentRole = "Spectator"
  UpdateHud("LOBBY", "0s", "Ready: 0", "Score: 0")

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

  -- Listen for props count updates via Global Event (same pattern as EndRoundScores)
  if propsCountEvent then
    propsCountEvent:Connect(function(count)
      currentPropsCount = count
      print("[PropHuntHUD] Props count updated: " .. tostring(count))
    end)
  else
    print("[PropHuntHUD] WARNING: Props count event not found!")
  end
end