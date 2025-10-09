# FINAL Module Setup - Complete & Verified

**Every file location verified. Follow this EXACTLY.**

---

## Setup Overview

You need **2 GameObjects**:
1. `PropHuntModules` - with 9 components
2. `SceneManager` - with 1 component

---

## Step 1: Create PropHuntModules GameObject

1. Hierarchy → Right-click → **Create Empty**
2. Name: `PropHuntModules`
3. Position: `0, 0, 0`

---

## Step 2: Add Components to PropHuntModules

With `PropHuntModules` selected, add these **9 components in order**:

### How to Add Each Component:
- Select `PropHuntModules` in Hierarchy
- Click **Add Component** in Inspector
- Search for the component name below
- Click to add

### The 9 Components:

#### 1. PropHuntConfig ⚠️ ADD FIRST
- [ ] Add Component → Search: `PropHuntConfig`
- **File:** `Assets/PropHunt/Scripts/PropHuntConfig.lua`

#### 2. PropHuntPlayerManager
- [ ] Add Component → Search: `PropHuntPlayerManager`
- **File:** `Assets/PropHunt/Scripts/Modules/PropHuntPlayerManager.lua`

#### 3. PropHuntScoringSystem
- [ ] Add Component → Search: `PropHuntScoringSystem`
- **File:** `Assets/PropHunt/Scripts/Modules/PropHuntScoringSystem.lua`

#### 4. ZoneManager
- [ ] Add Component → Search: `ZoneManager`
- **File:** `Assets/PropHunt/Scripts/Modules/ZoneManager.lua`

#### 5. PropHuntTeleporter
- [ ] Add Component → Search: `PropHuntTeleporter`
- **File:** `Assets/PropHunt/Scripts/Modules/PropHuntTeleporter.lua`

#### 6. PropHuntVFXManager
- [ ] Add Component → Search: `PropHuntVFXManager`
- **File:** `Assets/PropHunt/Scripts/Modules/PropHuntVFXManager.lua`

#### 7. PropHuntUIManager
- [ ] Add Component → Search: `PropHuntUIManager`
- **File:** `Assets/PropHunt/Scripts/Modules/PropHuntUIManager.lua`

#### 8. PropHuntGameManager
- [ ] Add Component → Search: `PropHuntGameManager`
- **File:** `Assets/PropHunt/Scripts/PropHuntGameManager.lua`

#### 9. devx_tweens (Drag & Drop Method)
- [ ] In Project window, navigate to: `Assets/Downloads/DevBasics Toolkit/Scripts/Shared/`
- [ ] Find file: `devx_tweens.lua`
- [ ] **Drag the file** onto `PropHuntModules` GameObject in Hierarchy
- **File:** `Assets/Downloads/DevBasics Toolkit/Scripts/Shared/devx_tweens.lua`

**Alternative for #9:** Add Component → Search: `devx_tweens` (if drag & drop doesn't work)

---

## Step 3: Verify PropHuntModules

Select `PropHuntModules` in Hierarchy. In Inspector, you should see:

```
Transform
PropHuntConfig (Script)
PropHuntPlayerManager (Script)
PropHuntScoringSystem (Script)
ZoneManager (Script)
PropHuntTeleporter (Script)
PropHuntVFXManager (Script)
PropHuntUIManager (Script)
PropHuntGameManager (Script)
devx_tweens (Script)
```

**Count: 9 scripts + Transform = 10 total components**

---

## Step 4: Create SceneManager GameObject

**IMPORTANT: This is a SEPARATE GameObject!**

1. Hierarchy → Right-click → **Create Empty**
2. Name: `SceneManager`
3. Position: `0, 0, 0`

---

## Step 5: Add SceneManager Component

1. Select `SceneManager` GameObject
2. Click **Add Component**
3. Search: `SceneManager`
4. Click to add
- **File:** `Assets/Downloads/Scene Teleporter/Scripts/SceneManager.lua`

---

## Step 6: Configure SceneManager

With `SceneManager` selected, find the **SceneManager** component in Inspector:

1. **sceneNames** → Click dropdown
2. Set **Size:** `2`
3. **Element 0:** Type `Lobby`
4. **Element 1:** Type `Arena`

---

## Step 7: Test - Press Play

1. Press **Play** button in Unity
2. Open **Console** (Ctrl/Cmd + Shift + C)

### ✅ SUCCESS - You Should See:

```
[PropHunt] GM Started
[PropHunt] CFG H=35s U=240s E=15s P=2
[PropHunt] LOBBY
```

You may also see:
```
[SceneManager] failed to load scene `Lobby`
```
**This warning is OK - ignore it.** We're using a single scene with two areas.

### ❌ FAILURE - If You See:

| Error Message | What's Missing | Fix |
|---------------|----------------|-----|
| `module 'PropHuntConfig' is not registered` | PropHuntConfig component | Go to Step 2 #1 |
| `module 'PropHuntPlayerManager' is not registered` | PropHuntPlayerManager component | Go to Step 2 #2 |
| `module 'Modules.PropHuntScoringSystem' is not registered` | PropHuntScoringSystem component | Go to Step 2 #3 |
| `module 'Modules.ZoneManager' is not registered` | ZoneManager component | Go to Step 2 #4 |
| `module 'Modules.PropHuntTeleporter' is not registered` | PropHuntTeleporter component | Go to Step 2 #5 |
| `module 'Modules.PropHuntVFXManager' is not registered` | PropHuntVFXManager component | Go to Step 2 #6 |
| `module 'PropHuntUIManager' is not registered` | PropHuntUIManager component | Go to Step 2 #7 |
| `module 'PropHuntGameManager' is not registered` | PropHuntGameManager component | Go to Step 2 #8 |
| `module 'devx_tweens' is not registered` | devx_tweens component | Go to Step 2 #9 |
| `module 'SceneManager' is not registered` | SceneManager component | Go to Step 5 |

---

## Troubleshooting

### Component doesn't appear in Add Component search

**Problem:** You search for "PropHuntConfig" but nothing appears.

**Solution:**
1. Edit ANY .lua file in your project (add a space somewhere)
2. Save the file (Ctrl/Cmd + S)
3. Return to Unity
4. Wait 30 seconds for Highrise to regenerate C# wrappers
5. Try Add Component search again

### Can't drag devx_tweens onto GameObject

**Problem:** Drag & drop doesn't seem to work.

**Solution:**
1. Select `PropHuntModules`
2. Click **Add Component**
3. Search: `devx_tweens`
4. Click to add

### Still getting "module not registered" after adding everything

**Problem:** All components are added but still getting errors.

**Solution:**
1. Stop Play mode
2. File → Save Scene (Ctrl/Cmd + S)
3. File → Save Project
4. Press Play again
5. If still failing, close Unity and reopen

---

## What Happens Next?

Once modules are working (no errors in console), you can proceed to scene setup:

1. **Create Zones** (3 zone volumes)
2. **Create Spawns** (Lobby + Arena spawns)
3. **Create Props** (5+ possessable props)
4. **Wire References** (connect everything to GameManager)

See `UNITY_SCENE_FROM_SCRATCH.md` for detailed scene setup instructions.

---

## Quick Verification Command

**Check your Inspector matches this:**

### PropHuntModules GameObject:
- Transform
- 9 Lua script components

### SceneManager GameObject:
- Transform
- 1 SceneManager component (configured with Lobby/Arena)

**Total GameObjects needed at this stage: 2**

---

## File Locations (For Reference)

All files verified to exist:

```
Assets/PropHunt/Scripts/
├── PropHuntConfig.lua
├── PropHuntGameManager.lua
└── Modules/
    ├── PropHuntPlayerManager.lua
    ├── PropHuntScoringSystem.lua
    ├── ZoneManager.lua
    ├── PropHuntTeleporter.lua
    ├── PropHuntVFXManager.lua
    └── PropHuntUIManager.lua

Assets/Downloads/
├── DevBasics Toolkit/Scripts/Shared/
│   └── devx_tweens.lua
└── Scene Teleporter/Scripts/
    └── SceneManager.lua
```

---

**Status:** ☐ PropHuntModules created | ☐ 9 components added | ☐ SceneManager created | ☐ No errors in Console

**Once you see "[PropHunt] GM Started" with no "module not registered" errors, you're ready for scene setup!**
