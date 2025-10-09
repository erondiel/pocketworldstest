# Range Indicator System

A visual indicator system that creates a pulsing circular area around a player or specified object, useful for showing interaction ranges, ability areas, or detection zones in your game.

## Features

- **Visual Range Indicator**: Creates a circular indicator that follows the player or specified object
- **Breathing Animation**: Smooth pulsing animation to make the indicator more noticeable
- **Configurable Parameters**: Adjustable size, timing, and animation settings
- **Automatic Cleanup**: Automatically removes the indicator after a set time
- **Flexible Deployment**: Can be attached to the script's GameObject or default to the local player

## Configuration

### Basic Settings
- **Range Indicator Prefab**: The visual prefab to use for the indicator (required)
- **Radius**: Size of the indicator circle (range: 0-100, default: 4)
- **Hide After Time**: How long before the indicator automatically disappears (default: 10 seconds)
- **Animation Speed**: Speed of the pulsing animation (default: 1)
- **Deploy To Assigned Object**: Toggle to deploy the indicator to this GameObject instead of the player (default: false)

### Testing/Demo Settings
- **Test Demo**: Enable/disable automatic testing mode (default: true)
- **Test Demo Spawn After Time**: Delay before spawning the test indicator (default: 5 seconds)

## Usage

1. **Setup**:
   - Drag and drop the "RangeIndicatorManager" prefab in your scene
   - Assign your range indicator prefab in the Unity Inspector
   - Enable "Deploy To Assigned Object" if you want the indicator to follow this GameObject instead of the player

2. **Manual Spawning**:
   ```lua
   -- Spawn on local player (when DeployToAssignedObject is false)
   DeployRangeIndicator()
   
   -- Spawn on this GameObject (when DeployToAssignedObject is true)
   DeployRangeIndicator(true)
   ```

3. **Manual Removal**:
   ```lua
   DestroyRangeIndicator(_RangeIndicatorInstance) -- Call this to remove the indicator
   ```

## Behavior

- The indicator follows either this GameObject (when enabled) or the player's position
- Creates a smooth "breathing" animation effect by scaling the indicator up and down
- Maintains a constant height while scaling horizontally
- Automatically cleans up after the specified time
- Can be manually triggered or set to automatically spawn in test mode

## Technical Details

- Uses a tweening system for smooth animations
- Implements a parent-child relationship with the target object for automatic following
- Handles cleanup of both the visual indicator and animation tweens
- Includes safety checks for object existence
- Provides distance calculation functionality through `CalculateDistanceToTarget`

## Notes

- The test demo mode is intended for development and should be disabled in production
- The breathing animation uses an easeInOutSine curve for smooth transitions
- The indicator scales between 100% and 120% of the specified radius during animation
- If "Deploy To Assigned Object" is disabled, the system defaults to using the local player
- The indicator will automatically clean up its animations when destroyed
- You must have the TweenModule to enable the breathing animation