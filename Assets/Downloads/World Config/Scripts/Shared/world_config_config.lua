--!Type(Module)

--!Tooltip("Storage key prefix for world configuration (e.g., 'WorldConfig')")
--!SerializeField
local _StorageKeyPrefix : string = "WorldConfig"

--!Tooltip("Whether to automatically create default configuration for new worlds")
--!SerializeField
local _AutoCreateDefaults : boolean = true

--!Tooltip("Whether to log all configuration operations for debugging")
--!SerializeField
local _EnableLogging : boolean = true

--("Default configuration for new worlds - these will be automatically applied")
local _DefaultConfig : { [string]: any } = {
    -- World Settings
    ["world_name"] = "My World",
    ["world_description"] = "A custom Highrise world",
    ["max_players"] = 50,
    ["world_theme"] = "default",
    
    -- Gameplay Settings
    ["enable_pvp"] = false,
    ["enable_voice_chat"] = true,
    ["enable_text_chat"] = true,
    ["spawn_protection_time"] = 10,
    
    -- Economy Settings
    ["starting_currency"] = 1000,
    ["currency_name"] = "Coins",
    ["enable_trading"] = true,
    ["tax_rate"] = 0.05,
    
    -- Environment Settings
    ["time_of_day"] = "day",
    ["weather_enabled"] = true,
    ["gravity_strength"] = 1.0,
    ["day_night_cycle"] = true,
    
    -- Custom Settings (add your own here)
    ["custom_setting_1"] = "default_value",
    ["custom_setting_2"] = 100
}

--("Configuration that can be modified by the client (security consideration)")
local _ClientModifiableConfig : { string } = {
    "world_name",
    "world_description",
    "max_players",
    "world_theme",
    "enable_pvp",
    "enable_voice_chat",
    "enable_text_chat",
    "spawn_protection_time",
    "starting_currency",
    "currency_name",
    "enable_trading",
    "tax_rate",
    "time_of_day",
    "weather_enabled",
    "gravity_strength",
    "day_night_cycle",
    "custom_setting_1",
    "custom_setting_2"
}

--("Configuration that are read-only and cannot be modified by clients")
local _ReadOnlyConfig : { string } = {
    -- Add read-only config keys here if needed
}

--("Configuration that should trigger a UI update when changed")
local _UIUpdateConfig : { string } = {
    "world_name",
    "world_description",
    "max_players",
    "world_theme",
    "enable_pvp",
    "enable_voice_chat",
    "enable_text_chat"
}

--("Configuration that should be validated before saving (e.g., numeric ranges)")
local _ValidatedConfig : { [string]: { min: number, max: number } } = {
    ["max_players"] = { min = 1, max = 100 },
    ["spawn_protection_time"] = { min = 0, max = 300 },
    ["starting_currency"] = { min = 0, max = 100000 },
    ["tax_rate"] = { min = 0.0, max = 1.0 },
    ["gravity_strength"] = { min = 0.1, max = 5.0 }
}

--("UI Configuration for each setting - defines how settings are displayed")
local _UIConfig : { [string]: { 
    type: string, 
    label: string, 
    section: string, 
    options: { string }?, 
    min: number?, 
    max: number?, 
    step: number? 
} } = {
    -- World Information
    ["world_name"] = { type = "text", label = "World Name", section = "World Information" },
    ["world_description"] = { type = "text", label = "World Description", section = "World Information" },
    ["max_players"] = { type = "slider", label = "Max Players", section = "World Information", min = 1, max = 100, step = 1 },
    ["world_theme"] = { type = "dropdown", label = "World Theme", section = "World Information", options = { "default", "fantasy", "sci-fi", "modern", "medieval" } },
    
    -- Gameplay Settings
    ["enable_pvp"] = { type = "toggle", label = "Enable PvP", section = "Gameplay Settings" },
    ["enable_voice_chat"] = { type = "toggle", label = "Enable Voice Chat", section = "Gameplay Settings" },
    ["enable_text_chat"] = { type = "toggle", label = "Enable Text Chat", section = "Gameplay Settings" },
    ["spawn_protection_time"] = { type = "slider", label = "Spawn Protection (seconds)", section = "Gameplay Settings", min = 0, max = 300, step = 5 },
    
    -- Economy Settings
    ["starting_currency"] = { type = "slider", label = "Starting Currency", section = "Economy Settings", min = 0, max = 10000, step = 100 },
    ["currency_name"] = { type = "text", label = "Currency Name", section = "Economy Settings" },
    ["enable_trading"] = { type = "toggle", label = "Enable Trading", section = "Economy Settings" },
    ["tax_rate"] = { type = "slider", label = "Tax Rate", section = "Economy Settings", min = 0.0, max = 1.0, step = 0.01 },
    
    -- Environment Settings
    ["time_of_day"] = { type = "dropdown", label = "Time of Day", section = "Environment Settings", options = { "day", "night", "dawn", "dusk" } },
    ["weather_enabled"] = { type = "toggle", label = "Weather Enabled", section = "Environment Settings" },
    ["gravity_strength"] = { type = "slider", label = "Gravity Strength", section = "Environment Settings", min = 0.1, max = 5.0, step = 0.1 },
    ["day_night_cycle"] = { type = "toggle", label = "Day/Night Cycle", section = "Environment Settings" },
    
    -- Custom Settings
    ["custom_setting_1"] = { type = "text", label = "Custom Setting 1", section = "Custom Settings" },
    ["custom_setting_2"] = { type = "slider", label = "Custom Setting 2", section = "Custom Settings", min = 0, max = 200, step = 1 }
}

--[[
  GetStorageKeyPrefix: Returns the storage key prefix for world configuration.
  @return string
]]
function GetStorageKeyPrefix(): string
    return _StorageKeyPrefix
end

--[[
  IsAutoCreateDefaults: Returns whether to automatically create default configuration.
  @return boolean
]]
function IsAutoCreateDefaults(): boolean
    return _AutoCreateDefaults
end

--[[
  IsLoggingEnabled: Returns whether logging is enabled.
  @return boolean
]]
function IsLoggingEnabled(): boolean
    return _EnableLogging
end

--[[
  GetDefaultConfig: Returns the default configuration for new worlds.
  @return table
]]
function GetDefaultConfig()
    -- Return a deep copy to prevent modification of the original defaults
    local copy = {}
    for key, value in pairs(_DefaultConfig) do
        copy[key] = value
    end
    return copy
end

--[[
  GetClientModifiableConfig: Returns the list of configuration that clients can modify.
  @return { string }
]]
function GetClientModifiableConfig(): { string }
    return _ClientModifiableConfig
end

--[[
  GetReadOnlyConfig: Returns the list of read-only configuration.
  @return { string }
]]
function GetReadOnlyConfig(): { string }
    return _ReadOnlyConfig
end

--[[
  GetUIUpdateConfig: Returns the list of configuration that trigger UI updates.
  @return { string }
]]
function GetUIUpdateConfig(): { string }
    return _UIUpdateConfig
end

--[[
  GetValidatedConfig: Returns the validation rules for configuration.
  @return table
]]
function GetValidatedConfig()
    return _ValidatedConfig
end

--[[
  GetUIConfig: Returns the UI configuration for all settings.
  @return table
]]
function GetUIConfig()
    return _UIConfig
end

--[[
  GetUIConfigForSetting: Returns the UI configuration for a specific setting.
  @param settingKey string - The setting key to get UI config for
  @return table or nil
]]
function GetUIConfigForSetting(settingKey: string)
    return _UIConfig[settingKey]
end

--[[
  GetSettingsBySection: Returns all settings grouped by section.
  @return table
]]
function GetSettingsBySection()
    local sections = {}
    
    for settingKey, config in pairs(_UIConfig) do
        local section = config.section
        if not sections[section] then
            sections[section] = {}
        end
        table.insert(sections[section], settingKey)
    end
    
    return sections
end

--[[
  IsSettingClientModifiable: Checks if a setting can be modified by the client.
  @param settingKey: string
  @return boolean
]]
function IsSettingClientModifiable(settingKey: string): boolean
    for _, key in ipairs(_ClientModifiableConfig) do
        if key == settingKey then
            return true
        end
    end
    return false
end

--[[
  IsSettingReadOnly: Checks if a setting is read-only.
  @param settingKey: string
  @return boolean
]]
function IsSettingReadOnly(settingKey: string): boolean
    for _, key in ipairs(_ReadOnlyConfig) do
        if key == settingKey then
            return true
        end
    end
    return false
end

--[[
  IsSettingUIUpdate: Checks if a setting should trigger UI updates.
  @param settingKey: string
  @return boolean
]]
function IsSettingUIUpdate(settingKey: string): boolean
    for _, key in ipairs(_UIUpdateConfig) do
        if key == settingKey then
            return true
        end
    end
    return false
end

--[[
  ValidateSettingValue: Validates a setting value against its rules.
  @param settingKey: string
  @param value: any
  @return boolean, string (success, error message)
]]
function ValidateSettingValue(settingKey: string, value: any): (boolean, string)
    local validation = _ValidatedConfig[settingKey]
    if not validation then
        return true, "" -- No validation rules, accept any value
    end
    
    if validation.min ~= nil and value < validation.min then
        return false, "Value must be at least " .. tostring(validation.min)
    end
    
    if validation.max ~= nil and value > validation.max then
        return false, "Value must be at most " .. tostring(validation.max)
    end
    
    return true, ""
end
