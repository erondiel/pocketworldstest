# Unity Module Setup Checklist

**Complete this checklist to fix all "module is not registered" errors**

Time: 3-5 minutes

---

## ☐ Step 1: Create Module Container (30 sec)

1. Hierarchy → Right-click → **Create Empty**
2. Name: `PropHuntModules`
3. Position: `0, 0, 0`

---

## ☐ Step 2: Add Required PropHunt Modules (2 min)

With `PropHuntModules` GameObject selected, add these components **in this order**:

### Core Modules (Must add ALL 7):

- [ ] 1. **PropHuntConfig** ⚠️ Add this FIRST! (Others depend on it)
- [ ] 2. PropHuntPlayerManager
- [ ] 3. PropHuntScoringSystem
- [ ] 4. ZoneManager
- [ ] 5. PropHuntTeleporter
- [ ] 6. PropHuntVFXManager
- [ ] 7. PropHuntUIManager

**How to add:**
- Select `PropHuntModules` → Inspector → **Add Component**
- Search for script name → Click to add
- Repeat for each module

---

## ☐ Step 3: Add External Dependencies (1 min)

### DevBasics Tweens (Required for VFX)

**Option A: Add via drag-and-drop (recommended)**
1. Navigate to: `Assets/Downloads/DevBasics Toolkit/Scripts/Shared/`
2. Find: `devx_tweens.lua`
3. Drag it onto `PropHuntModules` GameObject in Hierarchy

**Option B: Add as component**
1. Select `PropHuntModules`
2. Add Component → Search: `devx_tweens` → Add

✅ **File location:** `Assets/Downloads/DevBasics Toolkit/Scripts/Shared/devx_tweens.lua`

---

### Scene Teleporter (Required for Lobby↔Arena transitions)

**IMPORTANT:** This one goes on a SEPARATE GameObject!

1. Hierarchy → Create Empty → Name: `SceneManager`
2. Position: `0, 0, 0`
3. Select `SceneManager` → Add Component → Search: `SceneManager` → Add
4. In Inspector, configure SceneManager:
   - **Scene Names** array size: `2`
   - Element 0: `Lobby`
   - Element 1: `Arena`

✅ **File location:** `Assets/Downloads/Scene Teleporter/Scripts/SceneManager.lua`

---

## ☐ Step 4: Verify Setup (30 sec)

1. Press **Play** button
2. Open **Console** (Ctrl/Cmd + Shift + C)
3. Check for errors

**Expected result:**
```
[PropHunt] GM Started
[PropHunt] CFG H=35s U=240s E=15s P=2
```

**No more "module is not registered" errors!**

---

## Troubleshooting

### ❌ Still seeing "module 'PropHuntConfig' is not registered"
- Make sure you added **PropHuntConfig** to `PropHuntModules` GameObject
- Verify it appears in Inspector when `PropHuntModules` is selected
- PropHuntConfig must be added BEFORE other modules

### ❌ "module 'devx_tweens' is not registered"
- Add `devx_tweens.lua` to `PropHuntModules` GameObject
- File path: `Assets/Downloads/DevBasics Toolkit/Scripts/Shared/devx_tweens.lua`

### ❌ "module 'SceneManager' is not registered"
- Create separate `SceneManager` GameObject
- Add `SceneManager.lua` component to it
- Configure scene names: ["Lobby", "Arena"]

### ❌ Can't find module in Add Component search
- Edit any .lua file → Save → Return to Unity
- Wait 10-30 seconds for Highrise to regenerate C# wrappers
- Try searching again

### ❌ "attempt to index nil with 'GetCurrentState'"
- This means a module didn't load because a dependency is missing
- Go back through Steps 2-3 and verify all modules are added

---

## Final Hierarchy Structure

After completing all steps, your hierarchy should look like:

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
│   └── devx_tweens
├── SceneManager (separate GameObject)
│   └── SceneManager (component)
└── ... (your other scene objects)
```

---

## Next Steps After Module Setup

Once all modules are registered:

1. ✅ Continue with **QUICK_UNITY_SETUP.md** to create zones, spawns, and props
2. ✅ Run **ValidationTest.lua** to verify all systems work
3. ✅ Test gameplay in Play mode

---

## Quick Reference: All Required Modules

| # | Module | GameObject | Required? |
|---|--------|------------|-----------|
| 1 | PropHuntConfig | PropHuntModules | ✅ Yes |
| 2 | PropHuntPlayerManager | PropHuntModules | ✅ Yes |
| 3 | PropHuntScoringSystem | PropHuntModules | ✅ Yes |
| 4 | ZoneManager | PropHuntModules | ✅ Yes |
| 5 | PropHuntTeleporter | PropHuntModules | ✅ Yes |
| 6 | PropHuntVFXManager | PropHuntModules | ✅ Yes |
| 7 | PropHuntUIManager | PropHuntModules | ✅ Yes |
| 8 | devx_tweens | PropHuntModules | ✅ Yes (VFX) |
| 9 | SceneManager | SceneManager | ✅ Yes (Teleport) |

**Total:** 9 modules on 2 GameObjects

---

**Status:** ☐ Complete | **Errors:** ____ | **Time:** ____ min
