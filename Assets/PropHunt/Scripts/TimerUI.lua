--[[
    TimerUI (Client)
    Minimal timer/state display scaffold. Replace logs with real UI bindings.
]]

--!Type(Client)

-- last known state pushed from server (scaffold)
local currentState = "LOBBY"
local stateTimer = 0
local function getGlobalChannel(key, factory)
    local cached = _G[key]
    if cached then return cached end
    local created = factory()
    _G[key] = created
    return created
end

local stateChangedEvent = getGlobalChannel("__PH_EVT_STATE", function() return Event.new("PH_StateChanged") end)
local roleAssignedEvent = getGlobalChannel("__PH_EVT_ROLE", function() return Event.new("PH_RoleAssigned") end)

local function NormalizeState(value)
    if type(value) == "number" then
        if value == 1 then return "LOBBY"
        elseif value == 2 then return "HIDING"
        elseif value == 3 then return "HUNTING"
        elseif value == 4 then return "ROUND_END"
        end
    end
    return tostring(value)
end

-- Example: call this from a RemoteFunction when server broadcasts state
function OnServerStateChanged(newState, timer)
    currentState = NormalizeState(newState)
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
    stateChangedEvent:Connect(function(newState, timer)
        OnServerStateChanged(newState, timer)
    end)

    roleAssignedEvent:Connect(function(role)
        print("[TimerUI] Role assigned:", tostring(role))
    end)
end
