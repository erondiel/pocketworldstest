# Triggerable Object

A component that enables/disables a mesh renderer when triggered by a player character. It can be used to create interactive objects that appear or disappear when players interact with them.

## Features

- Toggle mesh visibility on trigger enter/exit
- Optional sound effects on activation
- Local or synchronized behavior across clients
- NavMesh obstacle support for pathfinding

## Configuration

### Basic Settings

- **Synchronize** (`_Syncronize`): If enabled, the mesh state will be synchronized across all clients. If disabled, only the local player will see the changes.
- **Hide On Start** (`_HideOnStart`): If enabled, the mesh will be hidden by default and shown when triggered. If disabled, the mesh will be visible by default and hidden when triggered.

### Sound Settings

- **Play Sound Effect** (`_PlaySoundEffect`): Enable/disable sound effects when the trigger is activated
- **Sound Effect** (`_SoundEffect`): The audio clip to play when triggered
- **Volume** (`_Volume`): Volume level of the sound effect (0-1)

## Usage

1. Attach this script to any GameObject with a MeshRenderer component
2. Configure the trigger settings in the Unity Inspector
3. Add a collider set to "Is Trigger" to the GameObject
4. Change the layer of the object to "CharacterTrigger"
5. The mesh will toggle visibility when a player character enters/exits the trigger area

## Behavior

- When a player enters the trigger area:
  - The mesh visibility toggles based on `HideOnStart` setting
  - If enabled, plays the configured sound effect
  - If `HideOnStart` is false, disables the NavMeshObstacle

- When a player exits the trigger area:
  - The mesh visibility toggles back to its original state
  - If `HideOnStart` is false, re-enables the NavMeshObstacle

## Requirements

- A GameObject with a MeshRenderer component
- A collider component set to "Is Trigger"
- Object layer set to "CharacterTrigger"
- (Optional) A NavMeshObstacle component if using pathfinding features
- (Optional) An AudioClip if using sound effects

