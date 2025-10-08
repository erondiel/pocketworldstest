# UI Panels Asset

A comprehensive UI system for Highrise Studio that provides reusable panel components for common UI interactions. This asset includes confirmation prompts, input fields, switches, sliders, dropdowns, progress indicators, and notifications.

## Features

- **Confirmation Prompts**: Yes/No dialogs with customizable messages
- **Input Fields**: Text input forms with multiple fields
- **Switches**: Toggle switches for settings and preferences
- **Sliders**: Range controls for numeric values
- **Dropdowns**: Selection menus with multiple options
- **Progress Indicators**: Loading bars with status updates
- **Notifications**: Toast-style messages with different types
- **Tooltips**: Contextual help text

## Architecture

### Core Components

- **`panels.uxml`**: UI structure with all panel definitions
- **`panels.uss`**: Styling following project design patterns
- **`panels.lua`**: Main controller handling panel logic and interactions

### Panel Types

1. **Confirmation Panel**: Simple yes/no dialogs
2. **Input Panel**: Multi-field text input forms
3. **Switches Panel**: Toggle controls for settings
4. **Slider Panel**: Range controls for numeric values
5. **Dropdown Panel**: Selection menus
6. **Progress Panel**: Loading indicators with status
7. **Notification Panel**: Toast-style messages

## Usage

### Basic Setup

1. **Add to Scene**: Attach the UI Panels to a GameObject in your scene
2. **Configure Output Mode**: Set to "Above Chat" or "HUD" for interactivity
3. **Access Script**: Reference the `panels.lua` script for API calls

### API Methods

#### Confirmation Dialog
```lua
-- Show a confirmation dialog
UIPanels.ShowConfirmation(
    "Delete Item", 
    "Are you sure you want to delete this item?",
    function() 
        print("User confirmed")
        -- Handle confirmation
    end,
    function() 
        print("User cancelled")
        -- Handle cancellation
    end
)
```

#### Input Form
```lua
-- Show an input form
UIPanels.ShowInput(
    "Create Item",
    "Name:",
    "Enter item name...",
    "Description:",
    "Enter description...",
    function(inputData)
        print("Name:", inputData.value1)
        print("Description:", inputData.value2)
        -- Handle form submission
    end,
    function()
        print("Form cancelled")
        -- Handle cancellation
    end
)
```

#### Settings Switches
```lua
-- Show switches panel
UIPanels.ShowSwitches(
    "Game Settings",
    {
        {label = "Enable Sound", checked = true},
        {label = "Show Notifications", checked = false},
        {label = "Auto Save", checked = true}
    },
    function(switchStates)
        print("Sound enabled:", switchStates.switch1)
        print("Notifications:", switchStates.switch2)
        print("Auto Save:", switchStates.switch3)
        -- Handle settings save
    end,
    function()
        print("Settings cancelled")
        -- Handle cancellation
    end
)
```

#### Slider Controls
```lua
-- Show sliders panel
UIPanels.ShowSliders(
    "Adjust Settings",
    {
        {label = "Volume", value = 50, min = 0, max = 100},
        {label = "Brightness", value = 75, min = 0, max = 100},
        {label = "Speed", value = 5, min = 1, max = 10}
    },
    function(sliderValues)
        print("Volume:", sliderValues.volume)
        print("Brightness:", sliderValues.brightness)
        print("Speed:", sliderValues.speed)
        -- Handle slider values
    end,
    function()
        print("Sliders cancelled")
        -- Handle cancellation
    end
)
```

#### Dropdown Selection
```lua
-- Show dropdowns panel
UIPanels.ShowDropdowns(
    "Select Options",
    function(selections)
        print("Category:", selections.category)
        print("Priority:", selections.priority)
        -- Handle selections
    end,
    function()
        print("Dropdowns cancelled")
        -- Handle cancellation
    end
)
```

#### Progress Indicator
```lua
-- Show progress panel
UIPanels.ShowProgress(
    "Processing",
    "Please wait while we process your request...",
    3.0, -- Duration in seconds
    function()
        print("Progress completed")
        -- Handle completion
    end,
    function()
        print("Progress cancelled")
        -- Handle cancellation
    end
)
```

#### Notifications
```lua
-- Show different types of notifications
UIPanels.ShowNotification("success", "Success!", "Operation completed successfully", 3.0)
UIPanels.ShowNotification("warning", "Warning!", "Please check your input", 4.0)
UIPanels.ShowNotification("error", "Error!", "Something went wrong", 5.0)
UIPanels.ShowNotification("info", "Info", "Here's some information", 3.0)
```

### Advanced Usage

#### Custom Panel Data
```lua
-- Show panel with custom data
UIPanels.ShowPanel("confirmation", {
    title = "Custom Title",
    message = "Custom message with {{$1}} placeholder",
    confirmText = "Yes, Delete",
    cancelText = "No, Keep",
    onConfirm = function()
        -- Custom confirm logic
    end,
    onCancel = function()
        -- Custom cancel logic
    end
})
```

#### Tooltip System
```lua
-- Show tooltip at specific position
UIPanels.ShowTooltip("This is a helpful tooltip", {x = 100, y = 200})

-- Hide tooltip
UIPanels.HideTooltip()
```

## Styling

The UI Panels use a consistent design system that matches your project's existing UI patterns:

### Color Variables
- `--color-white`: Primary text color
- `--color-white-dark`: Panel background
- `--color-black`: Dark backgrounds
- `--button-primary`: Primary action buttons
- `--button-secondary`: Secondary action buttons
- `--button-danger`: Destructive actions
- `--toggle-on`: Active toggle state
- `--toggle-off`: Inactive toggle state

### Responsive Design
- Panels adapt to different screen sizes
- Mobile-friendly button layouts
- Flexible content areas

## Customization

### Adding New Panel Types

1. **Add UXML Structure**: Define the panel in `panels.uxml`
2. **Add USS Styles**: Style the panel in `panels.uss`
3. **Add Lua Logic**: Implement panel logic in `panels.lua`
4. **Add API Method**: Create public method for easy access

### Modifying Existing Panels

1. **Update UXML**: Modify the panel structure
2. **Update USS**: Adjust styling and layout
3. **Update Lua**: Modify behavior and callbacks

## Best Practices

### Performance
- Panels are hidden by default to avoid rendering overhead
- Use timers efficiently for progress and notifications
- Clean up callbacks and timers in `OnDestroy()`

### User Experience
- Provide clear, descriptive titles and messages
- Use appropriate button labels (e.g., "Delete" vs "Remove")
- Show loading states for long operations
- Provide feedback for user actions

### Code Organization
- Use descriptive callback function names
- Handle all user interactions (confirm, cancel, close)
- Validate input data before processing
- Log important user actions for debugging

## Integration Examples

### Inventory System
```lua
-- Delete item confirmation
function DeleteItem(itemId)
    UIPanels.ShowConfirmation(
        "Delete Item",
        "Are you sure you want to delete this item? This action cannot be undone.",
        function()
            -- Server call to delete item
            DeleteItemFromInventory(itemId)
        end
    )
end
```

### Settings Menu
```lua
-- Open settings panel
function OpenSettings()
    UIPanels.ShowSwitches(
        "Game Settings",
        {
            {label = "Enable Sound", checked = GetSoundEnabled()},
            {label = "Show Chat", checked = GetChatEnabled()},
            {label = "Auto Save", checked = GetAutoSaveEnabled()}
        },
        function(settings)
            SetSoundEnabled(settings.switch1)
            SetChatEnabled(settings.switch2)
            SetAutoSaveEnabled(settings.switch3)
            SaveSettings()
        end
    )
end
```

### Form Validation
```lua
-- Create new item with validation
function CreateNewItem()
    UIPanels.ShowInput(
        "Create New Item",
        "Item Name:",
        "Enter item name...",
        "Description:",
        "Enter item description...",
        function(inputData)
            if inputData.value1 == "" then
                UIPanels:ShowNotification("error", "Error", "Item name is required", 3.0)
                return
            end
            
            if inputData.value2 == "" then
                UIPanels:ShowNotification("error", "Error", "Item description is required", 3.0)
                return
            end
            
            -- Create item
            CreateItem(inputData.value1, inputData.value2)
            UIPanels:ShowNotification("success", "Success", "Item created successfully", 3.0)
        end
    )
end
```

## Troubleshooting

### Common Issues

1. **Panel not showing**: Check that the UI GameObject is active and output mode is set correctly
2. **Buttons not working**: Ensure the UI output mode allows input (Above Chat or HUD)
3. **Styling issues**: Verify USS file is properly linked and variables are defined
4. **Callbacks not firing**: Check that callback functions are properly defined

### Debug Tips

- Use `print()` statements in callbacks to verify they're being called
- Check Unity Console for any binding errors
- Use UI Toolkit Debugger to inspect panel hierarchy
- Verify all `--!Bind` elements are properly connected

## File Structure

```
Assets/UI Panels/
├── UI/
│   ├── panels.uxml          # UI structure
    ├── panels.lua           # Main controller
│   └── panels.uss           # Styling
│
└── README.md                # This documentation
```
