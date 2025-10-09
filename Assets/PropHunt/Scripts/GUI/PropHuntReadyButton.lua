--!Type(UI)

local PlayerManager = require("PropHuntPlayerManager")

--!Bind
local _button : VisualElement = nil
--!Bind
local _label : Label = nil

function ReadyUpButton()
    print("[PropHuntReadyButton] Ready button pressed")
    PlayerManager.ReadyUpRequest:FireServer()
end

_button:RegisterPressCallback(ReadyUpButton)

function self:Start()
    print("[PropHuntReadyButton] Started")
    
    -- Listen to ready state changes to update button
    local playerInfo = PlayerManager.GetPlayerInfo(client.localPlayer)
    if playerInfo then
        playerInfo.isReady.Changed:Connect(function(newValue, oldValue)
            if newValue then
                _button:SetEnabled(false)
                _label.text = "Ready!"
            else
                _button:SetEnabled(true)
                _label.text = "Ready"
            end
        end)
    end
end

