--!Type(UI)

local Logger = require("PropHuntLogger")
local PlayerManager = require("PropHuntPlayerManager")

--!Bind
local _button : VisualElement = nil
--!Bind
local _label : Label = nil

function ReadyUpButton()
    local playerInfo = PlayerManager.GetPlayerInfo(client.localPlayer)
    if not playerInfo then
        Logger.Log("ReadyButton", "Player info not found")
        return
    end

    local isCurrentlyReady = playerInfo.isReady.value

    if isCurrentlyReady then
        Logger.Log("ReadyButton", "Un-ready button pressed")
    else
        Logger.Log("ReadyButton", "Ready button pressed")
    end

    PlayerManager.ReadyUpRequest:FireServer()
end

_button:RegisterPressCallback(ReadyUpButton)

local function UpdateButtonVisuals(isReady)
    if isReady then
        -- Player is ready - yellow border
        _label.text = "Ready!"
        _button.style.borderBottomColor = Color.new(1, 1, 0, 1) -- Yellow
        _button.style.backgroundColor = Color.new(0.2, 0.2, 0, 0.5) -- Dark yellow tint
    else
        -- Player is not ready - green border
        _label.text = "Ready"
        _button.style.borderBottomColor = Color.new(0, 1, 0, 1) -- Green
        _button.style.backgroundColor = Color.new(0, 0, 0, 0.5) -- Black
    end
end

function self:Start()
    Logger.Log("ReadyButton", "Started")

    -- Listen to ready state changes to update button
    local playerInfo = PlayerManager.GetPlayerInfo(client.localPlayer)
    if playerInfo then
        -- Set initial state
        UpdateButtonVisuals(playerInfo.isReady.value)

        -- Listen for changes
        playerInfo.isReady.Changed:Connect(function(newValue, oldValue)
            UpdateButtonVisuals(newValue)
            if newValue then
                Logger.Log("ReadyButton", "Player marked as ready")
            else
                Logger.Log("ReadyButton", "Player unmarked as ready")
            end
        end)
    end
end

