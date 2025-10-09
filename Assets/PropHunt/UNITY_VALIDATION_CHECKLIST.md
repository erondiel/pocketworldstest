# Unity Scene Validation Checklist

Use this checklist to verify your PropHunt Unity scene is set up correctly.

## ✅ Pre-Flight Check (Before Opening Unity)

- [x] All Lua scripts have been fixed with module exports
- [x] All module import paths corrected (no "Modules." prefix)
- [x] All function names match between GameManager and modules
- [x] VFXManager has all required phase transition functions

## 📋 Unity Scene Setup Checklist

### 1. PropHuntModules GameObject

**Location**: Root of scene hierarchy

**Required Components (in this order)**:
- [ ] PropHuntConfig
- [ ] PropHuntGameManager
- [ ] PropHuntPlayerManager
- [ ] PropHuntScoringSystem
- [ ] PropHuntTeleporter
- [ ] PropHuntVFXManager
- [ ] ZoneManager
- [ ] devx_tweens

**How to verify**:
1. Select PropHuntModules GameObject in Hierarchy
2. In Inspector, count components - should have exactly 8 Lua scripts
3. Check Console for "[ModuleName] registered" messages when entering Play mode

### 2. Teleporter Configuration

**On PropHuntModules GameObject**:
- [ ] PropHuntTeleporter component is present
- [ ] Lobby Spawn Position is set (Vector3 or Transform)
- [ ] Arena Spawn Position is set (Vector3 or Transform)

**How to verify**:
1. Select PropHuntModules
2. Find "Prop Hunt Teleporter" in Inspector
3. Verify both spawn positions have values (not 0,0,0 unless intentional)

### 3. Zone Volumes (Optional for V1, but recommended)

**For each zone area in your scene**:
- [ ] GameObject with BoxCollider (or other collider)
- [ ] Collider "Is Trigger" is ENABLED
- [ ] GameObject layer is "CharacterTrigger"
- [ ] ZoneVolume script attached
- [ ] zoneName set: "NearSpawn", "Mid", or "Far"
- [ ] zoneWeight set: 1.5 (Near), 1.0 (Mid), or 0.6 (Far)

**How to verify**:
1. Select each zone GameObject
2. Check "Is Trigger" checkbox is ticked
3. Verify layer in top of Inspector
4. Check ZoneVolume component fields are filled

### 4. Possessable Props (Optional for V1)

**For each prop object**:
- [ ] GameObject with Collider
- [ ] Possessable script attached
- [ ] MainCollider reference assigned
- [ ] HitPoint transform assigned (or null)

**How to verify**:
1. Select a prop GameObject
2. Verify Possessable component in Inspector
3. Check references are assigned (MainCollider required)

### 5. Client-Side Systems (HunterTagSystem, PropDisguiseSystem)

**Two options**:

**Option A: Attach to player character prefab**
- [ ] HunterTagSystem on player prefab
- [ ] PropDisguiseSystem on player prefab

**Option B: Scene singleton GameObjects**
- [ ] HunterTagSystem on GameObject in scene
- [ ] PropDisguiseSystem on GameObject in scene

**How to verify**:
1. Search Project for HunterTagSystem and PropDisguiseSystem
2. Check where they are attached (prefab vs scene)
3. Verify only ONE instance exists (no duplicates)

## 🧪 Testing Validation

### Phase 1: Module Loading Test

**Steps**:
1. Enter Play mode in Unity Editor
2. Check Console for module registration messages

**Expected Console Output**:
```
[PropHunt] PropHuntConfig loaded
[PlayerManager] Server tracking: [YourName]
[ZoneManager] Registered zone: NearSpawn (weight: 1.5)
[PropHunt] GameState: LOBBY
```

**If you see errors**:
- "module 'X' is not registered" → Module not attached to PropHuntModules GameObject
- "attempt to call a nil value" → Module missing exports (should be fixed now)
- "failed to load scene 'Lobby'" → IGNORE THIS (harmless, we use single scene)

### Phase 2: ValidationTest Run

**Steps**:
1. Create new GameObject in scene
2. Attach ValidationTest.lua script
3. Enter Play mode
4. Check Console for test results

**Expected Output**:
```
[ValidationTest] PropHunt V1 Integration Validation Test
[ValidationTest] [TEST 1] PropHuntConfig Module
[ValidationTest] ✓ Config values: Hide=35s, Hunt=240s, TagRange=4.0m, Cooldown=0.5s
[ValidationTest] [TEST 2] Scoring System Module
[ValidationTest] ✓ Scoring initialized. Player1 score=X, Player2 score=Y
[ValidationTest] [TEST 3] Zone Manager Module
[ValidationTest] ✓ ZoneManager loaded. Default weight=1.0
[ValidationTest] [TEST 4] Teleporter Module
[ValidationTest] ✓ Teleporter loaded. Lobby=Lobby, Arena=Arena
[ValidationTest] [TEST 5] VFX Manager Module
[ValidationTest] ✓ VFXManager loaded. All placeholder VFX functions present
[ValidationTest] [TEST 6] Game Manager Module
[ValidationTest] ✓ GameManager loaded. Current state=LOBBY, Timer=0
[ValidationTest] ✓✓✓ ALL TESTS PASSED! ✓✓✓
```

**If tests fail**:
- Review which test failed
- Check the specific module mentioned
- Verify it's attached to PropHuntModules GameObject
- Verify it has proper exports (should be fixed now)

### Phase 3: Gameplay Test (Multi-Player Required)

**Requirements**:
- 2+ players connected (use Highrise multiplayer testing)
- PropHuntModules GameObject configured
- Teleporter spawn positions set

**Test Flow**:
1. Enter Play mode with 2+ players
2. Both players click "Ready" button
3. Verify state transitions: LOBBY → HIDING → HUNTING → ROUND_END → LOBBY
4. Verify console shows state changes and role assignments
5. Verify no "nil value" errors in Console

**Expected Behavior**:
- [x] Lobby countdown starts when 2+ players ready
- [x] Roles assigned at HIDING phase start
- [x] Players teleport to arena
- [x] Timer counts down correctly
- [x] State advances automatically
- [x] Scores update (check Console logs)

## ❌ Common Issues & Solutions

### Issue: "module 'X' is not registered"
**Solution**: Add missing module component to PropHuntModules GameObject

### Issue: "attempt to call a nil value"
**Solution**: This should be FIXED now. If you still see this, report which function/line number

### Issue: "failed to load scene 'Lobby'"
**Solution**: IGNORE - This is harmless. We use single scene with two areas.

### Issue: Players don't teleport
**Solution**: Check PropHuntTeleporter component has valid spawn positions set

### Issue: Zones not working
**Solution**:
1. Verify zone collider "Is Trigger" is enabled
2. Verify GameObject layer is "CharacterTrigger"
3. Enable debug logging on ZoneVolume component

### Issue: Ready button doesn't appear
**Solution**: This is a UI issue - check PropHuntUIManager and HUD setup

## 🎯 Minimum Viable Setup

To test core game loop with ZERO props/zones:

**Required**:
1. PropHuntModules GameObject with all 8 components
2. PropHuntTeleporter spawn positions configured
3. 2+ players connected

**Not Required**:
- Zone volumes (defaults to 1.0x weight)
- Possessable props (can test state machine without)
- Client systems (can test server logic only)

This minimal setup should allow you to verify:
- ✅ Module loading
- ✅ State transitions
- ✅ Role assignment
- ✅ Teleportation
- ✅ Scoring (basic)
- ✅ Timer system

## 📞 If Still Having Issues

If you've verified all items above and still have errors:

1. **Check exact error message** - Copy full error from Console
2. **Note the line number** - Error shows file:line
3. **Check which module** - Which script is failing?
4. **Verify module exports** - Open the .lua file, scroll to bottom, confirm `return { }` exists

All module exports have been added - if you see "attempt to call a nil value" errors, it means a function is being called that doesn't exist in the export table.

---

## ✅ Success Criteria

You'll know everything is working when:

1. ✅ No module registration errors in Console
2. ✅ ValidationTest shows "ALL TESTS PASSED"
3. ✅ Game advances through states: LOBBY → HIDING → HUNTING → ROUND_END
4. ✅ Console shows scoring updates every 5 seconds during HUNTING
5. ✅ No "nil value" errors at any point

**Once you see these, you're ready to add props, zones, and polish!**
