--!Type(Module)

local Logger = require("PropHuntLogger")

Logger.Log("UIManager", "========================================")
Logger.Log("UIManager", "PropHuntUIManager.lua LOADED")
Logger.Log("UIManager", "========================================")

--!SerializeField
local _HUD : GameObject = nil

-- UI GameObjects to hide during gameplay (found by CLIENT at runtime)
local _UIGameObjectsToHide : {GameObject} = {}
local UI_NAMES_TO_HIDE = {"ReadyButton", "SpectatorButton"}

-- EndRoundScore UI (shown only during ROUND_END)
local _EndRoundScoreUI : GameObject = nil

-- Game states
local GameState = {
    LOBBY = 1,
    HIDING = 2,
    HUNTING = 3,
    ROUND_END = 4
}

Logger.Log("UIManager", "Requiring dependencies...")
local success, err = pcall(function()
    Config = require("PropHuntConfig")
    Logger.Log("UIManager", "- Config loaded")
    GameManager = require("PropHuntGameManager")
    Logger.Log("UIManager", "- GameManager loaded")
    PlayerManager = require("PropHuntPlayerManager")
    Logger.Log("UIManager", "- PlayerManager loaded")
end)

if not success then
    Logger.Error("UIManager", "ERROR loading dependencies: " .. tostring(err))
else
    Logger.Log("UIManager", "All dependencies loaded!")
end

local Config = require("PropHuntConfig")
local GameManager = require("PropHuntGameManager")
local PlayerManager = require("PropHuntPlayerManager")

local _HudScript : PropHuntHUD = nil
local _hudUpdateTimer : Timer | nil = nil

-- State changed event from server
local stateChangedEvent = Event.new("PH_StateChanged")

local stateMapping = {
    [1] = "LOBBY",
    [2] = "HIDING",
    [3] = "HUNTING",
    [4] = "ROUND_END"
}

local function FormatState(value)
    return stateMapping[tonumber(value)] or tostring(value)
end

local function FormatTime(seconds : number) : string
    if seconds <= 0 then return "0s" end
    
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = math.floor(seconds % 60)
    
    if minutes > 0 then
        return tostring(minutes) .. "m " .. tostring(remainingSeconds) .. "s"
    else
        return tostring(remainingSeconds) .. "s"
    end
end

local function StopHUDTimer()
    if _hudUpdateTimer then
        _hudUpdateTimer:Stop()
        _hudUpdateTimer = nil
    end
end

local function StartHUDTimer()
    StopHUDTimer()

    _hudUpdateTimer = Timer.Every(1, function()
        local gameState = GameManager.GetCurrentState()
        local stateTimer = GameManager.GetStateTimer()
        local playerCount = GameManager.GetActivePlayerCount()
        local readyCount = PlayerManager.GetReadyPlayerCount()
        local minPlayers = Config.GetMinPlayersToStart()

        local stateName = FormatState(gameState)
        local stateText = stateName  -- Removed "State:" prefix
        local timerText = FormatTime(math.max(0, stateTimer))  -- Removed "Time:" prefix

        -- Show ready count in lobby, total count during game
        local playersText
        if gameState == 1 then -- LOBBY
            playersText = "Ready: " .. tostring(readyCount) .. "/" .. tostring(minPlayers)
        else
            playersText = "Players: " .. tostring(playerCount)
        end

        -- Get player's score (can be negative for hunters who missed)
        local scoreText = "Score: 0"
        local localPlayer = client.localPlayer
        if localPlayer then
            local playerInfo = PlayerManager.GetPlayerInfo(localPlayer)
            if playerInfo and playerInfo.score then
                local score = playerInfo.score.value
                scoreText = "Score: " .. tostring(math.floor(score))
            end
        end

        if _HudScript then
            _HudScript.UpdateHud(stateText, timerText, playersText, scoreText)
        end
    end)
end

local function SetUIVisibility(shouldShow : boolean)
    Logger.Log("UIManager", "SetUIVisibility called with: " .. tostring(shouldShow))

    if not _UIGameObjectsToHide or #_UIGameObjectsToHide == 0 then
        Logger.Log("UIManager", "WARNING: No UI GameObjects assigned to hide/show list!")
        return
    end

    Logger.Log("UIManager", "Processing " .. tostring(#_UIGameObjectsToHide) .. " UI GameObjects...")

    local count = 0
    for i, uiObject in ipairs(_UIGameObjectsToHide) do
        if uiObject then
            local name = uiObject.name or "Unknown"
            local wasActive = uiObject.activeSelf

            Logger.Log("UIManager", "GameObject[" .. tostring(i) .. "]: " .. name .. " - was active: " .. tostring(wasActive))

            uiObject:SetActive(shouldShow)
            count = count + 1

            -- Verify it changed
            Timer.After(0.1, function()
                if uiObject then
                    local nowActive = uiObject.activeSelf
                    Logger.Log("UIManager", "GameObject[" .. tostring(i) .. "]: " .. name .. " - now active: " .. tostring(nowActive))

                    if nowActive ~= shouldShow then
                        Logger.Log("UIManager", "WARNING: GameObject " .. name .. " state didn't change! Retrying...")
                        uiObject:SetActive(shouldShow)
                    end
                end
            end)
        else
            Logger.Log("UIManager", "WARNING: UI GameObject at index " .. tostring(i) .. " is nil!")
        end
    end

    if shouldShow then
        Logger.Log("UIManager", "✓ Attempted to SHOW " .. tostring(count) .. " UI elements")
    else
        Logger.Log("UIManager", "✓ Attempted to HIDE " .. tostring(count) .. " UI elements")
    end
end

function self:ServerStart()
    -- Server doesn't manage UI - nothing to do here
    Logger.Log("UIManager", "ServerStart - Server doesn't manage UI GameObjects")
end

function self:ClientAwake()
    if _HUD then
        _HudScript = _HUD:GetComponent(PropHuntHUD)
    end
end

function self:ClientStart()
    Logger.Log("UIManager", "ClientStart - Finding UI GameObjects by name...")

    -- Find UI GameObjects by name (CLIENT has access to scene GameObjects)
    for _, name in ipairs(UI_NAMES_TO_HIDE) do
        local obj = GameObject.Find(name)
        if obj then
            table.insert(_UIGameObjectsToHide, obj)
            Logger.Log("UIManager", "Found: " .. name)
        else
            Logger.Log("UIManager", "WARNING: Could not find GameObject: " .. name)
        end
    end

    -- Find EndRoundScore UI (managed separately - shown only during ROUND_END)
    _EndRoundScoreUI = GameObject.Find("EndRoundScore")
    if _EndRoundScoreUI then
        Logger.Log("UIManager", "Found EndRoundScore UI")
        _EndRoundScoreUI:SetActive(false) -- Hide by default
    else
        Logger.Log("UIManager", "WARNING: Could not find EndRoundScore GameObject")
    end

    if #_UIGameObjectsToHide == 0 then
        Logger.Log("UIManager", "ERROR: No UI GameObjects found!")
        Logger.Log("UIManager", "Make sure GameObjects are named: " .. table.concat(UI_NAMES_TO_HIDE, ", "))
    else
        Logger.Log("UIManager", "CLIENT loaded " .. tostring(#_UIGameObjectsToHide) .. " UI GameObjects to manage")
    end

    -- Start the HUD timer
    StartHUDTimer()

    -- Listen to game state changes via NetworkValue (same pattern as HunterTagSystem)
    local localPlayer = client.localPlayer
    if localPlayer then
        local playerInfo = PlayerManager.GetPlayerInfo(localPlayer)
        if playerInfo and playerInfo.gameState then
            -- Set initial visibility based on current state
            local currentState = playerInfo.gameState.value
            Logger.Log("UIManager", "CLIENT: Initial state from NetworkValue = " .. tostring(currentState))

            if currentState == GameState.LOBBY then
                SetUIVisibility(true)
            else
                SetUIVisibility(false)
            end

            -- Listen for state changes via NetworkValue.Changed
            playerInfo.gameState.Changed:Connect(function(newState, oldState)
                Logger.Log("UIManager", "CLIENT: *** State changed via NetworkValue to " .. tostring(newState) .. " (was " .. tostring(oldState) .. ") ***")

                -- Show UI in LOBBY (state 1), hide during gameplay
                if newState == GameState.LOBBY then
                    Logger.Log("UIManager", "CLIENT: State = LOBBY → Showing UI")
                    SetUIVisibility(true)
                    if _HUD then _HUD:SetActive(true) end
                    if _EndRoundScoreUI then
                        _EndRoundScoreUI:SetActive(false)
                    end
                elseif newState == GameState.ROUND_END then
                    Logger.Log("UIManager", "CLIENT: State = ROUND_END → Showing EndRoundScore")
                    SetUIVisibility(false) -- Hide lobby UI
                    if _HUD then _HUD:SetActive(false) end -- Hide HUD during end screen
                    if _EndRoundScoreUI then
                        _EndRoundScoreUI:SetActive(true)
                    end
                else
                    Logger.Log("UIManager", "CLIENT: State = " .. tostring(newState) .. " → Hiding UI")
                    SetUIVisibility(false)
                    if _HUD then _HUD:SetActive(true) end -- Show HUD during gameplay
                    if _EndRoundScoreUI then
                        _EndRoundScoreUI:SetActive(false)
                    end
                end
            end)

            Logger.Log("UIManager", "CLIENT: NetworkValue state listener registered!")
        else
            Logger.Log("UIManager", "ERROR: Could not get playerInfo or gameState NetworkValue!")
        end
    else
        Logger.Log("UIManager", "ERROR: Could not get local player!")
    end

    -- Backup: Also listen to event-based state changes (fallback)
    stateChangedEvent:Connect(function(newState, timer)
        Logger.Log("UIManager", "CLIENT: State changed via Event to " .. tostring(newState))

        if newState == GameState.LOBBY then
            SetUIVisibility(true)
            if _HUD then _HUD:SetActive(true) end
            if _EndRoundScoreUI then
                _EndRoundScoreUI:SetActive(false)
            end
        elseif newState == GameState.ROUND_END then
            SetUIVisibility(false)
            if _HUD then _HUD:SetActive(false) end -- Hide HUD during end screen
            if _EndRoundScoreUI then
                _EndRoundScoreUI:SetActive(true)
            end
        else
            SetUIVisibility(false)
            if _HUD then _HUD:SetActive(true) end -- Show HUD during gameplay
            if _EndRoundScoreUI then
                _EndRoundScoreUI:SetActive(false)
            end
        end
    end)
end

function self:OnDestroy()
    StopHUDTimer()
end

-- ========== MODULE EXPORTS ==========
-- Note: This module is not currently required by other scripts,
-- but exports are included for future extensibility

Logger.Log("UIManager", "Script fully loaded, returning exports")
return {}