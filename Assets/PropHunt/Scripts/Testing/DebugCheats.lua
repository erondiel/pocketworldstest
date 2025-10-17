--[[
    DebugCheats (Client)
    - Subscribes to server debug events and prints structured info for debugging
]]

--!Type(Module)

-- Network events (must match server names)
local debugEvent = Event.new("PH_Debug")

function self:ClientStart()
    print("[Debug] Client logging active")

    -- Listen to server debug events and log them
    debugEvent:Connect(function(kind, a, b, c)
        print(string.format("[Debug] %s | %s | %s | %s", tostring(kind), tostring(a), tostring(b), tostring(c)))
    end)
end
