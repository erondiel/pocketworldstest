--!Type(Module)

--[[
  PropHuntVFXManager.lua

  Manages all visual effects for PropHunt using the DevBasics Tweens system.
  Provides wrapper functions for common VFX animations and placeholder functions
  for game-specific effects that will be replaced with particle systems later.

  Dependencies:
    - DevBasics Toolkit: devx_tweens.lua
    - PropHuntConfig.lua (for debug logging)
]]

-- Import DevBasics Tweens module
local TweenModule = require("devx_tweens")
local Tween = TweenModule.Tween
local TweenSequence = TweenModule.TweenSequence
local TweenGroup = TweenModule.TweenGroup
local Easing = TweenModule.Easing

local PropHuntConfig = require("PropHuntConfig")

-- ========== VFX CONFIGURATION ==========
-- These values define the visual characteristics of effects
-- Adjust these to fine-tune the feel of VFX animations

--!Tooltip("Duration for fade in animations")
--!SerializeField
local _fadeInDuration : number = 0.3

--!Tooltip("Duration for fade out animations")
--!SerializeField
local _fadeOutDuration : number = 0.25

--!Tooltip("Duration for scale pulse animations")
--!SerializeField
local _pulseDuration : number = 0.4

--!Tooltip("Duration for slide in animations")
--!SerializeField
local _slideInDuration : number = 0.35

--!Tooltip("Default easing for UI animations")
--!SerializeField
local _defaultEasing : string = "easeOutQuad"

-- VFX Timings (per Game Design Document)
local VFX_PLAYER_VANISH_DURATION = 0.4  -- Vertical slice dissolve
local VFX_PROP_INFILL_DURATION = 0.5    -- Radial mask inwards
local VFX_REJECTION_DURATION = 0.2      -- Brief red flash
local VFX_TAG_HIT_DURATION = 0.25       -- Compressed ring shock
local VFX_TAG_MISS_DURATION = 0.15      -- Dust poof

-- ========== UTILITY FUNCTIONS ==========

--[[
  GetEasingFunction: Converts easing name string to easing function
  @param easingName: string - Name of the easing function
  @return function - The easing function
]]
local function GetEasingFunction(easingName : string)
    return Easing[easingName] or Easing.linear
end

--[[
  DebugVFX: Logs VFX debug messages
  @param message: string - The debug message
]]
local function DebugVFX(message : string)
    if PropHuntConfig.IsDebugEnabled() then
        PropHuntConfig.DebugLog("[VFX] " .. message)
    end
end

-- ========== UI ANIMATION WRAPPERS ==========
-- These functions wrap the DevBasics Tweens system for common UI animations

--[[
  FadeIn: Fades in a UI element from transparent to opaque
  @param element: VisualElement - The UI element to fade in
  @param duration: number (optional) - Animation duration in seconds
  @param easing: string (optional) - Easing function name
  @param onComplete: function (optional) - Callback when animation completes
  @return Tween - The tween object for further control

  Usage:
    local myElement = document:Q("my-element")
    PropHuntVFXManager.FadeIn(myElement, 0.5, "easeOutCubic", function()
        print("Fade in complete!")
    end)
]]
function FadeIn(element, duration, easing, onComplete)
    duration = duration or _fadeInDuration
    easing = easing or _defaultEasing

    if not element then
        DebugVFX("FadeIn called with nil element")
        return nil
    end

    DebugVFX("FadeIn: duration=" .. duration)

    local easingFunc = GetEasingFunction(easing)
    local tween = Tween:new(0, 1, duration, false, false, easingFunc, function(value, t)
        element.style.opacity = value
    end, onComplete)

    tween:start()
    return tween
end

--[[
  FadeOut: Fades out a UI element from opaque to transparent
  @param element: VisualElement - The UI element to fade out
  @param duration: number (optional) - Animation duration in seconds
  @param easing: string (optional) - Easing function name
  @param onComplete: function (optional) - Callback when animation completes
  @return Tween - The tween object for further control
]]
function FadeOut(element, duration, easing, onComplete)
    duration = duration or _fadeOutDuration
    easing = easing or _defaultEasing

    if not element then
        DebugVFX("FadeOut called with nil element")
        return nil
    end

    DebugVFX("FadeOut: duration=" .. duration)

    local easingFunc = GetEasingFunction(easing)
    local tween = Tween:new(1, 0, duration, false, false, easingFunc, function(value, t)
        element.style.opacity = value
    end, onComplete)

    tween:start()
    return tween
end

--[[
  ScalePulse: Creates a pulsing scale animation on a GameObject
  @param gameObject: GameObject - The object to pulse
  @param fromScale: number - Starting scale multiplier
  @param toScale: number - Ending scale multiplier
  @param duration: number (optional) - Animation duration in seconds
  @param easing: string (optional) - Easing function name
  @param loop: boolean (optional) - Whether to loop the animation
  @param pingPong: boolean (optional) - Whether to reverse on each loop
  @return Tween - The tween object for further control

  Usage:
    PropHuntVFXManager.ScalePulse(propObject, 1.0, 1.2, 0.5, "easeInOutQuad", true, true)
]]
function ScalePulse(gameObject, fromScale, toScale, duration, easing, loop, pingPong)
    duration = duration or _pulseDuration
    easing = easing or "easeInOutQuad"
    loop = loop or false
    pingPong = pingPong or false

    if not gameObject then
        DebugVFX("ScalePulse called with nil gameObject")
        return nil
    end

    DebugVFX("ScalePulse: " .. gameObject.name .. " from " .. fromScale .. " to " .. toScale)

    local originalScale = gameObject.transform.localScale
    local easingFunc = GetEasingFunction(easing)

    local tween = Tween:new(fromScale, toScale, duration, loop, pingPong, easingFunc, function(value, t)
        gameObject.transform.localScale = Vector3.new(
            originalScale.x * value,
            originalScale.y * value,
            originalScale.z * value
        )
    end, nil)

    tween:start()
    return tween
end

--[[
  SlideIn: Slides a UI element from a start position to an end position
  @param element: VisualElement - The UI element to slide
  @param startPos: Vector2 - Starting position (in pixels)
  @param endPos: Vector2 - Ending position (in pixels)
  @param duration: number (optional) - Animation duration in seconds
  @param easing: string (optional) - Easing function name
  @param onComplete: function (optional) - Callback when animation completes
  @return Tween - The tween object for further control

  Note: This animates the translate transform, not absolute position
]]
function SlideIn(element, startPos, endPos, duration, easing, onComplete)
    duration = duration or _slideInDuration
    easing = easing or "easeOutBack"

    if not element then
        DebugVFX("SlideIn called with nil element")
        return nil
    end

    DebugVFX("SlideIn: duration=" .. duration)

    -- We'll use a sequence to animate X and Y together
    local easingFunc = GetEasingFunction(easing)

    -- Create tween for X position
    local tweenX = Tween:new(startPos.x, endPos.x, duration, false, false, easingFunc, function(value, t)
        element.style.translate = Vector2.new(value, element.style.translate.y)
    end, nil)

    -- Create tween for Y position (runs in parallel via TweenGroup)
    local tweenY = Tween:new(startPos.y, endPos.y, duration, false, false, easingFunc, function(value, t)
        element.style.translate = Vector2.new(element.style.translate.x, value)
    end, nil)

    -- Group tweens to run in parallel
    local group = TweenGroup:new()
    group.onComplete = onComplete
    group:add(tweenX)
    group:add(tweenY)
    group:start()

    return group
end

--[[
  PositionTween: Animates a GameObject's position from start to end
  @param gameObject: GameObject - The object to move
  @param startPos: Vector3 - Starting position
  @param endPos: Vector3 - Ending position
  @param duration: number - Animation duration in seconds
  @param easing: string (optional) - Easing function name
  @param onComplete: function (optional) - Callback when animation completes
  @return TweenSequence - The tween sequence for control
]]
function PositionTween(gameObject, startPos, endPos, duration, easing, onComplete)
    easing = easing or "easeOutQuad"

    if not gameObject then
        DebugVFX("PositionTween called with nil gameObject")
        return nil
    end

    DebugVFX("PositionTween: " .. gameObject.name)

    local easingFunc = GetEasingFunction(easing)

    -- We need to animate X, Y, Z simultaneously
    local progress = 0
    local tween = Tween:new(0, 1, duration, false, false, easingFunc, function(t, easedT)
        local newPos = Vector3.new(
            startPos.x + (endPos.x - startPos.x) * easedT,
            startPos.y + (endPos.y - startPos.y) * easedT,
            startPos.z + (endPos.z - startPos.z) * easedT
        )
        gameObject.transform.position = newPos
    end, onComplete)

    tween:start()
    return tween
end

-- ========== GAME-SPECIFIC VFX PLACEHOLDERS ==========
-- These are placeholder functions that trigger VFX at specific positions
-- They will be replaced with actual particle system instantiation later

--[[
  PlayerVanishVFX: Triggers the player vanish effect when a prop possesses

  Spec from GDD:
    - Vertical slice dissolve with soft sparks (0.4s)
    - Player model fades out in vertical bands from bottom to top
    - 3-5 micro sparkles trail upward

  @param position: Vector3 - World position where effect should play
  @param playerCharacter: GameObject (optional) - The player character object
  @return void

  TODO: Replace with particle system instantiation:
    1. Instantiate PlayerVanishVFX prefab at position
    2. Play dissolve shader on playerCharacter material
    3. Spawn upward-moving sparkle particles
    4. Destroy VFX after VFX_PLAYER_VANISH_DURATION
]]
function PlayerVanishVFX(position, playerCharacter)
    DebugVFX("PlayerVanishVFX at " .. tostring(position))

    -- PLACEHOLDER: Log the effect
    -- In final implementation, this will:
    -- 1. Instantiate a particle system prefab
    -- 2. Apply dissolve shader to player material
    -- 3. Schedule destruction after duration

    if playerCharacter then
        -- Placeholder: Scale down player over time
        ScalePulse(playerCharacter, 1.0, 0.0, VFX_PLAYER_VANISH_DURATION, "easeInQuad", false, false)

        -- TODO: Apply vertical slice dissolve shader
        -- local renderer = playerCharacter:GetComponent(Renderer)
        -- if renderer then
        --     local material = renderer.material
        --     -- Animate _DissolveAmount from 0 to 1
        -- end
    end

    -- TODO: Spawn sparkle particles
    print("[VFX PLACEHOLDER] Player Vanish at " .. tostring(position))
end

--[[
  PropInfillVFX: Triggers the prop infill effect when possession completes

  Spec from GDD:
    - Radial mask inwards from edges to center
    - Emissive rim grows then normalizes
    - Prop "materializes" into existence
    - Duration: 0.5s

  @param position: Vector3 - World position of the prop
  @param propObject: GameObject - The prop being possessed
  @return void

  TODO: Replace with shader animation:
    1. Set prop material _InfillProgress to 0
    2. Tween _InfillProgress from 0 to 1 over VFX_PROP_INFILL_DURATION
    3. Set _EmissiveRim intensity: 0 -> 2.0 -> 0.5 (keyframed)
    4. Play subtle "pop" sound effect
]]
function PropInfillVFX(position, propObject)
    DebugVFX("PropInfillVFX at " .. tostring(position))

    -- PLACEHOLDER: Log the effect
    print("[VFX PLACEHOLDER] Prop Infill at " .. tostring(position))

    if propObject then
        -- Placeholder: Scale up prop from tiny to normal
        -- In final version, this will be handled by shader infill mask
        ScalePulse(propObject, 0.1, 1.0, VFX_PROP_INFILL_DURATION, "easeOutBack", false, false)

        -- TODO: Animate shader properties
        -- local renderer = propObject:GetComponent(Renderer)
        -- if renderer then
        --     local material = renderer.material
        --     -- Tween material.SetFloat("_InfillProgress", 0 -> 1)
        --     -- Tween material.SetFloat("_EmissiveRim", 0 -> 2.0 -> 0.5)
        -- end
    end
end

--[[
  RejectionVFX: Triggers the rejection effect when double-possess is attempted

  Spec from GDD:
    - Brief red edge flash (0.2s)
    - "Thunk" sound effect
    - No particle spawn (pure shader effect)

  @param position: Vector3 - World position of the already-possessed prop
  @param propObject: GameObject - The prop that rejected the possession
  @return void

  TODO: Replace with shader flash:
    1. Flash prop outline to red color
    2. Set _OutlineColor to Color.red
    3. Tween _OutlineIntensity: 0 -> 3.0 -> 0 over VFX_REJECTION_DURATION
    4. Play "thunk" audio clip
]]
function RejectionVFX(position, propObject)
    DebugVFX("RejectionVFX at " .. tostring(position))

    -- PLACEHOLDER: Log the effect
    print("[VFX PLACEHOLDER] Rejection at " .. tostring(position))

    if propObject then
        -- Placeholder: Quick shake effect
        local originalPos = propObject.transform.position
        local sequence = TweenSequence:new()

        -- Shake left
        local shake1 = Tween:new(0, 0.1, 0.05, false, false, Easing.linear, function(value, t)
            propObject.transform.position = Vector3.new(
                originalPos.x + value,
                originalPos.y,
                originalPos.z
            )
        end, nil)

        -- Shake right
        local shake2 = Tween:new(0.1, -0.1, 0.1, false, false, Easing.linear, function(value, t)
            propObject.transform.position = Vector3.new(
                originalPos.x + value,
                originalPos.y,
                originalPos.z
            )
        end, nil)

        -- Return to center
        local shake3 = Tween:new(-0.1, 0, 0.05, false, false, Easing.linear, function(value, t)
            propObject.transform.position = Vector3.new(
                originalPos.x + value,
                originalPos.y,
                originalPos.z
            )
        end, nil)

        sequence:add(shake1)
        sequence:add(shake2)
        sequence:add(shake3)
        sequence:start()

        -- TODO: Flash red outline shader
        -- local outline = propObject:GetComponent(Outline)
        -- if outline then
        --     -- Animate outline color to red and back
        -- end
    end
end

--[[
  TagHitVFX: Triggers the successful tag effect when a hunter tags a prop

  Spec from GDD:
    - Compressed ring shock wave at HitPoint (0.25s)
    - 3-5 micro-spark motes radiating outward
    - Chromatic ripples on prop surface
    - Impact sound effect

  @param position: Vector3 - World position of the hit (prop's HitPoint)
  @param propObject: GameObject (optional) - The tagged prop
  @return void

  TODO: Replace with particle system:
    1. Instantiate TagHitVFX prefab at position
    2. Play ring shock particle system
    3. Spawn 3-5 spark particles with radial velocity
    4. Trigger chromatic aberration shader on prop
    5. Play impact audio
    6. Destroy VFX after VFX_TAG_HIT_DURATION
]]
function TagHitVFX(position, propObject)
    DebugVFX("TagHitVFX at " .. tostring(position))

    -- PLACEHOLDER: Log the effect
    print("[VFX PLACEHOLDER] Tag Hit at " .. tostring(position))

    -- TODO: Instantiate hit VFX prefab
    -- local hitVFX = Object.Instantiate(TagHitVFXPrefab, position, Quaternion.identity)
    -- Timer.After(VFX_TAG_HIT_DURATION, function()
    --     Object.Destroy(hitVFX)
    -- end)

    if propObject then
        -- Placeholder: Quick scale punch
        ScalePulse(propObject, 1.0, 0.9, VFX_TAG_HIT_DURATION * 0.5, "easeOutQuad", false, false)
    end
end

--[[
  TagMissVFX: Triggers the miss effect when a hunter's tag doesn't hit anything

  Spec from GDD:
    - Dust poof decal at impact point (0.15s)
    - Color-neutral (gray/white)
    - Small particle burst
    - Soft "whiff" sound

  @param position: Vector3 - World position where the ray hit (or max range point)
  @param normal: Vector3 (optional) - Surface normal for orienting the decal
  @return void

  TODO: Replace with particle system:
    1. Instantiate TagMissVFX prefab at position
    2. Align to surface normal if provided
    3. Play dust poof particle burst
    4. Spawn temporary dust decal
    5. Play "whiff" audio
    6. Destroy VFX after VFX_TAG_MISS_DURATION
]]
function TagMissVFX(position, normal)
    DebugVFX("TagMissVFX at " .. tostring(position))

    -- PLACEHOLDER: Log the effect
    print("[VFX PLACEHOLDER] Tag Miss at " .. tostring(position))

    -- TODO: Instantiate miss VFX prefab
    -- local rotation = Quaternion.identity
    -- if normal then
    --     rotation = Quaternion.LookRotation(normal)
    -- end
    -- local missVFX = Object.Instantiate(TagMissVFXPrefab, position, rotation)
    -- Timer.After(VFX_TAG_MISS_DURATION, function()
    --     Object.Destroy(missVFX)
    -- end)
end

-- ========== ADVANCED ANIMATION HELPERS ==========

--[[
  CreateSequence: Creates a new tween sequence for chaining animations
  @return TweenSequence - An empty sequence ready for tweens

  Usage:
    local seq = PropHuntVFXManager.CreateSequence()
    seq:add(tween1)
    seq:add(tween2)
    seq.onComplete = function() print("Done!") end
    seq:start()
]]
function CreateSequence()
    return TweenSequence:new()
end

--[[
  CreateGroup: Creates a new tween group for parallel animations
  @return TweenGroup - An empty group ready for tweens

  Usage:
    local grp = PropHuntVFXManager.CreateGroup()
    grp:add(tween1)
    grp:add(tween2)
    grp.onComplete = function() print("All done!") end
    grp:start()
]]
function CreateGroup()
    return TweenGroup:new()
end

--[[
  ColorTween: Animates a color property (for materials, UI, etc.)
  @param fromColor: Color - Starting color
  @param toColor: Color - Ending color
  @param duration: number - Animation duration
  @param onUpdate: function(Color) - Callback with current color value
  @param easing: string (optional) - Easing function name
  @param onComplete: function (optional) - Callback when complete
  @return Tween

  Note: This uses the color lerp from devx_tweens
]]
function ColorTween(fromColor, toColor, duration, onUpdate, easing, onComplete)
    easing = easing or "linear"
    local easingFunc = GetEasingFunction(easing)

    local tween = Tween:new(0, 1, duration, false, false, easingFunc, function(t, easedT)
        local currentColor = Color.new(
            fromColor.r + (toColor.r - fromColor.r) * easedT,
            fromColor.g + (toColor.g - fromColor.g) * easedT,
            fromColor.b + (toColor.b - fromColor.b) * easedT,
            fromColor.a + (toColor.a - fromColor.a) * easedT
        )
        if onUpdate then
            onUpdate(currentColor)
        end
    end, onComplete)

    tween:start()
    return tween
end

-- ========== EXPORTED FUNCTIONS ==========
-- Return all public functions for module usage

return {
    -- UI Animation Wrappers
    FadeIn = FadeIn,
    FadeOut = FadeOut,
    ScalePulse = ScalePulse,
    SlideIn = SlideIn,
    PositionTween = PositionTween,

    -- Game VFX Placeholders
    PlayerVanishVFX = PlayerVanishVFX,
    PropInfillVFX = PropInfillVFX,
    RejectionVFX = RejectionVFX,
    TagHitVFX = TagHitVFX,
    TagMissVFX = TagMissVFX,

    -- Advanced Helpers
    CreateSequence = CreateSequence,
    CreateGroup = CreateGroup,
    ColorTween = ColorTween,

    -- Direct access to easing functions if needed
    Easing = Easing
}
