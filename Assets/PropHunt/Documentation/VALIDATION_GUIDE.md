# PropHunt V1 Integration Validation Guide

This guide will help you validate that all the integration work is functioning correctly.

## Quick Validation (5 minutes)

### Step 1: Unity Compilation Check

1. Open Unity project
2. Wait for scripts to compile
3. Check Console for errors

**Expected Result:** ✅ No compilation errors

**Common Issues:**
- Missing DevBasics Tweens → See "Missing Dependencies" section below
- "Module not found" errors → Check file paths match exactly
- C# generation errors → Wait 30s for Highrise SDK to regenerate wrappers

### Step 2: Run Validation Test Script

1. In Unity Hierarchy, create empty GameObject named "ValidationTest"
2. Add Component → Search for "ValidationTest"
3. Attach the ValidationTest.lua script
4. Enter Play mode
5. Check Console for validation results

**Expected Result:** ✅ All 6 tests pass
```
[ValidationTest] ✓✓✓ ALL TESTS PASSED! ✓✓✓
[ValidationTest] PropHunt V1 integration is working correctly!
```

### Step 3: Manual Gameplay Test

1. Enter Play mode
2. Open Console (Ctrl/Cmd + Shift + C)
3. Look for PropHunt log messages:
   - `[PropHunt] GM Started`
   - `[PropHunt] CFG H=35s U=240s E=15s P=2`
   - State transition logs

**Expected Result:** ✅ Game manager starts, state machine runs

---

## Detailed Validation Checklist

### ✅ Module Loading (Phase 1)

Test each module loads without errors:

- [ ] **PropHuntConfig.lua** - All parameters accessible
- [ ] **PropHuntScoringSystem.lua** - Scoring functions callable
- [ ] **PropHuntTeleporter.lua** - Scene names configured
- [ ] **ZoneManager.lua** - Zone tracking works
- [ ] **PropHuntVFXManager.lua** - VFX functions exist
- [ ] **PropHuntGameManager.lua** - State machine initialized

**How to test:** Run ValidationTest.lua script (see Step 2 above)

### ✅ State Machine (Phase 2)

Test the game state flow:

1. Enter Play mode
2. Press Ready button (if visible)
3. Watch Console for state transitions:
   - `LOBBY -> HIDING`
   - `HIDING -> HUNTING`
   - `HUNTING -> ROUND_END`
   - `ROUND_END -> LOBBY`

**Expected Console Output:**
```
[PropHunt] LOBBY->HIDING
[PropHunt] HIDE 35s
[PropHunt] HIDING->HUNTING
[PropHunt] HUNT 240s
```

**To force state changes (debug):**
Open DebugCheats.lua and use force state commands

### ✅ Scoring System (Phase 3)

Test scoring integration:

1. Enter Play mode
2. Wait for HUNTING phase
3. Check Console for tick scoring:
   - `[ScoringSystem] Prop tick score awarded...`
4. Check scores update every 5 seconds

**Expected:** Zone-based scoring logs appear during Hunt phase

### ✅ Network Synchronization (Phase 4)

Test client-server communication:

1. Enter Play mode with 2+ players (multiplayer sim or published)
2. Ready up on both clients
3. Verify both clients see:
   - Same game state
   - Same timer countdown
   - Role assignments

**Expected:** All clients synchronized

### ✅ Hunter Tagging (Phase 5)

**Note:** Requires Unity scene with character setup

1. Enter HUNTING phase as hunter
2. Tap on screen
3. Check Console for:
   - `[HunterTagSystem] Hit @ (x, y, z)`
   - Distance validation messages
   - VFX trigger logs

**Expected:**
- Raycast from player body position
- Distance validation at 4.0m
- Cooldown 0.5s enforced
- Tag miss logs if no target

### ✅ Prop Possession (Phase 6)

**Note:** Requires Unity scene with Possessable props

1. Enter HIDING phase as prop
2. Tap on a prop
3. Confirm possession
4. Try to possess another prop

**Expected:**
- First possession succeeds with VFX logs
- Second possession rejected (One-Prop Rule)
- `[PropDisguiseSystem] Already possessed a prop this round`

### ✅ Zone Detection (Phase 7)

**Note:** Requires Unity scene with ZoneVolume GameObjects

1. Create zone volumes in scene (see Unity Setup below)
2. Enter Play mode
3. Move player through zones
4. Check Console for:
   - `[ZoneVolume] Player entered zone...`
   - `[ZoneManager] Zone weight updated...`

**Expected:** Zone tracking updates as player moves

---

## Missing Dependencies Check

### DevBasics Tweens Library

The VFXManager requires DevBasics Tweens. Check if it exists:

```bash
ls /Users/andres.camacho/Development/Personal/pocketworldstest/Assets/Downloads/DevBasics\ Toolkit/Scripts/Shared/devx_tweens.lua
```

**If missing:**
1. VFX animations won't work (placeholder functions will log errors)
2. You can disable VFX calls temporarily or install DevBasics Toolkit

**Workaround:** Comment out VFXManager imports in:
- PropHuntGameManager.lua (line 14)
- HunterTagSystem.lua (line 10)
- PropDisguiseSystem.lua (line 9)

### Scene Teleporter Asset

Check if SceneManager exists:

```bash
ls /Users/andres.camacho/Development/Personal/pocketworldstest/Assets/Downloads/Scene\ Teleporter/Scripts/SceneManager.lua
```

**If missing:** Teleporter module will fail to load

---

## Unity Scene Setup (Required for Full Testing)

To test gameplay features, you need Unity scene elements:

### Minimal Setup (15 minutes)

1. **Create Zone Volumes:**
   ```
   Hierarchy → Create Empty → Name: "Zone_NearSpawn"
   Add Component: Box Collider (Is Trigger ✓)
   Add Component: ZoneVolume
   Set: zoneName = "NearSpawn", zoneWeight = 1.5
   Layer: CharacterTrigger
   ```
   Repeat for Mid (1.0) and Far (0.6)

2. **Create Spawn Points:**
   ```
   Hierarchy → Create Empty → Name: "LobbySpawn"
   Position: (0, 0, 0)

   Hierarchy → Create Empty → Name: "ArenaSpawn"
   Position: (1000, 0, 0) or separate area
   ```

3. **Create SceneManager:**
   ```
   Hierarchy → Create Empty → Name: "SceneManager"
   Add Component: SceneManager (from Scene Teleporter asset)
   Inspector: sceneNames array size = 2
     Element 0: "Lobby"
     Element 1: "Arena"
   ```

4. **Create Possessable Props:**
   ```
   Place any 3D objects in Arena area
   Add Component: Possessable
   Set: propId = unique name (e.g., "Chair01", "Table02")
   ```

---

## Common Issues & Solutions

### Issue: "Module not found: Modules.PropHuntScoringSystem"
**Solution:** Check file path is exactly:
```
Assets/PropHunt/Scripts/Modules/PropHuntScoringSystem.lua
```

### Issue: VFXManager errors about devx_tweens
**Solution:**
1. Check DevBasics Toolkit is in `/Assets/Downloads/`
2. Or comment out VFXManager imports temporarily

### Issue: No state transitions happening
**Solution:**
1. Check ValidationTest passes
2. Verify PlayerManager ready-up system works
3. Use DebugCheats to force states

### Issue: "attempt to call nil value" on scoring functions
**Solution:**
1. Check ScoringSystem.lua compiled without errors
2. Verify module exports functions (check file ends with function definitions)
3. Run ValidationTest to confirm module loads

### Issue: Teleporter doesn't move players
**Solution:**
1. Verify SceneManager GameObject exists in scene
2. Check scene names configured: ["Lobby", "Arena"]
3. Verify spawn points exist: LobbySpawn, ArenaSpawn GameObjects

---

## Success Criteria

All validation complete when:

- ✅ ValidationTest script shows "ALL TESTS PASSED"
- ✅ No compilation errors in Unity Console
- ✅ Game manager starts and transitions through states
- ✅ Scoring system awards points (visible in logs)
- ✅ Hunter tagging validates distance and cooldown
- ✅ Prop possession enforces One-Prop Rule
- ✅ Zones track player positions (if scene setup complete)
- ✅ Teleporter moves players between areas (if scene setup complete)

---

## Next Steps After Validation

Once validation passes:

1. **Unity Scene Polish** - Create proper arena layout with zones
2. **Particle Systems** - Replace VFX placeholders
3. **Custom Shaders** - Outline, dissolve, emissive effects
4. **Multiplayer Testing** - Test with 2+ players
5. **Balance Tuning** - Adjust scoring values based on gameplay

---

## Quick Commands

**Check all module files exist:**
```bash
find Assets/PropHunt/Scripts/Modules -name "*.lua" -type f
```

**Check for Lua syntax errors:**
```bash
luac -p Assets/PropHunt/Scripts/**/*.lua
```
(If you have lua installed)

**Force Unity script recompilation:**
1. Edit any .lua file
2. Save
3. Wait 10-30 seconds for C# regeneration

---

## Getting Help

If validation fails:

1. Check Console for specific error messages
2. Review this guide's "Common Issues" section
3. Check IMPLEMENTATION_PLAN.md for integration status
4. Review individual module documentation in `/Assets/PropHunt/Documentation/`

**Debug Mode:**
Set `_enableDebug = true` in PropHuntConfig.lua for verbose logging
