--[[
    DebugCheats (Client)
    - Subscribes to server debug events and prints structured info
    - Provides a simple gesture-based cheat menu (long-press to enable, then tap quadrant to force state)
]]

--!Type(Module)

-- Network events (must match server names)
local debugEvent = Event.new("PH_Debug")
local forceStateRequest = RemoteFunction.new("PH_ForceState")

local cheatEnabled = false
local forceStateRF = nil
local debugEvt = nil

local function PrintHelp()
    print("[Cheats] Enabled. Tap quadrants to force state:")
    print("[Cheats]  TL=LOBBY | TR=HIDING | BL=HUNTING | BR=ROUND_END")
    print("[Cheats]  Long-press again to disable.")
end

local function ForceState(name)
    forceStateRequest:InvokeServer(name, function(ok, msg)
        print("[Cheats] ForceState", name, ok, msg)
    end)
end

local function HandleTap(tap)
    if not cheatEnabled then return end
    local pos = tap.position
    local w = Screen.width
    local h = Screen.height
    local left = pos.x < (w * 0.5)
    local top = pos.y > (h * 0.5)

    if top and left then
        ForceState("LOBBY")
    elseif top and not left then
        ForceState("HIDING")
    elseif (not top) and left then
        ForceState("HUNTING")
    else
        ForceState("ROUND_END")
    end
end

local function ToggleCheats()
    cheatEnabled = not cheatEnabled
    if cheatEnabled then PrintHelp() else print("[Cheats] Disabled") end
end

function self:ClientStart()
    print("[Cheats] ClientStart")

    -- Debug events from server
    debugEvent:Connect(function(kind, a, b, c)
        print("[Debug]", tostring(kind), tostring(a), tostring(b), tostring(c))
    end)

    -- Long-press toggles cheat mode
    Input.LongPressBegan:Connect(function(evt)
        ToggleCheats()
    end)

    -- Tap to select a state when cheat is enabled
    Input.Tapped:Connect(HandleTap)
end
