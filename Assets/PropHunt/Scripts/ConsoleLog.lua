--[[
    ConsoleLog - Helper to log to Unity Console from Lua
    Usage: local log = require("ConsoleLog")
           log("My message")
           log.warn("Warning message")
           log.error("Error message")
]]

--!Type(Module)

local ConsoleLog = {}

-- Regular log (appears in Unity Console as Info)
function ConsoleLog.log(message)
    Debug.Log(tostring(message))
end

-- Warning (appears in Unity Console as Warning)
function ConsoleLog.warn(message)
    Debug.LogWarning(tostring(message))
end

-- Error (appears in Unity Console as Error)
function ConsoleLog.error(message)
    Debug.LogError(tostring(message))
end

-- Default call behavior
setmetatable(ConsoleLog, {
    __call = function(_, message)
        Debug.Log(tostring(message))
    end
})

return ConsoleLog

