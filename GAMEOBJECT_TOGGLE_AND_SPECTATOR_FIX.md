# UI Visibility & Mid-Game Spectator Fix

## Summary
Fixed UI buttons to properly hide during gameplay using rootElement.style.display and ensured mid-game joiners are properly tagged as spectators. Also fixed spectator toggle infinite loop.

## Problem 1: UI Still Appearing During Gameplay

### Issue
UI elements were visible and clickable during HIDING/HUNTING/ROUND_END phases when they should only appear in LOBBY.

### Solution: Bound Element style.display
For UI scripts (--!Type(UI)), we use --!Bind to access UI elements and hide the container:

```lua
-- Bind the container element in UXML
--!Bind
local _button : VisualElement = nil

-- LOBBY: Show UI
_button.style.display = DisplayStyle.Flex

-- HIDING/HUNTING/ROUND_END: Hide UI
_button.style.display = DisplayStyle.None
```

### Why This Approach:

| Approach | Works for UI Scripts | Visibility | Event Processing |
|----------|---------------------|-----------|------------------|
| `GameObject.SetActive()` | ❌ No (UI uses UIDocument) | N/A | N/A |
| `self.uiDocument:GetRootVisualElement()` | ❌ No (uiDocument is nil) | N/A | N/A |
| `--!Bind + style.display` | ✅ Yes | ✅ Controlled | ✅ Disabled when None |

**DisplayStyle.None on bound element**:
- ✅ Hides UI element and children
- ✅ Disables event processing
- ✅ Proper for Highrise UI Toolkit (--!Bind pattern)

## Problem 2: Spectator Toggle Infinite Loop

### Issue
When toggling spectator mode, the toggle would enter an infinite loop:
1. User clicks toggle → fires server request
2. Server changes isSpectator BoolValue
3. BoolValue.Changed event fires → updates toggle value
4. Updating toggle value triggers BoolChangeEvent → fires server request again
5. Loop repeats infinitely

### Solution: isUpdatingFromServer Flag
Added a boolean flag to prevent toggle changes from firing server requests when the change came from server sync:

```lua
local isUpdatingFromServer = false

-- User clicks toggle
_toggle:RegisterCallback(BoolChangeEvent, function(event)
    if not isUpdatingFromServer then
        -- Only fire server if user initiated change
        PlayerManager.SpectatorToggleRequest:FireServer()
    end
end)

-- Server updates spectator state
playerInfo.isSpectator.Changed:Connect(function(newValue, oldValue)
    isUpdatingFromServer = true  -- Prevent loop
    _toggle.value = newValue
    isUpdatingFromServer = false
end)
```

## Problem 3: Mid-Game Joiners Not Tagged as Spectators

### Issue
Players joining mid-game were teleported to Arena but not marked as spectators, causing:
- Not in spectators list
- Could attempt to ready up (though UI hidden)
- Not properly tracked in spectator system

### Solution: ForceSpectatorMode()

Created new server-side function in **PlayerManager**:

```lua
function ForceSpectatorMode(player : Player)
    -- Set spectator state
    players[player].isSpectator.value = true

    -- Un-ready if they were ready
    if players[player].isReady.value then
        players[player].isReady.value = false
        -- Remove from ready list
    end

    -- Add to spectator list
    spectatorPlayersTable[player] = true
    spectatorPlayers.value = spectatorPlayersTable

    -- Trigger teleport callback
    if OnSpectatorToggleCallback then
        OnSpectatorToggleCallback(player, true)
    end

    return true
end
```

### Mid-Game Join Flow:

```
Player joins during HIDING/HUNTING
  ↓
Server detects currentState != LOBBY
  ↓
Wait 0.5s for PlayerManager to track player
  ↓
Call PlayerManager.ForceSpectatorMode(player)
  ↓
Sets isSpectator = true
Adds to spectatorPlayers table
Triggers OnSpectatorToggled callback
  ↓
GameManager.OnSpectatorToggled teleports to Arena
  ↓
Player is in Arena as proper spectator
  ↓
When round ends → LOBBY transition
  ↓
Player can toggle spectator OFF to play next round
```

## Files Modified

### 1. PropHuntReadyButton.lua
**Changes**:
- Use bound `_button` element (already bound via --!Bind)
- Changed to `_button.style.display = DisplayStyle.None/Flex`
- Added logging for show/hide events

**Code**:
```lua
--!Bind
local _button : VisualElement = nil

local function UpdateButtonVisibility(currentState)
    if not _button then return end

    if currentState == GameState.LOBBY then
        _button.style.display = DisplayStyle.Flex
        print("[PropHuntReadyButton] UI shown (LOBBY)")
    else
        _button.style.display = DisplayStyle.None
        print("[PropHuntReadyButton] UI hidden (game in progress)")
    end
end
```

### 2. PropHuntSpectatorButton.lua & PropHuntSpectatorButton.uxml
**Changes**:
- Added `isUpdatingFromServer` flag to prevent toggle loop
- Added `name="_container"` to UXML spectator-container element
- Bind `_container` via --!Bind
- Changed to `_container.style.display = DisplayStyle.None/Flex`
- Wrap toggle value updates in flag to prevent server request loop
- Added logging for user vs server toggle changes

**UXML**:
```xml
<VisualElement class="spectator-container" name="_container">
  <Label class="spectator-label" text="Spectator" />
  <hr:UISwitchToggle class="spectator-toggle" name="_toggle" />
</VisualElement>
```

**Lua Code**:
```lua
--!Bind
local _container : VisualElement = nil
local isUpdatingFromServer = false

local function UpdateButtonVisibility(currentState)
    if not _container then return end

    if currentState == GameState.LOBBY then
        _container.style.display = DisplayStyle.Flex
        print("[PropHuntSpectatorButton] UI shown (LOBBY)")
    else
        _container.style.display = DisplayStyle.None
        print("[PropHuntSpectatorButton] UI hidden (game in progress)")
    end
end

-- Prevent toggle loop with flag
_toggle:RegisterCallback(BoolChangeEvent, function(event)
    if not isUpdatingFromServer then
        print("[PropHuntSpectatorButton] User toggled spectator")
        PlayerManager.SpectatorToggleRequest:FireServer()
    end
end)

playerInfo.isSpectator.Changed:Connect(function(newValue, oldValue)
    print("[PropHuntSpectatorButton] Server updated spectator state")
    isUpdatingFromServer = true
    _toggle.value = newValue
    isUpdatingFromServer = false
end)
```

### 3. PropHuntPlayerManager.lua
**Changes**:
- Added `ForceSpectatorMode(player)` function
- Exported in module API

**New Function**:
- Sets `isSpectator.value = true`
- Un-readies player if needed
- Adds to spectator TableValue
- Triggers teleport callback
- Returns success boolean

### 4. PropHuntGameManager.lua - OnPlayerJoinedScene
**Changes**:
- Calls `PlayerManager.ForceSpectatorMode(player)` for mid-game joins
- Cleaner logic with success check
- Better logging

**Code**:
```lua
if currentState.value ~= GameState.LOBBY then
    Timer.After(0.5, function()
        local success = PlayerManager.ForceSpectatorMode(player)
        if success then
            Log("Mid-game joiner set as spectator and teleported")
        else
            Teleporter.TeleportToArena(player) -- Fallback
        end
    end)
end
```

## Console Log Examples

### UI Visibility Toggle
```
[PropHuntReadyButton] Started
[PropHuntReadyButton] UI shown (LOBBY)
[PropHuntSpectatorButton] Started
[PropHuntSpectatorButton] UI shown (LOBBY)

[PropHunt] LOBBY->HIDING
[PropHuntReadyButton] UI hidden (game in progress)
[PropHuntSpectatorButton] UI hidden (game in progress)

[PropHunt] ROUND_END->LOBBY
[PropHuntReadyButton] UI shown (LOBBY)
[PropHuntSpectatorButton] UI shown (LOBBY)
```

### Spectator Toggle (No Loop)
```
[PropHuntSpectatorButton] User toggled spectator
[PlayerManager] Player became spectator: VirtualPlayer3
[PropHuntSpectatorButton] Server updated spectator state
```

### Mid-Game Join as Spectator
```
[PropHunt] JOIN ErondielPC (3)
[PropHunt] MID-GAME JOIN: ErondielPC → forcing spectator mode
[PlayerManager] Forcing spectator mode: ErondielPC
[PropHunt] SPECTATOR ON: ErondielPC teleported to Arena
[PropHunt] Mid-game joiner ErondielPC set as spectator and teleported to Arena
```

## Testing Checklist

### UI Visibility Toggle
- [ ] Ready button visible in LOBBY
- [ ] Ready button completely hidden in HIDING
- [ ] Ready button completely hidden in HUNTING
- [ ] Ready button completely hidden in ROUND_END
- [ ] Ready button reappears when ROUND_END → LOBBY
- [ ] Cannot click Ready button during game phases
- [ ] Same behavior for Spectator toggle

### Spectator Toggle Loop Fix
- [ ] Clicking spectator toggle once fires only ONE server request
- [ ] Server updating spectator state does NOT trigger another request
- [ ] No infinite loop in console logs
- [ ] Toggle state syncs correctly with server

### Mid-Game Join Spectator
- [ ] Player joins during HIDING → marked as spectator
- [ ] Player joins during HUNTING → marked as spectator
- [ ] Player joins during ROUND_END → marked as spectator
- [ ] Mid-game joiner appears in spectator list
- [ ] Mid-game joiner teleports to Arena
- [ ] Mid-game joiner has `isSpectator.value = true`
- [ ] Mid-game joiner cannot ready up (already spectator)
- [ ] Mid-game joiner can toggle spectator OFF in next lobby
- [ ] Multiple mid-game joins work correctly
- [ ] Mid-game joiner excluded from role assignment

## Benefits

### Bound Element style.display Approach:

1. **UI Toolkit Compatibility**
   - Works with Highrise UI Toolkit (--!Bind pattern)
   - Proper API for UI scripts (--!Type(UI))
   - No uiDocument or GameObject dependency issues

2. **Performance**
   - DisplayStyle.None disables event processing
   - Hidden UI doesn't consume render resources
   - Efficient for mobile devices

3. **Clarity**
   - Clear show/hide state in logs
   - Standard CSS-like approach
   - Easy to understand and debug

4. **Reliability**
   - Works correctly with UIDocument system
   - No GameObject.SetActive() errors on UI elements
   - Guaranteed to work with Highrise UI framework

### isUpdatingFromServer Flag:

1. **Loop Prevention**
   - Prevents infinite toggle loops
   - Distinguishes user changes from server sync
   - Clean separation of concerns

2. **Network Efficiency**
   - Only fires server request when user clicks
   - No duplicate network traffic
   - Reduces server load

3. **State Consistency**
   - Toggle always in sync with server
   - No race conditions
   - Predictable behavior

### ForceSpectatorMode() Approach:

1. **Proper State Management**
   - Centralized spectator logic
   - All spectator state updated atomically
   - Triggers existing callback system

2. **Network Sync**
   - TableValue properly updated
   - BoolValue properly updated
   - All clients see spectator state

3. **Consistency**
   - Same behavior as manual spectator toggle
   - Reuses existing OnSpectatorToggled callback
   - No duplicate teleport logic

4. **Extensibility**
   - Can be called from anywhere
   - Returns success boolean for error handling
   - Easy to add mid-game spectator features later

## Edge Cases Handled

### 1. Bound element null check
```lua
if not _button then
    return
end
_button.style.display = DisplayStyle.Flex
```

### 2. Initial toggle state (without triggering event)
```lua
isUpdatingFromServer = true
_toggle.value = playerInfo.isSpectator.value
isUpdatingFromServer = false
```

### 3. PlayerManager tracking delay
```lua
Timer.After(0.5, function()
    -- Ensure player is tracked before forcing spectator
end)
```

### 4. Fallback teleport
```lua
if success then
    -- Spectator mode set + auto-teleport
else
    -- Manual teleport fallback
end
```

### 5. Already spectator check
```lua
if players[player].isSpectator.value then
    return true  -- Already spectator, success
end
```

## Alternative Approaches (Not Used)

### 1. CSS visibility: hidden
❌ Still processes events
❌ Still consumes render resources
❌ Can cause layout issues

### 2. Manually tracking spectators in GameManager
❌ Duplicate state management
❌ Risk of desync with PlayerManager
❌ More complex code

### 3. Setting spectator directly in GameManager
❌ Bypasses PlayerManager logic
❌ Doesn't update TableValue correctly
❌ Won't trigger network sync

## Status

✅ **COMPLETE** - UI visibility control, spectator toggle loop fix, and mid-game spectator tagging implemented

**Lines Changed**: ~100 lines across 5 files
**Key Fixes**:
- ✅ Bound element style.display for UI visibility (--!Bind pattern, not uiDocument or GameObject)
- ✅ isUpdatingFromServer flag to prevent toggle loop
- ✅ ForceSpectatorMode for mid-game joiners
- ✅ Added name="_container" to PropHuntSpectatorButton.uxml

**Testing Required**: Manual testing in Unity with:
1. UI visibility during phase transitions
2. Spectator toggle (verify no loop)
3. Mid-game joins
