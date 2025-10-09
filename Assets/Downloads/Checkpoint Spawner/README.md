# CheckPoint Spawner

A Highrise Studio asset for creating and managing checkpoint systems in your games. This asset allows players to progress through levels with automatic position saving and respawning at the last reached checkpoint.

## Features

- **Persistent Checkpoint System**: Automatically saves player progress using Storage
- **Client-Server Architecture**: Follows security model with proper client-server separation
- **Visual Feedback**: Optional audio, particles, and UI notifications when reaching checkpoints
- **Easy Setup**: Simple drag-and-drop prefab with customizable settings
- **Progressive Checkpoints**: Players can only move forward through checkpoints, not backward
- **Auto-Disable Previous**: Option to automatically disable previous checkpoints once reached

## Installation

1. Import the CheckPoint Spawner asset into your project
2. Drag and drop the `CheckPoints` prefab from `Assets/CheckPoint Spawner/Prefabs/` into your scene
3. Position the checkpoint triggers where you want them in your level
4. Configure the settings in the CheckPointsManager component

## Configuration

The main `CheckPoints` prefab contains the following components:

### CheckPointsManager

This is the main controller script with the following settings:

- **Disable CheckPoints On Reach**: Automatically disables previous checkpoints when a new one is reached
- **Play Audio On Change**: Plays a sound when a checkpoint is reached
- **Audio Clip**: The audio shader to play
- **Display Popup On Change**: Shows a UI notification when a checkpoint is reached
- **Check Points**: List of checkpoint GameObjects in sequential order
- **Default CheckPoint ID**: The starting checkpoint ID (usually 1)
- **Play Particles On Spawn**: Shows particles when a player spawns at a checkpoint
- **Particles On Spawn**: The particle effect prefab
- **Particles On Spawn Duration**: How long particles should display
- **Storage Key**: The key used to save checkpoint progress in player storage

## Creating New Checkpoints

To add a new checkpoint to your system:

1. Create a new GameObject as a child of the `CheckPoints` parent object
2. Name it with a sequential ID (e.g., `CheckPoint6`)
3. Add a BoxCollider component and set it as a Trigger
4. Change the object layer to `CharacterTrigger`
5. Add the `CheckPointDetector` script component
6. **Important**: Set the `_CheckPointID` to a unique sequential number
7. Add the GameObject to the `_CheckPoints` list in the CheckPointsManager

## How It Works

1. When a player enters a checkpoint trigger, the `CheckPointDetector` script fires an event
2. The server validates the checkpoint request and updates the player's saved progress
3. When a player joins the game, they spawn at their last saved checkpoint
4. Optional visual and audio feedback plays when checkpoints are reached

## Client-Server Architecture

This asset follows proper Highrise security practices:

- **Client**: Detects when player enters checkpoint triggers and requests checkpoint updates
- **Server**: Validates checkpoint requests, stores progress, and manages spawning

## Example Usage

```lua
-- To manually set a player's checkpoint from another script:
local CheckPointManager = require("CheckPointsManager")
CheckPointManager.SetNewCheckPoint(3) -- Set to checkpoint ID 3
```

## Customization

### UI Popup

You can customize the checkpoint notification by modifying:
- `CheckPointPopupUI.uxml` - Structure
- `CheckPointPopupUI.uss` - Styling
- `CheckPointPopupUI.lua` - Behavior

### Audio

Replace the default audio shader in the `_AudioClip` field of the CheckPointsManager.

### Particles

Replace the default particle effect in the `_ParticlesOnSpawn` field of the CheckPointsManager.

## Troubleshooting

- **Checkpoints not saving**: Make sure the Storage system is properly initialized
- **Players not spawning at checkpoints**: Verify the `_CheckPointID` values are sequential and unique
- **Visual effects not showing**: Check that the audio shader and particle prefabs are properly assigned

## Notes

- All checkpoint GameObjects should be on a layer that can trigger with the player character
- The checkpoint system uses Highrise Storage to persist player progress between sessions
- For multiplayer games, each player's progress is tracked independently
