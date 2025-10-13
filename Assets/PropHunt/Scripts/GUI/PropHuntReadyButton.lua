--!Type(UI)

local PlayerManager = require("PropHuntPlayerManager")

--!Bind
local _button : VisualElement = nil
--!Bind
local _label : Label = nil

-- Game states (duplicated from GameManager since UI can't require Module)
local GameState = {
    LOBBY = 1,
    HIDING = 2,
    HUNTING = 3,
    ROUND_END = 4
}

function ReadyUpButton()
    local playerInfo = PlayerManager.GetPlayerInfo(client.localPlayer)
    if not playerInfo then
        print("[PropHuntReadyButton] Player info not found")
        return
    end

    local isCurrentlyReady = playerInfo.isReady.value

    if isCurrentlyReady then
        print("[PropHuntReadyButton] Un-ready button pressed")
    else
        print("[PropHuntReadyButton] Ready button pressed")
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

local function UpdateButtonVisibility(currentState)
    if not _button then
        return
    end

    if currentState == GameState.LOBBY then
        -- Show in lobby
        _button.style.display = DisplayStyle.Flex
        print("[PropHuntReadyButton] UI shown (LOBBY)")
    else
        -- Hide during game phases
        _button.style.display = DisplayStyle.None
        print("[PropHuntReadyButton] UI hidden (game in progress)")
    end
end

function self:Start()
    print("[PropHuntReadyButton] Started")

    -- Listen to game state changes to show/hide UI
    local currentStateValue = NumberValue.new("PH_CurrentState", GameState.LOBBY)
    UpdateButtonVisibility(currentStateValue.value)

    currentStateValue.Changed:Connect(function(newState, oldState)
        UpdateButtonVisibility(newState)
    end)

    -- Listen to ready state changes to update button
    local playerInfo = PlayerManager.GetPlayerInfo(client.localPlayer)
    if playerInfo then
        -- Set initial state
        UpdateButtonVisuals(playerInfo.isReady.value)

        -- Listen for changes
        playerInfo.isReady.Changed:Connect(function(newValue, oldValue)
            UpdateButtonVisuals(newValue)
            if newValue then
                print("[PropHuntReadyButton] Player marked as ready")
            else
                print("[PropHuntReadyButton] Player unmarked as ready")
            end
        end)
    end
end

