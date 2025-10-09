# Spectator System Documentation

## Overview
The spectator system allows players to watch the game without participating. Spectators can toggle their status on/off at any time during the lobby phase.

## Features
- ✅ Toggle spectator mode via button in lobby
- ✅ Automatic teleportation to Arena when becoming spectator
- ✅ Excluded from ready system (spectators cannot ready up)
- ✅ Excluded from role assignment (not assigned as Hunter or Prop)
- ✅ Automatic teleportation during phase transitions
- ✅ Can leave spectator mode and rejoin gameplay

## Architecture

### Network Synchronization
**PlayerManager** tracks spectator state:
- `isSpectator: BoolValue` - Per-player spectator state (network-synced)
- `spectatorPlayers: TableValue` - Global list of spectators (network-synced)

### Component Overview

#### 1. PropHuntPlayerManager.lua
**Location**: `Assets/PropHunt/Scripts/Modules/PropHuntPlayerManager.lua`

**Key Functions**:
```lua
-- Check if player is spectator
PlayerManager.IsPlayerSpectator(player : Player) : boolean

-- Get list of spectator players
PlayerManager.GetSpectatorPlayers() : table

-- Get spectator count
PlayerManager.GetSpectatorPlayerCount() : number

-- Toggle spectator state (server-side handler)
ToggleSpectatorRequest(player : Player) : boolean

-- Register callback for spectator toggle
RegisterSpectatorToggleCallback(callback : function)
```

**Network Events**:
```lua
SpectatorToggleRequest = Event.new("PH_SpectatorToggleRequest")
```

**Behavior**:
1. When player toggles spectator ON:
   - Sets `isSpectator.value = true`
   - Removes from ready list if they were ready
   - Adds to spectator list
   - Calls GameManager callback for teleportation

2. When player toggles spectator OFF:
   - Sets `isSpectator.value = false`
   - Removes from spectator list
   - Calls GameManager callback for teleportation

#### 2. PropHuntSpectatorButton.lua
**Location**: `Assets/PropHunt/Scripts/GUI/PropHuntSpectatorButton.lua`

**Type**: `--!Type(UI)`

**UI Elements**:
- `_button : VisualElement` - Clickable button
- `_label : Label` - Button text ("Become Spectator" / "Leave Spectator")

**Behavior**:
- Fires `SpectatorToggleRequest:FireServer()` when clicked
- Listens to `isSpectator.Changed` event for visual updates
- Changes button color:
  - Blue (0.4, 0.4, 0.8) when NOT spectator
  - Red (0.8, 0.4, 0.4) when IS spectator

#### 3. PropHuntGameManager.lua
**Location**: `Assets/PropHunt/Scripts/PropHuntGameManager.lua`

**Key Functions**:
```lua
-- Get all spectator players
GetSpectatorPlayers() : table

-- Handle spectator toggle (teleportation)
OnSpectatorToggled(player : Player, isNowSpectator : boolean)
```

**Integration Points**:

1. **ServerStart**:
   - Registers `OnSpectatorToggled` callback with PlayerManager

2. **AssignRoles** (line 426):
   - Filters out spectators before role assignment
   - Spectators are assigned "spectator" role (not hunter/prop)
   - Minimum player count excludes spectators

3. **TransitionToState - HIDING** (line 314):
   - Teleports props to arena
   - Teleports spectators to arena

4. **TransitionToState - LOBBY** (line 296):
   - Teleports ALL players (including spectators) to lobby

5. **OnSpectatorToggled** (line 729):
   - When spectator ON → Teleport to Arena immediately
   - When spectator OFF in LOBBY → Teleport to Lobby

## Teleportation Flow

### Scenario 1: Player Becomes Spectator in Lobby
```
Player clicks "Become Spectator" button
  ↓
PropHuntSpectatorButton fires SpectatorToggleRequest:FireServer()
  ↓
PlayerManager.ToggleSpectatorRequest(player) on server
  ↓
Sets isSpectator.value = true, updates spectator list
  ↓
Calls OnSpectatorToggleCallback(player, true)
  ↓
GameManager.OnSpectatorToggled(player, true)
  ↓
Teleporter.TeleportToArena(player)
  ↓
Player is now in Arena watching
```

### Scenario 2: Spectator Leaves Spectator Mode
```
Spectator clicks "Leave Spectator" button
  ↓
PropHuntSpectatorButton fires SpectatorToggleRequest:FireServer()
  ↓
PlayerManager.ToggleSpectatorRequest(player) on server
  ↓
Sets isSpectator.value = false, removes from spectator list
  ↓
Calls OnSpectatorToggleCallback(player, false)
  ↓
GameManager.OnSpectatorToggled(player, false)
  ↓
IF currentState == LOBBY:
    Teleporter.TeleportToLobby(player)
  ↓
Player can now ready up and play
```

### Scenario 3: Round Starts with Spectators
```
Round transition: LOBBY → HIDING
  ↓
GameManager.TransitionToState(GameState.HIDING)
  ↓
Teleport props to Arena
  ↓
Get spectator list via GetSpectatorPlayers()
  ↓
Teleporter.TeleportAllToArena(spectators)
  ↓
Spectators remain in Arena throughout round
```

### Scenario 4: Round Ends
```
Round transition: ROUND_END → LOBBY
  ↓
GameManager.TransitionToState(GameState.LOBBY)
  ↓
Teleporter.TeleportAllToLobby(GetActivePlayers())
  ↓
ALL players (including spectators) teleported to Lobby
  ↓
Spectators can toggle OFF to play next round
```

## Unity Setup

### Required UI Setup
1. Create UXML file: `PropHuntSpectatorButton.uxml`
2. Create USS file: `PropHuntSpectatorButton.uss` (optional)
3. Add UI elements:
   - Root `VisualElement` named `_button`
   - Child `Label` named `_label` with text "Become Spectator"

### Suggested UXML Structure
```xml
<?xml version="1.0" encoding="utf-8"?>
<UXML xmlns="UnityEngine.UIElements">
  <VisualElement name="_button" class="spectator-button">
    <Label name="_label" text="Become Spectator" />
  </VisualElement>
</UXML>
```

### Suggested USS Styling
```css
.spectator-button {
  width: 200px;
  height: 50px;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  border-width: 2px;
  transition-duration: 0.2s;
}

.spectator-button Label {
  font-size: 16px;
  color: white;
  -unity-text-align: middle-center;
}
```

## Testing Checklist

### Basic Functionality
- [ ] Button appears in lobby UI
- [ ] Clicking button toggles spectator state
- [ ] Button text changes ("Become Spectator" ↔ "Leave Spectator")
- [ ] Button color changes (blue ↔ red)

### Teleportation
- [ ] Becoming spectator teleports player to Arena
- [ ] Leaving spectator (in lobby) teleports player to Lobby
- [ ] Spectators teleport to Arena when round starts (HIDING phase)
- [ ] Spectators return to Lobby when round ends

### Ready System
- [ ] Spectators cannot ready up (ready button disabled/hidden)
- [ ] Becoming spectator removes ready status
- [ ] Leaving spectator allows readying up again

### Role Assignment
- [ ] Spectators are not assigned Hunter or Prop role
- [ ] Spectators are logged as "SPECTATOR" in console
- [ ] Minimum player count excludes spectators
- [ ] Example: 1 player + 1 spectator = "need 2 minimum" message

### Multi-Client Sync
- [ ] Other clients see spectator teleport to Arena
- [ ] Other clients see spectator return to Lobby
- [ ] Spectator count updates correctly on all clients

### Edge Cases
- [ ] Toggling spectator during countdown doesn't break countdown
- [ ] Disconnecting as spectator removes from spectator list
- [ ] Rejoining after disconnect resets spectator state

## Console Log Examples

### Spectator Toggle
```
[PlayerManager] Player became spectator: ErondielPC
[PropHunt Teleporter] Teleporting ErondielPC to Arena
SPECTATOR ON: ErondielPC teleported to Arena
```

### Role Assignment with Spectators
```
ROLES: 1 Hunters, 1 Props, 1 Spectators (total 3 players)
HUNTER: VirtualPlayer1
PROP: VirtualPlayer2
SPECTATOR: ErondielPC
```

### Round Start with Spectators
```
LOBBY->HIDING
HIDE 35s
[PropHunt Teleporter] Teleporting 1 players to Arena
Teleported 1 spectators to Arena
```

## Known Limitations (V1)

1. **No Spectator Camera**
   - Spectators use normal player camera
   - Cannot follow other players or switch views
   - Planned for V2

2. **No Spectator UI Indicators**
   - No visual indicator showing spectator status to other players
   - No spectator count in HUD
   - Planned for V2

3. **Spectator Toggle Only in Lobby**
   - Cannot become spectator mid-round
   - Can only toggle during LOBBY phase
   - This is intentional to prevent exploitation

## API Reference

### PlayerManager Public API
```lua
-- Get spectator state
IsPlayerSpectator(player : Player) : boolean

-- Get spectator list
GetSpectatorPlayers() : table

-- Get spectator count
GetSpectatorPlayerCount() : number

-- Register callback (called by GameManager)
RegisterSpectatorToggleCallback(callback : function)
```

### GameManager Public API
```lua
-- Get list of spectator players
GetSpectatorPlayers() : table
```

### Network Events (Client → Server)
```lua
-- Toggle spectator state
SpectatorToggleRequest:FireServer()
```

## File Summary

### Modified Files
1. `PropHuntPlayerManager.lua` - Added spectator state tracking
2. `PropHuntGameManager.lua` - Added spectator teleportation logic
3. `PropHuntSpectatorButton.lua` - Created new UI component

### Lines of Code Added
- PlayerManager: ~40 lines
- GameManager: ~35 lines
- SpectatorButton: ~39 lines
- **Total**: ~114 lines

## Future Enhancements (V2)

1. **Spectator Camera System**
   - Free-roam camera
   - Follow player camera
   - Cycle through players

2. **Spectator UI**
   - Spectator count indicator
   - Visual marker for spectators
   - Spectator list panel

3. **Mid-Round Spectator Toggle**
   - Allow joining as spectator mid-round
   - Eliminate player → auto-spectator option

4. **Spectator Chat**
   - Separate chat channel for spectators
   - Prevent spoiling hiding spots

## Troubleshooting

### Issue: Button not responding
**Solution**: Ensure `_button` and `_label` are properly bound in UXML with matching names

### Issue: Spectator not teleporting
**Solution**: Check that `LobbySpawn` and `ArenaSpawn` GameObjects are configured in PropHuntTeleporter

### Issue: Ready button still works for spectators
**Solution**: Update ready button logic to check `PlayerManager.IsPlayerSpectator(client.localPlayer)`

### Issue: Spectator counted in minimum players
**Solution**: Verify `AssignRoles()` filters out spectators before checking player count

## Credits
Implemented by Claude Code (claude.ai/code) as part of PropHunt V1 development.
