# Scene Teleporter Integration Guide

## Overview

This document describes how to integrate the Scene Teleporter asset into PropHuntGameManager for Lobby ↔ Arena transitions.

## Architecture

### Scene Teleporter Asset

**Location:** `/Assets/Downloads/Scene Teleporter/`

**Key Files:**
- `SceneManager.lua` - Core teleportation system using `server.LoadSceneAdditive()` and `server.MovePlayerToScene()`
- `SceneSwitcher.lua` - UI trigger component for manual scene switching (not used in PropHunt)

**How It Works:**
1. SceneManager loads multiple scenes additively on server startup
2. Exposes `movePlayerToScene(sceneName)` function that fires a client→server event
3. Server receives event and calls `server.MovePlayerToScene(player, sceneInfo)`

### PropHunt Wrapper Module

**Location:** `/Assets/PropHunt/Scripts/Modules/PropHuntTeleporter.lua`

**Purpose:**
- Wraps SceneManager with PropHunt-specific functions
- Provides role-based teleportation helpers
- Simplifies integration with PropHuntGameManager

**Public API:**
```lua
local Teleporter = require("PropHuntTeleporter")

-- Core functions
Teleporter.TeleportToArena(player)
Teleporter.TeleportToLobby(player)
Teleporter.TeleportAllToArena(playersList)
Teleporter.TeleportAllToLobby(playersList)

-- Role-based helpers
Teleporter.TeleportPropsToArena(propsTeam)
Teleporter.TeleportHuntersToArena(huntersTeam)
Teleporter.TeleportAllPlayersToLobby(allPlayers)

-- Configuration
Teleporter.SetSceneNames("Lobby", "Arena")
Teleporter.GetLobbySceneName()
Teleporter.GetArenaSceneName()
```

## Unity Setup Requirements

### Step 1: Configure SceneManager GameObject

1. **Create SceneManager GameObject** (if not already in scene):
   - Open `Assets/PropHunt/Scenes/test.unity`
   - Create empty GameObject named "SceneManager"
   - Add the generated `SceneManager` component (from `SceneManager.lua`)

2. **Configure Scene Names**:
   - In the Unity Inspector, find the `SceneManager` component
   - Set `sceneNames` array to include:
     - Element 0: `"Lobby"`
     - Element 1: `"Arena"`
   - **IMPORTANT:** These scene names must match your actual Unity scene setup

3. **Scene Setup Options**:

   **Option A: Single Scene with Spawn Areas** (Recommended for V1)
   - Use a single `test.unity` scene
   - Create two distinct world space areas:
     - Lobby area (spawn point at origin)
     - Arena area (spawn point at offset position, e.g., +1000 units on X-axis)
   - SceneManager will teleport players between spawn points within the same scene
   - Configure spawn transforms in each area

   **Option B: Multiple Scenes**
   - Create separate Unity scenes: `Lobby.unity` and `Arena.unity`
   - Add both scenes to Build Settings (even though Highrise doesn't use traditional builds)
   - SceneManager will load both additively and move players between them

### Step 2: Create Spawn Point References

For teleportation to work correctly, you need spawn points in each area:

1. **Lobby Spawn Point**:
   - Create empty GameObject: `LobbySpawn`
   - Position it at the Lobby ready area
   - Tag: `Respawn` or `LobbySpawn`

2. **Arena Spawn Point**:
   - Create empty GameObject: `ArenaSpawn`
   - Position it at the Arena center or prop hiding area
   - Tag: `Respawn` or `ArenaSpawn`

3. **Link Spawn Points to Scenes** (if using multiple scenes):
   - In each scene, ensure there's a spawn point GameObject
   - SceneManager will use the scene's default spawn when calling `server.MovePlayerToScene()`

## Integration into PropHuntGameManager

### Code Changes Required

**File:** `/Assets/PropHunt/Scripts/PropHuntGameManager.lua`

### 1. Import the Teleporter Module

Add this near the top of the file with other requires:

```lua
local Config = require("PropHuntConfig")
local PlayerManager = require("PropHuntPlayerManager")
local Teleporter = require("PropHuntTeleporter")  -- ADD THIS LINE
```

### 2. Update TransitionToState Function

Modify the `TransitionToState()` function to handle teleportation:

```lua
function TransitionToState(newState)
    local oldName = GetStateName(currentState)
    local newName = GetStateName(newState)
    Log(string.format("%s->%s", oldName, newName))

    currentState.value = newState

    if newState == GameState.LOBBY then
        stateTimer.value = 0
        eliminatedPlayers = {}
        -- Reset ready status when returning to lobby after a round
        PlayerManager.ResetAllPlayers()

        -- TELEPORTATION: Move all players back to Lobby
        local allPlayers = GetActivePlayers()
        Teleporter.TeleportAllPlayersToLobby(allPlayers)

    elseif newState == GameState.HIDING then
        stateTimer.value = Config.GetHidePhaseTime()
        Log(string.format("HIDE %ds", Config.GetHidePhaseTime()))

        -- TELEPORTATION: Move Props to Arena, Hunters stay in Lobby
        Teleporter.TeleportPropsToArena(propsTeam)

    elseif newState == GameState.HUNTING then
        stateTimer.value = Config.GetHuntPhaseTime()
        Log(string.format("HUNT %ds", Config.GetHuntPhaseTime()))

        -- TELEPORTATION: Move Hunters to Arena (Props already there)
        Teleporter.TeleportHuntersToArena(huntersTeam)

    elseif newState == GameState.ROUND_END then
        stateTimer.value = Config.GetRoundEndTime()
        Log(string.format("END %ds", Config.GetRoundEndTime()))
        -- Players can stay in Arena during round end, or teleport to Lobby early
        -- Uncomment if you want immediate Lobby return:
        -- local allPlayers = GetActivePlayers()
        -- Teleporter.TeleportAllPlayersToLobby(allPlayers)
    end

    -- Notify all clients of state change
    BroadcastStateChange(newState, stateTimer)
    debugEvent:FireAllClients("STATE", newName, stateTimer, roundNumber)
end
```

### 3. Optional: Custom Scene Names

If your Unity scenes have different names, configure them in `ServerStart()`:

```lua
function self:ServerStart()
    Log("GM Started")

    -- Configure scene names if different from defaults
    Teleporter.SetSceneNames("MyLobby", "MyArena")

    -- ... rest of ServerStart code
end
```

## Game Flow with Teleportation

### State Transitions

1. **LOBBY State**
   - All players in Lobby area
   - Players can ready up
   - Countdown timer when minimum ready

2. **LOBBY → HIDING Transition**
   - Roles assigned (Props vs Hunters)
   - **Props teleported to Arena**
   - Hunters remain in Lobby (can see countdown UI)
   - Props have 35s to select disguises and hide

3. **HIDING → HUNTING Transition**
   - **Hunters teleported to Arena**
   - Props already in position (immobile once possessed)
   - Hunt phase begins (240s)

4. **HUNTING → ROUND_END Transition**
   - All players remain in Arena
   - Display results, winner announcement (15s)

5. **ROUND_END → LOBBY Transition**
   - **All players teleported back to Lobby**
   - Scores displayed
   - Ready system resets
   - New round can begin

## Testing Checklist

- [ ] SceneManager GameObject exists in Unity scene
- [ ] `sceneNames` array configured with "Lobby" and "Arena"
- [ ] Lobby spawn point exists and positioned correctly
- [ ] Arena spawn point exists and positioned correctly
- [ ] Teleporter module imported in PropHuntGameManager
- [ ] TransitionToState calls Teleporter functions
- [ ] Test LOBBY → HIDING: Props teleport to Arena
- [ ] Test HIDING → HUNTING: Hunters teleport to Arena
- [ ] Test ROUND_END → LOBBY: All players return to Lobby
- [ ] Verify no teleport errors in Unity Console
- [ ] Verify players spawn at correct positions
- [ ] Test with 2+ players (multiplayer simulation)

## Troubleshooting

### Players Not Teleporting

**Issue:** `movePlayerToScene()` called but nothing happens

**Solution:**
- Check Unity Console for errors
- Verify SceneManager GameObject has the SceneManager component attached
- Ensure `sceneNames` array is populated in Inspector
- Confirm scene names match exactly (case-sensitive)

### Players Teleporting to Wrong Location

**Issue:** Players teleport but spawn at incorrect position

**Solution:**
- Check spawn point GameObject positions in Unity scene
- Verify scene default spawn points are set correctly
- Use Unity's Scene view to visualize spawn locations
- Consider adding debug logs in Teleporter to print target positions

### "Scene not found" Error

**Issue:** `SceneManager` can't find Lobby or Arena scene

**Solution:**
- If using multiple scenes: Add scenes to Build Settings
- If using single scene with areas: Ensure spawn GameObjects exist
- Check scene name spelling in SceneManager Inspector
- Try using SceneManager's `scenes` table debug print to see loaded scenes

### Network Sync Issues

**Issue:** Clients see players in wrong locations

**Solution:**
- Ensure `server.MovePlayerToScene()` is called on server-side
- Verify SceneManager is a Module type (runs on both client/server)
- Check that player character synchronization is working
- Use Network Profiler in Unity to check for sync lag

## Performance Considerations

- **Scene Loading:** Additive scene loading happens once at server startup (minimal performance impact)
- **Teleportation:** `MovePlayerToScene()` is lightweight, instant for clients
- **Mobile Optimization:** No additional draw calls, just player position updates
- **Batch Teleports:** `TeleportAll*` functions iterate efficiently, no async issues

## Future Enhancements

- **VFX Integration:** Add teleport beam VFX at spawn/departure points (see CLAUDE.md Phase Transition VFX spec)
- **Camera Transitions:** Smooth camera fade-out/fade-in during teleports
- **Spectator Mode:** Dedicated spectator spawn points with overview camera
- **Join-in-Progress:** Late joiners automatically teleport to appropriate area based on current game state
- **AFK Handling:** Auto-teleport AFK players back to Lobby

## Related Documentation

- **Scene Teleporter Asset:** `Assets/Downloads/Scene Teleporter/`
- **PropHunt Game Flow:** `Assets/PropHunt/Documentation/README.md`
- **Input System:** `Assets/PropHunt/Documentation/INPUT_SYSTEM.md`
- **Game Design Document:** `Assets/PropHunt/Docs/Prop_Hunt__V1_Game_Design_Document_(Tech_ArtFocused).pdf`

## Notes

- The SceneManager from the Scene Teleporter asset uses **Module type**, which means it runs on both client and server
- The `movePlayerToScene()` function is a client-initiated request that fires to the server
- For server-authoritative teleportation (as in PropHunt), we rely on the event handler in SceneManager that calls `server.MovePlayerToScene()`
- PropHuntTeleporter wraps this system to provide a cleaner, PropHunt-specific API
- All teleportation calls should be made from server-side code (PropHuntGameManager is Module type, so ensure calls are in Server* functions or state transitions)
