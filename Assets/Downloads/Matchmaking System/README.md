# Matchmaking System

A complete multiplayer matchmaking and game session management system for Highrise Studio. This asset provides a ready-to-use solution for creating multiplayer games with lobby functionality, round-based gameplay, and player management.

## Features

- **Player Lobby System**: Players can join and ready up before games start
- **Round-Based Gameplay**: Configurable rounds with automatic progression
- **Real-time HUD**: Live updates showing game state, player count, and timers
- **Mid-game Joining**: Optional support for players joining during active rounds
- **Network Synchronization**: Full client-server architecture with proper state management
- **Customizable Configuration**: Easy-to-modify settings for different game types

## Installation

1. Drag and drop the `Matchmaking.prefab` into your scene hierarchy
2. Adjust the settings in the Inspector to match your game requirements

## Configuration Options

### Core Settings
- **Enable Debug**: Toggle debug logging for development
- **Min Players To Start**: Minimum number of ready players required to begin a game
- **Starting Time**: Countdown duration before each round starts (in seconds)
- **Round Time**: Duration of each gameplay round (in seconds)
- **Max Rounds**: Total number of rounds before the game resets
- **HUD Update Interval**: How frequently the UI updates (in seconds)
- **Allow Mid Game Join**: Whether players can join during active rounds

## Game States

The system operates in three main states:

1. **Waiting**: Players can join and ready up
2. **Starting**: Countdown before round begins
3. **In Progress**: Active gameplay round

## UI Components

### HUD Display
- Shows current game state
- Displays player count and ready status
- Shows countdown timers
- Indicates current round progress

### Join Button
- Allows players to ready up
- Automatically disables when player is ready
- Respects mid-game join settings

## Architecture

### Scripts Overview

#### Core Modules
- **mkConfig**: Centralized configuration management
- **mkEvents**: Event system for client-server communication
- **mkGameState**: Game state and timing management
- **mkMatchmakingManager**: Player tracking and game flow control
- **mkUIManager**: UI updates and timer management

#### UI Scripts
- **mkhud**: HUD display logic and text updates
- **mkjoinbutton**: Ready button functionality

### Network Architecture
- **Server Authority**: All game logic runs server-side
- **Client UI**: UI updates and player input handling
- **Network Values**: Synchronized state using Highrise's Network Values
- **Event Communication**: Client-server communication via Events

## Customization

### Adding Game Logic
To add custom gameplay logic:

1. **Extend mkMatchmakingManager**: Add your game logic in the `StartGame()` function
2. **Use Game State Events**: Listen to state changes to trigger custom behavior
3. **Player Tracking**: Use `GetPlayerInfo()` to access individual player data

### UI Customization
- Modify the UXML files for layout changes
- Update USS files for styling
- Extend Lua scripts for additional UI functionality

### Configuration
- Adjust settings in the Inspector for different game types
- Modify `mkConfig.lua` for programmatic configuration
- Use debug mode during development

## Best Practices

1. **Test with Multiple Players**: Always test with multiple clients to ensure proper synchronization
2. **Use Debug Mode**: Enable debug logging during development to track system behavior
3. **Validate Settings**: Ensure your configuration values make sense for your game type
4. **Handle Edge Cases**: Consider what happens when players disconnect during gameplay

## Troubleshooting

### Common Issues
- **Players not joining**: Check if the prefab is properly placed in the scene
- **UI not updating**: Verify that the HUD and Join Button references are set in the Inspector
- **Game not starting**: Ensure minimum player count is met and players are ready
- **Network issues**: Check that all scripts have proper type declarations

### Debug Information
Enable debug mode to see detailed logs about:
- Player join/disconnect events
- Game state changes
- Round progression
- Player ready status

## API Reference

### Key Functions
- `MatchmakingManager.GetReadyPlayerCount()`: Get current ready player count
- `GameState.GetGameState()`: Get current game state
- `GameState.GetCurrentRound()`: Get current round number
- `Config.GetMinPlayersToStart()`: Get minimum players required

### Events
- `ReadyUpRequest`: Fired when player clicks ready button
- `PlayerIsReady`: Broadcast when player becomes ready

## Support

For issues or questions about this asset, refer to Discord **studio-help** or mention @iHsein