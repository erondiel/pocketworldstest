--!Type(UI)

local PlayerManager = require("PropHuntPlayerManager")

--!Bind
local _toggle : UISwitchToggle = nil
--!Bind
local _container : VisualElement = nil

local isUpdatingFromServer = false -- Flag to prevent toggle loop

-- Game states (duplicated from GameManager since UI can't require Module)
local GameState = {
    LOBBY = 1,
    HIDING = 2,
    HUNTING = 3,
    ROUND_END = 4
}

local function UpdateButtonVisibility(currentState)
    if not _container then
        return
    end

    if currentState == GameState.LOBBY then
        -- Show in lobby
        _container.style.display = DisplayStyle.Flex
        print("[PropHuntSpectatorButton] UI shown (LOBBY)")
    else
        -- Hide during game phases
        _container.style.display = DisplayStyle.None
        print("[PropHuntSpectatorButton] UI hidden (game in progress)")
    end
end

function self:Start()
    print("[PropHuntSpectatorButton] Started")

    -- Listen to game state changes to show/hide UI
    local currentStateValue = NumberValue.new("PH_CurrentState", GameState.LOBBY)
    UpdateButtonVisibility(currentStateValue.value)

    currentStateValue.Changed:Connect(function(newState, oldState)
        UpdateButtonVisibility(newState)
    end)

    -- Listen to toggle changes (only fire server if user changed it, not server sync)
    if _toggle then
        _toggle:RegisterCallback(BoolChangeEvent, function(event)
            if not isUpdatingFromServer then
                print("[PropHuntSpectatorButton] User toggled spectator to: " .. tostring(_toggle.value))
                PlayerManager.SpectatorToggleRequest:FireServer()
            end
        end)
    end

    -- Listen to spectator state changes to sync toggle state
    local playerInfo = PlayerManager.GetPlayerInfo(client.localPlayer)
    if playerInfo then
        -- Set initial toggle state (without triggering event)
        isUpdatingFromServer = true
        _toggle.value = playerInfo.isSpectator.value
        isUpdatingFromServer = false

        -- Listen for server-side changes to keep toggle in sync
        playerInfo.isSpectator.Changed:Connect(function(newValue, oldValue)
            print("[PropHuntSpectatorButton] Server updated spectator state to: " .. tostring(newValue))
            isUpdatingFromServer = true
            _toggle.value = newValue
            isUpdatingFromServer = false
        end)
    end
end
