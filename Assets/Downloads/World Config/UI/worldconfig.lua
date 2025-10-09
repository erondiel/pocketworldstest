--!Type(UI)

local Config = require("world_config_config")

--!Bind
local _title : Label = nil
--!Bind
local _wrapper : VisualElement = nil
--!Bind
local _showButtonLabel : Label = nil
--!Bind
local _showButton : VisualElement = nil
--!Bind
local _closeButton : VisualElement = nil
--!Bind
local _container : VisualElement = nil
--!Bind
local _settingsContent : VisualElement = nil
--!Bind
local _resetButton : VisualElement = nil
--!Bind
local _saveButton : VisualElement = nil
--!Bind
local _modalOverlay : VisualElement = nil
--!Bind
local _modalTitle : Label = nil
--!Bind
local _modalCloseButton : VisualElement = nil
--!Bind
local _modalLabel : Label = nil
--!Bind
local _modalTextField : UITextField = nil
--!Bind
local _modalCancelButton : VisualElement = nil
--!Bind
local _modalSaveButton : VisualElement = nil
--!Bind
local _dropdownModalOverlay : VisualElement = nil
--!Bind
local _dropdownModalContainer : VisualElement = nil
--!Bind
local _dropdownModalTitle : Label = nil
--!Bind
local _dropdownModalCloseButton : VisualElement = nil
--!Bind
local _dropdownModalLabel : Label = nil
--!Bind
local _dropdownOptionsList : VisualElement = nil

-- Reset Modal Bindings
--!Bind
local _resetModalOverlay : VisualElement = nil
--!Bind
local _resetModalContainer : VisualElement = nil
--!Bind
local _resetModalTitle : Label = nil
--!Bind
local _resetModalCloseButton : VisualElement = nil
--!Bind
local _resetModalLabel : Label = nil
--!Bind
local _resetModalCancelButton : VisualElement = nil
--!Bind
local _resetModalConfirmButton : VisualElement = nil

-- UI State
local _isInitialized : boolean = false
local _currentConfig : { [string]: any } = {}
local _hasUnsavedChanges : boolean = false
local _isUpdatingFromServer : boolean = false
local _isLoading : boolean = false

-- Dynamic UI Elements Storage
local _uiElements : { [string]: any } = {} -- Stores references to dynamically created UI elements

-- Modal State
local _currentModalSetting : string = nil

--[[
  Show loading state
]]
function ShowLoadingState()
    _isLoading = true
    _resetButton:SetEnabled(false)
    _saveButton:SetEnabled(false)
    
    -- Update button labels to show loading
    local resetLabel = _resetButton:Q("button-label")
    local saveLabel = _saveButton:Q("button-label")
    
    if resetLabel then
        resetLabel.text = "Loading..."
    end
    if saveLabel then
        saveLabel.text = "Loading..."
    end
end

--[[
  Hide loading state
]]
function HideLoadingState()
    _isLoading = false
    _resetButton:SetEnabled(true)
    _saveButton:SetEnabled(true)
    
    -- Restore button labels
    local resetLabel = _resetButton:Q("button-label")
    local saveLabel = _saveButton:Q("button-label")
    
    if resetLabel then
        resetLabel.text = "Reset to Defaults"
    end
    if saveLabel then
        saveLabel.text = "Save Config"
    end
end

--[[
  Initialize the scale of the UI
]]
local function InitializeScale()
  if not view.parent then 
      return
  end

  local width = _wrapper.worldBound.width

  if width == 0 or width ~= width then 
      return
  end

  -- Scale between 0.8 and 1.0 based on screen width
  -- 300px or less = 0.8 scale
  -- 700px = 0.9 scale
  -- 1200px or more = 1.0 scale (capped to avoid oversized UI)
  local t = math.clamp((width - 300) / (1200 - 300), 0, 1)
  local scaleValue = 0.8 + t * (1.0 - 0.8)
  local scale = Vector2.new(scaleValue, scaleValue)

  _wrapper.style.scale = StyleScale.new(Scale.new(scale))
end

--[[
  Show the world config UI
]]
function Show()
    _wrapper.visible = true
    _showButton.visible = false
    
    if not _isInitialized then
        InitializeUI()
    end
end

--[[
  Hide the world config UI
]]
function OnClose()
    if _hasUnsavedChanges then
        -- TODO: Show confirmation dialog
        print("[WorldConfig] Unsaved changes detected")
    end
    
    _wrapper.visible = false
    _showButton.visible = true
end

--[[
  Initialize the UI with current configuration
]]
function InitializeUI()
    print("[WorldConfig] Initializing UI...")
    
    -- Generate dynamic UI based on configuration
    GenerateDynamicUI()
    
    -- Load current configuration (for now, use defaults)
    LoadDefaultConfig()
    
    -- Setup event listeners for action buttons
    SetupActionButtonListeners()
end

--[[
  Load default configuration for demo purposes
]]
function LoadDefaultConfig()
    ShowLoadingState()
    
    -- Simulate loading delay (remove this when backend is implemented)
    Timer.After(0.5, function()
        _currentConfig = Config.GetDefaultConfig()
        UpdateUIWithConfig(_currentConfig)
        _isInitialized = true
        HideLoadingState()
        print("[WorldConfig] Loaded default configuration")
    end)
end

--[[
  Generate dynamic UI based on configuration
]]
function GenerateDynamicUI()
    -- Clear existing content
    _settingsContent:Clear()
    _uiElements = {}
    
    -- Get settings grouped by section
    local sections = Config.GetSettingsBySection()
    
    -- Create sections in order
    local sectionOrder = { "World Information", "Gameplay Settings", "Economy Settings", "Environment Settings", "Custom Settings" }
    
    for _, sectionName in ipairs(sectionOrder) do
        if sections[sectionName] then
            CreateConfigSection(sectionName, sections[sectionName])
        end
    end
    
    -- Update all UI elements with current config values
    UpdateUIWithConfig(_currentConfig)
end

--[[
  Create a configuration section with all its settings
]]
function CreateConfigSection(sectionName: string, settingKeys: { string })
    local sectionElement = VisualElement.new()
    sectionElement:AddToClassList("settings-section")
    
    -- Section title
    local titleElement = Label.new()
    titleElement:AddToClassList("section-title")
    titleElement.text = sectionName
    sectionElement:Add(titleElement)
    
    -- Create setting items
    for _, settingKey in ipairs(settingKeys) do
        local settingElement = CreateSettingItem(settingKey)
        if settingElement then
            sectionElement:Add(settingElement)
        end
    end
    
    _settingsContent:Add(sectionElement)
end

--[[
  Create a single setting item based on its configuration
]]
function CreateSettingItem(settingKey: string): VisualElement?
    local config = Config.GetUIConfigForSetting(settingKey)
    if not config then
        return nil
    end
    
    local settingItem = VisualElement.new()
    settingItem:AddToClassList("setting-item")
    
    -- Setting label
    local labelElement = Label.new()
    labelElement:AddToClassList("setting-label")
    labelElement.text = config.label
    settingItem:Add(labelElement)
    
    -- Create control based on type
    if config.type == "label" then
        local valueElement = Label.new()
        valueElement:AddToClassList("setting-value")
        valueElement.text = "Loading..."
        settingItem:Add(valueElement)
        _uiElements[settingKey] = valueElement
        
    elseif config.type == "toggle" then
        local toggleElement = UISwitchToggle.new()
        toggleElement:AddToClassList("toggle-switch")
        settingItem:Add(toggleElement)
        _uiElements[settingKey] = toggleElement
        
        -- Setup event listener
        toggleElement:RegisterCallback(BoolChangeEvent, function(event)
            HandleToggleChange(settingKey, toggleElement)
        end)
        
    elseif config.type == "slider" then
        local sliderContainer = VisualElement.new()
        sliderContainer:AddToClassList("slider-container")
        
        local sliderElement = UISlider.new()
        sliderElement:AddToClassList("slider")
        
        -- Set slider range based on config
        if config.min and config.max then
            sliderElement.lowValue = config.min
            sliderElement.highValue = config.max
        end
        
        local valueElement = Label.new()
        valueElement:AddToClassList("slider-value")
        valueElement.text = "0"
        
        sliderContainer:Add(sliderElement)
        sliderContainer:Add(valueElement)
        settingItem:Add(sliderContainer)
        
        _uiElements[settingKey] = sliderElement
        _uiElements[settingKey .. "_value"] = valueElement
        
        -- Setup event listener
        sliderElement:RegisterCallback(IntChangeEvent, function(event)
            HandleSliderChange(settingKey, sliderElement, valueElement, config)
        end)
        
    elseif config.type == "dropdown" then
        local dropdownDisplay = Label.new()
        dropdownDisplay:AddToClassList("setting-value")
        dropdownDisplay.text = "Click to select"
        settingItem:Add(dropdownDisplay)
        _uiElements[settingKey] = dropdownDisplay
        
        -- Setup click handler to open dropdown modal
        dropdownDisplay:RegisterPressCallback(function()
            OpenDropdownModal(settingKey, config.label, config.options or {})
        end)

    elseif config.type == "text" then
        local textDisplay = Label.new()
        textDisplay:AddToClassList("setting-value")
        textDisplay.text = "Click to edit"
        settingItem:Add(textDisplay)
        _uiElements[settingKey] = textDisplay
        
        -- Setup click handler to open modal
        textDisplay:RegisterPressCallback(function()
            OpenTextModal(settingKey, config.label)
        end)
    end
    
    return settingItem
end

--[[
  Update UI elements with current configuration
]]
function UpdateUIWithConfig(config : { [string]: any })
    -- Set flag to prevent event loops during server updates
    _isUpdatingFromServer = true
    
    -- Update each setting based on its type
    for settingKey, value in pairs(config) do
        local uiConfig = Config.GetUIConfigForSetting(settingKey)
        if uiConfig and _uiElements[settingKey] then
            UpdateSettingElement(settingKey, value, uiConfig)
        end
    end
    
    _hasUnsavedChanges = false
    
    -- Clear the flag after a short delay to allow UI updates to complete
    Timer.After(0.1, function()
        _isUpdatingFromServer = false
    end)
end

--[[
  Update a setting element based on its type and configuration
]]
function UpdateSettingElement(settingKey: string, value: any, config: any)
    local element = _uiElements[settingKey]
    if not element then 
        print("[WorldConfig] No UI element found for: " .. settingKey)
        return 
    end
    
    
    if config.type == "label" then
        element.text = tostring(value or "Unknown")
        
    elseif config.type == "toggle" then
        element:SetValueWithoutNotify(value or false)
        
    elseif config.type == "slider" then
        local valueElement = _uiElements[settingKey .. "_value"]
        if valueElement then
            UpdateSliderElement(element, valueElement, value, settingKey, config)
        end
        
    elseif config.type == "dropdown" then
        element.text = tostring(value or "Click to select"):gsub("^%l", string.upper)
        
    elseif config.type == "text" then
        element.text = tostring(value or "Click to edit")
    end
end

--[[
  Update a slider element
]]
function UpdateSliderElement(sliderElement: UISlider, valueElement: Label, value: number, settingKey: string, config: any)
    -- Convert actual value to slider range
    local sliderValue = value or 0
    
    if settingKey == "tax_rate" then
        -- Tax Rate: 0.0-1.0 -> 0-100 range
        sliderValue = math.max(0, math.min(100, value * 100))
        valueElement.text = string.format("%.1f%%", sliderValue)
    else
        -- Default conversion
        if config.min and config.max then
            sliderValue = math.max(config.min, math.min(config.max, value))
            valueElement.text = string.format("%.0f", value)
        end
    end
    
    sliderElement:SetValueWithoutNotify(sliderValue)
end

function ResetAllContent()
    _settingsContent:Clear()
    _uiElements = {}

    -- Load the default config FIRST
    _currentConfig = Config.GetDefaultConfig()
    
    -- Then generate UI with the default values
    GenerateDynamicUI()
end

--[[
  Setup event listeners for action buttons only
]]
function SetupActionButtonListeners()
    -- Setup event listeners for UXML action buttons
    _resetButton:RegisterPressCallback(ResetToDefaults)
    _saveButton:RegisterPressCallback(SaveConfig)
end

--[[
  Handle toggle change event
]]
function HandleToggleChange(settingKey : string, toggleElement : UISwitchToggle)
    -- Ignore changes if we're updating from server to prevent loops
    if _isUpdatingFromServer or _isLoading then
        return
    end
    
    local newValue = toggleElement.value
    
    _currentConfig[settingKey] = newValue
    _hasUnsavedChanges = true
end

--[[
  Handle slider change event
]]
function HandleSliderChange(settingKey: string, sliderElement: UISlider, valueElement: Label, config: any)
    -- Ignore changes if we're updating from server to prevent loops
    if _isUpdatingFromServer or _isLoading then
        return
    end
    
    -- Get slider value and convert to actual value based on setting type
    local sliderValue = sliderElement.value
    local actualValue = sliderValue
    
    if settingKey == "tax_rate" then
        -- Tax Rate: slider is 0-100, convert to 0.0-1.0 for storage
        actualValue = sliderValue / 100.0
        valueElement.text = string.format("%.1f%%", sliderValue)
    else
        -- Default conversion
        valueElement.text = string.format("%.0f", sliderValue)
    end
    
    _currentConfig[settingKey] = actualValue
    _hasUnsavedChanges = true
end

--[[
  Open dropdown selection modal
]]
function OpenDropdownModal(settingKey: string, label: string, options: { string })
    _currentModalSetting = settingKey
    _dropdownModalTitle.text = "Select " .. label
    _dropdownModalLabel.text = "Choose an option:"
    
    -- Clear existing options
    _dropdownOptionsList:Clear()
    
    -- Create option buttons
    for i, option in ipairs(options) do
        local optionItem = VisualElement.new()
        optionItem:AddToClassList("dropdown-modal-option")
        
        local optionLabel = Label.new()
        optionLabel:AddToClassList("dropdown-modal-option-label")
        optionLabel.text = option:gsub("^%l", string.upper)
        optionItem:Add(optionLabel)
        
        -- Setup option click handler
        optionItem:RegisterPressCallback(function()
            SelectDropdownOption(settingKey, option)
        end)
        
        _dropdownOptionsList:Add(optionItem)
    end
    
    _dropdownModalOverlay.style.display = DisplayStyle.Flex
end

--[[
  Close dropdown selection modal
]]
function CloseDropdownModal()
    _dropdownModalOverlay.style.display = DisplayStyle.None
    _currentModalSetting = nil
end

--[[
  Select an option from the dropdown modal
]]
function SelectDropdownOption(settingKey: string, selectedValue: string)
    -- Ignore changes if we're updating from server to prevent loops
    if _isUpdatingFromServer or _isLoading then
        return
    end
    
    -- Update the setting
    _currentConfig[settingKey] = selectedValue
    _hasUnsavedChanges = true
    
    -- Update the display
    local element = _uiElements[settingKey]
    if element then
        element.text = selectedValue:gsub("^%l", string.upper)
    end
    
    CloseDropdownModal()
end

--[[
  Open text input modal
]]
function OpenTextModal(settingKey: string, label: string)
    _currentModalSetting = settingKey
    _modalTitle.text = "Edit " .. label
    _modalLabel.text = label .. ":"
    _modalTextField.value = tostring(_currentConfig[settingKey] or "")
    _modalOverlay.style.display = DisplayStyle.Flex
end

--[[
  Close text input modal
]]
function CloseTextModal()
    _modalOverlay.style.display = DisplayStyle.None
    _currentModalSetting = nil
end

--[[
  Save text from modal
]]
function SaveTextFromModal()
    if not _currentModalSetting or _isLoading then
        return
    end
    
    local newValue = _modalTextField.value
    _currentConfig[_currentModalSetting] = newValue
    _hasUnsavedChanges = true
    
    -- Update the display
    local element = _uiElements[_currentModalSetting]
    if element then
        element.text = newValue ~= "" and newValue or "Click to edit"
    end
    
    CloseTextModal()
end

--[[
  Reset all configuration to defaults
]]
function ResetToDefaults()
    if _isLoading then
        return
    end
    
    -- Show confirmation modal
    _resetModalOverlay.style.display = DisplayStyle.Flex
end

function ConfirmReset()
    if _isLoading then
        return
    end
    
    ShowLoadingState()
    CloseResetModal()
    
    Timer.After(0.3, function()
        -- Clear UI and recreate with defaults
        ResetAllContent()
        
        _hasUnsavedChanges = false
        HideLoadingState()
    end)
end

function CloseResetModal()
    _resetModalOverlay.style.display = DisplayStyle.None
end

--[[
  Save current configuration
]]
function SaveConfig()
    if not _hasUnsavedChanges then
        print("[WorldConfig] No changes to save")
        return
    end
    
    if _isLoading then
        return -- Prevent multiple saves while loading
    end
    
    ShowLoadingState()
    
    -- Simulate save delay (remove this when backend is implemented)
    Timer.After(0.4, function()
        -- For now, just mark as saved (no backend yet)
        _hasUnsavedChanges = false
        
        HideLoadingState()
        print("[WorldConfig] Configuration saved successfully (frontend only)")
    end)
end

function self:OnEnable()
    _title.text = "World Configuration"
    _showButtonLabel.text = "World Config"
end

function self:Awake()
    -- Dynamic UI will be initialized in InitializeUI()
end

function self:Start()
    -- Initialize the UI
    InitializeUI()
    
    -- Setup modal event listeners
    _modalCloseButton:RegisterPressCallback(CloseTextModal)
    _modalCancelButton:RegisterPressCallback(CloseTextModal)
    _modalSaveButton:RegisterPressCallback(SaveTextFromModal)
    
    -- Setup dropdown modal event listeners
    _dropdownModalCloseButton:RegisterPressCallback(CloseDropdownModal)
    
    -- Reset modal event listeners
    _resetModalCloseButton:RegisterPressCallback(CloseResetModal)
    _resetModalCancelButton:RegisterPressCallback(CloseResetModal)
    _resetModalConfirmButton:RegisterPressCallback(ConfirmReset)
    
    -- Initially hide the wrapper and modals
    OnClose()
    CloseTextModal()
    CloseDropdownModal()
    CloseResetModal()
end

function self:OnDestroy()
    -- Clean up any resources if needed
end

-- Register button callbacks
_closeButton:RegisterPressCallback(OnClose)
_showButton:RegisterPressCallback(Show)
