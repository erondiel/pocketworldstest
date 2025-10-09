# Single Scene Setup Guide (Mobile-Friendly)

The PropHuntTeleporter now uses **position-based teleportation** in a single Unity scene. No separate scenes needed!

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

1. In Unity, select the **PropHuntModules** GameObject
2. In the Inspector, find the **PropHuntTeleporter** component
3. You'll see two fields:
   - **Lobby Spawn Position**
   - **Arena Spawn Position**

4. **Drag and drop**:
   - Drag `LobbySpawn` GameObject → **Lobby Spawn Position** field
   - Drag `ArenaSpawn` GameObject → **Arena Spawn Position** field

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

## Step 4: Optional - Set Player Spawn Point

If you want to control where **new players** initially spawn:

1. In Unity: **GameObject → Create Empty**
2. Name it **`PlayerSpawnPoint`**
3. Position it in the Lobby area (near LobbySpawn)
4. Set this as your Highrise player spawn point

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
    ├── PropHuntConfig
    ├── PropHuntGameManager
    ├── PropHuntTeleporter ← Configure spawn positions here!
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
- **"Arena spawn position not configured!"** → Drag ArenaSpawn to Inspector field
- **"Lobby spawn position not configured!"** → Drag LobbySpawn to Inspector field
- **"Cannot teleport nil player"** → Player character might not be spawned yet (usually harmless)

---

## Benefits of Single Scene

✅ **Faster loading** - No scene switching overhead
✅ **Mobile-friendly** - Lower memory usage
✅ **Easier debugging** - Everything in one scene
✅ **Faster iteration** - No build settings setup

---

## What Changed

**Before** (Scene Teleporter asset):
- Required separate Lobby.unity and Arena.unity scenes
- Used SceneManager to load scenes additively
- More memory overhead

**After** (Single scene):
- One Unity scene with two areas
- Simple position-based teleportation
- Uses `player.character.transform.position = targetPosition`

---

## Next Steps

1. ✅ Create LobbySpawn and ArenaSpawn GameObjects
2. ✅ Configure PropHuntTeleporter in Inspector
3. ✅ Build your lobby area around LobbySpawn
4. ✅ Build your arena area around ArenaSpawn
5. ✅ Test teleportation in Play mode

**That's it! No scene switching needed.**
