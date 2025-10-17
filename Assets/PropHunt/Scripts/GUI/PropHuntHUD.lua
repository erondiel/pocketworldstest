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
local currentState = 1  -- LOBBY
local currentScore = 0

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

-- Helper function to get remaining props count
local function GetRemainingPropsCount()
  local propsTeam = GameManager.GetPropsTeam()
  return #propsTeam
end

-- Helper function to get ready players count
local function GetReadyPlayersCount()
  return PlayerManager.GetReadyPlayerCount()
end

function UpdateHud(stateText, timerText, playersText, scoreText)
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
    -- Line 5: Players/Props count depending on state
    local scoreDisplay = scoreText or ("Score: " .. currentScore)
    local playersDisplay = playersText

    -- Update players display based on game state
    if currentState == GameManager.GameState.LOBBY then
      -- In LOBBY: Show ready players count
      local readyCount = GetReadyPlayersCount()
      playersDisplay = "Ready: " .. readyCount
    elseif currentState == GameManager.GameState.HIDING or currentState == GameManager.GameState.HUNTING then
      -- During game: Show remaining props
      local propsCount = GetRemainingPropsCount()
      playersDisplay = "Props: " .. propsCount
    else
      -- ROUND_END: Show nothing or keep last value
      playersDisplay = playersText or ""
    end

    _playersLabel.text = scoreDisplay .. "\n" .. playersDisplay
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
  currentState = GameManager.GameState.LOBBY
  UpdateHud("LOBBY", "0s", "")

  -- Get local player's role and score from PlayerManager NetworkValue
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

      -- Listen for score changes (if available)
      if playerInfo.score then
        playerInfo.score.Changed:Connect(function(newScore, oldScore)
          currentScore = newScore
          print("[PropHuntHUD] Score updated: " .. currentScore)
        end)
      end
    else
      print("[PropHuntHUD] WARNING: Could not get player info for role tracking")
    end
  end

  -- Listen for role assignments (backup event system)
  roleAssignedEvent:Connect(function(role)
    print("[PropHuntHUD] Role assigned via event: " .. tostring(role))
    currentRole = FormatRole(role)
  end)

  -- Listen for state changes to reset role to Spectator in LOBBY and track current state
  stateChangedEvent:Connect(function(newState, timer)
    currentState = newState
    if newState == 1 then -- LOBBY state
      currentRole = "Spectator"
      print("[PropHuntHUD] Returned to LOBBY - role reset to Spectator")
    end
  end)
end