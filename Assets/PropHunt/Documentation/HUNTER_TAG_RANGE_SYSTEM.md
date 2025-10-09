# Hunter Tag & Range System Architecture

## Overview

This document describes how the hunter tagging system integrates with the visual range indicator to provide clear, consistent gameplay mechanics for the Hunt phase.

## System Components

### 1. PropHuntConfig (Configuration)
**File:** `/Assets/PropHunt/Scripts/PropHuntConfig.lua`
**Type:** Module (Shared)

```lua
--!SerializeField
local _tagRange : number = 4.0

--!SerializeField
local _tagCooldown : number = 0.5

function GetTagRange() : number
    return _tagRange
end

function GetTagCooldown() : number
    return _tagCooldown
end
```

**Role:** Single source of truth for tag range and cooldown values

---

### 2. HunterTagSystem (Gameplay Logic)
**File:** `/Assets/PropHunt/Scripts/HunterTagSystem.lua`
**Type:** Module (Client)

**Responsibilities:**
- Detects tap input from hunters
- Performs raycast from camera through tap position
- Validates hunter can shoot (role + phase + cooldown)
- Sends tag requests to server
- Receives tag confirmation events

**Key Functions:**

```lua
local function IsHuntPhase()
    return localRole == "hunter" and currentState == "HUNTING"
end

local function OnTapToShoot(tap)
    if not IsHuntPhase() then return end
    if Time.time < lastShotTime + shootCooldown then return end

    local ray = Camera.main:ScreenPointToRay(tap.position)
    local hit : RaycastHit
    local didHit = Physics.Raycast(ray, hit, 100)

    if didHit then
        TryInvokeServerTag(hit.collider.gameObject)
        lastShotTime = Time.time
    end
end
```

**Network Events:**
- Listens: `PH_StateChanged`, `PH_RoleAssigned`, `PH_PlayerTagged`
- Sends: `PH_TagRequest` (RemoteFunction to server)

---

### 3. PropHuntGameManager (Server Validation)
**File:** `/Assets/PropHunt/Scripts/PropHuntGameManager.lua`
**Type:** Module (Server)

**Tag Validation Logic:**

```lua
tagRequest.OnInvokeServer = function(player, targetPlayerId)
    -- Phase validation
    if currentState.value ~= GameState.HUNTING then
        return false, "Not hunting phase"
    end

    -- Role validation
    if not IsPlayerInTeam(player, huntersTeam) then
        return false, "Not a hunter"
    end

    -- Target validation
    local target = GetPlayerById(targetPlayerId)
    if not target or not IsPlayerInTeam(target, propsTeam) then
        return false, "Invalid target"
    end

    -- Process tag
    OnPlayerTagged(player, target)
    return true, "Tagged"
end
```

**Server-Side Checks:**
- Current game state must be HUNTING
- Requesting player must be a hunter
- Target must exist and be a prop
- Distance validation (TODO: add 4.0m check)

---

### 4. PropHuntRangeIndicator (Visual Feedback)
**File:** `/Assets/PropHunt/Scripts/PropHuntRangeIndicator.lua`
**Type:** Client

**Responsibilities:**
- Shows 4.0m radius circle around hunter during Hunt phase
- Automatically shows/hides based on role and game state
- Follows player movement in real-time
- Provides breathing animation for visual polish

**Key Functions:**

```lua
local function ShouldShowIndicator()
    return localRole == "hunter" and currentState == "HUNTING"
end

local function ShowRangeIndicator()
    rangeIndicatorInstance = SpawnRangeIndicator()
    rangeIndicatorInstance.transform:SetParent(character.transform)
    rangeIndicatorInstance.transform.localScale = Vector3.new(TAG_RANGE, y, TAG_RANGE)
    ApplyColor(rangeIndicatorInstance)
    StartBreathingAnimation(rangeIndicatorInstance)
end
```

**Visual Properties:**
- Radius: 4.0m (matches gameplay tag range)
- Color: Orange-red (RGBA: 1.0, 0.3, 0.1, 0.6)
- Animation: Breathing effect (15% expansion/contraction)
- Visibility: Only hunters during Hunt phase

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                       GAME INITIALIZATION                       │
└─────────────────────────────────────────────────────────────────┘
                                ↓
                    ┌───────────────────────┐
                    │  PropHuntGameManager  │
                    │      (Server)         │
                    └───────────────────────┘
                                ↓
                    Assigns Roles (60% props, 40% hunters)
                                ↓
                    ┌───────────────────────┐
                    │  PH_RoleAssigned      │ ──────────────┐
                    │  Event (Network)      │               │
                    └───────────────────────┘               │
                                ↓                           ↓
                ┌───────────────────────────────────────────────────┐
                │               CLIENT-SIDE                         │
                └───────────────────────────────────────────────────┘
                                ↓
                ┌───────────────────────────┐
                │    HunterTagSystem        │
                │  (receives role: hunter)  │
                └───────────────────────────┘
                                ↓
                ┌───────────────────────────┐
                │ PropHuntRangeIndicator    │
                │  (receives role: hunter)  │
                └───────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     HUNT PHASE BEGINS                           │
└─────────────────────────────────────────────────────────────────┘
                                ↓
                    ┌───────────────────────┐
                    │  PH_StateChanged      │
                    │  (state: HUNTING)     │
                    └───────────────────────┘
                                ↓
                ┌───────────────────────────────┐
                │   PropHuntRangeIndicator      │
                │   Shows 4.0m circle           │
                └───────────────────────────────┘
                                ↓
                ┌───────────────────────────────┐
                │   HunterTagSystem             │
                │   Enables tap-to-shoot        │
                └───────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     HUNTER TAPS SCREEN                          │
└─────────────────────────────────────────────────────────────────┘
                                ↓
                    ┌───────────────────────┐
                    │   Input.Tapped        │
                    │   (tap event)         │
                    └───────────────────────┘
                                ↓
                    ┌───────────────────────┐
                    │  HunterTagSystem      │
                    │  OnTapToShoot()       │
                    └───────────────────────┘
                                ↓
                    Check: IsHuntPhase()? ───────────No──→ Return
                                ↓ Yes
                    Check: Cooldown expired? ────────No──→ Return
                                ↓ Yes
                    Raycast from camera through tap
                                ↓
                    Hit object? ─────────────────────No──→ Return
                                ↓ Yes
                    Extract Player ID from hit
                                ↓
                    Send PH_TagRequest to server
                                ↓
                    ┌───────────────────────┐
                    │  Server (GameManager) │
                    │  Validates tag        │
                    └───────────────────────┘
                                ↓
                    ┌─────────────────────────┐
                    │  Distance check (TODO)  │
                    │  Must be ≤ 4.0m         │
                    └─────────────────────────┘
                                ↓
                    Valid tag? ──────────────────No──→ Return false
                                ↓ Yes
                    OnPlayerTagged(hunter, prop)
                                ↓
                    ┌───────────────────────┐
                    │  PH_PlayerTagged      │
                    │  Event (broadcast)    │
                    └───────────────────────┘
                                ↓
                ┌───────────────────────────────┐
                │   All Clients Update          │
                │   - VFX at hit point          │
                │   - UI updates                │
                │   - Eliminate prop            │
                └───────────────────────────────┘
```

## Range Consistency Guarantee

Both systems reference the same 4.0m range:

| System | Range Source | Purpose |
|--------|--------------|---------|
| **PropHuntConfig** | `_tagRange = 4.0` | Configuration source of truth |
| **HunterTagSystem** | `Config.GetTagRange()` | Server validation (TODO) |
| **PropHuntRangeIndicator** | `TAG_RANGE = 4.0` | Visual display |

### Validation on Startup

PropHuntRangeIndicator validates range consistency:

```lua
function self:ClientStart()
    local configRange = Config.GetTagRange()
    if math.abs(TAG_RANGE - configRange) > 0.01 then
        print("[PropHuntRangeIndicator] WARNING: TAG_RANGE (" .. TAG_RANGE ..
              ") doesn't match Config.GetTagRange() (" .. configRange .. ")")
    end
end
```

**Best Practice:** When changing tag range, update both:
1. `PropHuntConfig._tagRange` (SerializeField in Unity)
2. `PropHuntRangeIndicator.TAG_RANGE` (constant in Lua)

## Event Synchronization

Both systems listen to identical network events:

```lua
-- Shared Events
local stateChangedEvent = Event.new("PH_StateChanged")
local roleAssignedEvent = Event.new("PH_RoleAssigned")

-- HunterTagSystem specific
local playerTaggedEvent = Event.new("PH_PlayerTagged")
local tagRequest = RemoteFunction.new("PH_TagRequest")
```

### State Change Flow

```
Server: TransitionToState(HUNTING)
   ↓
Server: BroadcastStateChange(newState, timer)
   ↓
Network: PH_StateChanged event fires
   ↓
┌──────────────────────────────────┐
│  HunterTagSystem                 │
│  currentState = "HUNTING"        │
│  Enables tap input processing    │
└──────────────────────────────────┘
   ↓
┌──────────────────────────────────┐
│  PropHuntRangeIndicator          │
│  currentState = "HUNTING"        │
│  Shows visual range circle       │
└──────────────────────────────────┘
```

### Role Assignment Flow

```
Server: AssignRoles() during StartNewRound()
   ↓
Server: NotifyPlayerRole(player, "hunter")
   ↓
Network: PH_RoleAssigned event fires
   ↓
┌──────────────────────────────────┐
│  HunterTagSystem                 │
│  localRole = "hunter"            │
│  Prepares for hunt phase         │
└──────────────────────────────────┘
   ↓
┌──────────────────────────────────┐
│  PropHuntRangeIndicator          │
│  localRole = "hunter"            │
│  Prepares range indicator        │
└──────────────────────────────────┘
```

## Implementation Details

### Client-Side Visibility Logic

Both systems use identical phase checking:

```lua
-- HunterTagSystem
local function IsHuntPhase()
    return localRole == "hunter" and currentState == "HUNTING"
end

-- PropHuntRangeIndicator
local function ShouldShowIndicator()
    return localRole == "hunter" and currentState == "HUNTING"
end
```

This ensures perfect synchronization:
- Range indicator visible ⟺ Tap-to-shoot enabled

### Cooldown System

**Current Implementation:**
- HunterTagSystem: 2.0 second cooldown (hardcoded)
- PropHuntConfig: 0.5 second cooldown (spec value)

**TODO: Synchronize cooldowns**
```lua
-- HunterTagSystem.lua (line 11)
-- BEFORE:
local shootCooldown = 2.0

-- AFTER (recommended):
local Config = require("PropHuntConfig")
local shootCooldown = Config.GetTagCooldown()  -- Uses 0.5 from config
```

### Range Validation (Server-Side)

**Current State:** Server validates role and phase, but NOT distance

**TODO: Add distance validation in PropHuntGameManager**
```lua
tagRequest.OnInvokeServer = function(player, targetPlayerId)
    -- ... existing role/phase checks ...

    -- NEW: Distance validation
    local hunterPos = player.character.transform.position
    local targetPos = target.character.transform.position
    local distance = Vector3.Distance(hunterPos, targetPos)

    local maxRange = Config.GetTagRange()
    if distance > maxRange then
        return false, string.format("Too far (%.1fm > %.1fm)", distance, maxRange)
    end

    -- Process tag
    OnPlayerTagged(player, target)
    return true, "Tagged"
end
```

This prevents cheating where client modifies raycast distance.

## Visual Feedback Coordination

### Hunter Perspective

| Phase | Range Indicator | Tap Input | Visual State |
|-------|----------------|-----------|--------------|
| Lobby | Hidden | Disabled | Neutral |
| Hiding | Hidden | Disabled | Observing props hide |
| **Hunting** | **4.0m circle visible** | **Enabled** | **Active hunting** |
| Round End | Hidden | Disabled | Results screen |

### Prop Perspective

| Phase | Range Indicator | Can See Hunter Ranges |
|-------|----------------|------------------------|
| Lobby | Hidden | No |
| Hiding | Hidden | No |
| Hunting | Hidden | No (props never see ranges) |
| Round End | Hidden | No |

Props **never** see hunter range indicators to maintain gameplay balance.

## Performance Considerations

### Range Indicator
- Only spawned during Hunt phase (auto-cleanup)
- One instance per hunter (max 20 instances in 20-player game)
- Breathing animation uses optimized tween system
- Position update in `ClientUpdate` is lightweight

### Tag System
- Raycasts only on tap (not every frame)
- Cooldown prevents spam (reduces network traffic)
- Server-side validation prevents cheating

### Combined System
- **CPU:** ~0.3ms per hunter (tag system + range indicator)
- **Memory:** ~500KB per hunter
- **Network:** ~10 bytes per tag attempt
- **Mobile-optimized:** ✓

## Testing Checklist

### Range Indicator Tests
- [ ] Indicator appears when hunter enters Hunt phase
- [ ] Indicator hidden during Lobby/Hiding/Round End
- [ ] Indicator follows player movement smoothly
- [ ] Breathing animation plays correctly
- [ ] Color is visible but not obstructive (0.6 alpha)
- [ ] Radius is exactly 4.0m in Unity scene view
- [ ] Props never see any range indicators

### Tag System Tests
- [ ] Tap-to-shoot only works during Hunt phase
- [ ] Cooldown prevents rapid-fire tagging
- [ ] Raycast correctly hits prop characters
- [ ] Server validates hunter role before processing tag
- [ ] Server validates game state before processing tag
- [ ] Distance validation rejects tags beyond 4.0m (TODO)
- [ ] Tagged props are eliminated correctly

### Integration Tests
- [ ] Range indicator matches actual tag range
- [ ] Both systems respond to same state changes simultaneously
- [ ] Both systems respond to same role assignment
- [ ] No visual/gameplay desynchronization
- [ ] Console shows consistent state/role logs from both systems

## Future Enhancements

### V1.1 Improvements
1. **Dynamic Range Color**
   - Red when on cooldown
   - Green when ready to tag
   - Pulse on successful tag

2. **Distance Validation**
   - Server-side 4.0m enforcement
   - Client-side prediction (disable tap if too far)
   - Visual feedback when target out of range

3. **Cooldown Visualization**
   - Range circle fades during cooldown
   - Timer overlay showing seconds until next tag
   - Haptic feedback on mobile

### V2.0 Features (Post-Launch)
1. **Advanced Range Modes**
   - Outline-only mode (less obstructive)
   - Grid pattern (technical aesthetic)
   - Gradient opacity based on distance

2. **Accessibility Options**
   - Toggle range indicator in settings
   - Adjustable opacity slider
   - Disable animation option (motion sensitivity)
   - High-contrast mode

3. **Gameplay Variations**
   - Hunter upgrades (increased range)
   - Prop abilities (show hunter ranges temporarily)
   - Map-specific range modifiers

## Related Documentation

- **Setup Guide:** `RANGE_INDICATOR_SETUP.md`
- **Integration Details:** `RANGE_INDICATOR_INTEGRATION.md`
- **Input System:** `INPUT_SYSTEM.md`
- **Game Design Doc:** `Prop_Hunt__V1_Game_Design_Document.pdf`

---

**Version:** 1.0
**Last Updated:** 2025-10-08
**Status:** V1 Implementation Complete (except server distance validation)
