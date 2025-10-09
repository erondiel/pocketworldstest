# Module Registration Fix

## The Problem

You're seeing these errors:
```
module 'Modules.PropHuntVFXManager' is not registered in the scene or world
module 'Modules.PropHuntScoringSystem' is not registered in the scene or world
```

**Cause:** Highrise requires all Lua modules to be attached to GameObjects in the scene before they can be imported with `require()`.

---

## Quick Fix (2 minutes)

### Step 1: Create Module Manager GameObject

1. In Unity Hierarchy → Right-click → Create Empty
2. Name it: `PropHuntModules`
3. Position: `X: 0, Y: 0, Z: 0`

### Step 2: Add All Module Scripts

With `PropHuntModules` selected, click **Add Component** and add these scripts **one by one**:

1. Add Component → Search: `PropHuntConfig` → Add ⚠️ **CRITICAL - Add this first!**
2. Add Component → Search: `PropHuntScoringSystem` → Add
3. Add Component → Search: `PropHuntVFXManager` → Add
4. Add Component → Search: `ZoneManager` → Add
5. Add Component → Search: `PropHuntTeleporter` → Add
6. Add Component → Search: `PropHuntPlayerManager` → Add
7. Add Component → Search: `PropHuntUIManager` → Add

### Step 2b: Add DevBasics Tweens (if available)

If you have DevBasics Toolkit installed:

1. Navigate to: `Assets/Downloads/DevBasics Toolkit/Scripts/Shared/`
2. Find `devx_tweens.lua`
3. Drag it onto the `PropHuntModules` GameObject (or add as component)

**If you DON'T have DevBasics Toolkit:**
- VFX animations will be disabled (placeholder logs only)
- Game will still work, just without visual effects
- You can install it later from Highrise asset library

### Step 2c: Add Scene Teleporter (if available)

If you have Scene Teleporter asset installed:

1. Navigate to: `Assets/Downloads/Scene Teleporter/Scripts/`
2. Find `SceneManager.lua`
3. Create a separate GameObject named `SceneManager`
4. Add the `SceneManager` component to it
5. Configure scene names: `["Lobby", "Arena"]`

**If you DON'T have Scene Teleporter:**
- Teleportation between Lobby/Arena will be disabled
- Players will spawn in place
- You can install it later from Highrise asset library

### Step 3: Verify

Press Play and check the Console. The module errors should be gone.

---

## Why This Happens

In Highrise Lua:
- **Modules** (scripts with `--!Type(Module)`) must exist as components in the scene
- The `require()` function searches for these components
- If not found, you get "module is not registered" errors

Think of it like this:
- ❌ **Wrong:** Create `.lua` file → `require()` it → Works
- ✅ **Correct:** Create `.lua` file → Attach to GameObject → `require()` it → Works

---

## Alternative: Add to Existing GameObject

Instead of creating a new `PropHuntModules` GameObject, you can add all modules to your existing `PropHuntSceneManager`:

1. Select `PropHuntSceneManager`
2. Add all 6 module components to it

Both approaches work - it's just organizational preference.

---

## What About Non-Module Scripts?

Scripts with `--!Type(Server)` or `--!Type(Client)` don't need to be registered this way - they're standalone components.

Only **Module** type scripts need scene registration.

---

## Module List Reference

All PropHunt modules that need registration:

| Module Script | Location | Required? |
|---------------|----------|-----------|
| **PropHuntConfig** | `Assets/PropHunt/Scripts/` | ✅ **REQUIRED** |
| PropHuntScoringSystem | `Assets/PropHunt/Scripts/Modules/` | ✅ Required |
| PropHuntVFXManager | `Assets/PropHunt/Scripts/Modules/` | ✅ Required |
| ZoneManager | `Assets/PropHunt/Scripts/Modules/` | ✅ Required |
| PropHuntTeleporter | `Assets/PropHunt/Scripts/Modules/` | ✅ Required |
| PropHuntPlayerManager | `Assets/PropHunt/Scripts/` | ✅ Required |
| PropHuntUIManager | `Assets/PropHunt/Scripts/Modules/` | ✅ Required |
| devx_tweens | `Assets/Downloads/DevBasics Toolkit/Scripts/Shared/` | ⚠️ Optional (VFX) |
| SceneManager | `Assets/Downloads/Scene Teleporter/Scripts/` | ⚠️ Optional (Teleport) |

---

## After Fixing

Once modules are registered, you should see:
```
[PropHunt] GM Started
[PropHunt] CFG H=35s U=240s E=15s P=2
[PropHunt] LOBBY->HIDING
```

No more "module is not registered" errors!
