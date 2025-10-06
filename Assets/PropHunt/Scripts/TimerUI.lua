--[[
    TimerUI (Client)
    Minimal timer/state display scaffold. Replace logs with real UI bindings.
]]

--!Type(Client)

-- last known state pushed from server (scaffold)
local currentState = "LOBBY"
local stateTimer = 0
local stateChangedEvent = nil
local roleAssignedEvent = nil

-- Example: call this from a RemoteFunction when server broadcasts state
function OnServerStateChanged(newState, timer)
    currentState = tostring(newState)
    stateTimer = tonumber(timer) or 0
    print(string.format("[TimerUI] State: %s | Timer: %.1f", currentState, stateTimer))
end

function self:Update()
    -- If we have a timer, decrement locally for display only
    if stateTimer and stateTimer > 0 then
        stateTimer = math.max(0, stateTimer - Time.deltaTime)
    end
end

function self:ClientStart()
    print("[TimerUI] ClientStart (UI scaffold active)")
    -- Subscribe to server events
    stateChangedEvent = Event.new("PH_StateChanged")
    stateChangedEvent:Connect(function(newState, timer)
        OnServerStateChanged(newState, timer)
    end)

    roleAssignedEvent = Event.new("PH_RoleAssigned")
    roleAssignedEvent:Connect(function(role)
        print("[TimerUI] Role assigned:", tostring(role))
    end)
end
