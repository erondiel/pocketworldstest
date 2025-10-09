# WorldConfig Asset

A comprehensive world configuration system for Highrise Studio that allows world creators to manage and customize various world settings through an intuitive UI interface.

## Features

- **Dynamic UI Generation**: Automatically creates UI elements based on configuration definitions
- **Modal-Based Input**: Clean modal dialogs for text input and dropdown selections
- **Real-time Updates**: Instant UI updates when settings are modified
- **Reset to Defaults**: One-click reset functionality with confirmation modal
- **Loading States**: Visual feedback during operations
- **Modular Design**: Easy to extend with new setting types and configurations

## Architecture

### Core Components

- **`world_config_config.lua`**: Configuration definitions, default values, and UI metadata
- **`worldconfig.lua`**: Main UI controller handling dynamic generation and user interactions
- **`worldconfig.uxml`**: UI structure with modal overlays for input dialogs
- **`worldconfig.uss`**: Styling for all UI components including modals and responsive design

### Setting Types Supported

- **Text**: String values with modal input dialog
- **Toggle**: Boolean switches with visual feedback
- **Slider**: Numeric ranges with min/max constraints
- **Dropdown**: Predefined options with modal selection
- **Label**: Read-only display values

## Usage

### Basic Setup

1. **Add to Scene**: Attach the WorldConfig UI to a GameObject in your scene
2. **Configure Settings**: Modify `world_config_config.lua` to define your world's settings
3. **Customize UI**: Update the USS file to match your world's visual theme

### Adding New Settings

1. **Define in Config**: Add your setting to `_DefaultConfig` in `world_config_config.lua`
2. **Add UI Metadata**: Include the setting in `_UIConfig` with type, label, and options
3. **Update Sections**: Add the setting to the appropriate section in `GetSettingsBySection()`

Example:
```lua
-- In _DefaultConfig
["custom_setting"] = "default_value"

-- In _UIConfig
["custom_setting"] = {
    type = "text",
    label = "Custom Setting",
    section = "Custom Settings"
}
```

## Server Integration

### Backend Implementation

To make this asset fully functional, you'll need to implement server-side functionality:

1. **Storage Integration**: Use Highrise Storage API to persist configuration
2. **Event Handling**: Implement server-side event handlers for configuration changes
3. **Validation**: Add server-side validation for setting values
4. **Permissions**: Implement access control for who can modify settings

### Recommended Server Structure

```lua
-- Server-side manager
local WorldConfigManager = require("world_config_manager")

-- Handle configuration requests
Events.GetConfig:Connect(function(player, data)
    local config = WorldConfigManager.GetConfig()
    Events.SendConfig:FireClient(player, config)
end)

-- Handle configuration updates
Events.UpdateConfig:Connect(function(player, data)
    if WorldConfigManager.ValidatePlayer(player) then
        WorldConfigManager.UpdateConfig(data)
        Events.ConfigUpdated:FireAllClients(WorldConfigManager.GetConfig())
    end
end)
```

### Storage Keys

- **Configuration**: `{world_id}/WorldConfig`
- **Player Permissions**: `{world_id}/WorldConfig/Permissions/{player_id}`

## UI Customization

### Styling

The UI uses a modular CSS approach with the following key classes:

- **`.worldconfig`**: Main container styling
- **`.setting-item`**: Individual setting containers
- **`.modal-overlay`**: Modal backdrop and positioning
- **`.button-container`**: Action button styling

### Responsive Design

The UI automatically adapts to different screen sizes and supports:
- Flexible layouts with CSS Grid/Flexbox
- Modal dialogs that center properly
- Scrollable content areas
- Touch-friendly button sizes

## Configuration Sections

### World Information
- World Name
- World Description
- Maximum Players
- World Theme

### Gameplay Settings
- PvP Enable/Disable
- Voice Chat Settings
- Text Chat Settings
- Spawn Protection Time

### Economy Settings
- Starting Currency
- Currency Name
- Trading Enable/Disable
- Tax Rate

### Environment Settings
- Time of Day
- Weather System
- Gravity Strength
- Day/Night Cycle

### Custom Settings
- Extensible section for world-specific configurations

## Events

### Client-Server Communication

The asset is designed to work with a custom event system:

- **`GetConfig`**: Request current configuration from server
- **`UpdateConfig`**: Send configuration changes to server
- **`ConfigUpdated`**: Server broadcasts configuration updates to all clients
- **`ResetConfig`**: Request configuration reset to defaults

## Security Considerations

- **Server Validation**: All configuration changes should be validated server-side
- **Permission System**: Implement role-based access control
- **Rate Limiting**: Prevent spam configuration updates
- **Input Sanitization**: Validate all user inputs before processing

## Performance

- **Efficient Updates**: Only updates changed UI elements
- **Lazy Loading**: UI elements are created on-demand
- **Memory Management**: Proper cleanup of event listeners and UI elements
- **Optimized Rendering**: Uses UI Toolkit's efficient rendering system

### Debug Mode

Enable debug logging by setting `_EnableLogging = true` in the config file.

## Future Enhancements

- **Real-time Collaboration**: Multiple users editing configuration simultaneously
- **Configuration Profiles**: Save and load different configuration sets
- **Import/Export**: Configuration backup and sharing functionality
- **Advanced Validation**: Complex validation rules and constraints
- **Audit Logging**: Track all configuration changes with timestamps
