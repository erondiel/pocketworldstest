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

-- ========== NETWORK EVENTS ==========
-- EndRound VFX event for broadcasting to all clients
local endRoundVFXEvent = Event.new("PH_EndRoundVFX")

-- ========== UI ANIMATION CONFIGURATION ==========
-- These values define the visual characteristics of UI animations
-- Adjust these to fine-tune the feel of VFX animations

--!Header("UI Animation Settings")
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

--!Space(10)
--!Header("Player VFX")
--!SerializeField
--!Tooltip("VFX prefab for player vanish effect")
local _playerVanishVFXPrefab : GameObject = nil

--!SerializeField
--!Tooltip("Duration for player vanish VFX (set to longest particle system duration)")
local _playerVanishDuration : number = 2.5

--!SerializeField
--!Tooltip("VFX prefab for player appear effect")
local _playerAppearVFXPrefab : GameObject = nil

--!SerializeField
--!Tooltip("Duration for player appear VFX")
local _playerAppearDuration : number = 2.5

--!Space(10)
--!Header("Prop VFX")
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

--!Space(10)
--!Header("Tag VFX")
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
--!Tooltip("Duration for tag hit scale punch animation")
local _tagHitScalePunchDuration : number = 0.3

--!SerializeField
--!Tooltip("Duration for tag miss scale punch animation")
local _tagMissScalePunchDuration : number = 0.3

--!Space(10)
--!Header("Phase Transition VFX")
--!SerializeField
--!Tooltip("VFX prefab for end round effect (duration matches Round End timer from PropHuntConfig)")
local _endRoundVFXPrefab : GameObject = nil

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
  SpawnUIVFX: Spawns a UI-based VFX (Canvas with RectTransform)
  Unlike SpawnVFX, this handles Screen Space Canvas elements that don't use world position

  @param prefabRef: GameObject - SerializeField reference to UI VFX prefab (must have Canvas component)
  @param duration: number - How long before disabling the VFX
  @param vfxName: string - Name for logging (e.g., "EndRound")
  @return GameObject - The spawned VFX instance (or nil if failed)

  Pattern:
  1. Verify prefabRef is assigned in Inspector
  2. Enable the UI VFX (it positions itself via RectTransform anchors)
  3. Schedule disable after duration
]]
local function SpawnUIVFX(prefabRef, duration, vfxName)
    -- Validate prefab reference
    if not prefabRef then
        print(string.format("[VFX] ERROR: %s UI prefab not assigned in Inspector!", vfxName))
        return nil
    end

    -- The SerializeField reference IS the GameObject itself - use it directly
    local vfxInstance = prefabRef

    -- Enable the VFX GameObject (UI elements position themselves via RectTransform)
    vfxInstance:SetActive(true)

    print(string.format("[VFX] %s UI VFX spawned (screen-space overlay, will disable after %.2fs)", vfxName, duration))

    -- Schedule disable after duration
    Timer.After(duration, function()
        if vfxInstance then
            vfxInstance:SetActive(false)
            print(string.format("[VFX] %s UI VFX disabled after %.2fs", vfxName, duration))
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
    - Player LERP moves from current position to prop position while shrinking

  @param propPosition: Vector3 - World position of the prop (where VFX spawns)
  @param playerCharacter: GameObject (optional) - The player character object
  @return void

  Implementation:
    1. Spawn VFX at prop position (target)
    2. LERP player character from current position to prop position
    3. Simultaneously shrink player character from 1.0 to 0.0
    4. Duration: half of VFX timer (same as shrink)
]]
function PlayerVanishVFX(propPosition, playerCharacter)
    DebugVFX("PlayerVanishVFX at prop position: " .. tostring(propPosition))

    -- Spawn VFX at prop position (the target destination)
    local vfxInstance = SpawnVFX(_playerVanishVFXPrefab, _playerVanishDuration, propPosition, "PlayerVanish")

    -- Shrink duration is half of VFX timer (e.g., 2.5s VFX → 1.25s shrink)
    local shrinkDuration = _playerVanishDuration / 2

    -- Animate player character (scale down + LERP to prop)
    if playerCharacter then
        local startPosition = playerCharacter.transform.position
        local targetPosition = propPosition

        DebugVFX(string.format("Shrinking and moving character over %.2fs (VFX timer: %.2fs)",
            shrinkDuration, _playerVanishDuration))
        DebugVFX(string.format("LERP from (%.1f, %.1f, %.1f) to (%.1f, %.1f, %.1f)",
            startPosition.x, startPosition.y, startPosition.z,
            targetPosition.x, targetPosition.y, targetPosition.z))

        local originalScale = playerCharacter.transform.localScale
        local easingFunc = GetEasingFunction("easeInQuad")

        -- Combined tween: scale + position
        local combinedTween = Tween:new(0.0, 1.0, shrinkDuration, false, false, easingFunc, function(t, easedT)
            -- Scale down (1.0 → 0.0)
            local scaleValue = 1.0 - easedT
            playerCharacter.transform.localScale = Vector3.new(
                originalScale.x * scaleValue,
                originalScale.y * scaleValue,
                originalScale.z * scaleValue
            )

            -- LERP position (startPosition → propPosition)
            local lerpedPosition = Vector3.new(
                startPosition.x + (targetPosition.x - startPosition.x) * easedT,
                startPosition.y + (targetPosition.y - startPosition.y) * easedT,
                startPosition.z + (targetPosition.z - startPosition.z) * easedT
            )
            playerCharacter.transform.position = lerpedPosition
        end, nil)

        combinedTween:start()

        -- NOTE: Material fading disabled - Highrise character materials don't support
        -- alpha modification via material.color. The shrinking animation provides
        -- enough visual feedback for the vanish effect.
    end
end

--[[
  GetPropBoundsSize: Calculates the maximum dimension of a prop's bounds
  @param propGameObject: GameObject - The prop to measure
  @return number - The maximum dimension (x, y, or z) of the bounds, or 1.0 if unavailable
]]
local function GetPropBoundsSize(propGameObject)
    if not propGameObject then
        return 1.0
    end

    local renderer = propGameObject:GetComponent(MeshRenderer)
    if not renderer then
        DebugVFX("GetPropBoundsSize: No MeshRenderer found on " .. propGameObject.name)
        return 1.0
    end

    local bounds = renderer.bounds
    if not bounds then
        DebugVFX("GetPropBoundsSize: No bounds available on " .. propGameObject.name)
        return 1.0
    end

    local size = bounds.size
    -- Return the maximum dimension (largest of x, y, z)
    local maxDim = math.max(size.x, math.max(size.y, size.z))

    DebugVFX(string.format("GetPropBoundsSize: %s bounds = (%.2f, %.2f, %.2f), max = %.2f",
        propGameObject.name, size.x, size.y, size.z, maxDim))

    return maxDim
end

--[[
  PlayerAppearVFX: Triggers the player appear effect when a tagged prop is revealed

  This is the reverse of PlayerVanishVFX:
    - Player character scales from 0.0 to 1.0 (growing)
    - VFX particle system scales based on prop size
    - Duration is half of VFX timer (same as vanish)

  @param position: Vector3 - World position where effect should play
  @param playerCharacter: GameObject (optional) - The player character object
  @param propGameObject: GameObject (optional) - The prop that was possessed (for VFX scaling)
  @return void
]]
function PlayerAppearVFX(position, playerCharacter, propGameObject)
    DebugVFX("PlayerAppearVFX at " .. tostring(position))

    -- Spawn VFX using SerializeField reference
    local vfxInstance = SpawnVFX(_playerAppearVFXPrefab, _playerAppearDuration, position, "PlayerAppear")

    -- Scale VFX based on prop size (if provided)
    if vfxInstance and propGameObject then
        local propSize = GetPropBoundsSize(propGameObject)
        -- Use a scale factor to make VFX proportional to prop size
        -- Factor of 1.5 provides good coverage without being too large
        local vfxScale = propSize * 1.5
        vfxInstance.transform.localScale = Vector3.new(vfxScale, vfxScale, vfxScale)
        DebugVFX(string.format("Scaled PlayerAppear VFX to %.2f (prop size: %.2f)", vfxScale, propSize))
    end

    -- Grow duration is half of VFX timer (same as vanish shrink duration)
    local growDuration = _playerAppearDuration / 2

    -- Scale up player character (reverse of vanish)
    if playerCharacter then
        DebugVFX(string.format("Growing character over %.2fs (VFX timer: %.2fs)",
            growDuration, _playerAppearDuration))

        -- Scale animation (0.0 → 1.0) - REVERSE of vanish
        -- NOTE: Use hardcoded Vector3(1,1,1) instead of originalScale because
        -- the character scale is set to (0,0,0) before this VFX triggers,
        -- so multiplying by originalScale would always result in zero.
        local easingFunc = GetEasingFunction("easeOutQuad")  -- Opposite of vanish's easeInQuad
        local scaleTween = Tween:new(0.0, 1.0, growDuration, false, false, easingFunc, function(value, t)
            playerCharacter.transform.localScale = Vector3.new(value, value, value)
        end, nil)

        scaleTween:start()

        -- NOTE: Material fading disabled - Highrise character materials don't support
        -- alpha modification via material.color. The growing animation provides
        -- enough visual feedback for the appear effect.
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

  @param position: Vector3 - World position of the possessed prop
  @param propObject: GameObject (optional) - The tagged prop (should be provided)
  @return void

  Implementation:
    1. Spawn TagHitVFX particle prefab at prop position
    2. Scale punch animation: 1.0 → 1.2 → 1.0 (ping-pong)
    3. Duration configurable via _tagHitScalePunchDuration
]]
function TagHitVFX(position, propObject)
    DebugVFX("TagHitVFX at " .. tostring(position))

    -- Spawn VFX using SerializeField reference at prop position
    local vfxInstance = SpawnVFX(_tagHitVFXPrefab, _tagHitDuration, position, "TagHit")

    if propObject then
        -- Scale punch: grow to 120% then back to 100%
        -- Half duration to grow, half duration to shrink back
        local halfDuration = _tagHitScalePunchDuration / 2

        DebugVFX(string.format("Tag hit scale punch on %s (%.2fs)", propObject.name, _tagHitScalePunchDuration))

        -- Create sequence: scale up → scale down
        local sequence = TweenSequence:new()

        local originalScale = propObject.transform.localScale

        -- Phase 1: Scale up to 120% (1.0 → 1.2)
        local scaleUp = Tween:new(1.0, 1.2, halfDuration, false, false, Easing.easeOutQuad, function(value, t)
            propObject.transform.localScale = Vector3.new(
                originalScale.x * value,
                originalScale.y * value,
                originalScale.z * value
            )
        end, nil)

        -- Phase 2: Scale back down to 100% (1.2 → 1.0)
        local scaleDown = Tween:new(1.2, 1.0, halfDuration, false, false, Easing.easeInQuad, function(value, t)
            propObject.transform.localScale = Vector3.new(
                originalScale.x * value,
                originalScale.y * value,
                originalScale.z * value
            )
        end, nil)

        sequence:add(scaleUp)
        sequence:add(scaleDown)
        sequence:start()
    else
        DebugVFX("WARNING: TagHitVFX called without propObject - scale punch skipped")
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
  @param propObject: GameObject (optional) - The tapped prop (if any)
  @return void

  Implementation:
    1. Spawn TagMissVFX particle prefab at position
    2. Scale punch animation: 1.0 → 0.8 → 1.0 (shrink then grow back)
    3. Duration configurable via _tagMissScalePunchDuration
]]
function TagMissVFX(position, propObject)
    DebugVFX("TagMissVFX at " .. tostring(position))

    -- Spawn VFX using SerializeField reference
    local vfxInstance = SpawnVFX(_tagMissVFXPrefab, _tagMissDuration, position, "TagMiss")

    if propObject then
        -- Scale punch: shrink to 80% then back to 100% (opposite of hit)
        -- Half duration to shrink, half duration to grow back
        local halfDuration = _tagMissScalePunchDuration / 2

        DebugVFX(string.format("Tag miss scale punch on %s (%.2fs)", propObject.name, _tagMissScalePunchDuration))

        -- Create sequence: scale down → scale up
        local sequence = TweenSequence:new()

        local originalScale = propObject.transform.localScale

        -- Phase 1: Scale down to 80% (1.0 → 0.8)
        local scaleDown = Tween:new(1.0, 0.8, halfDuration, false, false, Easing.easeInQuad, function(value, t)
            propObject.transform.localScale = Vector3.new(
                originalScale.x * value,
                originalScale.y * value,
                originalScale.z * value
            )
        end, nil)

        -- Phase 2: Scale back up to 100% (0.8 → 1.0)
        local scaleUp = Tween:new(0.8, 1.0, halfDuration, false, false, Easing.easeOutQuad, function(value, t)
            propObject.transform.localScale = Vector3.new(
                originalScale.x * value,
                originalScale.y * value,
                originalScale.z * value
            )
        end, nil)

        sequence:add(scaleDown)
        sequence:add(scaleUp)
        sequence:start()
    else
        DebugVFX("WARNING: TagMissVFX called without propObject - scale punch skipped")
    end
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

--[[
  TriggerEndRoundVFX: SERVER-SIDE ONLY - Broadcasts End Round VFX to all clients

  This function should ONLY be called from server-side code (GameManager).
  It broadcasts the event to all clients, who will then spawn the VFX locally.

  Spec from GDD:
    - Victory/defeat screen transition
    - Score celebration effects
    - Confetti or sparkle bursts
    - Winner announcement effects

  @param winningTeam: string - "Props" or "Hunters"
  @param winningPlayers: table - List of winning players
  @return void
]]
function TriggerEndRoundVFX(winningTeam, winningPlayers)
    DebugVFX("SERVER: Broadcasting EndRound VFX to all clients - winning team: " .. tostring(winningTeam))

    -- Broadcast event to ALL clients (they will spawn the VFX locally)
    local winningPlayersCount = winningPlayers and #winningPlayers or 0
    endRoundVFXEvent:FireAllClients(winningTeam, winningPlayersCount)

    print("[VFX] SERVER: Broadcast EndRound VFX event (team: " .. tostring(winningTeam) .. ", players: " .. tostring(winningPlayersCount) .. ")")
end

--[[
  PlayEndRoundVFX: CLIENT-SIDE ONLY - Spawns the End Round VFX locally

  This function is called by the network event listener on each client.
  It actually spawns and plays the VFX prefab.

  @param winningTeam: string - "Props" or "Hunters"
  @param winningPlayersCount: number - Number of winning players
  @return void
]]
local function PlayEndRoundVFX(winningTeam, winningPlayersCount)
    DebugVFX("CLIENT: Playing EndRound VFX - winning team: " .. tostring(winningTeam))

    -- Use Round End timer duration from PropHuntConfig
    local vfxDuration = PropHuntConfig.GetRoundEndTime()
    DebugVFX("VFX duration: " .. vfxDuration .. "s (matches Round End timer)")

    -- Spawn UI VFX (Screen Space Canvas) - no position needed
    local vfxInstance = SpawnUIVFX(_endRoundVFXPrefab, vfxDuration, "EndRound")

    -- PLACEHOLDER: Log the transition
    print("[VFX PLACEHOLDER] End round VFX - victory screen, confetti, score celebration")
    print("[VFX] Winning team: " .. tostring(winningTeam))
    print("[VFX] VFX duration: " .. vfxDuration .. "s")
    print("[VFX] Winning players count: " .. tostring(winningPlayersCount))

    -- TODO: Implement end round VFX:
    -- 1. Spawn confetti/sparkle particle systems
    -- 2. Play victory/defeat screen transition
    -- 3. Trigger score celebration effects
    -- 4. Play winner announcement sound effects
    -- 5. Display team-specific victory animations
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

-- ========== CLIENT LIFECYCLE ==========
-- Module type with ClientStart to listen for network events

function self:ClientStart()
    -- Listen for EndRound VFX event from server
    endRoundVFXEvent:Connect(function(winningTeam, winningPlayersCount)
        PlayEndRoundVFX(winningTeam, winningPlayersCount)
    end)

    print("[VFX] Client started - listening for EndRound VFX events")
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
    TriggerEndRoundVFX = TriggerEndRoundVFX,

    -- Advanced Helpers
    CreateSequence = CreateSequence,
    CreateGroup = CreateGroup,
    ColorTween = ColorTween,

    -- Direct access to easing functions if needed
    Easing = Easing
}
