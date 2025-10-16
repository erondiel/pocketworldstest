--[[
    PropHunt Logger Module
    Centralized logging system with per-system toggles for debug output

    Usage:
        local Logger = require("PropHuntLogger")
        Logger.Log("GameManager", "Player joined")
        Logger.Warn("ScoringSystem", "Invalid score detected")
        Logger.Error("Teleporter", "Spawn point not found")
]]

--!Type(Module)

-- ========== LOG SYSTEM TOGGLES ==========
-- Set to true to enable logging for specific systems
-- Set to false to disable logging for that system

--!SerializeField
--!Tooltip("Enable/disable logging for GameManager")
local _enableGameManager : boolean = true

--!SerializeField
--!Tooltip("Enable/disable logging for PlayerManager")
local _enablePlayerManager : boolean = true

--!SerializeField
--!Tooltip("Enable/disable logging for ScoringSystem")
local _enableScoringSystem : boolean = true

--!SerializeField
--!Tooltip("Enable/disable logging for Teleporter")
local _enableTeleporter : boolean = true

--!SerializeField
--!Tooltip("Enable/disable logging for VFXManager")
local _enableVFXManager : boolean = true

--!SerializeField
--!Tooltip("Enable/disable logging for ZoneManager")
local _enableZoneManager : boolean = true

--!SerializeField
--!Tooltip("Enable/disable logging for UIManager")
local _enableUIManager : boolean = true

--!SerializeField
--!Tooltip("Enable/disable logging for HunterTagSystem")
local _enableHunterTagSystem : boolean = true

--!SerializeField
--!Tooltip("Enable/disable logging for PropPossessionSystem")
local _enablePropPossessionSystem : boolean = true

--!SerializeField
--!Tooltip("Enable/disable logging for PropDisguiseSystem - Not Implemented")
local _enablePropDisguiseSystem_NotImplemented : boolean = true

--!SerializeField
--!Tooltip("Enable/disable logging for RangeIndicator - Not Implemented")
local _enableRangeIndicator_NotImplemented : boolean = false

--!SerializeField
--!Tooltip("Enable/disable logging for ReadyButton - Not Implemented")
local _enableReadyButton_NotImplemented : boolean = false

--!SerializeField
--!Tooltip("Enable/disable logging for SpectatorButton - Not Implemented")
local _enableSpectatorButton_NotImplemented : boolean = false

--!SerializeField
--!Tooltip("Enable/disable logging for RecapScreen - Not Implemented")
local _enableRecapScreen_NotImplemented : boolean = true

--!SerializeField
--!Tooltip("Enable/disable logging for HUD - Not Implemented")
local _enableHUD_NotImplemented : boolean = false

--!SerializeField
--!Tooltip("Enable/disable logging for Config")
local _enableConfig : boolean = true

-- ========== SYSTEM NAME MAPPING ==========
-- Maps system names to their toggle flags
local systemToggles = {
    ["GameManager"] = function() return _enableGameManager end,
    ["PlayerManager"] = function() return _enablePlayerManager end,
    ["ScoringSystem"] = function() return _enableScoringSystem end,
    ["Teleporter"] = function() return _enableTeleporter end,
    ["VFXManager"] = function() return _enableVFXManager end,
    ["VFX"] = function() return _enableVFXManager end,  -- Alias
    ["ZoneManager"] = function() return _enableZoneManager end,
    ["UIManager"] = function() return _enableUIManager end,
    ["HunterTagSystem"] = function() return _enableHunterTagSystem end,
    ["PropPossessionSystem"] = function() return _enablePropPossessionSystem end,
    ["PropDisguiseSystem"] = function() return _enablePropDisguiseSystem_NotImplemented end,
    ["RangeIndicator"] = function() return _enableRangeIndicator_NotImplemented end,
    ["ReadyButton"] = function() return _enableReadyButton_NotImplemented end,
    ["SpectatorButton"] = function() return _enableSpectatorButton_NotImplemented end,
    ["RecapScreen"] = function() return _enableRecapScreen_NotImplemented end,
    ["HUD"] = function() return _enableHUD_NotImplemented end,
    ["Config"] = function() return _enableConfig end,

    -- Alternative names / aliases
    ["PropHunt"] = function() return _enableGameManager end,
    ["PropHuntGameManager"] = function() return _enableGameManager end,
    ["PropHuntPlayerManager"] = function() return _enablePlayerManager end,
    ["PropHuntScoringSystem"] = function() return _enableScoringSystem end,
    ["PropHuntTeleporter"] = function() return _enableTeleporter end,
    ["PropHuntVFXManager"] = function() return _enableVFXManager end,
    ["PropHuntUIManager"] = function() return _enableUIManager end,
    ["PropHuntZoneManager"] = function() return _enableZoneManager end,
    ["PropHuntHUD"] = function() return _enableHUD end,
    ["PropHuntConfig"] = function() return _enableConfig end,
}

-- ========== UTILITY FUNCTIONS ==========

--[[
    Check if logging is enabled for a specific system
    @param systemName: string - Name of the system (e.g., "GameManager")
    @return boolean - Whether logging is enabled
]]
local function IsSystemEnabled(systemName)
    -- Check system-specific toggle
    local toggleFunc = systemToggles[systemName]
    if toggleFunc then
        return toggleFunc()
    end

    -- Unknown system - default to enabled
    return true
end

--[[
    Format a log message with system prefix
    @param systemName: string - Name of the system
    @param message: string - The message to log
    @param level: string - Log level (INFO, WARN, ERROR, DEBUG)
    @return string - Formatted message
]]
local function FormatMessage(systemName, message, level)
    level = level or "INFO"
    return string.format("[%s] [%s] %s", systemName, level, tostring(message))
end

-- ========== PUBLIC LOGGING FUNCTIONS ==========

--[[
    Log an INFO message
    @param systemName: string - Name of the system
    @param message: string - The message to log
]]
function Log(systemName, message)
    if not IsSystemEnabled(systemName) then return end

    print(FormatMessage(systemName, message, "INFO"))
end

--[[
    Log a WARNING message
    @param systemName: string - Name of the system
    @param message: string - The message to log
]]
function Warn(systemName, message)
    if not IsSystemEnabled(systemName) then return end

    print(FormatMessage(systemName, message, "WARN"))
end

--[[
    Log an ERROR message
    @param systemName: string - Name of the system
    @param message: string - The message to log
]]
function Error(systemName, message)
    if not IsSystemEnabled(systemName) then return end

    print(FormatMessage(systemName, message, "ERROR"))
end

--[[
    Log a DEBUG message (verbose)
    @param systemName: string - Name of the system
    @param message: string - The message to log
]]
function Debug(systemName, message)
    if not IsSystemEnabled(systemName) then return end

    print(FormatMessage(systemName, message, "DEBUG"))
end

--[[
    Check if a system's logging is enabled (for conditional expensive operations)
    @param systemName: string - Name of the system
    @return boolean - Whether logging is enabled for this system
]]
function IsEnabled(systemName)
    return IsSystemEnabled(systemName)
end

--[[
    Quick formatted log for common patterns
    @param systemName: string - Name of the system
    @param format: string - String format (like string.format)
    @param ... - Arguments for the format string
]]
function Logf(systemName, format, ...)
    if not _showInfo then return end
    if not IsSystemEnabled(systemName) then return end

    local message = string.format(format, ...)
    print(FormatMessage(systemName, message, "INFO"))
end

-- ========== MODULE EXPORTS ==========
return {
    Log = Log,
    Warn = Warn,
    Error = Error,
    Debug = Debug,
    Logf = Logf,
    IsEnabled = IsEnabled,
}
