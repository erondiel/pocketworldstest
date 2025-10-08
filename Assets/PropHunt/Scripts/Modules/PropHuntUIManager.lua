--!Type(Module)

--!SerializeField
local _HUD : GameObject = nil
--!SerializeField
local _ReadyButton : GameObject = nil

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
        local stateText = "State: " .. stateName
        local timerText = "Time: " .. FormatTime(math.max(0, stateTimer))
        
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

function EnableDisableReadyButton(state : boolean)
    if _ReadyButton then
        _ReadyButton:SetActive(state)
    end
end

function self:ClientAwake()
    if _HUD then
        _HudScript = _HUD:GetComponent(PropHuntHUD)
    end
end

function self:ClientStart()
    print("[PropHuntUIManager] ClientStart")
    
    -- Start the HUD timer immediately
    StartHUDTimer()
    
    -- Show ready button initially
    EnableDisableReadyButton(true)
    
    -- Listen for state changes from server to control button visibility
    stateChangedEvent:Connect(function(newState, timer)
        print("[PropHuntUIManager] State changed: " .. FormatState(newState) .. " | Timer: " .. tostring(timer))
        
        -- Show button in LOBBY, hide during gameplay
        if newState == 1 then -- LOBBY
            EnableDisableReadyButton(true)
        else
            EnableDisableReadyButton(false)
        end
    end)
end

function self:OnDestroy()
    StopHUDTimer()
end