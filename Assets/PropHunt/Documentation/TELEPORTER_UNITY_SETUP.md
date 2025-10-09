# Scene Teleporter Unity Setup Guide

## Quick Setup Checklist

Use this checklist to set up Scene Teleporter in Unity before integrating with PropHuntGameManager.

### Step 1: Verify Scene Teleporter Asset
- [ ] Confirm `Assets/Downloads/Scene Teleporter/` exists
- [ ] Verify `SceneManager.lua` is present
- [ ] Verify Unity has generated the C# wrapper for SceneManager

### Step 2: Configure SceneManager GameObject
- [ ] Open scene: `Assets/PropHunt/Scenes/test.unity`
- [ ] Create new empty GameObject named "SceneManager" (or find existing)
- [ ] Add component: Search for "SceneManager" and attach the generated component
- [ ] Configure Inspector settings (see details below)

### Step 3: Set Up Scene Names
In the SceneManager component Inspector:

**For Single Scene Setup (Recommended V1):**
- [ ] Set `sceneNames` array size to 2
- [ ] Element 0: `"Lobby"` (this will be a spawn point name)
- [ ] Element 1: `"Arena"` (this will be a spawn point name)

**For Multiple Scene Setup:**
- [ ] Create `Lobby.unity` scene in `Assets/PropHunt/Scenes/`
- [ ] Create `Arena.unity` scene in `Assets/PropHunt/Scenes/`
- [ ] Add both scenes to Build Settings (File > Build Settings > Add Open Scenes)
- [ ] Set `sceneNames` array with exact scene names

### Step 4: Create Spawn Points

**Lobby Spawn:**
- [ ] Create empty GameObject: `LobbySpawn`
- [ ] Position: (0, 0, 0) or your desired lobby location
- [ ] Add component: `Transform` (already present)
- [ ] Tag: Create and assign `LobbySpawn` tag
- [ ] Save scene

**Arena Spawn:**
- [ ] Create empty GameObject: `ArenaSpawn`
- [ ] Position: For single scene, offset far from Lobby (e.g., X=1000, Y=0, Z=0)
- [ ] Add component: `Transform` (already present)
- [ ] Tag: Create and assign `ArenaSpawn` tag
- [ ] Save scene

### Step 5: Configure PropHunt Scripts
- [ ] Verify `PropHuntTeleporter.lua` exists in `Assets/PropHunt/Scripts/Modules/`
- [ ] Open `PropHuntGameManager.lua` in your code editor
- [ ] Add import: `local Teleporter = require("PropHuntTeleporter")`
- [ ] Update `TransitionToState()` function with teleport calls (see TELEPORTER_CODE_SNIPPETS.md)
- [ ] Save and return to Unity to trigger C# regeneration

### Step 6: Test in Unity
- [ ] Enter Play mode
- [ ] Check Unity Console for errors
- [ ] Verify SceneManager initializes (look for "MovePlayerToSceneEvent" in logs)
- [ ] Test state transitions (use debug commands if available)
- [ ] Verify players move between Lobby and Arena areas
- [ ] Exit Play mode

## Detailed Configuration

### SceneManager Inspector Settings

```
SceneManager (Script)
├── Script: SceneManager
└── Scene Names (Array)
    ├── Size: 2
    ├── Element 0: "Lobby"
    └── Element 1: "Arena"
```

**Important Notes:**
- Scene names are case-sensitive
- Must match your actual Unity scene names OR spawn point GameObject names
- For single scene setup, these are logical area names, not physical scenes

### Spawn Point Setup (Single Scene Method)

This is the recommended approach for V1:

**Lobby Area:**
```
Hierarchy:
PropHunt
├── SceneManager
├── GameManagers
│   └── PropHuntGameManager (GameObject with component)
└── Spawns
    ├── LobbySpawn
    │   └── Position: (0, 0, 0)
    └── ArenaSpawn
        └── Position: (1000, 0, 0)  // Far from Lobby
```

**In Scene View:**
- Lobby area should contain: Ready UI, player spawn markers
- Arena area should contain: Props (possessables), hunter spawn markers
- Physically separate areas (e.g., 500-1000 units apart)

### Alternative: Multiple Scenes Method

**Lobby.unity:**
- Contains: Lobby UI, SceneManager reference
- Spawn point: GameObject at scene origin

**Arena.unity:**
- Contains: Props, hiding spots, zone volumes
- Spawn point: GameObject at scene origin

**Both scenes loaded additively at runtime by SceneManager**

### Tags Setup

Create these tags if they don't exist:

1. Go to: Edit > Project Settings > Tags and Layers
2. Add new tags:
   - `LobbySpawn`
   - `ArenaSpawn`
   - `Possessable` (if not already created)
   - `Zone_NearSpawn` (for scoring zones)
   - `Zone_Mid`
   - `Zone_Far`

### Layer Setup (Optional but Recommended)

For better performance and collision filtering:

1. Go to: Edit > Project Settings > Tags and Layers
2. Add custom layers:
   - Layer 8: `Props`
   - Layer 9: `Players`
   - Layer 10: `UI`
   - Layer 11: `Zones`

3. Assign layers:
   - All possessable props: `Props` layer
   - Player characters: `Players` layer
   - Zone volumes: `Zones` layer

## Testing Scenarios

### Test 1: Manual Scene Switch (UI Method)

This tests the base Scene Teleporter functionality:

1. Create test button in scene (optional):
   - Add UI > Button to Canvas
   - Add `SceneSwitcher.lua` component
   - Set `sceneName` to "Arena"
   - Add trigger collider at Lobby spawn

2. Enter Play mode
3. Walk into trigger area
4. Click button
5. Verify player teleports to Arena spawn

### Test 2: PropHunt State Transitions

This tests the PropHuntTeleporter integration:

1. Enter Play mode
2. Open Unity Console
3. Use debug commands to force state changes (if available):
   ```lua
   -- From debug console or DebugCheats script
   forceState("HIDING")  -- Should teleport Props to Arena
   forceState("HUNTING") -- Should teleport Hunters to Arena
   forceState("LOBBY")   -- Should teleport all to Lobby
   ```

4. Verify console shows:
   ```
   [PropHunt Teleporter] Teleporting PlayerName to Arena
   [PropHunt Teleporter] Teleported 2 players to Arena
   ```

### Test 3: Multiplayer Simulation

1. Enable Highrise multiplayer simulation (if available)
2. Spawn 2+ players
3. Ready up players
4. Let countdown complete
5. Verify:
   - Props teleport to Arena during HIDING
   - Hunters stay in Lobby during HIDING
   - Hunters teleport to Arena at HUNTING start
   - All return to Lobby at ROUND_END

## Common Issues and Solutions

### Issue: "SceneManager component not found"

**Solution:**
- Wait for Unity to regenerate C# scripts from Lua
- Check Packages/com.pz.studio.generated/Runtime/Highrise.Lua.Generated/ for SceneManager.cs
- Reimport SceneManager.lua (right-click > Reimport)

### Issue: "Scene 'Arena' not found"

**Solution:**
- Verify scene name spelling in SceneManager Inspector
- For single scene setup: scene names are logical, not physical - ensure spawn GameObjects exist
- For multiple scenes: add scenes to Build Settings

### Issue: Players teleport but fall through floor

**Solution:**
- Check spawn point Y position (should be above ground)
- Verify terrain/floor has colliders
- Ensure Physics layers allow player collision with ground

### Issue: SceneManager not loading scenes

**Solution:**
- Check that SceneManager GameObject exists before game starts
- Verify ServerAwake() is being called (add debug print)
- Check Unity Console for scene loading errors

### Issue: Teleportation works in Editor but not in Highrise build

**Solution:**
- Verify all scenes are included in Highrise publish settings
- Check Highrise Studio build logs for errors
- Test locally with Highrise's standalone player first

## Performance Notes

- **Scene Loading:** Happens once at server startup (ServerAwake)
- **Memory:** Both scenes loaded in memory (single scene method uses less)
- **Teleportation:** Instant, no loading screens
- **Mobile:** Optimized for mobile platforms, no performance concerns

## Next Steps

After completing this setup:

1. Review `TELEPORTER_INTEGRATION.md` for code integration
2. Copy code snippets from `TELEPORTER_CODE_SNIPPETS.md`
3. Integrate teleportation into PropHuntGameManager
4. Test all state transitions
5. Add VFX at spawn points (see CLAUDE.md for VFX specs)
6. Configure zone volumes for scoring system

## Visual Setup Reference

```
Scene Hierarchy:
test.unity
├── SceneManager (GameObject)
│   └── SceneManager (Component)
│       └── sceneNames: ["Lobby", "Arena"]
│
├── Spawns (Empty GameObject for organization)
│   ├── LobbySpawn (Transform: 0,0,0)
│   │   └── Tag: LobbySpawn
│   └── ArenaSpawn (Transform: 1000,0,0)
│       └── Tag: ArenaSpawn
│
├── GameManagers
│   └── PropHuntGameManager (GameObject)
│       └── PropHuntGameManager (Component)
│
├── Lobby Area
│   ├── Floor
│   ├── Walls
│   └── UI Elements
│
└── Arena Area
    ├── Floor
    ├── Walls
    ├── Props (Possessables)
    └── Zone Volumes
        ├── Zone_NearSpawn
        ├── Zone_Mid
        └── Zone_Far
```

## Verification Checklist

Before declaring setup complete:

- [ ] SceneManager GameObject exists in Hierarchy
- [ ] SceneManager component attached and configured
- [ ] Scene names array populated (2 elements)
- [ ] LobbySpawn GameObject created and positioned
- [ ] ArenaSpawn GameObject created and positioned
- [ ] PropHuntTeleporter.lua exists in Modules folder
- [ ] PropHuntGameManager imports Teleporter module
- [ ] TransitionToState calls Teleporter functions
- [ ] No errors in Unity Console
- [ ] Play mode test successful
- [ ] State transitions trigger teleportation
- [ ] Players spawn at correct locations
- [ ] Multiplayer test successful (if available)

## Support Resources

- **Scene Teleporter Documentation:** Check `Assets/Downloads/Scene Teleporter/` for README
- **Highrise Scene Loading:** https://create.highrise.game/learn/studio-api/scene
- **PropHunt Game Flow:** `Assets/PropHunt/Documentation/README.md`
- **Integration Guide:** `TELEPORTER_INTEGRATION.md`
- **Code Examples:** `TELEPORTER_CODE_SNIPPETS.md`
