--!Type(Module)

local Config = require("devx_config")

--!Tooltip("Enable/Disable registry logging")
--!SerializeField
local _EnableRegistyLogging : boolean = false

local Events = {}

function register(name, enableLogging: boolean)
  if Events[name] then
    if enableLogging then
      print("Event '" .. name .. "' is already registered.")
    end
    return
  end
  Events[name] = Event.new(name)
  if enableLogging then
    print("Registered event: " .. name)
  end
end

function get(name)
  return Events[name]
end

function init()
  for _, name in ipairs(Config.GetEvents()) do
    register(name, _EnableRegistyLogging)
  end
end


init()