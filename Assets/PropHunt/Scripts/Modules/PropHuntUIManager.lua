--!Type(Module)

--!SerializeField
local _HUD : GameObject = nil

local _HudScript : PropHuntHUD = nil

-- Game State Data
local stateTimer = 0
local currentState = "LOBBY"
local playersReady = 0
local playersTotal = 0

local stateMapping = {
    [1] = "LOBBY",
    [2] = "HIDING",
    [3] = "HUNTING",
    [4] = "ROUND_END"
}

local function FormatState(value)
    return stateMapping[tonumber(value)] or tostring(value)
end

local function StartHUDTimer()
    -- Define event here to ensure it's client-only
    local stateChangedEvent = Event.new("PH_StateChanged")

    -- Timer to decrement the countdown every second
    Timer.Every(1, function()
        if stateTimer > 0 then
            stateTimer = math.max(0, stateTimer - 1)
            UpdateDisplay()
        end
    end)

    -- Listen for state changes from the server
    stateChangedEvent:Connect(function(newState, timer, pReady, pTotal)
        print("----------------------------------------")
        print("[PropHuntUIManager] stateChangedEvent received!")
        print("[PropHuntUIManager] Raw newState: " .. tostring(newState))
        print("[PropHuntUIManager] Raw timer: " .. tostring(timer))
        print("[PropHuntUIManager] Raw pReady: " .. tostring(pReady))
        print("[PropHuntUIManager] Raw pTotal: " .. tostring(pTotal))
        print("----------------------------------------")

        currentState = FormatState(newState)
        stateTimer = tonumber(timer) or 0
        playersReady = tonumber(pReady) or 0
        playersTotal = tonumber(pTotal) or 0

        UpdateDisplay()
    end)
end

local function UpdateDisplay()
    if _HudScript then
        local stateText = string.format("State: %s", currentState)
        local timerText = string.format("Time: %.0fs", math.max(0, stateTimer))
        local playersText = string.format("Players: %d/%d", playersReady, playersTotal)
        _HudScript.UpdateHud(stateText, timerText, playersText)
    end
end

function self:ClientAwake()
    if _HUD then
        _HudScript = _HUD:GetComponent(PropHuntHUD)
    else
        print("[PropHuntUIManager] Error: _HUD is not assigned.")
    end
end

function self:ClientStart()
    print("[PropHuntUIManager] ClientStart")

    if not _HudScript then
        print("[PropHuntUIManager] _HudScript not found, aborting ClientStart.")
        return
    end

    StartHUDTimer()
    UpdateDisplay() -- Initial display update
end