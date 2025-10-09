--!Type(ClientAndServer)

--!SerializeField
local TrapBox : GameObject = nil
--!SerializeField
local SafeBox : GameObject = nil
--!SerializeField
local offsetTimer : number = 0
--!SerializeField
local intervalTimer : number = 2

local currentState = false;

function self:ClientStart()

    function ToggleTrap(state)
        SafeBox:SetActive(not state)
        TrapBox:SetActive(state)
        currentState = state
    end

    function StartTrapSycle()
        ToggleTrap(true)
        Timer.Every(intervalTimer, function()
            ToggleTrap(not currentState)
        end)
    end

    Timer.After(offsetTimer, function()
        StartTrapSycle()
    end)
end