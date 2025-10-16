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

-- ========== VFX PREFAB REFERENCES (SerializeField) ==========
-- Drag VFX prefabs from VFXPrefabs GameObject in Unity Inspector
-- These are used to get the GameObject name, then we find it at runtime

--!SerializeField
--!Tooltip("VFX prefab for player vanish effect")
local _playerVanishVFXPrefab : GameObject = nil

--!SerializeField
--!Tooltip("Duration for player vanish VFX (set to longest particle system duration)")
local _playerVanishDuration : number = 2.5

--!SerializeField
--!Tooltip("VFX prefab for prop infill effect")
local _propInfillVFXPrefab : GameObject = nil

--!SerializeField
--!Tooltip("Duration for prop infill VFX (auto-filled from particle system)")
local _propInfillDuration : number = 1.2

--!SerializeField
--!Tooltip("VFX prefab for rejection effect")
local _rejectionVFXPrefab : GameObject = nil

--!SerializeField
--!Tooltip("Duration for rejection VFX (auto-filled from particle system)")
local _rejectionDuration : number = 0.2

--!SerializeField
--!Tooltip("VFX prefab for tag hit effect")
local _tagHitVFXPrefab : GameObject = nil

--!SerializeField
--!Tooltip("Duration for tag hit VFX (auto-filled from particle system)")
local _tagHitDuration : number = 0.25

--!SerializeField
--!Tooltip("VFX prefab for tag miss effect")
local _tagMissVFXPrefab : GameObject = nil

--!SerializeField
--!Tooltip("Duration for tag miss VFX (auto-filled from particle system)")
local _tagMissDuration : number = 0.15

--!SerializeField
--!Tooltip("VFX prefab for player appear effect")
local _playerAppearVFXPrefab : GameObject = nil

--!SerializeField
--!Tooltip("Duration for player appear VFX")
local _playerAppearDuration : number = 2.5

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
  SpawnVFX: Finds and spawns a VFX prefab at the specified position
  Uses SerializeField reference to get GameObject name, then finds it in scene

  @param prefabRef: GameObject - SerializeField reference to VFX prefab
  @param position: Vector3 - World position to spawn VFX
  @param duration: number - How long before destroying the VFX
  @param vfxName: string - Name for logging (e.g., "PlayerVanish")
  @return GameObject - The spawned VFX instance (or nil if failed)

  Pattern:
  1. Check if prefabRef is assigned in Inspector
  2. Get the GameObject name from the reference
  3. Find the GameObject in scene (should be child of VFXPrefabs, disabled)
  4. Enable it at the target position
  5. Schedule destruction after duration
]]
local function SpawnVFX(prefabRef, duration, position, vfxName)
    -- Validate prefab reference
    if not prefabRef then
        print(string.format("[VFX] ERROR: %s prefab not assigned in Inspector!", vfxName))
        return nil
    end

    -- The SerializeField reference IS the GameObject itself - use it directly
    local vfxInstance = prefabRef

    -- Move to target position
    vfxInstance.transform.position = position

    -- Enable the VFX GameObject (works even if it's disabled)
    vfxInstance:SetActive(true)

    print(string.format("[VFX] %s VFX spawned at %s (will disable after %.2fs)", vfxName, tostring(position), duration))

    -- Schedule disable after duration
    Timer.After(duration, function()
        if vfxInstance then
            vfxInstance:SetActive(false)
            print(string.format("[VFX] %s VFX disabled after %.2fs", vfxName, duration))
        end
    end)

    return vfxInstance
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

    -- Spawn VFX using SerializeField reference
    local vfxInstance = SpawnVFX(_playerVanishVFXPrefab, _playerVanishDuration, position, "PlayerVanish")

    -- Shrink duration is half of VFX timer (e.g., 2.5s VFX → 1.25s shrink)
    local shrinkDuration = _playerVanishDuration / 2

    -- Scale down and fade out player character simultaneously
    if playerCharacter then
        DebugVFX(string.format("Shrinking and fading character over %.2fs (VFX timer: %.2fs)",
            shrinkDuration, _playerVanishDuration))

        -- Get all renderers on the character to fade them out
        local renderers = playerCharacter:GetComponentsInChildren(SkinnedMeshRenderer, true)

        -- Create a group to run scale and fade in parallel
        local tweenGroup = TweenGroup:new()

        -- 1. Scale animation (1.0 → 0.0)
        local originalScale = playerCharacter.transform.localScale
        local easingFunc = GetEasingFunction("easeInQuad")
        local scaleTween = Tween:new(1.0, 0.0, shrinkDuration, false, false, easingFunc, function(value, t)
            playerCharacter.transform.localScale = Vector3.new(
                originalScale.x * value,
                originalScale.y * value,
                originalScale.z * value
            )
        end, nil)

        tweenGroup:add(scaleTween)

        -- 2. Fade animation (1.0 → 0.0 alpha) for each renderer
        if renderers and #renderers > 0 then
            for i = 1, #renderers do
                local renderer = renderers[i]
                if renderer and renderer.material then
                    -- Get current color
                    local material = renderer.material
                    local originalColor = material.color

                    -- Create fade tween for this renderer's material
                    local fadeTween = Tween:new(1.0, 0.0, shrinkDuration, false, false, easingFunc, function(alpha, t)
                        -- Update material alpha
                        material.color = Color.new(
                            originalColor.r,
                            originalColor.g,
                            originalColor.b,
                            alpha
                        )
                    end, nil)

                    tweenGroup:add(fadeTween)
                end
            end

            DebugVFX(string.format("Fading %d renderer materials", #renderers))
        else
            DebugVFX("No renderers found on character - skipping fade")
        end

        -- Start all animations together
        tweenGroup:start()
    end
end

--[[
  PlayerAppearVFX: Triggers the player appear effect when a tagged prop is revealed

  This is the reverse of PlayerVanishVFX:
    - Player character scales from 0.0 to 1.0 (growing)
    - Player character fades from transparent to opaque
    - Duration is half of VFX timer (same as vanish)

  @param position: Vector3 - World position where effect should play
  @param playerCharacter: GameObject (optional) - The player character object
  @return void
]]
function PlayerAppearVFX(position, playerCharacter)
    DebugVFX("PlayerAppearVFX at " .. tostring(position))

    -- Spawn VFX using SerializeField reference
    local vfxInstance = SpawnVFX(_playerAppearVFXPrefab, _playerAppearDuration, position, "PlayerAppear")

    -- Grow duration is half of VFX timer (same as vanish shrink duration)
    local growDuration = _playerAppearDuration / 2

    -- Scale up and fade in player character simultaneously (reverse of vanish)
    if playerCharacter then
        DebugVFX(string.format("Growing and fading in character over %.2fs (VFX timer: %.2fs)",
            growDuration, _playerAppearDuration))

        -- Get all renderers on the character to fade them in
        local renderers = playerCharacter:GetComponentsInChildren(SkinnedMeshRenderer, true)

        -- Create a group to run scale and fade in parallel
        local tweenGroup = TweenGroup:new()

        -- 1. Scale animation (0.0 → 1.0) - REVERSE of vanish
        local originalScale = playerCharacter.transform.localScale
        local easingFunc = GetEasingFunction("easeOutQuad")  -- Opposite of vanish's easeInQuad
        local scaleTween = Tween:new(0.0, 1.0, growDuration, false, false, easingFunc, function(value, t)
            playerCharacter.transform.localScale = Vector3.new(
                originalScale.x * value,
                originalScale.y * value,
                originalScale.z * value
            )
        end, nil)

        tweenGroup:add(scaleTween)

        -- 2. Fade animation (0.0 → 1.0 alpha) - REVERSE of vanish
        if renderers and #renderers > 0 then
            for i = 1, #renderers do
                local renderer = renderers[i]
                if renderer and renderer.material then
                    -- Get current color
                    local material = renderer.material
                    local originalColor = material.color

                    -- Create fade tween for this renderer's material (fade IN from transparent)
                    local fadeTween = Tween:new(0.0, 1.0, growDuration, false, false, easingFunc, function(alpha, t)
                        -- Update material alpha
                        material.color = Color.new(
                            originalColor.r,
                            originalColor.g,
                            originalColor.b,
                            alpha
                        )
                    end, nil)

                    tweenGroup:add(fadeTween)
                end
            end

            DebugVFX(string.format("Fading in %d renderer materials", #renderers))
        else
            DebugVFX("No renderers found on character - skipping fade")
        end

        -- Start all animations together
        tweenGroup:start()
    end

    return vfxInstance
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

    -- Spawn VFX using SerializeField reference
    local vfxInstance = SpawnVFX(_propInfillVFXPrefab, _propInfillDuration, position, "PropInfill")

    if propObject then
        -- Placeholder: Scale up prop from tiny to normal
        -- In final version, this will be handled by shader infill mask
        ScalePulse(propObject, 0.1, 1.0, _propInfillDuration, "easeOutBack", false, false)

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

    -- Spawn VFX using SerializeField reference
    local vfxInstance = SpawnVFX(_rejectionVFXPrefab, _rejectionDuration, position, "Rejection")

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

    -- Spawn VFX using SerializeField reference
    local vfxInstance = SpawnVFX(_tagHitVFXPrefab, _tagHitDuration, position, "TagHit")

    if propObject then
        -- Placeholder: Quick scale punch
        ScalePulse(propObject, 1.0, 0.9, _tagHitDuration * 0.5, "easeOutQuad", false, false)
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

    -- Spawn VFX using SerializeField reference
    local vfxInstance = SpawnVFX(_tagMissVFXPrefab, _tagMissDuration, position, "TagMiss")

    -- TODO: Rotate VFX to align with surface normal if provided
    -- if vfxInstance and normal then
    --     vfxInstance.transform.rotation = Quaternion.LookRotation(normal)
    -- end
end

-- ========== PHASE TRANSITION VFX ==========
-- These functions trigger VFX for major game state transitions
-- Currently placeholders - will be enhanced with full VFX in future versions

--[[
  TriggerLobbyTransition: Plays VFX when transitioning to Lobby state

  Spec from GDD:
    - World desaturates in Lobby area
    - Arena area remains neutral
    - Subtle ambient particles in lobby

  @return void
]]
function TriggerLobbyTransition()
    DebugVFX("TriggerLobbyTransition - Entering Lobby state")

    -- PLACEHOLDER: Log the transition
    print("[VFX PLACEHOLDER] Lobby transition - desaturate world, spawn lobby particles")

    -- TODO: Implement lobby transition VFX:
    -- 1. Apply desaturation LUT to lobby area cameras
    -- 2. Spawn ambient particles in lobby
    -- 3. Fade in lobby UI elements
end

--[[
  TriggerHidePhaseStart: Plays VFX when Hide phase begins

  Spec from GDD:
    - Arena gains quick pulse-in gradient
    - Teleport beams on Props and Spectators
    - Green outlines enable on all possessable props

  @param propsTeam: table - List of players assigned to prop role
  @return void
]]
function TriggerHidePhaseStart(propsTeam)
    DebugVFX("TriggerHidePhaseStart - Hide phase starting with " .. tostring(#propsTeam) .. " props")

    -- PLACEHOLDER: Log the transition
    print("[VFX PLACEHOLDER] Hide phase start - pulse arena, teleport beams, enable outlines")

    -- TODO: Implement hide phase VFX:
    -- 1. Play arena pulse gradient (radial from center, 0.5s)
    -- 2. Spawn teleport beam VFX at each prop player position
    -- 3. Enable green outline shader on all Possessable objects
    -- 4. Play ambient "hiding music" transition

    -- For now, just log the prop team size
    if propsTeam then
        print("[VFX] Props team size: " .. tostring(#propsTeam))
    end
end

--[[
  TriggerHuntPhaseStart: Plays VFX when Hunt phase begins

  Spec from GDD:
    - Arena vignette expands
    - All green outlines globally fade with synchronized dissolve sweep
    - Tension music ramps up

  @return void
]]
function TriggerHuntPhaseStart()
    DebugVFX("TriggerHuntPhaseStart - Hunt phase starting")

    -- PLACEHOLDER: Log the transition
    print("[VFX PLACEHOLDER] Hunt phase start - expand vignette, fade outlines, tension music")

    -- TODO: Implement hunt phase VFX:
    -- 1. Expand arena vignette (from 0.3 to 0.7 over 1.0s)
    -- 2. Fade all green outlines with synchronized dissolve sweep
    -- 3. Disable outline shader keywords on all Possessable objects
    -- 4. Ramp up tension music track
    -- 5. Play hunt horn sound effect
end

-- ========== SCREEN FADE TRANSITIONS ==========
-- Full-screen fade effects for camera transitions during teleportation

-- Reference to fade overlay element (set by client)
local fadeOverlayElement = nil

--[[
  InitializeFadeOverlay: Sets up the fade overlay element
  Must be called from client with the fade overlay UI element
  @param element: VisualElement - The fade overlay from PropHuntHUD
]]
function InitializeFadeOverlay(element)
    fadeOverlayElement = element
    if fadeOverlayElement then
        -- Ensure it starts invisible
        fadeOverlayElement.style.opacity = 0
        fadeOverlayElement.style.display = "none"
        DebugVFX("Fade overlay initialized")
    end
end

--[[
  ScreenFadeTransition: Fades to black, executes action, then fades back
  Perfect for hiding camera movement during teleportation

  @param fadeOutDuration: number - Duration of fade to black (default: 0.3s)
  @param waitDuration: number - How long to stay black (default: 0.1s)
  @param fadeInDuration: number - Duration of fade from black (default: 0.3s)
  @param onFadedOut: function (optional) - Callback when fully black (do teleport here)
  @param onComplete: function (optional) - Callback when transition complete

  Usage:
    VFXManager.ScreenFadeTransition(0.3, 0.1, 0.3, function()
        -- Camera teleports here (during black screen)
        player.character.transform.position = targetPosition
    end, function()
        print("Fade transition complete!")
    end)
]]
function ScreenFadeTransition(fadeOutDuration, waitDuration, fadeInDuration, onFadedOut, onComplete)
    if not fadeOverlayElement then
        DebugVFX("ERROR: Fade overlay not initialized! Call InitializeFadeOverlay first")
        if onFadedOut then onFadedOut() end
        if onComplete then onComplete() end
        return
    end

    fadeOutDuration = fadeOutDuration or 0.3
    waitDuration = waitDuration or 0.1
    fadeInDuration = fadeInDuration or 0.3

    DebugVFX(string.format("ScreenFadeTransition: out=%.2fs, wait=%.2fs, in=%.2fs",
        fadeOutDuration, waitDuration, fadeInDuration))

    -- Show overlay
    fadeOverlayElement.style.display = "flex"

    -- Create sequence: fade out → wait → fade in
    local sequence = TweenSequence:new()

    -- 1. Fade to black (opacity 0 → 1)
    local fadeOut = Tween:new(0, 1, fadeOutDuration, false, false, Easing.easeInQuad, function(value, t)
        fadeOverlayElement.style.opacity = value
    end, function()
        -- Fully black - execute teleport action
        if onFadedOut then
            onFadedOut()
        end
    end)

    -- 2. Wait timer (stay black)
    local waitTween = Tween:new(0, 1, waitDuration, false, false, Easing.linear, function(value, t)
        -- Do nothing, just wait
    end, nil)

    -- 3. Fade from black (opacity 1 → 0)
    local fadeIn = Tween:new(1, 0, fadeInDuration, false, false, Easing.easeOutQuad, function(value, t)
        fadeOverlayElement.style.opacity = value
    end, function()
        -- Fade complete - hide overlay
        fadeOverlayElement.style.display = "none"
        DebugVFX("ScreenFadeTransition complete")
        if onComplete then
            onComplete()
        end
    end)

    -- Add to sequence
    sequence:add(fadeOut)
    sequence:add(waitTween)
    sequence:add(fadeIn)
    sequence:start()

    return sequence
end

--[[
  QuickFadeToBlack: Immediately fade to black
  @param duration: number (optional) - Fade duration (default: 0.3s)
  @param onComplete: function (optional) - Callback when fade complete
]]
function QuickFadeToBlack(duration, onComplete)
    if not fadeOverlayElement then
        DebugVFX("ERROR: Fade overlay not initialized!")
        if onComplete then onComplete() end
        return
    end

    duration = duration or 0.3
    fadeOverlayElement.style.display = "flex"

    local tween = Tween:new(0, 1, duration, false, false, Easing.easeInQuad, function(value, t)
        fadeOverlayElement.style.opacity = value
    end, onComplete)

    tween:start()
    return tween
end

--[[
  QuickFadeFromBlack: Immediately fade from black to clear
  @param duration: number (optional) - Fade duration (default: 0.3s)
  @param onComplete: function (optional) - Callback when fade complete
]]
function QuickFadeFromBlack(duration, onComplete)
    if not fadeOverlayElement then
        DebugVFX("ERROR: Fade overlay not initialized!")
        if onComplete then onComplete() end
        return
    end

    duration = duration or 0.3

    local tween = Tween:new(1, 0, duration, false, false, Easing.easeOutQuad, function(value, t)
        fadeOverlayElement.style.opacity = value
    end, function()
        fadeOverlayElement.style.display = "none"
        if onComplete then onComplete() end
    end)

    tween:start()
    return tween
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

    -- Screen Fade Transitions
    InitializeFadeOverlay = InitializeFadeOverlay,
    ScreenFadeTransition = ScreenFadeTransition,
    QuickFadeToBlack = QuickFadeToBlack,
    QuickFadeFromBlack = QuickFadeFromBlack,

    -- Game VFX Placeholders
    PlayerVanishVFX = PlayerVanishVFX,
    PlayerAppearVFX = PlayerAppearVFX,
    PropInfillVFX = PropInfillVFX,
    RejectionVFX = RejectionVFX,
    TagHitVFX = TagHitVFX,
    TagMissVFX = TagMissVFX,

    -- Phase Transition VFX
    TriggerLobbyTransition = TriggerLobbyTransition,
    TriggerHidePhaseStart = TriggerHidePhaseStart,
    TriggerHuntPhaseStart = TriggerHuntPhaseStart,

    -- Advanced Helpers
    CreateSequence = CreateSequence,
    CreateGroup = CreateGroup,
    ColorTween = ColorTween,

    -- Direct access to easing functions if needed
    Easing = Easing
}
