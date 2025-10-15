--!Type(Module)

print("========================================")
print("PropHuntUIManager.lua LOADED")
print("========================================")

--!SerializeField
local _HUD : GameObject = nil

-- UI GameObjects to hide during gameplay (found by CLIENT at runtime)
local _UIGameObjectsToHide : {GameObject} = {}
local UI_NAMES_TO_HIDE = {"ReadyButton", "SpectatorButton"}

-- Game states
local GameState = {
    LOBBY = 1,
    HIDING = 2,
    HUNTING = 3,
    ROUND_END = 4
}

print("[PropHuntUIManager] Requiring dependencies...")
local success, err = pcall(function()
    Config = require("PropHuntConfig")
    print("[PropHuntUIManager] - Config loaded")
    GameManager = require("PropHuntGameManager")
    print("[PropHuntUIManager] - GameManager loaded")
    PlayerManager = require("PropHuntPlayerManager")
    print("[PropHuntUIManager] - PlayerManager loaded")
end)

if not success then
    print("[PropHuntUIManager] ERROR loading dependencies: " .. tostring(err))
else
    print("[PropHuntUIManager] All dependencies loaded!")
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
        
        if _HudScript then
            _HudScript.UpdateHud(stateText, timerText, playersText)
        end
    end)
end

local function SetUIVisibility(shouldShow : boolean)
    print("[PropHuntUIManager] SetUIVisibility called with: " .. tostring(shouldShow))

    if not _UIGameObjectsToHide or #_UIGameObjectsToHide == 0 then
        print("[PropHuntUIManager] WARNING: No UI GameObjects assigned to hide/show list!")
        return
    end

    print("[PropHuntUIManager] Processing " .. tostring(#_UIGameObjectsToHide) .. " UI GameObjects...")

    local count = 0
    for i, uiObject in ipairs(_UIGameObjectsToHide) do
        if uiObject then
            local name = uiObject.name or "Unknown"
            local wasActive = uiObject.activeSelf

            print("[PropHuntUIManager] GameObject[" .. tostring(i) .. "]: " .. name .. " - was active: " .. tostring(wasActive))

            uiObject:SetActive(shouldShow)
            count = count + 1

            -- Verify it changed
            Timer.After(0.1, function()
                if uiObject then
                    local nowActive = uiObject.activeSelf
                    print("[PropHuntUIManager] GameObject[" .. tostring(i) .. "]: " .. name .. " - now active: " .. tostring(nowActive))

                    if nowActive ~= shouldShow then
                        print("[PropHuntUIManager] WARNING: GameObject " .. name .. " state didn't change! Retrying...")
                        uiObject:SetActive(shouldShow)
                    end
                end
            end)
        else
            print("[PropHuntUIManager] WARNING: UI GameObject at index " .. tostring(i) .. " is nil!")
        end
    end

    if shouldShow then
        print("[PropHuntUIManager] ✓ Attempted to SHOW " .. tostring(count) .. " UI elements")
    else
        print("[PropHuntUIManager] ✓ Attempted to HIDE " .. tostring(count) .. " UI elements")
    end
end

function self:ServerStart()
    -- Server doesn't manage UI - nothing to do here
    print("[PropHuntUIManager] ServerStart - Server doesn't manage UI GameObjects")
end

function self:ClientAwake()
    if _HUD then
        _HudScript = _HUD:GetComponent(PropHuntHUD)
    end
end

function self:ClientStart()
    print("[PropHuntUIManager] ClientStart - Finding UI GameObjects by name...")

    -- Find UI GameObjects by name (CLIENT has access to scene GameObjects)
    for _, name in ipairs(UI_NAMES_TO_HIDE) do
        local obj = GameObject.Find(name)
        if obj then
            table.insert(_UIGameObjectsToHide, obj)
            print("[PropHuntUIManager] Found: " .. name)
        else
            print("[PropHuntUIManager] WARNING: Could not find GameObject: " .. name)
        end
    end

    if #_UIGameObjectsToHide == 0 then
        print("[PropHuntUIManager] ERROR: No UI GameObjects found!")
        print("[PropHuntUIManager] Make sure GameObjects are named: " .. table.concat(UI_NAMES_TO_HIDE, ", "))
    else
        print("[PropHuntUIManager] CLIENT loaded " .. tostring(#_UIGameObjectsToHide) .. " UI GameObjects to manage")
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
            print("[PropHuntUIManager] CLIENT: Initial state from NetworkValue = " .. tostring(currentState))

            if currentState == GameState.LOBBY then
                SetUIVisibility(true)
            else
                SetUIVisibility(false)
            end

            -- Listen for state changes via NetworkValue.Changed
            playerInfo.gameState.Changed:Connect(function(newState, oldState)
                print("[PropHuntUIManager] CLIENT: *** State changed via NetworkValue to " .. tostring(newState) .. " (was " .. tostring(oldState) .. ") ***")

                -- Show UI in LOBBY (state 1), hide during gameplay
                if newState == GameState.LOBBY then
                    print("[PropHuntUIManager] CLIENT: State = LOBBY → Showing UI")
                    SetUIVisibility(true)
                else
                    print("[PropHuntUIManager] CLIENT: State = " .. tostring(newState) .. " → Hiding UI")
                    SetUIVisibility(false)
                end
            end)

            print("[PropHuntUIManager] CLIENT: NetworkValue state listener registered!")
        else
            print("[PropHuntUIManager] ERROR: Could not get playerInfo or gameState NetworkValue!")
        end
    else
        print("[PropHuntUIManager] ERROR: Could not get local player!")
    end

    -- Backup: Also listen to event-based state changes (fallback)
    stateChangedEvent:Connect(function(newState, timer)
        print("[PropHuntUIManager] CLIENT: State changed via Event to " .. tostring(newState))

        if newState == GameState.LOBBY then
            SetUIVisibility(true)
        else
            SetUIVisibility(false)
        end
    end)
end

function self:OnDestroy()
    StopHUDTimer()
end

-- ========== MODULE EXPORTS ==========
-- Note: This module is not currently required by other scripts,
-- but exports are included for future extensibility

print("[PropHuntUIManager] Script fully loaded, returning exports")
return {}