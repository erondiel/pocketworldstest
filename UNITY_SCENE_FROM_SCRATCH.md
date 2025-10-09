# PropHunt - Complete Scene Setup From Scratch

**Everything you need to build a playable PropHunt scene in Unity**

**Total Time:** 15-20 minutes
**Result:** Fully functional PropHunt game ready to test

---

## Part 1: Module Registration (3-5 min)

### Step 1.1: Create Module Container

1. Hierarchy → Right-click → **Create Empty**
2. Name: `PropHuntModules`
3. Position: `0, 0, 0`

### Step 1.2: Add PropHunt Core Modules

With `PropHuntModules` selected, add these components **in this exact order**:

**How to add:** Select `PropHuntModules` → Inspector → **Add Component** → Search for script name → Add

- [ ] 1. **PropHuntConfig** ⚠️ **ADD FIRST!** (all others depend on this)
- [ ] 2. PropHuntPlayerManager
- [ ] 3. PropHuntScoringSystem
- [ ] 4. ZoneManager
- [ ] 5. PropHuntTeleporter
- [ ] 6. PropHuntVFXManager
- [ ] 7. PropHuntUIManager

### Step 1.3: Add DevBasics Tweens (VFX System)

1. In Project window, navigate to: `Assets/Downloads/DevBasics Toolkit/Scripts/Shared/`
2. Find: `devx_tweens.lua`
3. **Drag it onto `PropHuntModules` GameObject** in Hierarchy

### Step 1.4: Create SceneManager (Teleportation)

**IMPORTANT: This is a SEPARATE GameObject!**

1. Hierarchy → Create Empty → Name: `SceneManager`
2. Position: `0, 0, 0`
3. Select `SceneManager` → Add Component → Search: `SceneManager`
4. In Inspector, configure SceneManager component:
   - **sceneNames** → Array Size: `2`
   - Element 0: `Lobby`
   - Element 1: `Arena`

### Step 1.5: Add PropHuntGameManager to Modules

**IMPORTANT:** PropHuntGameManager is also a Module, so it goes with the others!

1. Select `PropHuntModules` GameObject
2. Add Component → `PropHuntGameManager`
3. *We'll wire references later in Part 6*

---

## Part 2: Create Game World (5-7 min)

### Step 2.1: Ground Plane

1. Hierarchy → 3D Object → **Plane** → Name: `GroundPlane`
2. Position: `50, -0.1, 0`
3. Scale: `20, 1, 10`

### Step 2.2: Lobby Area Marker (Optional visual reference)

1. Create Empty → Name: `LobbyArea`
2. Position: `0, 0, 0`
3. *(Just for organization - players will spawn here)*

### Step 2.3: Arena Area Marker (Optional visual reference)

1. Create Empty → Name: `ArenaArea`
2. Position: `100, 0, 0`
3. *(Props and zones will be here)*

---

## Part 3: Create Spawn Points (1 min)

### Lobby Spawn

1. Create Empty → Name: `LobbySpawn`
2. Position: `0, 0, 0`
3. Rotation: `0, 90, 0`
4. Tag → **Add Tag** → Type: `SpawnPoint` → Save
5. Set Tag: `SpawnPoint`

### Arena Spawn

1. Create Empty → Name: `ArenaSpawn`
2. Position: `100, 0, 0`
3. Rotation: `0, -90, 0`
4. Set Tag: `SpawnPoint`

### Organize Spawns

1. Create Empty → Name: `SpawnPoints`
2. Drag `LobbySpawn` and `ArenaSpawn` into `SpawnPoints`

---

## Part 4: Create Zone Volumes (3 min)

Zones give props score multipliers based on hiding location.

### Create Zone Tag Types First

1. Inspector → Tag → **Add Tag**
2. Add these 3 tags:
   - `Zone_NearSpawn`
   - `Zone_Mid`
   - `Zone_Far`

### Zone 1: Near Spawn (1.5x multiplier - risky!)

1. Create Empty → Name: `Zone_NearSpawn`
2. Position: `95, 0, 0`
3. Add Component → **Box Collider**
4. Box Collider settings:
   - ✓ **Is Trigger**
   - Center: `0, 5, 0`
   - Size: `15, 10, 20`
5. Add Component → **ZoneVolume**
6. ZoneVolume settings:
   - Zone Name: `NearSpawn`
   - Zone Weight: `1.5`
7. Set Tag: `Zone_NearSpawn`

### Zone 2: Mid (1.0x multiplier - balanced)

1. Create Empty → Name: `Zone_Mid`
2. Position: `110, 0, 0`
3. Add Component → Box Collider
4. Box Collider:
   - ✓ Is Trigger
   - Center: `0, 5, 0`
   - Size: `20, 10, 20`
5. Add Component → ZoneVolume
6. ZoneVolume:
   - Zone Name: `Mid`
   - Zone Weight: `1.0`
7. Set Tag: `Zone_Mid`

### Zone 3: Far (0.6x multiplier - safe!)

1. Create Empty → Name: `Zone_Far`
2. Position: `130, 0, 0`
3. Add Component → Box Collider
4. Box Collider:
   - ✓ Is Trigger
   - Center: `0, 5, 0`
   - Size: `15, 10, 20`
5. Add Component → ZoneVolume
6. ZoneVolume:
   - Zone Name: `Far`
   - Zone Weight: `0.6`
7. Set Tag: `Zone_Far`

### Organize Zones

1. Create Empty → Name: `Zones`
2. Drag all 3 zone GameObjects into `Zones`

---

## Part 5: Create Possessable Props (3 min)

Props are objects that players can disguise as during Hide phase.

### Create Possessable Tag First

1. Inspector → Tag → Add Tag → Type: `Possessable` → Save

### Prop 1: Cube

1. 3D Object → **Cube** → Name: `Prop_Cube_1`
2. Position: `95, 0.5, 5`
3. Scale: `1, 1, 1`
4. Add Component → **Possessable**
5. Create child object:
   - Right-click `Prop_Cube_1` → Create Empty → Name: `HitPoint`
   - Position: `0, 0, 0` (local)
6. Wire Possessable references:
   - Drag `HitPoint` → Possessable → **Hit Point** field
   - Drag `Box Collider` → Possessable → **Main Collider** field
7. Set Tag: `Possessable`

### Prop 2: Sphere

1. 3D Object → Sphere → Name: `Prop_Sphere_1`
2. Position: `100, 0.5, -3`
3. Scale: `1.2, 1.2, 1.2`
4. Add Component → Possessable
5. Create child: HitPoint
6. Wire references:
   - HitPoint → Possessable → Hit Point
   - Sphere Collider → Possessable → Main Collider
7. Set Tag: Possessable

### Prop 3: Capsule

1. 3D Object → Capsule → Name: `Prop_Capsule_1`
2. Position: `110, 1, 2`
3. Scale: `0.8, 0.8, 0.8`
4. Add Component → Possessable
5. Create child: HitPoint
6. Wire references
7. Set Tag: Possessable

### Prop 4: Flat Cube

1. 3D Object → Cube → Name: `Prop_Cube_2`
2. Position: `120, 0.5, -5`
3. Scale: `1.5, 0.5, 1.5` (flat table-like)
4. Add Component → Possessable
5. Create child: HitPoint
6. Wire references
7. Set Tag: Possessable

### Prop 5: Cylinder

1. 3D Object → Cylinder → Name: `Prop_Cylinder_1`
2. Position: `130, 0.5, 3`
3. Scale: `1, 1.5, 1`
4. Add Component → Possessable
5. Create child: HitPoint
6. Wire references
7. Set Tag: Possessable

### Organize Props

1. Create Empty → Name: `Possessables`
2. Drag all 5 props into `Possessables`

---

## Part 6: Wire Game Manager References (1 min)

Now connect everything to the Game Manager.

1. Select `PropHuntModules` GameObject
2. Scroll down in Inspector to find **PropHuntGameManager** component
3. Wire these fields:
   - **Lobby Spawn** → Drag `LobbySpawn` GameObject here
   - **Arena Spawn** → Drag `ArenaSpawn` GameObject here
   - **Possessables Parent** → Drag `Possessables` GameObject here

**Note:** PropHuntGameManager is on the same GameObject as the other modules!

---

## Part 7: Add Validation Test (Optional - 1 min)

This script tests that all modules loaded correctly.

1. Create Empty → Name: `ValidationTest`
2. Add Component → **ValidationTest**
3. *Don't press Play yet - we'll test in Part 8*

---

## Part 8: Test Everything (2 min)

### First Test: Module Check

1. Press **Play** button
2. Open **Console** (Ctrl/Cmd + Shift + C)
3. Look for these messages:

**✅ Expected:**
```
[PropHunt] GM Started
[PropHunt] CFG H=35s U=240s E=15s P=2
[PropHunt] LOBBY
```

**❌ If you see errors:**
- "module is not registered" → Go back to Part 1, make sure all modules are added
- "nil value" errors → Check Part 6, make sure references are wired

### Second Test: Validation Script (If you added it)

Look for:
```
[ValidationTest] ✓✓✓ ALL TESTS PASSED! ✓✓✓
[ValidationTest] PropHunt V1 integration is working correctly!
```

### Stop Play Mode

Press Stop button or Ctrl/Cmd + P

---

## Part 9: Save Your Scene (30 sec)

1. File → Save Scene As...
2. Name: `PropHunt_Main`
3. Location: `Assets/PropHunt/Scenes/PropHunt_Main.unity`
4. Click **Save**

---

## ✅ Complete Setup Checklist

### Modules & Systems
- [ ] PropHuntModules GameObject with 7 core modules + devx_tweens
- [ ] SceneManager GameObject with SceneManager component
- [ ] PropHuntGameManager GameObject

### World Structure
- [ ] Ground plane
- [ ] LobbySpawn + ArenaSpawn with SpawnPoint tag
- [ ] 3 Zone volumes (NearSpawn, Mid, Far) with ZoneVolume components
- [ ] 5 Possessable props with Possessable components + HitPoint children

### Tags Created
- [ ] SpawnPoint
- [ ] Possessable
- [ ] Zone_NearSpawn
- [ ] Zone_Mid
- [ ] Zone_Far

### Wiring
- [ ] Game Manager → Lobby Spawn reference
- [ ] Game Manager → Arena Spawn reference
- [ ] Game Manager → Possessables Parent reference
- [ ] Each Prop → HitPoint child + MainCollider reference

### Testing
- [ ] Play mode - no "module is not registered" errors
- [ ] Console shows "[PropHunt] GM Started"
- [ ] ValidationTest passes (if added)
- [ ] Scene saved

---

## Your Final Hierarchy Should Look Like:

```
Hierarchy
├── PropHuntModules
│   ├── PropHuntConfig
│   ├── PropHuntPlayerManager
│   ├── PropHuntScoringSystem
│   ├── ZoneManager
│   ├── PropHuntTeleporter
│   ├── PropHuntVFXManager
│   ├── PropHuntUIManager
│   ├── PropHuntGameManager ← Also a module!
│   └── devx_tweens
├── SceneManager
│   └── SceneManager (component)
├── GroundPlane
├── SpawnPoints
│   ├── LobbySpawn
│   └── ArenaSpawn
├── Zones
│   ├── Zone_NearSpawn (BoxCollider + ZoneVolume)
│   ├── Zone_Mid (BoxCollider + ZoneVolume)
│   └── Zone_Far (BoxCollider + ZoneVolume)
├── Possessables
│   ├── Prop_Cube_1 (Possessable + HitPoint child)
│   ├── Prop_Sphere_1 (Possessable + HitPoint child)
│   ├── Prop_Capsule_1 (Possessable + HitPoint child)
│   ├── Prop_Cube_2 (Possessable + HitPoint child)
│   └── Prop_Cylinder_1 (Possessable + HitPoint child)
└── ValidationTest (optional)
```

---

## Next Steps

Once your scene is set up:

1. **Test Gameplay:**
   - Press Play
   - Scene should initialize without errors
   - State machine should start in LOBBY

2. **Add UI (Optional):**
   - HUD for timer/state display
   - Ready button for lobby
   - Recap screen for end-of-round

3. **Add More Props:**
   - Duplicate existing props
   - Place them in different zones
   - Vary sizes for gameplay variety

4. **Customize Visuals:**
   - Add materials to props
   - Add lighting
   - Add arena decorations

5. **Multiplayer Test:**
   - Publish to Highrise platform
   - Test with 2+ players
   - Verify ready-up, role assignment, scoring

---

## Quick Reference: Copy-Paste Values

**Positions:**
```
GroundPlane: 50, -0.1, 0
LobbySpawn: 0, 0, 0
ArenaSpawn: 100, 0, 0
Zone_NearSpawn: 95, 0, 0
Zone_Mid: 110, 0, 0
Zone_Far: 130, 0, 0
Prop_Cube_1: 95, 0.5, 5
Prop_Sphere_1: 100, 0.5, -3
Prop_Capsule_1: 110, 1, 2
Prop_Cube_2: 120, 0.5, -5
Prop_Cylinder_1: 130, 0.5, 3
```

**Zone Collider Sizes:**
```
All zones: Center (0, 5, 0)
NearSpawn: Size (15, 10, 20)
Mid: Size (20, 10, 20)
Far: Size (15, 10, 20)
```

**Zone Weights:**
```
NearSpawn: 1.5 (risky - close to spawn)
Mid: 1.0 (balanced)
Far: 0.6 (safe - far from spawn)
```

---

## Troubleshooting

### "module 'PropHuntConfig' is not registered"
→ Part 1.2: Make sure PropHuntConfig is added to PropHuntModules GameObject

### "module 'devx_tweens' is not registered"
→ Part 1.3: Drag devx_tweens.lua onto PropHuntModules

### "module 'SceneManager' is not registered"
→ Part 1.4: Create separate SceneManager GameObject with SceneManager component

### No props showing up in game
→ Part 6: Wire Possessables Parent reference to Game Manager

### Zones not detecting players
→ Part 4: Make sure BoxCollider "Is Trigger" is checked and ZoneVolume component is added

### Can't find Possessable component
→ Edit any .lua file, save, wait 30s for Unity to regenerate C# wrappers

### "module 'PropHuntGameManager' is not registered"
→ Part 1.5: Make sure PropHuntGameManager is added to PropHuntModules GameObject (it's also a Module!)

### "failed to load scene 'Lobby'" (SceneManager warning)
→ **This is EXPECTED and safe to ignore**
→ Scene Teleporter looks for separate Unity scenes, but we're using one scene with two areas
→ Teleportation will still work by moving players to different world positions
→ You can ignore this warning during V1 testing

---

**Status:** ☐ Complete | **Time:** _____ min | **Errors:** _____

**You're ready to play PropHunt!** 🎮
