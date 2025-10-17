# PropHunt Teleportation System - Single Scene Setup

**This is the AUTHORITATIVE GUIDE for PropHunt teleportation.**

The PropHuntTeleporter uses **position-based teleportation** in a single Unity scene. No separate scenes or SceneManager asset needed!

---

## Step 1: Create Spawn Points in Unity

1. In your Unity scene hierarchy, **right-click → Create Empty**
2. Name it **`LobbySpawn`**
3. Set position to where your lobby area is (e.g., `0, 0, 0`)

4. **Right-click → Create Empty** again
5. Name it **`ArenaSpawn`**
6. Set position far from lobby (e.g., `100, 0, 0` or `0, 0, 100`)

**Tip**: Place ArenaSpawn at least 50-100 units away from LobbySpawn so players can't see between areas.

---

## Step 2: Configure PropHuntTeleporter

**IMPORTANT:** The teleporter configuration is in **PropHuntConfig.lua**, NOT a separate SceneManager!

1. In Unity, select the **PropHuntModules** GameObject
2. In the Inspector, find the **PropHuntConfig** component (should be first in the list)
3. Scroll down to find the **Teleporter Settings** section
4. You'll see two SerializeFields:
   - **Lobby Spawn Position** (GameObject)
   - **Arena Spawn Position** (GameObject)

5. **Drag and drop**:
   - Drag `LobbySpawn` GameObject → **Lobby Spawn Position** field
   - Drag `ArenaSpawn` GameObject → **Arena Spawn Position** field

**Note:** PropHuntTeleporter module reads these values from PropHuntConfig at runtime.

---

## Step 3: Build Your Scene Layout

### Lobby Area (around LobbySpawn at 0, 0, 0)
- Ground plane
- Spawn point for new players
- Ready button UI
- Decorations/walls

### Arena Area (around ArenaSpawn at 100, 0, 0)
- Larger playable area
- Props with **Possessable** component
- Zone volumes (NearSpawn, Mid, Far)
- Hiding spots
- Obstacles

**Important**: Keep the two areas visually separated (use distance or walls) so players in Lobby can't see Arena.

---

## Step 4: How It Works

**Implementation Details:**

The PropHuntTeleporter module (`Assets/PropHunt/Scripts/Modules/PropHuntTeleporter.lua`) uses:
- `player.character.transform.position = targetSpawn.transform.position`
- Simple position updates, no scene loading overhead
- Server-authoritative teleportation (happens in PropHuntGameManager state transitions)

**Game Flow:**
1. **LOBBY → HIDING:** Props teleport to ArenaSpawn
2. **HIDING → HUNTING:** Hunters teleport to ArenaSpawn
3. **ROUND_END → LOBBY:** All players teleport to LobbySpawn

**Note:** Initial player spawn on join is controlled by Highrise SDK defaults (usually world origin). Players will be teleported to LobbySpawn when game state initializes.

---

## Example Scene Layout

```
Your Unity Scene
│
├── LobbySpawn (0, 0, 0)
│   ├── Ground
│   ├── Walls
│   └── UI Elements
│
├── ArenaSpawn (100, 0, 0)
│   ├── Ground
│   ├── Props (with Possessable)
│   ├── Zone_NearSpawn (BoxCollider, trigger)
│   ├── Zone_Mid (BoxCollider, trigger)
│   └── Zone_Far (BoxCollider, trigger)
│
└── PropHuntModules
    ├── PropHuntConfig ← Configure spawn positions here!
    ├── PropHuntGameManager
    ├── PropHuntTeleporter (reads from PropHuntConfig)
    └── ... (other modules)
```

---

## Testing

### In Play Mode:

1. Start the game - you should spawn in Lobby area
2. Press Ready (with 2+ players)
3. **Props get teleported to Arena** (position 100, 0, 0)
4. After Hide phase, **Hunters teleport to Arena**
5. After round ends, **everyone teleports back to Lobby** (position 0, 0, 0)

### Console Output:
```
[PropHunt Teleporter] Teleporting Player1 to Arena
[PropHunt Teleporter] Teleported 2 players to Arena
[PropHunt Teleporter] Teleporting Player1 to Lobby
[PropHunt Teleporter] Teleported 3 players to Lobby
```

### If you see errors:
- **"Arena spawn position not configured!"** → Drag ArenaSpawn to PropHuntConfig Inspector field
- **"Lobby spawn position not configured!"** → Drag LobbySpawn to PropHuntConfig Inspector field
- **"Cannot teleport nil player"** → Player character might not be spawned yet (usually harmless)
- **"failed to load scene 'Lobby'"** → This error is OBSOLETE (from old SceneManager system), ignore it or check for old teleporter docs that weren't deleted

---

## Benefits of Single Scene

✅ **Faster loading** - No scene switching overhead
✅ **Mobile-friendly** - Lower memory usage
✅ **Easier debugging** - Everything in one scene
✅ **Faster iteration** - No build settings setup

---

## Implementation Notes

**Current System (V1):**
- One Unity scene with two spatial areas (Lobby and Arena)
- Position-based teleportation via `player.character.transform.position`
- Spawn positions configured in PropHuntConfig.lua SerializeFields
- No SceneManager asset or scene loading required
- Lightweight, mobile-friendly approach

**Why Not Use Scene Teleporter Asset?**
- Simpler setup (no build settings configuration)
- Faster iteration (no scene switching)
- Lower memory overhead (one scene in memory)
- Better for mobile performance
- Easier debugging (everything visible in one scene hierarchy)

---

## Next Steps

1. ✅ Create LobbySpawn and ArenaSpawn GameObjects
2. ✅ Configure PropHuntTeleporter in Inspector
3. ✅ Build your lobby area around LobbySpawn
4. ✅ Build your arena area around ArenaSpawn
5. ✅ Test teleportation in Play mode

**That's it! No scene switching needed.**
