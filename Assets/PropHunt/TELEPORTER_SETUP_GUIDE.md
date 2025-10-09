# Teleporter Setup Guide - Choose Your Approach

The PropHuntTeleporter currently uses the **Scene Teleporter asset** which expects separate Unity scenes. You have **two options**:

---

## ⭐ Option 1: Separate Scenes (RECOMMENDED - Easier)

This is **simpler** because the Scene Teleporter asset handles everything for you.

### Steps:

#### 1. Create Unity Scenes

1. In Unity: **File → New Scene**
2. Save as `Lobby.unity` in `Assets/PropHunt/Scenes/`
3. Repeat: Create `Arena.unity`

#### 2. Configure Lobby.unity

- Open `Lobby.unity`
- Add spawn point, UI, ground, lighting
- Save

#### 3. Configure Arena.unity

- Open `Arena.unity`
- Add props, zone volumes, spawn points
- Save

#### 4. Set Up SceneManager

1. Open your **main scene** (the one with PropHuntModules)
2. Create new GameObject: `SceneManagerObject`
3. Add Component: **SceneManager** (from Scene Teleporter asset)
4. In Inspector, set **Scene Names**:
   ```
   Size: 2
   Element 0: "Lobby"
   Element 1: "Arena"
   ```

#### 5. Add Scenes to Build Settings

1. **File → Build Settings**
2. Click **Add Open Scenes** while each scene is open
3. Make sure both Lobby and Arena are in the list

### ✅ Done!

The teleporter will now:
- Load both scenes additively on game start
- Move players between scenes automatically

**Note**: The "failed to load scene 'Lobby'" error will disappear once you create these scenes.

---

## Option 2: Single Scene with Position Teleports

This keeps everything in **one Unity scene** but requires modifying the Teleporter script.

### Steps:

#### 1. Replace PropHuntTeleporter.lua

See the code in `TELEPORTER_OPTION2.md` - it uses Transform positions instead of scene loading.

#### 2. Create Spawn GameObjects

In your single Unity scene:

1. Create empty GameObject: `LobbySpawn`
   - Position: `(0, 0, 0)` (or wherever)
2. Create empty GameObject: `ArenaSpawn`
   - Position: `(100, 0, 0)` (far away from lobby)

#### 3. Configure Inspector

1. Select **PropHuntModules** GameObject
2. Find **PropHuntTeleporter** component
3. Set fields:
   - **Lobby Spawn Position**: Drag `LobbySpawn`
   - **Arena Spawn Position**: Drag `ArenaSpawn`

#### 4. Layout Your Scene

- **Lobby area**: Near `(0, 0, 0)`
  - Ready button UI
  - Spawn point
  - Decorations

- **Arena area**: Near `(100, 0, 0)` (or wherever ArenaSpawn is)
  - Zone volumes
  - Props with Possessable
  - Hiding spots

### ✅ Done!

Players teleport between positions in the same scene.

---

## Which Should You Choose?

### Choose Option 1 (Separate Scenes) if:
- ✅ You want the simplest setup
- ✅ You don't mind having 2 Unity scenes
- ✅ You want to use the Scene Teleporter asset as-is

### Choose Option 2 (Single Scene) if:
- ✅ You prefer everything in one file
- ✅ You're comfortable modifying Lua scripts
- ✅ You want faster iteration (no scene switching)

---

## My Recommendation

**Use Option 1 (Separate Scenes)** for your first test. It's simpler and the Scene Teleporter asset does all the work. You can always switch to Option 2 later if needed.

---

## Testing

Once configured, in Play mode you should see:

**Option 1**:
```
[SceneManager] Loaded scene: Lobby
[SceneManager] Loaded scene: Arena
[PropHunt Teleporter] Teleporting Player1 to Arena
```

**Option 2**:
```
[PropHunt Teleporter] Teleporting Player1 to Arena
[PropHunt Teleporter] Teleported 1 players to Arena
```

If you see "failed to load scene 'Lobby'", you're using the current code (Option 1) but haven't created the scenes yet.
