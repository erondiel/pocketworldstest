# PropHunt VFX System Documentation

**⚠️ V1 STATUS: PLACEHOLDER IMPLEMENTATION**

The VFX system framework is complete, but particle systems and custom shaders are **not implemented in V1**. Current implementation uses basic tweens for testing. See "Replacing Placeholders with Particle Systems" section below for V2+ implementation.

## Overview

The PropHunt VFX system is built on top of the **DevBasics Toolkit's Tweens system** (`devx_tweens.lua`). It provides a modular, easy-to-use interface for all visual effects in the game, from UI animations to gameplay VFX.

**Module Location:** `/Assets/PropHunt/Scripts/Modules/PropHuntVFXManager.lua`

**Type:** Module (Shared - can be used by both Client and Server scripts)

**Current State:**
- ✅ DevBasics Tweens integration complete
- ✅ UI animation wrappers complete
- ⚠️ Gameplay VFX are **placeholders** (scale/position tweens only)
- ❌ Particle systems **not created** (V2+)
- ❌ Custom shaders **not created** (V2+)

---

## Architecture

### Dependencies

```
PropHuntVFXManager.lua
    ├─ devx_tweens.lua (DevBasics Toolkit)
    │   ├─ Tween class
    │   ├─ TweenSequence class
    │   ├─ TweenGroup class
    │   └─ Easing functions
    └─ PropHuntConfig.lua (for debug logging)
```

### Core Concepts

1. **Tweens**: Animate a single value from start to end over time
2. **Sequences**: Chain multiple tweens to run one after another
3. **Groups**: Run multiple tweens in parallel
4. **Easing**: Control the rate of change (linear, ease-in, ease-out, etc.)

---

## DevBasics Tweens System

The underlying `devx_tweens.lua` module provides the core animation engine.

### Tween Class

Creates an animation that interpolates a value from `from` to `to` over `duration` seconds.

```lua
local tween = Tween:new(from, to, duration, loop, pingPong, easing, onUpdate, onComplete)
```

**Parameters:**
- `from` (number): Starting value
- `to` (number): Ending value
- `duration` (number): Time in seconds
- `loop` (boolean): Whether to loop the animation
- `pingPong` (boolean): Whether to reverse on each loop
- `easing` (function): Easing function from `Easing` table
- `onUpdate` (function): Called every frame with `(currentValue, easedProgress)`
- `onComplete` (function): Called when animation finishes

**Methods:**
- `tween:start()` - Start/restart the tween
- `tween:stop(doCompleteCB)` - Stop the tween
- `tween:pause()` - Pause the tween
- `tween:resume()` - Resume from pause
- `tween:isFinished()` - Check if tween is done
- `tween:setDelay(delay)` - Set a delay before starting
- `tween:getProgress()` - Get current progress (0-1)
- `tween:seek(progress)` - Jump to a specific progress point

### TweenSequence Class

Chains multiple tweens to run sequentially (one after another).

```lua
local sequence = TweenSequence:new()
sequence:add(tween1)
sequence:add(tween2)
sequence:add(tween3)
sequence.onComplete = function() print("All done!") end
sequence:start()
```

**Methods:**
- `sequence:add(tween)` - Add a tween to the sequence (returns self for chaining)
- `sequence:start()` - Start the sequence
- `sequence:stop()` - Stop the sequence

### TweenGroup Class

Runs multiple tweens in parallel (all at the same time).

```lua
local group = TweenGroup:new()
group:add(tween1)
group:add(tween2)
group.onComplete = function() print("All finished!") end
group:start()
```

**Methods:**
- `group:add(tween)` - Add a tween to the group (returns self for chaining)
- `group:start()` - Start all tweens
- `group:stop()` - Stop all tweens
- `group:pause()` - Pause all tweens
- `group:resume()` - Resume all tweens

### Easing Functions

All available easing functions from `devx_tweens.lua`:

**Basic:**
- `Easing.linear` - Constant speed
- `Easing.easeInQuad` - Slow start, fast end (quadratic)
- `Easing.easeOutQuad` - Fast start, slow end (quadratic)
- `Easing.easeInOutQuad` - Slow start and end, fast middle

**Cubic:**
- `Easing.easeInCubic` - Slow start (cubic)
- `Easing.easeOutCubic` - Slow end (cubic)
- `Easing.easeInOutCubic` - Slow start and end (cubic)

**Exponential:**
- `Easing.easeInExpo` - Very slow start, explosive end
- `Easing.easeOutExpo` - Explosive start, very slow end

**Back:**
- `Easing.easeInBack` - Pulls back before moving forward
- `Easing.easeOutBack` - Overshoots then settles (great for UI!)
- `Easing.easeInBackLinear` - Back ease transitioning to linear

**Elastic:**
- `Easing.easeInElastic` - Spring-like wobble at start
- `Easing.easeOutElastic` - Spring-like wobble at end

**Sine:**
- `Easing.easeInSine` - Gentle acceleration
- `Easing.easeOutSine` - Gentle deceleration

**Bounce:**
- `Easing.bounce` - Bounces like a ball

### Vector/Color Support

The tween system has built-in support for:
- `Vector2` - 2D positions (UI)
- `Vector3` - 3D positions, scales, rotations
- `Color` - RGBA color values

---

## PropHuntVFXManager API

### UI Animation Wrappers

These functions provide high-level wrappers for common UI animations.

#### FadeIn

Fades a UI element from transparent (0) to opaque (1).

```lua
local VFX = require("PropHuntVFXManager")

function ShowMenu()
    local menuElement = document:Q("menu-container")
    VFX.FadeIn(menuElement, 0.5, "easeOutCubic", function()
        print("Menu is fully visible!")
    end)
end
```

**Signature:**
```lua
FadeIn(element, duration, easing, onComplete) -> Tween
```

**Parameters:**
- `element` (VisualElement): UI Toolkit element to fade in
- `duration` (number, optional): Duration in seconds (default: 0.3)
- `easing` (string, optional): Easing function name (default: "easeOutQuad")
- `onComplete` (function, optional): Callback when complete

**Returns:** `Tween` object for further control

---

#### FadeOut

Fades a UI element from opaque (1) to transparent (0).

```lua
local VFX = require("PropHuntVFXManager")

function HideMenu()
    local menuElement = document:Q("menu-container")
    VFX.FadeOut(menuElement, 0.25, "easeInQuad", function()
        menuElement:SetActive(false)
    end)
end
```

**Signature:**
```lua
FadeOut(element, duration, easing, onComplete) -> Tween
```

**Parameters:** Same as `FadeIn`

---

#### ScalePulse

Creates a pulsing scale animation on a GameObject (grows/shrinks).

```lua
local VFX = require("PropHuntVFXManager")

function PulseReadyButton()
    local button = GameObject.Find("ReadyButton")
    -- Pulse from 100% to 120% and back repeatedly
    VFX.ScalePulse(button, 1.0, 1.2, 0.6, "easeInOutQuad", true, true)
end
```

**Signature:**
```lua
ScalePulse(gameObject, fromScale, toScale, duration, easing, loop, pingPong) -> Tween
```

**Parameters:**
- `gameObject` (GameObject): The object to scale
- `fromScale` (number): Starting scale multiplier (1.0 = 100%)
- `toScale` (number): Ending scale multiplier
- `duration` (number, optional): Duration in seconds (default: 0.4)
- `easing` (string, optional): Easing function name (default: "easeInOutQuad")
- `loop` (boolean, optional): Loop the animation (default: false)
- `pingPong` (boolean, optional): Reverse on each loop (default: false)

---

#### SlideIn

Slides a UI element from a start position to an end position.

```lua
local VFX = require("PropHuntVFXManager")

function ShowNotification()
    local notification = document:Q("notification")
    local startPos = Vector2.new(-300, 0)  -- Off-screen left
    local endPos = Vector2.new(0, 0)       -- On-screen
    VFX.SlideIn(notification, startPos, endPos, 0.4, "easeOutBack")
end
```

**Signature:**
```lua
SlideIn(element, startPos, endPos, duration, easing, onComplete) -> TweenGroup
```

**Parameters:**
- `element` (VisualElement): UI element to slide
- `startPos` (Vector2): Starting position offset in pixels
- `endPos` (Vector2): Ending position offset in pixels
- `duration` (number, optional): Duration in seconds (default: 0.35)
- `easing` (string, optional): Easing function name (default: "easeOutBack")
- `onComplete` (function, optional): Callback when complete

---

#### PositionTween

Animates a GameObject's world position from point A to point B.

```lua
local VFX = require("PropHuntVFXManager")

function TeleportPlayer(player, destination)
    local startPos = player.transform.position
    VFX.PositionTween(player, startPos, destination, 1.0, "easeInOutQuad", function()
        print("Teleport complete!")
    end)
end
```

**Signature:**
```lua
PositionTween(gameObject, startPos, endPos, duration, easing, onComplete) -> Tween
```

**Parameters:**
- `gameObject` (GameObject): Object to move
- `startPos` (Vector3): Starting world position
- `endPos` (Vector3): Ending world position
- `duration` (number): Duration in seconds
- `easing` (string, optional): Easing function name (default: "easeOutQuad")
- `onComplete` (function, optional): Callback when complete

---

### Game VFX Placeholders

These functions are **placeholders** for game-specific visual effects. They currently log debug messages and perform simple animations. They should be replaced with particle systems and shader effects in later iterations.

#### PlayerVanishVFX

Triggers when a Prop player possesses an object and their character vanishes.

**Game Design Spec:**
- Vertical slice dissolve (0.4s)
- Soft upward-moving sparks
- Bottom-to-top fade

```lua
local VFX = require("PropHuntVFXManager")

-- In PropDisguiseSystem.lua
function OnPossessSuccess(player, prop)
    local playerPos = player.character.transform.position
    VFX.PlayerVanishVFX(playerPos, player.character)
end
```

**Current Behavior:** Scales player down to 0 over 0.4s

**TODO (Final Implementation):**
1. Instantiate `PlayerVanishVFX` particle prefab
2. Apply vertical slice dissolve shader to player material
3. Animate shader `_DissolveAmount` from 0 to 1
4. Spawn 3-5 upward-drifting sparkle particles
5. Play vanish sound effect
6. Hide/destroy player character at end

---

#### PropInfillVFX

Triggers when a prop materializes after possession.

**Game Design Spec:**
- Radial mask inwards (edges to center)
- Emissive rim pulse: 0 → 2.0 → 0.5
- Duration: 0.5s

```lua
local VFX = require("PropHuntVFXManager")

-- In PropDisguiseSystem.lua
function OnPropPossessed(prop)
    local propPos = prop.transform.position
    VFX.PropInfillVFX(propPos, prop)
end
```

**Current Behavior:** Scales prop from 0.1 to 1.0 with easeOutBack

**TODO (Final Implementation):**
1. Set prop material `_InfillProgress` shader property to 0
2. Tween `_InfillProgress` from 0 to 1 over 0.5s
3. Keyframe `_EmissiveRim`: 0 → 2.0 (at 0.3s) → 0.5 (at 0.5s)
4. Play materialization sound effect

---

#### RejectionVFX

Triggers when a player tries to possess an already-possessed prop.

**Game Design Spec:**
- Brief red edge flash (0.2s)
- "Thunk" sound effect
- No particles (pure shader)

```lua
local VFX = require("PropHuntVFXManager")

-- In PropDisguiseSystem.lua
function OnPossessRejected(prop)
    local propPos = prop.transform.position
    VFX.RejectionVFX(propPos, prop)
end
```

**Current Behavior:** Shakes prop left-right with sequence

**TODO (Final Implementation):**
1. Flash prop outline shader to red
2. Tween `_OutlineColor` to `Color.red`
3. Tween `_OutlineIntensity`: 0 → 3.0 → 0 over 0.2s
4. Play "thunk" audio clip

---

#### TagHitVFX

Triggers when a Hunter successfully tags a Prop.

**Game Design Spec:**
- Compressed ring shock wave at prop's HitPoint
- 3-5 micro-spark motes radiating outward
- Chromatic ripples on prop surface
- Duration: 0.25s

```lua
local VFX = require("PropHuntVFXManager")

-- In HunterTagSystem.lua
function OnTagSuccess(hitPoint, prop)
    VFX.TagHitVFX(hitPoint, prop)
end
```

**Current Behavior:** Quick scale punch (1.0 → 0.9 → 1.0)

**TODO (Final Implementation):**
1. Instantiate `TagHitVFX` particle prefab at `hitPoint`
2. Play ring shock particle system (expanding circle)
3. Spawn 3-5 spark particles with radial outward velocity
4. Trigger chromatic aberration shader on prop material
5. Play impact sound effect
6. Destroy VFX GameObject after 0.25s

---

#### TagMissVFX

Triggers when a Hunter's tag misses (hits environment or nothing).

**Game Design Spec:**
- Small dust poof decal
- Color-neutral (gray/white)
- Duration: 0.15s
- Soft "whiff" sound

```lua
local VFX = require("PropHuntVFXManager")

-- In HunterTagSystem.lua
function OnTagMiss(hitPosition, surfaceNormal)
    VFX.TagMissVFX(hitPosition, surfaceNormal)
end
```

**Current Behavior:** Logs debug message only

**TODO (Final Implementation):**
1. Instantiate `TagMissVFX` particle prefab at `hitPosition`
2. Align to `surfaceNormal` if provided (orient decal)
3. Play dust poof particle burst
4. Spawn temporary dust decal (fades over 1s)
5. Play "whiff" audio clip
6. Destroy VFX GameObject after 0.15s

---

### Advanced Helpers

#### CreateSequence

Creates an empty TweenSequence for chaining animations.

```lua
local VFX = require("PropHuntVFXManager")

function ComplexAnimation()
    local seq = VFX.CreateSequence()

    -- Fade in
    seq:add(VFX.FadeIn(element, 0.3))

    -- Wait (use a dummy tween with no onUpdate)
    local waitTween = Tween:new(0, 1, 0.5, false, false, Easing.linear, nil, nil)
    seq:add(waitTween)

    -- Fade out
    seq:add(VFX.FadeOut(element, 0.3))

    seq.onComplete = function()
        print("Full sequence done!")
    end
    seq:start()
end
```

---

#### CreateGroup

Creates an empty TweenGroup for parallel animations.

```lua
local VFX = require("PropHuntVFXManager")

function ParallelAnimation()
    local grp = VFX.CreateGroup()

    grp:add(VFX.FadeIn(elementA, 0.5))
    grp:add(VFX.FadeIn(elementB, 0.5))
    grp:add(VFX.ScalePulse(objectC, 0.5, 1.0, 0.5))

    grp.onComplete = function()
        print("All animations finished!")
    end
    grp:start()
end
```

---

#### ColorTween

Animates a color from one value to another.

```lua
local VFX = require("PropHuntVFXManager")

function FlashScreen(material)
    local white = Color.new(1, 1, 1, 1)
    local clear = Color.new(1, 1, 1, 0)

    VFX.ColorTween(white, clear, 0.5, function(currentColor)
        material:SetColor("_FlashColor", currentColor)
    end, "easeOutQuad", function()
        print("Flash complete!")
    end)
end
```

---

## Integration Guide

### Using VFX in PropHunt Scripts

#### 1. Client-Side UI Animations

```lua
--!Type(Client)

local VFX = require("PropHuntVFXManager")

function self:ClientAwake()
    -- Get UI element
    local hud = document:Q("game-hud")

    -- Fade in on start
    VFX.FadeIn(hud, 0.5, "easeOutCubic")
end

function ShowPhaseTransition(phaseName)
    local banner = document:Q("phase-banner")
    local text = document:Q("phase-text")

    text.text = phaseName

    -- Slide in from top
    local startPos = Vector2.new(0, -100)
    local endPos = Vector2.new(0, 0)
    VFX.SlideIn(banner, startPos, endPos, 0.6, "easeOutBack", function()
        -- Hold for 2 seconds
        Timer.After(2.0, function()
            VFX.SlideIn(banner, endPos, Vector2.new(0, 100), 0.4, "easeInBack")
        end)
    end)
end
```

---

#### 2. Server-Side Gameplay VFX

```lua
--!Type(Server)

local VFX = require("PropHuntVFXManager")

function OnPropPossessed(player, propObject)
    -- Trigger VFX at player and prop locations
    local playerPos = player.character.transform.position
    local propPos = propObject.transform.position

    VFX.PlayerVanishVFX(playerPos, player.character)
    VFX.PropInfillVFX(propPos, propObject)
end

function OnHunterTagAttempt(hunter, hitInfo)
    if hitInfo.transform:GetComponent(Possessable) then
        -- Hit a possessed prop
        VFX.TagHitVFX(hitInfo.point, hitInfo.transform.gameObject)
    else
        -- Missed
        VFX.TagMissVFX(hitInfo.point, hitInfo.normal)
    end
end
```

---

#### 3. Module-Based Effects

```lua
--!Type(Module)

local VFX = require("PropHuntVFXManager")

function AnimateScorePopup(scoreValue, worldPosition)
    -- This would be called from a Client script
    -- Create a world-space UI element for score popup

    local popup = CreateScorePopup(scoreValue, worldPosition)

    -- Animate it
    local seq = VFX.CreateSequence()

    -- Pop in
    local scale1 = VFX.ScalePulse(popup, 0, 1.2, 0.2, "easeOutBack", false, false)
    seq:add(scale1)

    -- Settle
    local scale2 = VFX.ScalePulse(popup, 1.2, 1.0, 0.1, "easeOutQuad", false, false)
    seq:add(scale2)

    -- Move up
    local startPos = popup.transform.position
    local endPos = startPos + Vector3.new(0, 2, 0)
    local move = VFX.PositionTween(popup, startPos, endPos, 1.0, "easeOutQuad")
    seq:add(move)

    -- Fade out
    local fade = VFX.FadeOut(popup:GetComponent(CanvasGroup), 0.5)
    seq:add(fade)

    seq.onComplete = function()
        Object.Destroy(popup)
    end
    seq:start()
end
```

---

## Replacing Placeholders with Particle Systems

When you're ready to replace placeholder VFX with real particle systems, follow these steps:

### Step 1: Create Particle Prefabs

1. In Unity, create a new GameObject with a `ParticleSystem` component
2. Configure the particle system (emission, shape, color, etc.)
3. Save as a prefab in `/Assets/PropHunt/VFX/Prefabs/`

Example prefabs needed:
- `PlayerVanishVFX.prefab`
- `PropInfillVFX.prefab`
- `TagHitVFX.prefab`
- `TagMissVFX.prefab`

---

### Step 2: Reference Prefabs in Lua

Add SerializeFields to a script that uses the VFX:

```lua
--!Type(Client)

--!SerializeField
local _PlayerVanishVFXPrefab : GameObject = nil

--!SerializeField
local _PropInfillVFXPrefab : GameObject = nil

function PlayPlayerVanish(position)
    if _PlayerVanishVFXPrefab then
        local vfx = Object.Instantiate(_PlayerVanishVFXPrefab, position, Quaternion.identity)
        Timer.After(0.4, function()
            Object.Destroy(vfx)
        end)
    end
end
```

---

### Step 3: Update PropHuntVFXManager

Replace the placeholder functions with actual implementations:

```lua
-- Before (placeholder)
function PlayerVanishVFX(position, playerCharacter)
    DebugVFX("PlayerVanishVFX at " .. tostring(position))
    print("[VFX PLACEHOLDER] Player Vanish at " .. tostring(position))
end

-- After (real implementation)
function PlayerVanishVFX(position, playerCharacter)
    DebugVFX("PlayerVanishVFX at " .. tostring(position))

    -- Spawn particle system
    if _PlayerVanishVFXPrefab then
        local vfx = Object.Instantiate(_PlayerVanishVFXPrefab, position, Quaternion.identity)
        Timer.After(VFX_PLAYER_VANISH_DURATION, function()
            Object.Destroy(vfx)
        end)
    end

    -- Apply dissolve shader to player
    if playerCharacter then
        local renderer = playerCharacter:GetComponentInChildren(SkinnedMeshRenderer)
        if renderer then
            local material = renderer.material

            -- Animate dissolve
            Tween:new(0, 1, VFX_PLAYER_VANISH_DURATION, false, false, Easing.linear, function(value, t)
                material:SetFloat("_DissolveAmount", value)
            end, function()
                playerCharacter:SetActive(false)
            end):start()
        end
    end
end
```

---

### Step 4: Create Custom Shaders

For effects like dissolve, outline, and emissive rim, you'll need custom URP shaders.

Example shader keywords to implement:
- `_DissolveAmount` (0-1): Controls vertical slice dissolve
- `_InfillProgress` (0-1): Controls radial mask infill
- `_OutlineColor` (Color): Outline color
- `_OutlineIntensity` (float): Outline brightness
- `_EmissiveRim` (float): Emissive rim intensity

Place shaders in `/Assets/PropHunt/Shaders/`

---

## Performance Considerations

### Mobile Optimization

Since PropHunt targets mobile platforms via Highrise:

1. **Limit Particle Counts**: Keep particle emissions low (<50 per effect)
2. **Short Durations**: Most VFX should be <0.5s
3. **Reuse Tweens**: Don't create thousands of tween objects
4. **Stop Unused Tweens**: Call `tween:stop()` when an animation is interrupted
5. **Pool VFX Prefabs**: Use object pooling for frequently-spawned effects

### Tween Cleanup

Tweens are automatically cleaned up when they finish, but you can manually stop them:

```lua
local tween = VFX.FadeIn(element, 2.0)

-- Later, if you need to cancel it:
tween:stop(false)  -- Don't call onComplete callback
```

---

## Debugging

### Enable VFX Debug Logging

In `/Assets/PropHunt/Scripts/PropHuntConfig.lua`, set:

```lua
local _enableDebug : boolean = true
```

This will log all VFX function calls to the Unity Console.

### Common Issues

**Issue:** UI element doesn't fade
- Check that element exists: `if element then ... end`
- Verify element has opacity property
- Check Unity Console for errors

**Issue:** Tween doesn't start
- Ensure you called `tween:start()`
- Check that duration > 0
- Verify callback functions don't have errors

**Issue:** Particle system doesn't spawn
- Check that prefab reference is assigned in Unity Inspector
- Verify prefab has ParticleSystem component
- Check that Object.Instantiate is being called

---

## Future Enhancements

Planned improvements for post-V1:

1. **VFX Pooling System**: Reuse particle GameObjects instead of Instantiate/Destroy
2. **Audio Integration**: Automatic audio playback with VFX calls
3. **VFX Events**: Network events to sync VFX across clients
4. **Timeline Integration**: Use Unity Timeline for complex cinematic VFX
5. **Shader Graph Support**: Visual shader authoring for custom effects

---

## Example Use Cases

### Phase Transition Effects

```lua
-- In PropHuntGameManager.lua
local VFX = require("PropHuntVFXManager")

function TransitionToHidePhase()
    -- World desaturate in Lobby area
    local lobbyCamera = GetLobbyCamera()
    ApplyDesaturationFilter(lobbyCamera)

    -- Arena pulse-in gradient
    local arenaLight = GetArenaLight()
    VFX.ColorTween(
        Color.new(1, 1, 1, 0),  -- Start: white, transparent
        Color.new(0.8, 1.0, 1.2, 1),  -- End: cool blue tint, opaque
        0.8,
        function(color)
            arenaLight.color = color
        end,
        "easeOutQuad"
    )

    -- Teleport beam VFX on each prop player
    for _, player in ipairs(GetPropPlayers()) do
        SpawnTeleportBeam(player.transform.position)
    end
end
```

### UI Feedback Loop

```lua
-- In PropHuntHUD.lua
local VFX = require("PropHuntVFXManager")

function UpdateTimer(secondsRemaining)
    local timerLabel = document:Q("timer-label")
    timerLabel.text = FormatTime(secondsRemaining)

    -- Flash red when time is running out
    if secondsRemaining <= 10 and secondsRemaining > 0 then
        local seq = VFX.CreateSequence()

        -- Flash to red
        local flash = VFX.ColorTween(
            Color.white,
            Color.red,
            0.2,
            function(color)
                timerLabel.style.color = color
            end,
            "easeInQuad"
        )
        seq:add(flash)

        -- Back to white
        local restore = VFX.ColorTween(
            Color.red,
            Color.white,
            0.3,
            function(color)
                timerLabel.style.color = color
            end,
            "easeOutQuad"
        )
        seq:add(restore)

        seq:start()
    end
end
```

---

## API Reference Summary

### UI Animations
| Function | Purpose | Default Duration |
|----------|---------|------------------|
| `FadeIn(element, ...)` | Fade UI element in | 0.3s |
| `FadeOut(element, ...)` | Fade UI element out | 0.25s |
| `ScalePulse(obj, ...)` | Scale GameObject | 0.4s |
| `SlideIn(element, ...)` | Slide UI element | 0.35s |
| `PositionTween(obj, ...)` | Move GameObject | Custom |

### Gameplay VFX (Placeholders)
| Function | Spec Duration | Purpose |
|----------|---------------|---------|
| `PlayerVanishVFX(pos, char)` | 0.4s | Possession vanish |
| `PropInfillVFX(pos, prop)` | 0.5s | Possession infill |
| `RejectionVFX(pos, prop)` | 0.2s | Double-possess reject |
| `TagHitVFX(pos, prop)` | 0.25s | Successful tag |
| `TagMissVFX(pos, normal)` | 0.15s | Missed tag |

### Phase Transition VFX
| Function | Spec Duration | Purpose |
|----------|---------------|---------|
| `TriggerLobbyTransition()` | - | Lobby state transition |
| `TriggerHidePhaseStart(props)` | - | Hide phase start |
| `TriggerHuntPhaseStart()` | - | Hunt phase start |
| `TriggerEndRoundVFX(team, players)` | Configurable | Round end celebration |

### Advanced
| Function | Returns | Purpose |
|----------|---------|---------|
| `CreateSequence()` | TweenSequence | Chain animations |
| `CreateGroup()` | TweenGroup | Parallel animations |
| `ColorTween(...)` | Tween | Animate colors |

---

## Support

For questions or issues:
- Check the Unity Console for error messages
- Enable debug logging in PropHuntConfig
- Review the DevBasics Tweens source: `/Assets/Downloads/DevBasics Toolkit/Scripts/Shared/devx_tweens.lua`
- See Highrise Studio API docs: https://create.highrise.game/learn/studio-api
