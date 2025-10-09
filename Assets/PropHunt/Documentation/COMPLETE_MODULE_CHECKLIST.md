# Complete Module Registration Checklist - FINAL

**Use this to verify you have EVERYTHING needed. Check off each item as you add it.**

---

## GameObject 1: PropHuntModules

Create empty GameObject named `PropHuntModules` at position (0, 0, 0).

Then add these **9 components** (in this exact order):

### Core Modules (Add to PropHuntModules GameObject)

- [ ] 1. **PropHuntConfig** ⚠️ ADD FIRST
- [ ] 2. **PropHuntPlayerManager**
- [ ] 3. **PropHuntScoringSystem**
- [ ] 4. **ZoneManager**
- [ ] 5. **PropHuntTeleporter**
- [ ] 6. **PropHuntVFXManager**
- [ ] 7. **PropHuntUIManager**
- [ ] 8. **PropHuntGameManager** ← Don't forget this one!
- [ ] 9. **devx_tweens** (drag from `Assets/Downloads/DevBasics Toolkit/Scripts/Shared/devx_tweens.lua`)

**How to verify:** Select PropHuntModules in Hierarchy → Inspector should show all 9 components listed above

---

## GameObject 2: SceneManager

Create **separate** empty GameObject named `SceneManager` at position (0, 0, 0).

- [ ] Add component: **SceneManager** (from Scene Teleporter asset)
- [ ] Configure SceneManager:
  - sceneNames → Size: 2
  - Element 0: `Lobby`
  - Element 1: `Arena`

**How to verify:** Select SceneManager in Hierarchy → Inspector should show SceneManager component with 2 scene names

---

## Verification Test

Once you've added ALL modules above, press Play and check Console:

### ✅ Expected Output (Good):
```
[PropHunt] GM Started
[PropHunt] CFG H=35s U=240s E=15s P=2
[PropHunt] LOBBY
[SceneManager] failed to load scene `Lobby` ← This warning is OK, ignore it
```

### ❌ If You See These Errors (Bad):

| Error | Missing Module | Location |
|-------|---------------|----------|
| `module 'PropHuntConfig' is not registered` | PropHuntConfig | PropHuntModules |
| `module 'PropHuntPlayerManager' is not registered` | PropHuntPlayerManager | PropHuntModules |
| `module 'PropHuntScoringSystem' is not registered` | PropHuntScoringSystem | PropHuntModules |
| `module 'Modules.ZoneManager' is not registered` | ZoneManager | PropHuntModules |
| `module 'Modules.PropHuntTeleporter' is not registered` | PropHuntTeleporter | PropHuntModules |
| `module 'Modules.PropHuntVFXManager' is not registered` | PropHuntVFXManager | PropHuntModules |
| `module 'PropHuntUIManager' is not registered` | PropHuntUIManager | PropHuntModules |
| `module 'PropHuntGameManager' is not registered` | PropHuntGameManager | PropHuntModules |
| `module 'devx_tweens' is not registered` | devx_tweens | PropHuntModules |
| `module 'SceneManager' is not registered` | SceneManager | SceneManager GameObject |

---

## Quick Debug: List All Components

**To verify your setup:**

1. Select `PropHuntModules` in Hierarchy
2. In Inspector, you should see these components (in addition to Transform):
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

3. Select `SceneManager` in Hierarchy
4. In Inspector, you should see:
   ```
   Transform
   SceneManager (Script)
     sceneNames
       Size: 2
       Element 0: Lobby
       Element 1: Arena
   ```

---

## File Locations Reference

If you can't find a component in Add Component menu:

| Component | File Path |
|-----------|-----------|
| PropHuntConfig | `Assets/PropHunt/Scripts/PropHuntConfig.lua` |
| PropHuntPlayerManager | `Assets/PropHunt/Scripts/PropHuntPlayerManager.lua` |
| PropHuntScoringSystem | `Assets/PropHunt/Scripts/Modules/PropHuntScoringSystem.lua` |
| ZoneManager | `Assets/PropHunt/Scripts/Modules/ZoneManager.lua` |
| PropHuntTeleporter | `Assets/PropHunt/Scripts/Modules/PropHuntTeleporter.lua` |
| PropHuntVFXManager | `Assets/PropHunt/Scripts/Modules/PropHuntVFXManager.lua` |
| PropHuntUIManager | `Assets/PropHunt/Scripts/Modules/PropHuntUIManager.lua` |
| PropHuntGameManager | `Assets/PropHunt/Scripts/PropHuntGameManager.lua` |
| devx_tweens | `Assets/Downloads/DevBasics Toolkit/Scripts/Shared/devx_tweens.lua` |
| SceneManager | `Assets/Downloads/Scene Teleporter/Scripts/SceneManager.lua` |

**If component doesn't appear in Add Component search:**
1. Edit any .lua file in the project
2. Add a space, then save
3. Return to Unity
4. Wait 30 seconds for C# wrapper regeneration
5. Try searching again

---

## Common Mistakes

### ❌ Mistake 1: Creating separate GameObject for PropHuntGameManager
**Wrong:** Creating GameObject named "PropHuntGameManager" with component
**Right:** Adding PropHuntGameManager component to PropHuntModules GameObject

### ❌ Mistake 2: Forgetting devx_tweens
**Wrong:** Only adding the 8 Lua modules
**Right:** Adding devx_tweens as 9th component (it's required for VFX)

### ❌ Mistake 3: Adding SceneManager to PropHuntModules
**Wrong:** Putting SceneManager component on PropHuntModules
**Right:** Creating SEPARATE GameObject called "SceneManager" with SceneManager component

### ❌ Mistake 4: Not configuring SceneManager scene names
**Wrong:** Leaving sceneNames array empty or size 0
**Right:** Setting size to 2 with "Lobby" and "Arena"

---

## After Modules Are Working

Once you have NO "module is not registered" errors, you can proceed with:

1. **Create Zones** - 3 zone volumes (NearSpawn, Mid, Far)
2. **Create Spawns** - LobbySpawn and ArenaSpawn GameObjects
3. **Create Props** - 5+ Possessable props
4. **Wire References** - Connect spawns and props to GameManager

See `UNITY_SCENE_FROM_SCRATCH.md` for detailed instructions.

---

## Still Getting Errors?

**Copy and paste your EXACT error messages so I can help debug.**

Include:
- Full error text
- Which GameObject you're working on
- Screenshot of Inspector showing components (optional but helpful)

---

**Status:** ☐ All modules added | ☐ No errors in Console | ☐ Ready for scene setup
