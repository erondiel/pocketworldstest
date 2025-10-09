# PropHuntVFXManager - Quick Reference

**Location:** `/Assets/PropHunt/Scripts/Modules/PropHuntVFXManager.lua`

**Type:** Module (Shared)

## Quick Start

```lua
local VFX = require("PropHuntVFXManager")

-- Fade in a UI element
VFX.FadeIn(myElement, 0.5)

-- Pulse a GameObject
VFX.ScalePulse(myObject, 1.0, 1.2, 0.4, "easeInOutQuad", true, true)

-- Play possession VFX
VFX.PlayerVanishVFX(playerPos, playerCharacter)
VFX.PropInfillVFX(propPos, propObject)

-- Play tagging VFX
VFX.TagHitVFX(hitPoint, propObject)
VFX.TagMissVFX(missPoint, surfaceNormal)
```

## What It Does

Provides a high-level wrapper around the DevBasics Tweens system for:
- **UI Animations**: Fade, slide, and animate UI elements
- **GameObject Animations**: Scale, position, and color tweens
- **Gameplay VFX Placeholders**: Possession, tagging, rejection effects

## Core Functions

### UI Animations
- `FadeIn(element, duration?, easing?, onComplete?)`
- `FadeOut(element, duration?, easing?, onComplete?)`
- `SlideIn(element, startPos, endPos, duration?, easing?, onComplete?)`
- `ScalePulse(gameObject, fromScale, toScale, duration?, easing?, loop?, pingPong?)`
- `PositionTween(gameObject, startPos, endPos, duration, easing?, onComplete?)`

### Gameplay VFX (Placeholders - will be replaced with particle systems)
- `PlayerVanishVFX(position, playerCharacter?)` - Player dissolves on possession
- `PropInfillVFX(position, propObject?)` - Prop materializes
- `RejectionVFX(position, propObject?)` - Double-possess rejection flash
- `TagHitVFX(position, propObject?)` - Successful hunter tag
- `TagMissVFX(position, normal?)` - Hunter miss

### Advanced
- `CreateSequence()` - Chain animations sequentially
- `CreateGroup()` - Run animations in parallel
- `ColorTween(fromColor, toColor, duration, onUpdate, easing?, onComplete?)` - Animate colors

## Easing Functions

Available via `VFX.Easing.*`:
- `linear`, `easeInQuad`, `easeOutQuad`, `easeInOutQuad`
- `easeInCubic`, `easeOutCubic`, `easeInOutCubic`
- `easeInBack`, `easeOutBack` (overshoots - great for UI!)
- `easeInElastic`, `easeOutElastic` (spring wobble)
- `easeInExpo`, `easeOutExpo` (explosive)
- `easeInSine`, `easeOutSine` (gentle)
- `bounce` (bounces like a ball)

## Example: Chaining Animations

```lua
local VFX = require("PropHuntVFXManager")

local seq = VFX.CreateSequence()
seq:add(VFX.FadeIn(element, 0.3))
seq:add(VFX.ScalePulse(element, 1.0, 1.2, 0.2))
seq:add(VFX.FadeOut(element, 0.3))
seq.onComplete = function() print("Done!") end
seq:start()
```

## Example: Parallel Animations

```lua
local VFX = require("PropHuntVFXManager")

local grp = VFX.CreateGroup()
grp:add(VFX.FadeIn(elementA, 0.5))
grp:add(VFX.FadeIn(elementB, 0.5))
grp:add(VFX.ScalePulse(objectC, 1.0, 1.5, 0.5))
grp.onComplete = function() print("All done!") end
grp:start()
```

## Documentation

- **Full API Reference**: `/Assets/PropHunt/Documentation/VFX_SYSTEM.md`
- **Integration Examples**: `/Assets/PropHunt/Documentation/VFX_INTEGRATION_EXAMPLES.md`
- **DevBasics Tweens Source**: `/Assets/Downloads/DevBasics Toolkit/Scripts/Shared/devx_tweens.lua`

## VFX Timings (Per Game Design Doc)

| Effect | Duration | Description |
|--------|----------|-------------|
| PlayerVanishVFX | 0.4s | Vertical slice dissolve |
| PropInfillVFX | 0.5s | Radial mask inwards |
| RejectionVFX | 0.2s | Red flash |
| TagHitVFX | 0.25s | Ring shock wave |
| TagMissVFX | 0.15s | Dust poof |

## Current Status

**✅ Implemented:**
- Full tween wrapper system
- UI animation helpers
- Placeholder VFX functions with debug logging
- Easing function support
- Sequence and group support

**⏳ TODO (Post-V1):**
- Replace placeholders with particle system prefabs
- Implement custom shaders (dissolve, infill, outline)
- Add audio integration
- Create VFX pooling system
- Network event synchronization

## Integration Points

The VFX system should be integrated into:
1. **PropDisguiseSystem.lua** - Possession and rejection VFX
2. **HunterTagSystem.lua** - Tag hit and miss VFX
3. **PropHuntGameManager.lua** - Phase transition VFX
4. **PropHuntHUD.lua** - UI animations and feedback

See `VFX_INTEGRATION_EXAMPLES.md` for detailed code examples.

## Notes

- All placeholder VFX functions currently use simple scale/position tweens
- VFX are non-blocking - gameplay continues immediately
- Debug logging can be enabled in `PropHuntConfig.lua`
- Tweens auto-cleanup when finished (no manual cleanup needed)
- Mobile-optimized (short durations, minimal particle counts)
