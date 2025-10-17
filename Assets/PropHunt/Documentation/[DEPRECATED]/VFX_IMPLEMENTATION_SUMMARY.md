# VFX System Implementation Summary

## Overview

The VFX system now uses a **SerializeField reference pattern** to find and spawn VFX prefabs. This approach avoids serialization issues with GameObjects while maintaining flexibility to change VFX prefabs in the Unity Inspector.

## Architecture Pattern

### Setup Structure

```
Hierarchy:
├── VFXPrefabs (parent GameObject)
│   ├── CFX3_ResurrectionLight_Circle (disabled by default) - PlayerVanishVFX
│   ├── [PropInfillVFX prefab] (disabled by default)
│   ├── [RejectionVFX prefab] (disabled by default)
│   ├── [TagHitVFX prefab] (disabled by default)
│   └── [TagMissVFX prefab] (disabled by default)
└── PropHuntModules (GameObject with VFXManager script)
```

### How It Works

**Step 1: Unity Inspector Assignment**
- Drag VFX GameObjects from VFXPrefabs parent to SerializeField slots in PropHuntModules
- VFXManager stores the reference (not the GameObject itself)

**Step 2: Runtime VFX Spawning**
1. VFXManager calls `SpawnVFX(prefabRef, position, duration, name)`
2. Gets GameObject name from SerializeField reference: `prefabRef.name`
3. Finds the actual GameObject in scene: `GameObject.Find(name)`
4. Moves GameObject to target position
5. Enables the GameObject: `SetActive(true)`
6. Schedules disable after duration: `Timer.After(duration, function() SetActive(false) end)`

**Benefits**:
- ✅ Avoids GameObject serialization issues (known problem with Highrise SDK)
- ✅ Allows changing VFX prefabs in Inspector without code changes
- ✅ Single instance per VFX type (efficient memory usage)
- ✅ VFX GameObjects are reused (enable/disable pattern)

## SerializeField References (5 Total)

Add these to `PropHuntModules` GameObject in Unity Inspector:

```lua
--!SerializeField
--!Tooltip("VFX prefab for player vanish effect")
local _playerVanishVFXPrefab : GameObject = nil

--!SerializeField
--!Tooltip("VFX prefab for prop infill effect")
local _propInfillVFXPrefab : GameObject = nil

--!SerializeField
--!Tooltip("VFX prefab for rejection effect")
local _rejectionVFXPrefab : GameObject = nil

--!SerializeField
--!Tooltip("VFX prefab for tag hit effect")
local _tagHitVFXPrefab : GameObject = nil

--!SerializeField
--!Tooltip("VFX prefab for tag miss effect")
local _tagMissVFXPrefab : GameObject = nil
```

## SpawnVFX Helper Function

**Signature**:
```lua
local function SpawnVFX(prefabRef, position, duration, vfxName)
```

**Parameters**:
- `prefabRef`: GameObject - SerializeField reference assigned in Inspector
- `position`: Vector3 - World position to spawn VFX
- `duration`: number - How long before disabling the VFX
- `vfxName`: string - Name for logging (e.g., "PlayerVanish")

**Returns**:
- GameObject - The spawned VFX instance (or nil if failed)

**Process**:
1. Validates prefab reference is assigned
2. Gets GameObject name: `prefabRef.name`
3. Finds GameObject in scene: `GameObject.Find(name)`
4. Moves to position: `transform.position = position`
5. Enables: `SetActive(true)`
6. Schedules disable: `Timer.After(duration, function() SetActive(false) end)`

**Error Handling**:
- Checks if prefabRef is nil → prints error, returns nil
- Checks if prefabRef.name is empty → prints error, returns nil
- Checks if GameObject not found → prints error, returns nil

## Updated VFX Functions

All 5 VFX functions now use the same pattern:

### 1. PlayerVanishVFX
```lua
function PlayerVanishVFX(position, playerCharacter)
    DebugVFX("PlayerVanishVFX at " .. tostring(position))

    -- Spawn VFX using SerializeField reference
    local vfxInstance = SpawnVFX(_playerVanishVFXPrefab, position, VFX_PLAYER_VANISH_DURATION, "PlayerVanish")

    -- Scale down player character (keep existing placeholder for now)
    if playerCharacter then
        ScalePulse(playerCharacter, 1.0, 0.0, VFX_PLAYER_VANISH_DURATION, "easeInQuad", false, false)
    end
end
```

### 2. PropInfillVFX
```lua
function PropInfillVFX(position, propObject)
    DebugVFX("PropInfillVFX at " .. tostring(position))

    -- Spawn VFX using SerializeField reference
    local vfxInstance = SpawnVFX(_propInfillVFXPrefab, position, VFX_PROP_INFILL_DURATION, "PropInfill")

    if propObject then
        -- Placeholder: Scale up prop from tiny to normal
        ScalePulse(propObject, 0.1, 1.0, VFX_PROP_INFILL_DURATION, "easeOutBack", false, false)
    end
end
```

### 3. RejectionVFX
```lua
function RejectionVFX(position, propObject)
    DebugVFX("RejectionVFX at " .. tostring(position))

    -- Spawn VFX using SerializeField reference
    local vfxInstance = SpawnVFX(_rejectionVFXPrefab, position, VFX_REJECTION_DURATION, "Rejection")

    if propObject then
        -- Placeholder: Quick shake effect
        [shake animation code]
    end
end
```

### 4. TagHitVFX
```lua
function TagHitVFX(position, propObject)
    DebugVFX("TagHitVFX at " .. tostring(position))

    -- Spawn VFX using SerializeField reference
    local vfxInstance = SpawnVFX(_tagHitVFXPrefab, position, VFX_TAG_HIT_DURATION, "TagHit")

    if propObject then
        -- Placeholder: Quick scale punch
        ScalePulse(propObject, 1.0, 0.9, VFX_TAG_HIT_DURATION * 0.5, "easeOutQuad", false, false)
    end
end
```

### 5. TagMissVFX
```lua
function TagMissVFX(position, normal)
    DebugVFX("TagMissVFX at " .. tostring(position))

    -- Spawn VFX using SerializeField reference
    local vfxInstance = SpawnVFX(_tagMissVFXPrefab, position, VFX_TAG_MISS_DURATION, "TagMiss")

    -- TODO: Rotate VFX to align with surface normal if provided
end
```

## Unity Setup Checklist

### Step 1: Create VFX Hierarchy
- [ ] Create empty GameObject named "VFXPrefabs" in scene root
- [ ] Add particle system GameObjects as children (disabled by default)
- [ ] Current: `CFX3_ResurrectionLight_Circle` for PlayerVanishVFX

### Step 2: Assign SerializeField References
- [ ] Select PropHuntModules GameObject
- [ ] In Inspector, find PropHuntVFXManager script
- [ ] Drag `CFX3_ResurrectionLight_Circle` to "Player Vanish VFX Prefab" slot
- [ ] Drag other VFX prefabs to their respective slots (when created)

### Step 3: Configure VFX Prefabs
- [ ] Ensure all VFX GameObjects are **disabled by default** (inactive checkbox)
- [ ] Configure particle systems to play on enable
- [ ] Set particle system "Stop Action" to "Disable" (auto-disable when done)
- [ ] Test duration matches code constants

## VFX Durations

Defined in `PropHuntVFXManager.lua`:

```lua
local VFX_PLAYER_VANISH_DURATION = 1.0   -- Player scale down when possessing
local VFX_PROP_INFILL_DURATION = 1.2     -- Prop scale up when possessed
local VFX_REJECTION_DURATION = 0.2       -- Brief red flash
local VFX_TAG_HIT_DURATION = 0.25        -- Compressed ring shock
local VFX_TAG_MISS_DURATION = 0.15       -- Dust poof
```

**Important**: Particle system durations should match or be slightly shorter than these values.

## Testing Procedure

### Test 1: PlayerVanishVFX
1. Start game, ready up with 2+ players
2. Enter HIDING phase as Prop
3. Click on a prop to possess it
4. **Expected**: Particle effect spawns at your position, plays for 1.0s
5. **Expected**: Your character scales down to 0
6. **Expected**: Console shows: `[VFX] PlayerVanish VFX spawned at...`

### Test 2: PropInfillVFX
1. Same as Test 1 (triggers immediately after PlayerVanishVFX)
2. **Expected**: Particle effect spawns at prop position, plays for 1.2s
3. **Expected**: Prop scales up from tiny to normal
4. **Expected**: Console shows: `[VFX] PropInfill VFX spawned at...`

### Test 3: RejectionVFX
1. Possess a prop as Prop player
2. Try to possess the same prop again (or a different prop)
3. **Expected**: Particle effect spawns at prop position, plays for 0.2s
4. **Expected**: Prop shakes left-right-center
5. **Expected**: Console shows: `[VFX] Rejection VFX spawned at...`

### Test 4: TagHitVFX (NOT YET CALLED)
1. Enter HUNTING phase as Hunter
2. Tap on a possessed prop
3. **Expected**: Particle effect spawns at prop position, plays for 0.25s
4. **Note**: This requires adding VFX call to PropPossessionSystem (see below)

### Test 5: TagMissVFX (NOT YET CALLED)
1. Enter HUNTING phase as Hunter
2. Tap on a non-possessed prop
3. **Expected**: Particle effect spawns at prop position, plays for 0.15s
4. **Note**: This requires adding VFX call to PropPossessionSystem (see below)

## Still TODO: Add Missing VFX Calls

### TagHitVFX - Add to PropPossessionSystem.lua

**Location**: Line ~950, after `GameManager.OnPlayerTagged()`

```lua
-- HIT: Valid tag on possessed prop
print("[PropPossessionSystem] SERVER: Hunter " .. hunter.name .. " successfully tagged prop: " .. propName .. " (player: " .. propPlayer.name .. ")")

-- Call GameManager's tag handler to process the tag (scoring, etc.)
GameManager.OnPlayerTagged(hunter, propPlayer)

-- NEW: Broadcast TagHitVFX to all clients
local tagHitVFXEvent = Event.new("PH_TagHitVFX")
local propGameObject = GameObject.Find(propName)
if propGameObject then
    tagHitVFXEvent:FireAllClients(propGameObject.transform.position, propName)
end

-- IMMEDIATELY restore the tagged player's avatar
print("[PropPossessionSystem] SERVER: Restoring avatar for tagged player: " .. propPlayer.name)
restoreAvatarCommand:FireAllClients(propPlayer.user.id)
```

**Client-Side Listener** (add to `PropPossessionSystem.lua:ClientStart`):

```lua
-- Listen for tag hit VFX events
tagHitVFXEvent:Connect(function(position, propName)
    local propGameObject = GameObject.Find(propName)
    VFXManager.TagHitVFX(position, propGameObject)
end)
```

### TagMissVFX - Add to PropPossessionSystem.lua

**Location**: Line ~926, after miss penalty applied

```lua
if not possessingPlayerId then
    -- MISS: Hunter tapped a non-possessed prop - apply penalty
    print("[PropPossessionSystem] SERVER: Hunter " .. hunter.name .. " tapped non-possessed prop: " .. propName .. " - applying miss penalty")
    ScoringSystem.ApplyHunterMissPenalty(hunter)
    ScoringSystem.TrackHunterMiss(hunter)

    -- NEW: Send TagMissVFX to hunter client only
    local tagMissVFXEvent = Event.new("PH_TagMissVFX")
    local propGameObject = GameObject.Find(propName)
    if propGameObject then
        tagMissVFXEvent:FireClient(hunter, propGameObject.transform.position)
    end

    return
end
```

**Client-Side Listener** (add to `PropPossessionSystem.lua:ClientStart`):

```lua
-- Listen for tag miss VFX events
tagMissVFXEvent:Connect(function(position)
    VFXManager.TagMissVFX(position, nil)
end)
```

## Troubleshooting

### Error: "VFX prefab not assigned in Inspector!"
**Solution**: Drag VFX GameObject from VFXPrefabs to SerializeField slot in PropHuntModules Inspector.

### Error: "Could not find VFX GameObject 'X' in scene!"
**Solution**:
1. Check VFX GameObject name matches SerializeField reference
2. Ensure VFX GameObject is in scene (under VFXPrefabs parent)
3. Try restarting Unity to refresh GameObject references

### VFX doesn't appear
**Solution**:
1. Check VFX GameObject is disabled by default
2. Check particle system "Play On Awake" is enabled
3. Check particle system emission rate > 0
4. Check particle system max particles > 0
5. Check particle system material is assigned

### VFX appears in wrong position
**Solution**:
1. Check VFX GameObject position is set to (0,0,0) in Inspector
2. SpawnVFX moves the GameObject to target position at runtime

### VFX doesn't disable after duration
**Solution**:
1. Check particle system "Stop Action" is set to "Disable"
2. Check Timer.After is being called (look for console logs)
3. Verify duration constant matches particle system duration

## Current Status

✅ **Complete**:
- SpawnVFX helper function implemented
- All 5 SerializeField references added
- PlayerVanishVFX uses SerializeField pattern
- PropInfillVFX uses SerializeField pattern
- RejectionVFX uses SerializeField pattern
- TagHitVFX uses SerializeField pattern
- TagMissVFX uses SerializeField pattern

⏳ **Remaining**:
- Add remaining 4 VFX prefabs to VFXPrefabs GameObject
- Assign all 5 SerializeField references in Unity Inspector
- Add TagHitVFX network event and client listener (PropPossessionSystem)
- Add TagMissVFX network event and client listener (PropPossessionSystem)
- Test all 5 VFX in gameplay

## Files Modified

1. `Assets/PropHunt/Scripts/Modules/PropHuntVFXManager.lua`
   - Added 5 SerializeField references
   - Added SpawnVFX helper function
   - Updated all 5 VFX functions to use SpawnVFX

## Next Steps

1. **Create VFX Prefabs**: Add 4 more particle systems to VFXPrefabs GameObject
2. **Assign References**: Drag all 5 VFX to PropHuntModules Inspector
3. **Add Network Events**: Implement TagHitVFX and TagMissVFX broadcast in PropPossessionSystem
4. **Test**: Play through full game loop and verify all VFX trigger correctly
