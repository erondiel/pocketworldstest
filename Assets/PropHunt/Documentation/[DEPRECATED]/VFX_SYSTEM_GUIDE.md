# PropHunt VFX System Guide

## Overview

The VFX system in PropHunt uses a **centralized VFXManager module** that provides placeholder functions for visual effects. These functions are called at specific gameplay moments but currently only trigger **placeholder animations** (scale tweens, shakes, print statements). You will now **replace these placeholders with actual particle system prefabs**.

## Architecture

### Module Structure
- **VFXManager Location**: `Assets/PropHunt/Scripts/Modules/PropHuntVFXManager.lua`
- **Type**: Server-side Module (--!Type(Module))
- **Dependencies**: DevBasics Tweens (`devx_tweens`)

### How It Works
1. Game systems call VFXManager functions at specific events
2. VFXManager receives position + GameObject references
3. **Currently**: Triggers placeholder tweens (scale, shake, log)
4. **Your Task**: Replace placeholders with `Object.Instantiate(VFXPrefab, position, rotation)`

---

## VFX Events Reference

### 1. **Prop Possession VFX** (HIDING Phase)

#### PlayerVanishVFX
**When**: Prop player successfully possesses a prop
**Called From**: `PropPossessionSystem.lua:309` (CLIENT-SIDE)
**Trigger**: `VFXManager.PlayerVanishVFX(playerPos, localPlayer.character)`

**Function Signature**:
```lua
function PlayerVanishVFX(position, playerCharacter)
  -- position: Vector3 - World position of player before vanish
  -- playerCharacter: GameObject - The player's character object
end
```

**Current Placeholder**:
- Scales player character from 1.0 → 0.0 over 1.0 seconds
- Duration constant: `VFX_PLAYER_VANISH_DURATION = 1.0`



**Event Propagation**: ✅ **BROADCAST TO ALL CLIENTS**
- Called in `OnPossessionResult()` client function.
- The event should be propagated to all clients in the arena during the Hiding phase.
- If filtering clients is too complex, broadcasting to all players is an acceptable alternative.


---

#### PropInfillVFX
**When**: Prop finishes materializing after possession
**Called From**: `PropPossessionSystem.lua:310` (CLIENT-SIDE)
**Trigger**: `VFXManager.PropInfillVFX(propData.gameObject.transform.position, propData.gameObject)`

**Function Signature**:
```lua
function PropInfillVFX(position, propObject)
  -- position: Vector3 - World position of the prop
  -- propObject: GameObject - The prop being possessed
end
```

**Current Placeholder**:
- Scales prop from 0.1 → 1.0 over 1.2 seconds with bounce
- Duration constant: `VFX_PROP_INFILL_DURATION = 1.2`



**Event Propagation**: ✅ **BROADCAST TO ALL CLIENTS**
- Called immediately after PlayerVanishVFX.
- Should be propagated to all clients.


---

### 2. **Rejection VFX** (Failed Possession)

#### RejectionVFX
**When**: Player attempts to possess already-possessed prop OR tries to possess second prop
**Called From**: `PropPossessionSystem.lua:255, 264, 290` (CLIENT-SIDE)
**Trigger**: `VFXManager.RejectionVFX(propData.gameObject.transform.position, propData.gameObject)`

**Function Signature**:
```lua
function RejectionVFX(position, propObject)
  -- position: Vector3 - World position of the rejected prop
  -- propObject: GameObject - The prop that rejected possession
end
```

**Current Placeholder**:
- 3-step shake animation (left → right → center) over 0.2 seconds
- Duration constant: `VFX_REJECTION_DURATION = 0.2`



**Event Propagation**: ✅ **CLIENT-SIDE ONLY**
- Triggered when client-side validation fails
- Only the rejecting player sees this effect

---

### 3. **Hunter Tag VFX** (HUNTING Phase)

#### TagHitVFX
**When**: Hunter successfully tags a possessed prop
**Called From**: ❌ **NOT CALLED YET** (you need to add this)
**Should Be Called**: After `GameManager.OnPlayerTagged()` processes the tag

**Function Signature**:
```lua
function TagHitVFX(position, propObject)
  -- position: Vector3 - World position of the tagged prop
  -- propObject: GameObject (optional) - The tagged prop
end
```

**Current Placeholder**:
- Quick scale punch (1.0 → 0.9 over 0.125s)
- Duration constant: `VFX_TAG_HIT_DURATION = 0.25`

**Design Spec (GDD)**:
- Compressed ring shock wave at hit point (0.25s)
- 3-5 micro-spark motes radiating outward
- Chromatic ripples on prop surface
- Impact sound effect

**Event Propagation**: ❌ **NEEDS TO BE ADDED**
- Should broadcast to ALL clients (everyone sees the hit)
- Recommended: Add to `PropPossessionSystem.lua:950` after `GameManager.OnPlayerTagged()`

---

#### TagMissVFX
**When**: Hunter taps on non-possessed prop
**Called From**: ❌ **NOT CALLED YET** (you need to add this)
**Should Be Called**: In `PropPossessionSystem.lua:926` after miss penalty applied

**Function Signature**:
```lua
function TagMissVFX(position, normal)
  -- position: Vector3 - World position where ray hit
  -- normal: Vector3 (optional) - Surface normal for decal orientation
end
```

**Current Placeholder**:
- Only a print statement (no animation)
- Duration constant: `VFX_TAG_MISS_DURATION = 0.15`

**Design Spec (GDD)**:
- Dust poof decal at impact point (0.15s)
- Color-neutral (gray/white)
- Small particle burst
- Soft "whiff" sound

**Event Propagation**: ❌ **NEEDS TO BE ADDED**
- Should be client-side only (hunter sees their own miss)
- Or broadcast to all clients if you want others to see misses

---

## Event Propagation Summary

### ✅ Currently Working (Client-Side Only)
1. **PlayerVanishVFX** - Local player possession animation
2. **PropInfillVFX** - Local player possession animation
3. **RejectionVFX** - Local player rejection animation

### ❌ Missing (Need to Add)
4. **TagHitVFX** - Hunter tag success (should broadcast to all)
5. **TagMissVFX** - Hunter tag miss (can be local or broadcast)

---

## Where to Place VFX Prefabs

### Option 1: Scene-Based (Recommended for Testing)
**Location**: Place directly in Unity scene
**Structure**:
```
Hierarchy:
├── VFX (parent GameObject)
│   ├── PlayerVanishVFX (prefab, disabled by default)
│   ├── PropInfillVFX (prefab, disabled by default)
│   ├── RejectionVFX (prefab, disabled by default)
│   ├── TagHitVFX (prefab, disabled by default)
│   └── TagMissVFX (prefab, disabled by default)
```

**Pros**:
- Easy to test and iterate
- Can reference directly via `GameObject.Find("PlayerVanishVFX")`
- No need for Resources folder or addressables

**Cons**:
- Must exist in scene (won't work if removed)
- One instance per scene

---

### Option 2: Resources Folder (Recommended for Production)
**Location**: `Assets/PropHunt/Resources/VFX/`
**Structure**:
```
Assets/PropHunt/Resources/VFX/
├── PlayerVanishVFX.prefab
├── PropInfillVFX.prefab
├── RejectionVFX.prefab
├── TagHitVFX.prefab
└── TagMissVFX.prefab
```

**How to Use**:
```lua
-- Load prefab from Resources folder
local vfxPrefab = Resources.Load("VFX/PlayerVanishVFX")
-- Instantiate at position
local vfxInstance = Object.Instantiate(vfxPrefab, position, Quaternion.identity)
-- Destroy after duration
Timer.After(VFX_PLAYER_VANISH_DURATION, function()
    Object.Destroy(vfxInstance)
end)
```

**Pros**:
- Can instantiate multiple instances
- Portable (works in any scene)
- Standard Unity pattern

**Cons**:
- Requires Resources folder setup
- Slightly more complex code

---

### Option 3: Attach to Possessable Props (NOT Recommended)
**Location**: Add VFX prefabs as children of each Possessable prop

**Why NOT Recommended**:
- VFX needs to spawn at different locations (player vs prop)
- TagHitVFX/TagMissVFX can occur anywhere in arena
- Would require finding/cloning per prop (inefficient)
- Hard to manage (30+ props = 30+ VFX copies)

**Exception**: Rejection VFX COULD be attached to props since it always targets the prop itself, but for consistency use centralized approach.

---

## Implementation Checklist

### Step 1: Create VFX Prefabs
- [ ] Create particle systems in Unity for each VFX type
- [ ] Save as prefabs in `Assets/PropHunt/Resources/VFX/` or scene

### Step 2: Update VFXManager.lua
- [ ] Add SerializeField references for VFX prefabs (if scene-based)
- [ ] OR add Resources.Load calls (if Resources-based)
- [ ] Replace placeholder code with `Object.Instantiate()`
- [ ] Add `Timer.After()` to destroy VFX after duration

### Step 3: Add Missing VFX Calls

#### TagHitVFX (Server-Side, Broadcast to All)
Add to `PropPossessionSystem.lua` around line 950:

```lua
-- Call GameManager's tag handler to process the tag (scoring, etc.)
GameManager.OnPlayerTagged(hunter, propPlayer)

-- TODO: Broadcast TagHitVFX to all clients
-- Option A: Fire event to all clients
local tagHitEvent = Event.new("PH_TagHitVFX")
tagHitEvent:FireAllClients(propObject.transform.position, propName)

-- OR Option B: Call VFXManager directly (if VFXManager handles broadcast)
-- This would require VFXManager to have a network event for TagHitVFX
```

#### TagMissVFX (Server-Side, Can Be Client or Broadcast)
Add to `PropPossessionSystem.lua` around line 926:

```lua
-- MISS: Hunter tapped a non-possessed prop - apply penalty
print("[PropPossessionSystem] SERVER: Hunter " .. hunter.name .. " tapped non-possessed prop: " .. propName .. " - applying miss penalty")
ScoringSystem.ApplyHunterMissPenalty(hunter)
ScoringSystem.TrackHunterMiss(hunter)

-- TODO: Trigger TagMissVFX (send to hunter client only)
local tagMissEvent = Event.new("PH_TagMissVFX")
tagMissEvent:FireClient(hunter, propPosition, propNormal)

return
```

### Step 4: Test Each VFX
- [ ] Test PlayerVanishVFX during HIDING phase
- [ ] Test PropInfillVFX during HIDING phase
- [ ] Test RejectionVFX (double-possess attempt)
- [ ] Test TagHitVFX during HUNTING phase
- [ ] Test TagMissVFX during HUNTING phase

---

## Code Examples

### Scene-Based VFX (SerializeField Approach)

**VFXManager.lua** (add near top):
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

**Replace PlayerVanishVFX function**:
```lua
function PlayerVanishVFX(position, playerCharacter)
    DebugVFX("PlayerVanishVFX at " .. tostring(position))

    if not _playerVanishVFXPrefab then
        print("[VFX] WARNING: PlayerVanishVFX prefab not assigned!")
        return
    end

    -- Instantiate VFX at position
    local vfxInstance = Object.Instantiate(_playerVanishVFXPrefab, position, Quaternion.identity)

    -- Scale down player character (keep existing placeholder for now)
    if playerCharacter then
        ScalePulse(playerCharacter, 1.0, 0.0, VFX_PLAYER_VANISH_DURATION, "easeInQuad", false, false)
    end

    -- Destroy VFX after duration
    Timer.After(VFX_PLAYER_VANISH_DURATION, function()
        if vfxInstance then
            Object.Destroy(vfxInstance)
        end
    end)
end
```

---

### Resources-Based VFX Approach

**Replace PlayerVanishVFX function**:
```lua
function PlayerVanishVFX(position, playerCharacter)
    DebugVFX("PlayerVanishVFX at " .. tostring(position))

    -- Load prefab from Resources folder
    local vfxPrefab = Resources.Load("VFX/PlayerVanishVFX")
    if not vfxPrefab then
        print("[VFX] ERROR: Could not load VFX/PlayerVanishVFX from Resources!")
        return
    end

    -- Instantiate VFX at position
    local vfxInstance = Object.Instantiate(vfxPrefab, position, Quaternion.identity)

    -- Scale down player character (keep existing placeholder for now)
    if playerCharacter then
        ScalePulse(playerCharacter, 1.0, 0.0, VFX_PLAYER_VANISH_DURATION, "easeInQuad", false, false)
    end

    -- Destroy VFX after duration
    Timer.After(VFX_PLAYER_VANISH_DURATION, function()
        if vfxInstance then
            Object.Destroy(vfxInstance)
        end
    end)
end
```

---

## Network Event Propagation Verification

### Currently Working (Client-Side)
These functions are called on the client and only execute locally:

1. **PlayerVanishVFX** (line 309 of PropPossessionSystem.lua)
   - Triggered in `OnPossessionResult()` client function
   - Runs on `client.localPlayer` only
   - ✅ No broadcast needed (personal effect)

2. **PropInfillVFX** (line 310 of PropPossessionSystem.lua)
   - Triggered immediately after PlayerVanishVFX
   - Runs on `client.localPlayer` only
   - ✅ No broadcast needed (personal effect)

3. **RejectionVFX** (lines 255, 264, 290 of PropPossessionSystem.lua)
   - Triggered on client-side validation failure
   - Runs on `client.localPlayer` only
   - ✅ No broadcast needed (personal feedback)

---

### Missing Server-Broadcast Events

#### TagHitVFX - ❌ NOT IMPLEMENTED
**Current Code** (PropPossessionSystem.lua:946-963):
```lua
-- HIT: Valid tag on possessed prop
print("[PropPossessionSystem] SERVER: Hunter " .. hunter.name .. " successfully tagged prop: " .. propName .. " (player: " .. propPlayer.name .. ")")

-- Call GameManager's tag handler to process the tag (scoring, etc.)
GameManager.OnPlayerTagged(hunter, propPlayer)

-- IMMEDIATELY restore the tagged player's avatar
print("[PropPossessionSystem] SERVER: Restoring avatar for tagged player: " .. propPlayer.name)
restoreAvatarCommand:FireAllClients(propPlayer.user.id)

-- Teleport tagged prop to arena spawn position
print("[PropPossessionSystem] SERVER: Teleporting tagged player to Arena spawn: " .. propPlayer.name)
Teleporter.TeleportToArena(propPlayer)

-- Change role to spectator
PlayerManager.SetPlayerRole(propPlayer, "spectator")
```

**Problem**: No VFX triggered!

**Solution**: Add broadcast event after `GameManager.OnPlayerTagged()`:
```lua
-- NEW: Broadcast TagHitVFX to all clients
local tagHitVFXEvent = Event.new("PH_TagHitVFX")
-- Get prop position (need to find prop GameObject by name)
local propGameObject = GameObject.Find(propName)
if propGameObject then
    tagHitVFXEvent:FireAllClients(propGameObject.transform.position, propName)
else
    -- Fallback: use propPlayer position
    tagHitVFXEvent:FireAllClients(propPlayer.character.transform.position, propName)
end
```

---

#### TagMissVFX - ❌ NOT IMPLEMENTED
**Current Code** (PropPossessionSystem.lua:923-929):
```lua
if not possessingPlayerId then
    -- MISS: Hunter tapped a non-possessed prop - apply penalty
    print("[PropPossessionSystem] SERVER: Hunter " .. hunter.name .. " tapped non-possessed prop: " .. propName .. " - applying miss penalty")
    ScoringSystem.ApplyHunterMissPenalty(hunter)
    ScoringSystem.TrackHunterMiss(hunter)
    return
end
```

**Problem**: No VFX triggered!

**Solution 1 (Hunter Only)**: Send VFX to hunter client only:
```lua
-- NEW: Send TagMissVFX to hunter client
local tagMissVFXEvent = Event.new("PH_TagMissVFX")
local propGameObject = GameObject.Find(propName)
if propGameObject then
    tagMissVFXEvent:FireClient(hunter, propGameObject.transform.position, Vector3.zero)
else
    -- Fallback: use hunter position
    tagMissVFXEvent:FireClient(hunter, hunter.character.transform.position, Vector3.zero)
end
```

**Solution 2 (All Clients)**: Broadcast to all clients (optional - reveals hunter's failed attempts):
```lua
-- NEW: Broadcast TagMissVFX to all clients
local tagMissVFXEvent = Event.new("PH_TagMissVFX")
local propGameObject = GameObject.Find(propName)
if propGameObject then
    tagMissVFXEvent:FireAllClients(propGameObject.transform.position, Vector3.zero)
end
```

---

## Summary

### VFX Placement Recommendation
**Use Resources Folder** (`Assets/PropHunt/Resources/VFX/`)
- Clean separation from scene
- Easy to instantiate/destroy
- Portable across scenes

### Current Status
- ✅ **3/5 VFX functions called** (PlayerVanishVFX, PropInfillVFX, RejectionVFX)
- ✅ **All 3 are client-side only** (no broadcast needed)
- ❌ **2/5 VFX functions NOT called** (TagHitVFX, TagMissVFX)
- ❌ **Missing server-side broadcast events**

### Next Steps
1. Create particle system prefabs for all 5 VFX types
2. Place in `Assets/PropHunt/Resources/VFX/` folder
3. Update VFXManager functions to use `Resources.Load()` and `Object.Instantiate()`
4. Add server-side broadcast events for TagHitVFX and TagMissVFX
5. Add client-side listeners for broadcast events
6. Test all 5 VFX in gameplay

### Files to Modify
1. `PropHuntVFXManager.lua` - Replace placeholder code with prefab instantiation
2. `PropPossessionSystem.lua` - Add TagHitVFX and TagMissVFX calls (server-side)
3. Unity Scene - Create VFX prefabs and save to Resources folder
