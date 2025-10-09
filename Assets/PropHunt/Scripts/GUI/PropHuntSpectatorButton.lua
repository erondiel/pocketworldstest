--!Type(UI)

local PlayerManager = require("PropHuntPlayerManager")

--!Bind
local _toggle : UISwitchToggle = nil

function self:Start()
    print("[PropHuntSpectatorButton] Started")

    -- Listen to toggle changes
    if _toggle then
        _toggle:RegisterCallback(BoolChangeEvent, function(event)
            print("[PropHuntSpectatorButton] Spectator toggle changed to: " .. tostring(_toggle.value))
            PlayerManager.SpectatorToggleRequest:FireServer()
        end)
    end

    -- Listen to spectator state changes to sync toggle state
    local playerInfo = PlayerManager.GetPlayerInfo(client.localPlayer)
    if playerInfo then
        -- Set initial toggle state
        _toggle.value = playerInfo.isSpectator.value

        -- Listen for server-side changes to keep toggle in sync
        playerInfo.isSpectator.Changed:Connect(function(newValue, oldValue)
            _toggle.value = newValue
            if newValue then
                print("[PropHuntSpectatorButton] Entered spectator mode")
            else
                print("[PropHuntSpectatorButton] Left spectator mode")
            end
        end)
    end
end
