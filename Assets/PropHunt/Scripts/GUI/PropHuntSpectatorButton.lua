--!Type(UI)

local PlayerManager = require("PropHuntPlayerManager")

--!Bind
local _toggle : UISwitchToggle = nil
--!Bind
local _container : VisualElement = nil

local isUpdatingFromServer = false -- Flag to prevent toggle loop

function self:Start()
    print("[PropHuntSpectatorButton] Started")

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
