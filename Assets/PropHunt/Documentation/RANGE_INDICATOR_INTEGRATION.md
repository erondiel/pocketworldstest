# Range Indicator Integration

## Overview

The Range Indicator asset has been integrated into PropHunt to provide hunters with a clear visual representation of their 4.0m tag range during the Hunt phase. This enhances gameplay clarity and helps hunters understand their effective tagging distance.

## Asset Location

**Source Asset:** `/Users/andres.camacho/Development/Personal/pocketworldstest/Assets/Downloads/Range Indicator/`

**PropHunt Integration Script:** `/Users/andres.camacho/Development/Personal/pocketworldstest/Assets/PropHunt/Scripts/PropHuntRangeIndicator.lua`

**Dependencies:**
- DevBasics Toolkit (`devx_tweens.lua`) - Used for breathing animation
- PropHuntConfig - Tag range configuration
- PropHuntGameManager - State and role events

## Architecture

### PropHuntRangeIndicator.lua

**Type:** Client-side script (`--!Type(Client)`)

**Purpose:** Manages the visual range indicator specifically for PropHunt hunters, coordinating with the game's state machine and role assignment system.

**Key Features:**
- Automatically shows/hides based on player role and game phase
- Shows 4.0m radius circle around hunters during Hunt phase only
- Includes breathing animation for visual polish
- Follows player movement in real-time
- Customizable color (default: orange-red hunter theme)

### Integration Points

#### 1. Event System
The script listens to PropHunt's network events:
- `PH_StateChanged` - Triggered when game phase changes (Lobby → Hiding → Hunting → Round End)
- `PH_RoleAssigned` - Triggered when player is assigned Hunter or Prop role

#### 2. State Management
```lua
-- Indicator is shown ONLY when:
localRole == "hunter" AND currentState == "HUNTING"

-- Hidden in all other cases:
- Prop role (any phase)
- Hunter role in Lobby/Hiding/Round End
- Spectator role
```

#### 3. Visual Coordination with HunterTagSystem
Both systems use the same tag range constant:
- **HunterTagSystem:** Validates tags within 4.0m server-side
- **PropHuntRangeIndicator:** Displays 4.0m visual radius client-side
- **PropHuntConfig:** Defines `_tagRange = 4.0` as source of truth

## Setup Instructions

### 1. Unity Inspector Configuration

Attach `PropHuntRangeIndicator` component to a GameObject in the scene (e.g., `GameManager` or `HunterManager`).

Configure the following SerializeFields:

```
_RangeIndicatorPrefab: [Drag Range Indicator Prefab here]
  └─ From: Assets/Downloads/Range Indicator/Prefabs/

_IndicatorColor: RGBA(1.0, 0.3, 0.1, 0.6)
  └─ Orange-red with 60% opacity (hunter theme)

_EnableBreathingAnimation: true
  └─ Subtle pulsing effect for visual polish

_AnimationSpeed: 1.5
  └─ Speed of breathing animation (higher = faster)
```

### 2. Prefab Assignment

The Range Indicator prefab should be assigned in the Unity Inspector. The prefab includes:
- Mesh (circular disc)
- Material (with transparency support)
- Renderer component

### 3. Integration with Existing Systems

No changes required to existing scripts. The integration works automatically through:
- **PropHuntGameManager** - Already broadcasts state and role events
- **HunterTagSystem** - Already uses Config.GetTagRange() for validation
- **PropHuntConfig** - Already defines _tagRange = 4.0

## API Reference

### Public Configuration (SerializeFields)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `_RangeIndicatorPrefab` | GameObject | null | Range indicator prefab from asset |
| `_IndicatorColor` | Color | Orange-red | Color theme for hunter range circle |
| `_EnableBreathingAnimation` | boolean | true | Enable subtle pulsing animation |
| `_AnimationSpeed` | number | 1.5 | Speed multiplier for animation |

### Internal Constants

```lua
TAG_RANGE = 4.0  -- Matches Config.GetTagRange()
```

### Event Listeners

```lua
-- State Change Listener
stateChangedEvent:Connect(OnStateChanged)
  └─ Updates currentState and shows/hides indicator

-- Role Assignment Listener
roleAssignedEvent:Connect(OnRoleAssigned)
  └─ Updates localRole and shows/hides indicator
```

### Lifecycle Methods

```lua
self:ClientStart()
  └─ Initializes event listeners, validates config

self:ClientUpdate()
  └─ Updates indicator position to follow player

self:ClientOnDestroy()
  └─ Cleans up indicator and stops animations
```

## Visual Behavior

### Phase-Based Visibility

| Phase | Hunter | Prop | Spectator |
|-------|--------|------|-----------|
| Lobby | Hidden | Hidden | Hidden |
| Hiding | Hidden | Hidden | Hidden |
| **Hunting** | **VISIBLE** | Hidden | Hidden |
| Round End | Hidden | Hidden | Hidden |

### Animation Details

**Breathing Effect:**
- Base scale: 4.0m radius
- Expanded scale: 4.6m radius (115% of base)
- Easing: `easeInOutQuad` for smooth, organic motion
- Loop: Ping-pong (grows → shrinks → grows)
- Duration: 1.5 seconds per cycle (configurable)

**Color Theme:**
- Default: RGBA(1.0, 0.3, 0.1, 0.6)
- Orange-red aligns with hunter/danger theme
- 60% opacity allows seeing ground beneath
- Fully customizable via Unity Inspector

## Coordination with HunterTagSystem

### Shared Tag Range
Both systems reference the same 4.0m range:

```lua
-- PropHuntConfig.lua
local _tagRange : number = 4.0

-- PropHuntRangeIndicator.lua
local TAG_RANGE = 4.0  -- Visual radius

-- HunterTagSystem.lua (server validation)
-- Uses Config.GetTagRange() for distance checks
```

### Validation Warning
On startup, PropHuntRangeIndicator validates that its hardcoded `TAG_RANGE` matches the config:

```lua
if math.abs(TAG_RANGE - configRange) > 0.01 then
    print("[PropHuntRangeIndicator] WARNING: TAG_RANGE doesn't match Config")
end
```

**Best Practice:** If you change `_tagRange` in PropHuntConfig, also update `TAG_RANGE` in PropHuntRangeIndicator.lua to keep visual and gameplay ranges synchronized.

## Performance Considerations

### Optimization
- Only one indicator instance per hunter (singleton pattern)
- Indicator only active during Hunt phase (auto-cleanup)
- Tween animation uses optimized easing function
- Position update in `ClientUpdate` is lightweight (simple Vector3 copy)

### Mobile Performance
- Transparent material uses mobile-optimized shader
- Single mesh instance (low poly count)
- No realtime shadows on indicator
- Breathing animation is optional (can be disabled)

## Troubleshooting

### Indicator Not Appearing

**Check:**
1. Is `_RangeIndicatorPrefab` assigned in Inspector?
2. Is player role actually "hunter"? (Check console logs)
3. Is game state "HUNTING"? (Should see state change logs)
4. Does prefab have a Renderer component?

**Debug:**
```lua
print("[PropHuntRangeIndicator] Role: " .. localRole)
print("[PropHuntRangeIndicator] State: " .. currentState)
print("[PropHuntRangeIndicator] Should show: " .. tostring(ShouldShowIndicator()))
```

### Range Mismatch

If visual range doesn't match actual tag range:

1. Check PropHuntConfig `_tagRange` value in Inspector
2. Update `TAG_RANGE` constant in PropHuntRangeIndicator.lua
3. Verify HunterTagSystem uses `Config.GetTagRange()` for validation

### Animation Issues

If breathing animation is jerky or incorrect:
- Reduce `_AnimationSpeed` for slower, smoother motion
- Ensure TweenModule is correctly imported
- Check for conflicting scale modifications in other scripts

## Future Enhancements

Potential improvements for post-V1:

1. **Dynamic Color:**
   - Red when on cooldown
   - Green when ready to tag
   - Flashing when prop is in range

2. **Range Visualization Modes:**
   - Filled circle (current)
   - Outline only (cleaner look)
   - Grid pattern (technical aesthetic)

3. **Feedback Integration:**
   - Pulse effect on successful tag
   - Shrink effect on miss
   - Ripple effect when cooldown ends

4. **Accessibility Options:**
   - Toggle visibility in settings
   - Adjust opacity
   - Disable animation for motion sensitivity

## Related Documentation

- **Input System:** `Assets/PropHunt/Documentation/INPUT_SYSTEM.md`
- **Game Design Document:** `Assets/PropHunt/Docs/Prop_Hunt__V1_Game_Design_Document.pdf`
- **Project Overview:** `CLAUDE.md`

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-10-08 | Initial integration with Range Indicator asset |

## Credits

**Range Indicator Asset:** `/Assets/Downloads/Range Indicator/`
**Integration:** PropHunt Technical Art Showcase
**Maintainer:** PropHunt Development Team
