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

1. Add Component → Search: `PropHuntScoringSystem` → Add
2. Add Component → Search: `PropHuntVFXManager` → Add
3. Add Component → Search: `ZoneManager` → Add
4. Add Component → Search: `PropHuntTeleporter` → Add
5. Add Component → Search: `PropHuntPlayerManager` → Add
6. Add Component → Search: `PropHuntUIManager` → Add

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

| Module Script | Location |
|---------------|----------|
| PropHuntScoringSystem | `Assets/PropHunt/Scripts/Modules/` |
| PropHuntVFXManager | `Assets/PropHunt/Scripts/Modules/` |
| ZoneManager | `Assets/PropHunt/Scripts/Modules/` |
| PropHuntTeleporter | `Assets/PropHunt/Scripts/Modules/` |
| PropHuntPlayerManager | `Assets/PropHunt/Scripts/` |
| PropHuntUIManager | `Assets/PropHunt/Scripts/Modules/` |

---

## After Fixing

Once modules are registered, you should see:
```
[PropHunt] GM Started
[PropHunt] CFG H=35s U=240s E=15s P=2
[PropHunt] LOBBY->HIDING
```

No more "module is not registered" errors!
