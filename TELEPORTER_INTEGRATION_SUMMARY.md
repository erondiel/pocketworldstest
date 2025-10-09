# Scene Teleporter Integration Summary

## Overview

Successfully integrated the Scene Teleporter asset into PropHunt for Lobby ↔ Arena player transitions during game state changes.

**Date:** October 8, 2025
**Status:** Ready for Unity setup and code integration
**Files Created:** 4 new files (1 module, 3 documentation files)

## What Was Created

### 1. PropHuntTeleporter Module
**Location:** `/Assets/PropHunt/Scripts/Modules/PropHuntTeleporter.lua`

A wrapper module that provides PropHunt-specific teleportation functions using the Scene Teleporter asset.

**Key Features:**
- Wraps SceneManager.lua functionality with PropHunt-friendly API
- Provides role-based teleportation (Props, Hunters, All Players)
- Supports custom scene name configuration
- Includes debug logging for troubleshooting
- Type-safe function signatures

**Public API:**
```lua
local Teleporter = require("PropHuntTeleporter")

-- Core functions
Teleporter.TeleportToArena(player)           -- Single player to Arena
Teleporter.TeleportToLobby(player)           -- Single player to Lobby
Teleporter.TeleportAllToArena(playersList)   -- Multiple players to Arena
Teleporter.TeleportAllToLobby(playersList)   -- Multiple players to Lobby

-- Role-based helpers
Teleporter.TeleportPropsToArena(propsTeam)     -- Props only → Arena
Teleporter.TeleportHuntersToArena(huntersTeam) -- Hunters only → Arena
Teleporter.TeleportAllPlayersToLobby(allPlayers) -- Everyone → Lobby

-- Configuration
Teleporter.SetSceneNames("Lobby", "Arena")
Teleporter.GetLobbySceneName()
Teleporter.GetArenaSceneName()
```

### 2. Integration Documentation
**Location:** `/Assets/PropHunt/Documentation/TELEPORTER_INTEGRATION.md`

Comprehensive guide covering:
- Architecture overview (SceneManager + PropHuntTeleporter)
- Unity setup requirements (single scene vs. multiple scenes)
- Code integration steps for PropHuntGameManager
- Game flow with teleportation (state transitions)
- Testing checklist
- Troubleshooting guide
- Performance considerations
- Future enhancements (VFX, camera transitions, spectator mode)

**Key Sections:**
- How Scene Teleporter works (additive scene loading, event-based teleportation)
- Unity GameObject setup (SceneManager configuration)
- Spawn point creation (LobbySpawn, ArenaSpawn)
- Code changes required in PropHuntGameManager
- Testing procedures

### 3. Code Snippets Reference
**Location:** `/Assets/PropHunt/Documentation/TELEPORTER_CODE_SNIPPETS.md`

Quick copy-paste snippets for immediate integration:
- Import statement for PropHuntGameManager
- Complete TransitionToState() replacement with teleportation
- Minimal changes approach (just add teleport calls)
- Debug/testing functions
- Usage examples (single player, team, everyone)
- Error handling patterns
- Common integration patterns

**Quick Start:**
1. Copy import: `local Teleporter = require("PropHuntTeleporter")`
2. Copy TransitionToState() function replacement
3. Done - teleportation integrated

### 4. Unity Setup Guide
**Location:** `/Assets/PropHunt/Documentation/TELEPORTER_UNITY_SETUP.md`

Step-by-step Unity Editor setup:
- Visual checklist format for easy following
- SceneManager GameObject configuration
- Spawn point creation and positioning
- Tags and layers setup
- Testing scenarios (manual, state transitions, multiplayer)
- Common issues and solutions
- Verification checklist
- Scene hierarchy reference diagram

**Setup Time:** ~10-15 minutes

## Scene Teleporter Asset Analysis

**Location:** `/Assets/Downloads/Scene Teleporter/`

**How It Works:**
1. **ServerAwake:** Loads multiple scenes additively using `server.LoadSceneAdditive(sceneName)`
2. **Client Request:** `movePlayerToScene(sceneName)` fires event to server
3. **Server Response:** Calls `server.MovePlayerToScene(player, sceneInfo)` to teleport

**Files Examined:**
- `SceneManager.lua` - Core teleportation system (Module type)
- `SceneSwitcher.lua` - UI trigger component (not used in PropHunt)

**Key Insight:** SceneManager uses an event-based system (`Event.new("MovePlayerToSceneEvent")`) that PropHuntTeleporter wraps for cleaner integration.

## Integration Steps for PropHuntGameManager

### Step 1: Unity Setup (see TELEPORTER_UNITY_SETUP.md)
1. Create SceneManager GameObject in scene
2. Attach SceneManager component
3. Configure scene names: `["Lobby", "Arena"]`
4. Create LobbySpawn and ArenaSpawn GameObjects
5. Position spawn points appropriately

### Step 2: Code Integration (see TELEPORTER_CODE_SNIPPETS.md)
1. Add import to PropHuntGameManager.lua:
   ```lua
   local Teleporter = require("PropHuntTeleporter")
   ```

2. Update TransitionToState() function:
   ```lua
   if newState == GameState.LOBBY then
       -- ... existing code ...
       Teleporter.TeleportAllPlayersToLobby(GetActivePlayers())

   elseif newState == GameState.HIDING then
       -- ... existing code ...
       Teleporter.TeleportPropsToArena(propsTeam)

   elseif newState == GameState.HUNTING then
       -- ... existing code ...
       Teleporter.TeleportHuntersToArena(huntersTeam)
   end
   ```

3. Save and let Unity regenerate C# scripts

### Step 3: Testing
1. Enter Unity Play mode
2. Verify SceneManager initializes
3. Test state transitions (manual or debug commands)
4. Check Unity Console for teleportation logs
5. Verify player positions change correctly

## Game Flow with Teleportation

### State Transition Diagram
```
LOBBY (all in Lobby)
   ↓ Minimum players ready, countdown complete
   ↓ [Roles assigned: Props vs Hunters]
   ↓
HIDING (Props → Arena, Hunters stay in Lobby)
   ↓ Hide timer expires (35s)
   ↓
HUNTING (Hunters → Arena, Props already there)
   ↓ All props found OR hunt timer expires (240s)
   ↓
ROUND_END (all stay in Arena, results displayed)
   ↓ Round end timer expires (15s)
   ↓
LOBBY (all → Lobby, ready system resets)
```

### Teleportation Per State
- **LOBBY:** All players in Lobby area
- **HIDING:** Props in Arena, Hunters in Lobby (observe countdown)
- **HUNTING:** All players in Arena (gameplay active)
- **ROUND_END:** All players in Arena (results displayed)
- **Back to LOBBY:** All teleport to Lobby (scores visible, ready up for next round)

## Files Modified

**None** - This integration does not modify existing files. It only creates new files and requires manual integration steps.

## Files to Integrate (Manual Steps Required)

**PropHuntGameManager.lua** - Requires these changes:
1. Add import statement (line ~11, with other requires)
2. Add teleport calls in TransitionToState() function (lines ~230-250)
3. Optionally add SetSceneNames() in ServerStart() if using custom scene names

**Estimated Integration Time:** 5-10 minutes

## Dependencies

**Required:**
- Scene Teleporter asset: `/Assets/Downloads/Scene Teleporter/SceneManager.lua`
- Highrise Studio SDK: `server.LoadSceneAdditive()`, `server.MovePlayerToScene()`
- Unity scene with spawn points

**Optional:**
- Multiple Unity scenes (Lobby.unity, Arena.unity) if not using single scene approach

## Scene Setup Recommendations

### V1 Approach: Single Scene with Spawn Areas (Recommended)
**Pros:**
- Simpler setup, less memory usage
- Faster testing and iteration
- No scene loading/unloading overhead
- Both areas visible in Scene view

**Cons:**
- Both areas loaded in memory always (minimal impact)
- Need to physically separate areas to prevent visual overlap

**Setup:**
- Use `test.unity` scene
- Create Lobby area at origin (0,0,0)
- Create Arena area at offset (1000,0,0) or similar
- SceneManager "scene names" actually refer to spawn point GameObjects

### V2+ Approach: Multiple Scenes
**Pros:**
- True scene separation
- Can optimize each scene independently
- More scalable for large worlds

**Cons:**
- More complex setup
- Need to manage scene references
- Requires additive scene loading

**Setup:**
- Create Lobby.unity and Arena.unity
- Configure SceneManager with actual scene names
- Add scenes to Build Settings

## Testing Checklist

- [ ] SceneManager GameObject created in Unity
- [ ] SceneManager component configured with scene names
- [ ] LobbySpawn GameObject positioned
- [ ] ArenaSpawn GameObject positioned
- [ ] PropHuntTeleporter.lua module created
- [ ] PropHuntGameManager imports Teleporter
- [ ] TransitionToState calls Teleporter functions
- [ ] No Unity Console errors on Play
- [ ] State transition LOBBY→HIDING teleports Props to Arena
- [ ] State transition HIDING→HUNTING teleports Hunters to Arena
- [ ] State transition ROUND_END→LOBBY teleports all to Lobby
- [ ] Multiplayer simulation test passes (2+ players)

## Performance Impact

**Minimal to None:**
- Scene loading: Once at server startup (ServerAwake)
- Teleportation: Instant position update, no loading
- Memory: Single scene approach uses less memory
- Network: Lightweight position sync, already optimized by Highrise
- Mobile: No impact, same as any player movement

## Future Enhancements

**Post-V1 Features:**
1. **VFX Integration:**
   - Teleport beam VFX at spawn points
   - Particle effects on arrival/departure
   - See CLAUDE.md Phase Transition VFX spec

2. **Camera Transitions:**
   - Fade-out/fade-in during teleports
   - Smooth camera movement
   - Cinematic scene switches

3. **Spectator Mode:**
   - Dedicated spectator spawn with overview camera
   - Spectator-specific teleportation logic
   - Free camera movement in Arena

4. **Join-in-Progress:**
   - Late joiners auto-teleport to appropriate area
   - Based on current game state
   - Proper role assignment

5. **AFK Handling:**
   - Detect AFK players
   - Auto-teleport to Lobby
   - Kick from active round

## Troubleshooting Resources

**If teleportation doesn't work:**
1. Check `TELEPORTER_UNITY_SETUP.md` - Common Issues section
2. Verify SceneManager GameObject exists and is configured
3. Check Unity Console for errors
4. Ensure spawn points exist and are positioned correctly
5. Test with simple debug teleport function first

**If integration is unclear:**
1. Review `TELEPORTER_INTEGRATION.md` for architecture details
2. Use `TELEPORTER_CODE_SNIPPETS.md` for exact code to copy
3. Follow `TELEPORTER_UNITY_SETUP.md` checklist step-by-step

## Documentation Files

All documentation is located in `/Assets/PropHunt/Documentation/`:

1. **TELEPORTER_INTEGRATION.md** - Comprehensive integration guide
2. **TELEPORTER_CODE_SNIPPETS.md** - Copy-paste code examples
3. **TELEPORTER_UNITY_SETUP.md** - Unity Editor setup checklist

## Next Steps

1. **Read** `TELEPORTER_UNITY_SETUP.md` for Unity configuration
2. **Follow** the setup checklist to create SceneManager GameObject
3. **Review** `TELEPORTER_CODE_SNIPPETS.md` for integration code
4. **Copy** the import and TransitionToState snippets into PropHuntGameManager.lua
5. **Test** in Unity Play mode
6. **Verify** state transitions trigger teleportation correctly
7. **Iterate** based on testing feedback

## Support

**If you encounter issues:**
- Check the troubleshooting sections in each documentation file
- Verify all checklist items are completed
- Review Unity Console for specific error messages
- Test SceneManager independently before PropHunt integration
- Ensure Highrise Studio SDK is up to date

**Related Documentation:**
- PropHunt Game Flow: `README.md`
- Input System: `INPUT_SYSTEM.md`
- Game Design Document: `Prop_Hunt__V1_Game_Design_Document_(Tech_ArtFocused).pdf`
- Implementation Guide: `IMPLEMENTATION_GUIDE.md`

## Summary

The Scene Teleporter asset has been successfully analyzed and wrapped in a PropHunt-specific module. All necessary documentation has been created to guide Unity setup and code integration. The system is ready for implementation once the Unity configuration is complete.

**Total Files Created:** 4
**Total Lines of Code:** ~350 (Lua module + documentation)
**Estimated Setup Time:** 15-25 minutes (Unity + code integration)
**Dependencies:** Scene Teleporter asset (already present)
**Breaking Changes:** None (additive integration only)
