--!Type(UI)

-- UI Panels Manager
-- A comprehensive UI system for managing various panel types including:
-- Confirmation prompts, input fields, switches, sliders, dropdowns, progress, and notifications

--!Bind
local _panelsContainer : VisualElement = nil

-- Panel References
--!Bind
local _confirmationPanel : VisualElement = nil
--!Bind
local _inputPanel : VisualElement = nil
--!Bind
local _switchesPanel : VisualElement = nil
--!Bind
local _sliderPanel : VisualElement = nil
--!Bind
local _dropdownPanel : VisualElement = nil
--!Bind
local _progressPanel : VisualElement = nil
--!Bind
local _notificationPanel : VisualElement = nil
--!Bind
local _tooltipPanel : VisualElement = nil

-- Confirmation Panel Elements
--!Bind
local _confirmationTitle : Label = nil
--!Bind
local _confirmationMessage : Label = nil
--!Bind
local _confirmationCloseButton : VisualElement = nil
--!Bind
local _confirmationCancelButton : VisualElement = nil
--!Bind
local _confirmationConfirmButton : VisualElement = nil

-- Input Panel Elements
--!Bind
local _inputTitle : Label = nil
--!Bind
local _inputLabel : Label = nil
--!Bind
local _inputField : UITextField = nil
--!Bind
local _inputLabel2 : Label = nil
--!Bind
local _inputField2 : UITextField = nil
--!Bind
local _inputCloseButton : VisualElement = nil
--!Bind
local _inputCancelButton : VisualElement = nil
--!Bind
local _inputSubmitButton : VisualElement = nil

-- Switches Panel Elements
--!Bind
local _switchesTitle : Label = nil
--!Bind
local _switch1 : UISwitchToggle = nil
--!Bind
local _switch2 : UISwitchToggle = nil
--!Bind
local _switch3 : UISwitchToggle = nil
--!Bind
local _switchesCloseButton : VisualElement = nil
--!Bind
local _switchesCancelButton : VisualElement = nil
--!Bind
local _switchesSaveButton : VisualElement = nil

-- Slider Panel Elements
--!Bind
local _sliderTitle : Label = nil
--!Bind
local _volumeSlider : UISlider = nil
--!Bind
local _volumeValue : Label = nil
--!Bind
local _brightnessSlider : UISlider = nil
--!Bind
local _brightnessValue : Label = nil
--!Bind
local _speedSlider : UISlider = nil
--!Bind
local _speedValue : Label = nil
--!Bind
local _sliderCloseButton : VisualElement = nil
--!Bind
local _sliderCancelButton : VisualElement = nil
--!Bind
local _sliderApplyButton : VisualElement = nil

-- Dropdown Panel Elements
--!Bind
local _dropdownTitle : Label = nil
--!Bind
local _categoryDropdown : VisualElement = nil
--!Bind
local _categoryHeader : VisualElement = nil
--!Bind
local _categorySelected : Label = nil
--!Bind
local _priorityDropdown : VisualElement = nil
--!Bind
local _priorityHeader : VisualElement = nil
--!Bind
local _prioritySelected : Label = nil
--!Bind
local _dropdownCloseButton : VisualElement = nil
--!Bind
local _dropdownCancelButton : VisualElement = nil
--!Bind
local _dropdownApplyButton : VisualElement = nil

-- Progress Panel Elements
--!Bind
local _progressTitle : Label = nil
--!Bind
local _progressMessage : Label = nil
--!Bind
local _progressFill : VisualElement = nil
--!Bind
local _progressPercentage : Label = nil
--!Bind
local _progressStatus : Label = nil
--!Bind
local _progressCloseButton : VisualElement = nil
--!Bind
local _progressCancelButton : VisualElement = nil

-- Notification Panel Elements
--!Bind
local _notificationIcon : VisualElement = nil
--!Bind
local _notificationTitle : Label = nil
--!Bind
local _notificationMessage : Label = nil
--!Bind
local _notificationCloseButton : VisualElement = nil

-- Tooltip Elements
--!Bind
local _tooltipText : Label = nil
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

-- Constants
local PANEL_TYPES = {
    CONFIRMATION = "confirmation",
    INPUT = "input",
    SWITCHES = "switches",
    SLIDER = "slider",
    DROPDOWN = "dropdown",
    PROGRESS = "progress",
    NOTIFICATION = "notification"
}

local NOTIFICATION_TYPES = {
    SUCCESS = "success",
    WARNING = "warning",
    ERROR = "error",
    INFO = "info"
}

function GetNotificationTypes()
    return NOTIFICATION_TYPES
end

function GetPanelTypes()
    return PANEL_TYPES
end

-- Variables
local currentPanel = nil
local panelCallbacks = {}
local switchStates = {}
local sliderValues = {}
local dropdownSelections = {}
local progressTimer = nil
local currentOpenDropdown = nil
local notificationTimer = nil

-- Initialize the UI Panels system
function self:Awake()
    print("[UIPanels] Initializing UI Panels system")
    
    -- Initialize switch states
    switchStates = {
        switch1 = false,
        switch2 = false,
        switch3 = false
    }
    
    -- Initialize slider values
    sliderValues = {
        volume = 50,
        brightness = 75,
        speed = 5
    }
    
    -- Initialize dropdown selections
    dropdownSelections = {
        category = "Select Category",
        priority = "Select Priority"
    }
    
    SetupEventListeners()
    HideAllPanels()
end

-- Setup all event listeners for panels
function SetupEventListeners()
    print("[UIPanels] Setting up event listeners")
    
    -- Confirmation Panel Events
    if _confirmationCloseButton then
        _confirmationCloseButton:RegisterPressCallback(function() HidePanel() end)
    end
    if _confirmationCancelButton then
        _confirmationCancelButton:RegisterPressCallback(function() HidePanel() end)
    end
    if _confirmationConfirmButton then
        _confirmationConfirmButton:RegisterPressCallback(function() OnConfirmationConfirm() end)
    end
    
    -- Input Panel Events
    if _inputCloseButton then
        _inputCloseButton:RegisterPressCallback(function() HidePanel() end)
    end
    if _inputCancelButton then
        _inputCancelButton:RegisterPressCallback(function() HidePanel() end)
    end
    if _inputSubmitButton then
        _inputSubmitButton:RegisterPressCallback(function() OnInputSubmit() end)
    end
    
    -- Switches Panel Events
    if _switchesCloseButton then
        _switchesCloseButton:RegisterPressCallback(function() HidePanel() end)
    end
    if _switchesCancelButton then
        _switchesCancelButton:RegisterPressCallback(function() HidePanel() end)
    end
    if _switchesSaveButton then
        _switchesSaveButton:RegisterPressCallback(function() OnSwitchesSave() end)
    end
    
    -- Switch Toggle Events
    if _switch1 then
        _switch1:RegisterCallback(BoolChangeEvent, function(event) HandleSwitchChange("switch1", _switch1) end)
    end
    if _switch2 then
        _switch2:RegisterCallback(BoolChangeEvent, function(event) HandleSwitchChange("switch2", _switch2) end)
    end
    if _switch3 then
        _switch3:RegisterCallback(BoolChangeEvent, function(event) HandleSwitchChange("switch3", _switch3) end)
    end
    
    -- Slider Panel Events
    if _sliderCloseButton then
        _sliderCloseButton:RegisterPressCallback(function() HidePanel() end)
    end
    if _sliderCancelButton then
        _sliderCancelButton:RegisterPressCallback(function() HidePanel() end)
    end
    if _sliderApplyButton then
        _sliderApplyButton:RegisterPressCallback(function() OnSliderApply() end)
    end
    
    -- Slider Value Change Events
    if _volumeSlider then
        _volumeSlider:RegisterCallback(IntChangeEvent, function(event) OnSliderValueChanged("volume", _volumeSlider.value) end)
    end
    if _brightnessSlider then
        _brightnessSlider:RegisterCallback(IntChangeEvent, function(event) OnSliderValueChanged("brightness", _brightnessSlider.value) end)
    end
    if _speedSlider then
        _speedSlider:RegisterCallback(IntChangeEvent, function(event) OnSliderValueChanged("speed", _speedSlider.value) end)
    end
    
    -- Dropdown Panel Events
    if _dropdownCloseButton then
        _dropdownCloseButton:RegisterPressCallback(function() HidePanel() end)
    end
    if _dropdownCancelButton then
        _dropdownCancelButton:RegisterPressCallback(function() HidePanel() end)
    end
    if _dropdownApplyButton then
        _dropdownApplyButton:RegisterPressCallback(function() OnDropdownApply() end)
    end
    
    -- Dropdown Header Events
    if _categoryHeader then
        _categoryHeader:RegisterPressCallback(function() ToggleDropdown("category") end)
    end
    if _priorityHeader then
        _priorityHeader:RegisterPressCallback(function() ToggleDropdown("priority") end)
    end
    
    -- Dropdown Modal Events
    if _dropdownModalCloseButton then
        _dropdownModalCloseButton:RegisterPressCallback(function() HideDropdownModal() end)
    end
    if _dropdownModalOverlay then
        _dropdownModalOverlay:RegisterPressCallback(function() HideDropdownModal() end)
    end
    
    
    -- Progress Panel Events
    if _progressCloseButton then
        _progressCloseButton:RegisterPressCallback(function() HidePanel() end)
    end
    if _progressCancelButton then
        _progressCancelButton:RegisterPressCallback(function() OnProgressCancel() end)
    end
    
    -- Notification Panel Events
    if _notificationCloseButton then
        _notificationCloseButton:RegisterPressCallback(function() HideNotification() end)
    end
end

-- Hide all panels
function HideAllPanels()
    if _confirmationPanel then _confirmationPanel.style.display = DisplayStyle.None end
    if _inputPanel then _inputPanel.style.display = DisplayStyle.None end
    if _switchesPanel then _switchesPanel.style.display = DisplayStyle.None end
    if _sliderPanel then _sliderPanel.style.display = DisplayStyle.None end
    if _dropdownPanel then _dropdownPanel.style.display = DisplayStyle.None end
    if _progressPanel then _progressPanel.style.display = DisplayStyle.None end
    if _notificationPanel then _notificationPanel.style.display = DisplayStyle.None end
    if _tooltipPanel then _tooltipPanel.style.display = DisplayStyle.None end
    
    currentPanel = nil
end

-- Show a specific panel
function ShowPanel(panelType, data)
    print("[UIPanels] Showing panel:", panelType)
    
    HideAllPanels()
    
    if panelType == PANEL_TYPES.CONFIRMATION then
        ShowConfirmationPanel(data)
    elseif panelType == PANEL_TYPES.INPUT then
        ShowInputPanel(data)
    elseif panelType == PANEL_TYPES.SWITCHES then
        ShowSwitchesPanel(data)
    elseif panelType == PANEL_TYPES.SLIDER then
        ShowSliderPanel(data)
    elseif panelType == PANEL_TYPES.DROPDOWN then
        ShowDropdownPanel(data)
    elseif panelType == PANEL_TYPES.PROGRESS then
        ShowProgressPanel(data)
    elseif panelType == PANEL_TYPES.NOTIFICATION then
        ShowNotificationPanel(data)
    end
    
    currentPanel = panelType
end

-- Hide the current panel
function HidePanel()
    print("[UIPanels] Hiding current panel")
    
    if currentPanel then
        -- Call hide callback if exists
        if panelCallbacks[currentPanel] and panelCallbacks[currentPanel].onHide then
            panelCallbacks[currentPanel].onHide()
        end
        
        HideAllPanels()
    end
end

-- Show Confirmation Panel
function ShowConfirmationPanel(data)
    if not _confirmationPanel then return end
    
    -- Set title and message
    if _confirmationTitle and data.title then
        _confirmationTitle.text = data.title
    end
    if _confirmationMessage and data.message then
        _confirmationMessage.text = data.message
    end
    
    -- Set button labels
    if data.cancelText and _confirmationCancelButton then
        local cancelLabel = _confirmationCancelButton:Q("Label")
        if cancelLabel then cancelLabel.text = data.cancelText end
    end
    if data.confirmText and _confirmationConfirmButton then
        local confirmLabel = _confirmationConfirmButton:Q("Label")
        if confirmLabel then confirmLabel.text = data.confirmText end
    end
    
    -- Store callback
    panelCallbacks[PANEL_TYPES.CONFIRMATION] = data
    
    _confirmationPanel.style.display = DisplayStyle.Flex
end

-- Show Input Panel
function ShowInputPanel(data)
    if not _inputPanel then return end
    
    -- Set title
    if _inputTitle and data.title then
        _inputTitle.text = data.title
    end
    
    -- Set labels
    if _inputLabel and data.label1 then
        _inputLabel.text = data.label1
    end
    if _inputLabel2 and data.label2 then
        _inputLabel2.text = data.label2
    end
    
    -- Placeholders are set in UXML
    
    -- Set initial values
    if _inputField and data.value1 then
        _inputField.value = data.value1
    end
    if _inputField2 and data.value2 then
        _inputField2.value = data.value2
    end
    
    -- Store callback
    panelCallbacks[PANEL_TYPES.INPUT] = data
    
    _inputPanel.style.display = DisplayStyle.Flex
end

-- Show Switches Panel
function ShowSwitchesPanel(data)
    if not _switchesPanel then return end
    
    -- Set title
    if _switchesTitle and data.title then
        _switchesTitle.text = data.title
    end
    
    -- Set initial switch states
    if data.switches then
        for i, switchData in ipairs(data.switches) do
            local switchKey = "switch" .. i
            local switchElement = nil
            
            if switchKey == "switch1" then
                switchElement = _switch1
            elseif switchKey == "switch2" then
                switchElement = _switch2
            elseif switchKey == "switch3" then
                switchElement = _switch3
            end
            
            if switchElement and switchData.checked ~= nil then
                switchElement.value = switchData.checked
                switchStates[switchKey] = switchData.checked
            end
        end
    end
    
    -- Store callback
    panelCallbacks[PANEL_TYPES.SWITCHES] = data
    
    _switchesPanel.style.display = DisplayStyle.Flex
end

-- Show Slider Panel
function ShowSliderPanel(data)
    if not _sliderPanel then return end
    
    -- Set title
    if _sliderTitle and data.title then
        _sliderTitle.text = data.title
    end
    
    -- Set initial slider values
    if data.sliders then
        for i, sliderData in ipairs(data.sliders) do
            local sliderKey = ({"volume", "brightness", "speed"})[i]
            if sliderData.value then
                sliderValues[sliderKey] = sliderData.value
                UpdateSliderValue(sliderKey, sliderData.value)
            end
        end
    end
    
    -- Store callback
    panelCallbacks[PANEL_TYPES.SLIDER] = data
    
    _sliderPanel.style.display = DisplayStyle.Flex
end

-- Show Dropdown Panel
function ShowDropdownPanel(data)
    if not _dropdownPanel then return end
    
    -- Set title
    if _dropdownTitle and data.title then
        _dropdownTitle.text = data.title
    end
    
    -- Store callback
    panelCallbacks[PANEL_TYPES.DROPDOWN] = data
    
    _dropdownPanel.style.display = DisplayStyle.Flex
end

-- Show Progress Panel
function ShowProgressPanel(data)
    if not _progressPanel then return end
    
    -- Set title and message
    if _progressTitle and data.title then
        _progressTitle.text = data.title
    end
    if _progressMessage and data.message then
        _progressMessage.text = data.message
    end
    
    -- Start progress simulation if autoProgress is true
    if data.autoProgress then
        StartProgressSimulation(data.duration or 3.0)
    end
    
    -- Store callback
    panelCallbacks[PANEL_TYPES.PROGRESS] = data
    
    _progressPanel.style.display = DisplayStyle.Flex
end

-- Show Notification Panel
function ShowNotificationPanel(data)
    if not _notificationPanel then return end
    
    -- Set notification type and icon
    local notificationType = data.type or NOTIFICATION_TYPES.INFO
    if _notificationIcon then
        _notificationIcon:ClearClassList()
        _notificationIcon:AddToClassList(notificationType)
    end
    
    -- Set title and message
    if _notificationTitle and data.title then
        _notificationTitle.text = data.title
    end
    if _notificationMessage and data.message then
        _notificationMessage.text = data.message
    end
    
    _notificationPanel.style.display = DisplayStyle.Flex
    
    -- Auto-hide after duration
    if data.duration and data.duration > 0 then
        if notificationTimer then
            notificationTimer:Stop()
        end
        notificationTimer = Timer.After(data.duration, function()
            HideNotification()
        end)
    end
end

-- Hide notification
function HideNotification()
    if _notificationPanel then
        _notificationPanel.style.display = DisplayStyle.None
    end
    if notificationTimer then
        notificationTimer:Stop()
        notificationTimer = nil
    end
end

-- Show tooltip
function ShowTooltip(text, position)
    if not _tooltipPanel or not _tooltipText then return end
    
    _tooltipText.text = text
    _tooltipPanel.style.display = DisplayStyle.Flex
    
    if position then
        _tooltipPanel.style.left = position.x
        _tooltipPanel.style.top = position.y
    end
end

-- Hide tooltip
function HideTooltip()
    if _tooltipPanel then
        _tooltipPanel.style.display = DisplayStyle.None
    end
end

-- Event Handlers
function OnConfirmationConfirm()
    if panelCallbacks[PANEL_TYPES.CONFIRMATION] and panelCallbacks[PANEL_TYPES.CONFIRMATION].onConfirm then
        panelCallbacks[PANEL_TYPES.CONFIRMATION].onConfirm()
    end
    HidePanel()
end

function OnInputSubmit()
    local inputData = {
        value1 = _inputField and _inputField.value or "",
        value2 = _inputField2 and _inputField2.value or ""
    }
    
    if panelCallbacks[PANEL_TYPES.INPUT] and panelCallbacks[PANEL_TYPES.INPUT].onSubmit then
        panelCallbacks[PANEL_TYPES.INPUT].onSubmit(inputData)
    end
    HidePanel()
end

function OnSwitchesSave()
    if panelCallbacks[PANEL_TYPES.SWITCHES] and panelCallbacks[PANEL_TYPES.SWITCHES].onSave then
        panelCallbacks[PANEL_TYPES.SWITCHES].onSave(switchStates)
    end
    HidePanel()
end

function OnSliderApply()
    if panelCallbacks[PANEL_TYPES.SLIDER] and panelCallbacks[PANEL_TYPES.SLIDER].onApply then
        panelCallbacks[PANEL_TYPES.SLIDER].onApply(sliderValues)
    end
    HidePanel()
end

function OnDropdownApply()
    if panelCallbacks[PANEL_TYPES.DROPDOWN] and panelCallbacks[PANEL_TYPES.DROPDOWN].onApply then
        panelCallbacks[PANEL_TYPES.DROPDOWN].onApply(dropdownSelections)
    end
    HidePanel()
end

function OnProgressCancel()
    if progressTimer then
        progressTimer:Stop()
        progressTimer = nil
    end
    
    if panelCallbacks[PANEL_TYPES.PROGRESS] and panelCallbacks[PANEL_TYPES.PROGRESS].onCancel then
        panelCallbacks[PANEL_TYPES.PROGRESS].onCancel()
    end
    HidePanel()
end

-- Handle switch change event
function HandleSwitchChange(switchKey, switchElement)
    local newValue = switchElement.value
    switchStates[switchKey] = newValue
    
    print("[UIPanels] Switch", switchKey, "changed to:", tostring(newValue))
end

-- Slider value changed
function OnSliderValueChanged(sliderKey, value)
    sliderValues[sliderKey] = value
    UpdateSliderValue(sliderKey, value)
end

-- Update slider value display
function UpdateSliderValue(sliderKey, value)
    local valueLabel = nil
    
    if sliderKey == "volume" then
        valueLabel = _volumeValue
    elseif sliderKey == "brightness" then
        valueLabel = _brightnessValue
    elseif sliderKey == "speed" then
        valueLabel = _speedValue
    end
    
    if valueLabel then
        valueLabel.text = tostring(math.floor(value))
    end
end

-- Toggle dropdown (show modal)
function ToggleDropdown(dropdownKey)
    if not _dropdownModalOverlay or not _dropdownOptionsList then return end
    
    -- Set modal title and label
    local title = ""
    local label = ""
    local options = {}
    
    if dropdownKey == "category" then
        title = "Select Category"
        label = "Choose a category:"
        options = {"General", "Advanced", "Premium"}
    elseif dropdownKey == "priority" then
        title = "Select Priority"
        label = "Choose a priority level:"
        options = {"Low", "Medium", "High"}
    end
    
    if _dropdownModalTitle then
        _dropdownModalTitle.text = title
    end
    if _dropdownModalLabel then
        _dropdownModalLabel.text = label
    end
    
    -- Clear existing options
    _dropdownOptionsList:Clear()
    
    -- Create option elements
    for i, option in ipairs(options) do
        local optionElement = VisualElement.new()
        optionElement:AddToClassList("dropdown-modal-option")
        optionElement:RegisterPressCallback(function() SelectDropdownOption(dropdownKey, option) end)
        
        local optionLabel = Label.new()
        optionLabel:AddToClassList("dropdown-modal-option-label")
        optionLabel.text = option
        optionElement:Add(optionLabel)
        
        _dropdownOptionsList:Add(optionElement)
    end
    
    -- Show the modal
    _dropdownModalOverlay.style.display = DisplayStyle.Flex
    currentOpenDropdown = dropdownKey
end

-- Select dropdown option
function SelectDropdownOption(dropdownKey, option)
    dropdownSelections[dropdownKey] = option
    
    local selectedLabel = nil
    
    if dropdownKey == "category" then
        selectedLabel = _categorySelected
    elseif dropdownKey == "priority" then
        selectedLabel = _prioritySelected
    end
    
    if selectedLabel then
        selectedLabel.text = option
    end
    
    -- Hide the dropdown modal
    HideDropdownModal()
    
    print("[UIPanels] Selected", dropdownKey, ":", option)
end

-- Hide dropdown modal
function HideDropdownModal()
    if _dropdownModalOverlay then
        _dropdownModalOverlay.style.display = DisplayStyle.None
    end
    currentOpenDropdown = nil
end

-- Start progress simulation
function StartProgressSimulation(duration)
    local startTime = Time.time
    local endTime = startTime + duration
    
    if progressTimer then
        progressTimer:Stop()
    end
    
    progressTimer = Timer.Every(0.1, function()
        local currentTime = Time.time
        local progress = math.min((currentTime - startTime) / duration, 1.0)
        local percentage = math.floor(progress * 100)
        
        if _progressFill then
            _progressFill.style.width = StyleLength.new(Length.Percent(percentage))
        end
        if _progressPercentage then
            _progressPercentage.text = tostring(percentage) .. "%"
        end
        if _progressStatus then
            if progress < 0.3 then
                _progressStatus.text = "Initializing..."
            elseif progress < 0.7 then
                _progressStatus.text = "Processing..."
            else
                _progressStatus.text = "Finalizing..."
            end
        end
        
        if progress >= 1.0 then
            if progressTimer then
                progressTimer:Stop()
                progressTimer = nil
            end
            
            if panelCallbacks[PANEL_TYPES.PROGRESS] and panelCallbacks[PANEL_TYPES.PROGRESS].onComplete then
                panelCallbacks[PANEL_TYPES.PROGRESS].onComplete()
            end
            
            Timer.After(0.5, function()
                HidePanel()
            end)
        end
    end)
end

-- Public API Methods
function ShowConfirmation(title, message, onConfirm, onCancel)
    ShowPanel(PANEL_TYPES.CONFIRMATION, {
        title = title,
        message = message,
        onConfirm = onConfirm,
        onCancel = onCancel
    })
end

function ShowInput(title, label1, placeholder1, label2, placeholder2, onSubmit, onCancel)
    ShowPanel(PANEL_TYPES.INPUT, {
        title = title,
        label1 = label1,
        placeholder1 = placeholder1,
        label2 = label2,
        placeholder2 = placeholder2,
        onSubmit = onSubmit,
        onCancel = onCancel
    })
end

function ShowSwitches(title, switches, onSave, onCancel)
    ShowPanel(PANEL_TYPES.SWITCHES, {
        title = title,
        switches = switches,
        onSave = onSave,
        onCancel = onCancel
    })
end

function ShowSliders(title, sliders, onApply, onCancel)
    ShowPanel(PANEL_TYPES.SLIDER, {
        title = title,
        sliders = sliders,
        onApply = onApply,
        onCancel = onCancel
    })
end

function ShowDropdowns(title, onApply, onCancel)
    ShowPanel(PANEL_TYPES.DROPDOWN, {
        title = title,
        onApply = onApply,
        onCancel = onCancel
    })
end

function ShowProgress(title, message, duration, onComplete, onCancel)
    ShowPanel(PANEL_TYPES.PROGRESS, {
        title = title,
        message = message,
        duration = duration,
        autoProgress = true,
        onComplete = onComplete,
        onCancel = onCancel
    })
end

function ShowNotification(type, title, message, duration)
    ShowNotificationPanel({
        type = type,
        title = title,
        message = message,
        duration = duration
    })
end

-- Cleanup
function self:OnDestroy()
    print("[UIPanels] Cleaning up UI Panels system")
    
    if progressTimer then
        progressTimer:Stop()
        progressTimer = nil
    end
    
    if notificationTimer then
        notificationTimer:Stop()
        notificationTimer = nil
    end
    
    panelCallbacks = {}
end