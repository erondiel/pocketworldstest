# UI Visibility & Mid-Game Join Update

## Summary
Updated UI buttons to only show during LOBBY phase and implemented automatic teleportation for players who join mid-game.

## Changes Made

### 1. UI Button Visibility Control

Both **Ready Button** and **Spectator Toggle** now hide during active gameplay.

#### Visibility Rules:
- **LOBBY**: Buttons visible and clickable
- **HIDING**: Buttons hidden
- **HUNTING**: Buttons hidden
- **ROUND_END**: Buttons hidden

#### Implementation:

**PropHuntReadyButton.lua**:
```lua
local function UpdateButtonVisibility(currentState)
    if currentState == GameManager.GameState.LOBBY then
        rootElement.style.display = DisplayStyle.Flex  -- Show
    else
        rootElement.style.display = DisplayStyle.None  -- Hide
    end
end

-- Listen to game state changes
currentStateValue.Changed:Connect(function(newState, oldState)
    UpdateButtonVisibility(newState)
end)
```

**PropHuntSpectatorButton.lua**:
```lua
local function UpdateButtonVisibility(currentState)
    if currentState == GameManager.GameState.LOBBY then
        rootElement.style.display = DisplayStyle.Flex  -- Show
    else
        rootElement.style.display = DisplayStyle.None  -- Hide
    end
end

-- Listen to game state changes
currentStateValue.Changed:Connect(function(newState, oldState)
    UpdateButtonVisibility(newState)
end)
```

### 2. Mid-Game Join Handling

Players who join during an active game are automatically teleported to the Arena.

#### Behavior:

**Join During LOBBY**:
- Player spawns at default spawn location (Lobby area)
- UI buttons are visible
- Player can ready up or become spectator

**Join During HIDING/HUNTING/ROUND_END**:
- Player spawns at default spawn location
- **Automatically teleported to Arena after 0.5s**
- UI buttons are hidden (can't ready/spectator)
- Player watches ongoing game as observer
- Can join next round when game returns to LOBBY

#### Implementation:

**PropHuntGameManager.lua** - OnPlayerJoinedScene:
```lua
function OnPlayerJoinedScene(sceneObj, player)
    activePlayers[player.id] = player
    UpdatePlayerCount()
    Log(string.format("JOIN %s (%d)", player.name, count))

    -- If game is in progress (not lobby), teleport new player to Arena
    if currentState.value ~= GameState.LOBBY then
        Log(string.format("MID-GAME JOIN: %s teleporting to Arena", player.name))

        -- Small delay to ensure player is fully spawned
        Timer.After(0.5, function()
            Teleporter.TeleportToArena(player)
            Log(string.format("Mid-game player %s teleported to Arena", player.name))
        end)
    end
end
```

## User Experience

### Scenario 1: Normal Join (During Lobby)
```
Player joins world
  ↓
Spawns in Lobby
  ↓
Sees Ready button (center) and Spectator toggle (bottom-right)
  ↓
Can click Ready to participate or Spectator to watch
  ↓
Game starts when enough players ready
```

### Scenario 2: Mid-Game Join (During Active Round)
```
Player joins world during HIDING/HUNTING/ROUND_END
  ↓
Spawns in Lobby (default spawn)
  ↓
After 0.5s: Automatically teleported to Arena
  ↓
UI buttons are hidden (no Ready/Spectator buttons)
  ↓
Watches ongoing game from Arena
  ↓
When round ends: Teleported back to Lobby with everyone
  ↓
UI buttons reappear
  ↓
Can ready up for next round
```

### Scenario 3: State Transitions
```
LOBBY → HIDING transition
  ↓
Ready button hides
Spectator toggle hides
  ↓
Game in progress (HIDING/HUNTING)
  ↓
ROUND_END → LOBBY transition
  ↓
Ready button shows again
Spectator toggle shows again
```

## Technical Details

### Network Sync
Both UI scripts listen to the same NetworkValue:
```lua
local currentStateValue = NumberValue.new("PH_CurrentState", GameManager.GameState.LOBBY)
```

This ensures UI visibility syncs automatically when game state changes.

### Element Hierarchy
- **Ready Button**: `rootElement = _button.parent`
- **Spectator Toggle**: `rootElement = _toggle.parent.parent`

The root element is hidden/shown rather than the button itself, ensuring the entire container is affected.

### Teleport Delay Rationale
The 0.5s delay before mid-game teleport ensures:
1. Player character is fully spawned
2. Network sync is established
3. Teleportation command won't be lost
4. Camera is ready to follow

## Console Log Examples

### Mid-Game Join
```
[PropHunt] JOIN ErondielPC (3)
[PropHunt] MID-GAME JOIN: ErondielPC teleporting to Arena
[PropHunt Teleporter] Teleporting ErondielPC to Arena
[PropHunt] Mid-game player ErondielPC teleported to Arena
```

### State Change UI Update
```
[PropHuntReadyButton] Started
[PropHuntSpectatorButton] Started
[PropHunt] LOBBY->HIDING
[PropHuntReadyButton] Button hidden (state: 2)
[PropHuntSpectatorButton] Toggle hidden (state: 2)
```

## Files Modified

1. **PropHuntReadyButton.lua**
   - Added GameManager require
   - Added UpdateButtonVisibility function
   - Listen to currentState changes
   - Show/hide based on game state

2. **PropHuntSpectatorButton.lua**
   - Added GameManager require
   - Added UpdateButtonVisibility function
   - Listen to currentState changes
   - Show/hide based on game state

3. **PropHuntGameManager.lua** - OnPlayerJoinedScene
   - Check if game is in progress
   - Teleport mid-game joins to Arena after 0.5s delay

## Edge Cases Handled

### 1. Rapid State Changes
UI updates instantly when state changes - no desync.

### 2. Player Joins Right Before Round Start
If player joins 0.1s before LOBBY → HIDING:
- They see buttons briefly
- Buttons hide when HIDING starts
- If they clicked Ready just before transition, ready state persists

### 3. Player Joins During Round End
- Player teleports to Arena
- Sees round results (if recap screen is shown)
- Teleports back to Lobby when ROUND_END → LOBBY
- Buttons reappear

### 4. Spectator Mid-Game Join
- If player was spectator before disconnect
- Rejoins mid-game
- Spectator state may reset (new session)
- Auto-teleports to Arena anyway
- Can toggle spectator in next lobby

## Alternative Approach (Not Implemented)

### Custom Spawn Point
Unity supports defining spawn points via `SpawnLocation` component, but:
- Requires setting up separate spawn locations in Unity
- Doesn't support dynamic spawn based on game state
- Would need two spawn points: LobbySpawn (default) + ArenaSpawn (mid-game)
- Lua teleport approach is more flexible and explicit

Current teleport approach is preferred because:
✅ Works with single default spawn
✅ Explicit control over spawn location
✅ No Unity scene setup required
✅ Can log and debug easily
✅ Consistent with existing teleport system

## Testing Checklist

- [ ] Ready button visible in LOBBY
- [ ] Ready button hidden during HIDING
- [ ] Ready button hidden during HUNTING
- [ ] Ready button hidden during ROUND_END
- [ ] Ready button reappears when returning to LOBBY
- [ ] Spectator toggle visible in LOBBY
- [ ] Spectator toggle hidden during game phases
- [ ] Spectator toggle reappears in LOBBY
- [ ] Player joins mid-HIDING → teleports to Arena
- [ ] Player joins mid-HUNTING → teleports to Arena
- [ ] Player joins during LOBBY → stays in Lobby
- [ ] Mid-game join player can ready up in next lobby
- [ ] No errors when multiple players join mid-game

## Future Enhancements

1. **Mid-Game Join Notification**
   - Show message to mid-game joiner: "Game in progress - spectating"
   - Clear indication they'll join next round

2. **Spectator Camera for Mid-Game Joins**
   - Free-roam camera for mid-game joiners
   - Follow active players

3. **Late Join Option**
   - Allow joining as Prop/Hunter mid-round (if balanced)
   - Only during HIDING phase
   - Requires team rebalancing logic

## Status

✅ **COMPLETE** - UI visibility and mid-game join handling implemented

**Lines Changed**: ~60 lines across 3 files
**Testing Required**: Manual testing in Unity with multi-client setup
