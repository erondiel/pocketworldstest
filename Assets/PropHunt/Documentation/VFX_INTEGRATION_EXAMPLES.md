# PropHunt VFX Integration Examples

This document provides practical examples of integrating the VFX system into existing PropHunt scripts.

## Table of Contents
- [PropDisguiseSystem Integration](#propdisguisesystem-integration)
- [HunterTagSystem Integration](#huntertagsystem-integration)
- [PropHuntGameManager Integration](#prophuntgamemanager-integration)
- [PropHuntHUD Integration](#prophunthud-integration)
- [Testing VFX](#testing-vfx)

---

## PropDisguiseSystem Integration

### Current Flow
When a player successfully possesses a prop, we need to trigger two VFX:
1. **PlayerVanishVFX** - Player character dissolves
2. **PropInfillVFX** - Prop materializes

### Integration Points

Add this to `/Assets/PropHunt/Scripts/PropDisguiseSystem.lua`:

```lua
--!Type(Client)

-- Add VFX module import at the top
local VFX = require("PropHuntVFXManager")

-- ... existing code ...

-- In the function that handles successful possession (likely OnDisguiseApplied or similar)
function OnPossessionSuccess(player, propObject)
    -- Existing possession logic here
    -- ...

    -- NEW: Trigger VFX
    if player and player.character then
        local playerPos = player.character.transform.position
        VFX.PlayerVanishVFX(playerPos, player.character)
    end

    if propObject then
        local propPos = propObject.transform.position
        VFX.PropInfillVFX(propPos, propObject)
    end

    -- Continue with existing logic
end

-- In the function that handles possession rejection (double-possess attempt)
function OnPossessionRejected(propObject)
    -- Existing rejection logic here
    -- ...

    -- NEW: Trigger rejection VFX
    if propObject then
        local propPos = propObject.transform.position
        VFX.RejectionVFX(propPos, propObject)
    end

    -- Maybe show UI message: "This prop is already taken!"
end
```

### Server-Side Validation

If possession validation happens server-side, you'll need to fire a client event:

```lua
--!Type(Server)

-- In PropDisguiseSystem server script
local PossessionVFXEvent = Event.new("PH_PossessionVFX")

function ServerApplyDisguise(player, propId)
    -- Validate possession attempt
    local propObject = GetPropById(propId)
    local possessable = propObject:GetComponent(Possessable)

    if possessable.IsPossessed then
        -- Already possessed - send rejection VFX
        PossessionVFXEvent:FireClient(player, "rejection", propId)
        return false
    end

    -- Success - apply disguise
    possessable.IsPossessed = true
    possessable.OwnerPlayerId = player.user.id

    -- Send success VFX to all clients
    PossessionVFXEvent:FireAllClients("success", player.user.id, propId)
    return true
end
```

```lua
--!Type(Client)

local VFX = require("PropHuntVFXManager")

-- Listen for possession VFX events from server
local PossessionVFXEvent = Event.new("PH_PossessionVFX")

PossessionVFXEvent:Connect(function(eventType, arg1, arg2)
    if eventType == "success" then
        local playerId = arg1
        local propId = arg2

        local player = GetPlayerById(playerId)
        local propObject = GetPropById(propId)

        if player and player.character then
            VFX.PlayerVanishVFX(player.character.transform.position, player.character)
        end

        if propObject then
            VFX.PropInfillVFX(propObject.transform.position, propObject)
        end

    elseif eventType == "rejection" then
        local propId = arg1
        local propObject = GetPropById(propId)

        if propObject then
            VFX.RejectionVFX(propObject.transform.position, propObject)
        end
    end
end)
```

---

## HunterTagSystem Integration

### Current Flow
When a hunter taps to tag:
1. Raycast from player origin toward tap point
2. Check if hit a Possessable
3. Server validates and eliminates prop OR registers miss

### Integration Points

Add this to `/Assets/PropHunt/Scripts/HunterTagSystem.lua`:

```lua
--!Type(Client)

local VFX = require("PropHuntVFXManager")

-- ... existing input handling ...

Input.Tapped:Connect(function(tap : TapEvent)
    -- Existing raycast logic
    local camera = Camera.main
    local ray = camera:ScreenPointToRay(tap.position)

    local hit, hitInfo = Physics.Raycast(ray, maxDistance, layerMask)

    if hit then
        local possessable = hitInfo.transform:GetComponent(Possessable)

        if possessable and possessable.IsPossessed then
            -- Potential hit - send to server for validation
            TagRequestFunc:InvokeServer(possessable.gameObject.instanceId)

            -- OPTIMISTIC VFX: Play hit effect immediately (before server confirms)
            -- This makes the game feel more responsive
            VFX.TagHitVFX(hitInfo.point, hitInfo.transform.gameObject)

            -- NOTE: If server rejects (out of range, cooldown), we don't "undo" the VFX
            -- because it's so brief (0.25s) that it'll be gone before the rejection
        else
            -- Hit something that's not a prop - immediate miss VFX
            VFX.TagMissVFX(hitInfo.point, hitInfo.normal)
        end
    else
        -- Didn't hit anything - miss VFX at max range
        local missPosition = ray.origin + ray.direction * maxDistance
        VFX.TagMissVFX(missPosition, nil)
    end
end)
```

### Server-Side Confirmation

```lua
--!Type(Server)

-- In HunterTagSystem server validation
local TagConfirmEvent = Event.new("PH_TagConfirm")

TagRequestFunc.OnInvokeServer = function(player, propInstanceId)
    -- Validate cooldown
    if not CanTag(player) then
        return false, "Cooldown"
    end

    -- Validate distance
    local propObject = GetObjectByInstanceId(propInstanceId)
    if not propObject then
        return false, "Not Found"
    end

    local distance = Vector3.Distance(player.character.transform.position, propObject.transform.position)
    if distance > Config.GetTagRange() then
        return false, "Out of Range"
    end

    -- Validate possession state
    local possessable = propObject:GetComponent(Possessable)
    if not possessable or not possessable.IsPossessed then
        return false, "Not Possessed"
    end

    -- SUCCESS - eliminate prop
    EliminateProp(possessable.OwnerPlayerId)

    -- Award points to hunter
    AwardPoints(player, CalculateTagPoints(propObject))

    -- Fire confirmed tag event to all clients for VFX sync
    local hitPoint = possessable.HitPoint and possessable.HitPoint.position or propObject.transform.position
    TagConfirmEvent:FireAllClients("hit", player.user.id, propInstanceId, hitPoint)

    return true, "Tagged"
end
```

```lua
--!Type(Client)

local VFX = require("PropHuntVFXManager")

-- Listen for server-confirmed tags (for non-shooter clients to see VFX)
local TagConfirmEvent = Event.new("PH_TagConfirm")

TagConfirmEvent:Connect(function(eventType, hunterId, propInstanceId, hitPoint)
    if eventType == "hit" then
        local propObject = GetObjectByInstanceId(propInstanceId)

        -- Only play VFX for OTHER clients (shooter already played optimistic VFX)
        if propObject and client.localPlayer.user.id ~= hunterId then
            VFX.TagHitVFX(hitPoint, propObject)
        end

        -- Play additional "elimination" VFX here
        -- e.g., prop explosion, score popup, etc.
    end
end)
```

---

## PropHuntGameManager Integration

### Phase Transition VFX

Add phase transition effects to create visual polish between game states.

```lua
--!Type(Module)

local VFX = require("PropHuntVFXManager")

-- ... existing PropHuntGameManager code ...

function TransitionToState(newState)
    local oldState = _currentState
    _currentState = newState

    -- Trigger phase-specific VFX
    if newState == GameState.HIDING then
        OnEnterHidePhase()
    elseif newState == GameState.HUNTING then
        OnEnterHuntPhase()
    elseif newState == GameState.ROUND_END then
        OnEnterRoundEndPhase()
    end

    -- Fire state change event to clients
    StateChangeEvent:FireAllClients(newState, GetPhaseTimer(newState))
end

-- CLIENT-SIDE PHASE VFX
function OnEnterHidePhase()
    -- Called on clients when Hide phase starts

    -- 1. Desaturate lobby area
    ApplyLobbyDesaturation()

    -- 2. Arena pulse-in gradient
    local arenaLight = GameObject.Find("ArenaMainLight")
    if arenaLight then
        local light = arenaLight:GetComponent(Light)
        VFX.ColorTween(
            Color.new(1, 1, 1, 0.5),  -- Dim
            Color.new(1, 1, 1, 1.0),  -- Bright
            0.8,
            function(color)
                light.intensity = color.a
            end,
            "easeOutQuad"
        )
    end

    -- 3. Teleport beams on Props/Spectators
    for _, player in ipairs(GetPropPlayers()) do
        SpawnTeleportBeam(player.transform.position)
    end

    -- 4. Enable green outlines on all possessable props
    EnablePropOutlines(true)
end

function OnEnterHuntPhase()
    -- Called on clients when Hunt phase starts

    -- 1. Expand arena vignette
    ExpandArenaVignette()

    -- 2. Fade out all green outlines globally with synchronized dissolve sweep
    DisablePropOutlines(true)  -- true = animated fade

    -- 3. Play hunt phase sound sting
    PlayHuntPhaseSound()
end

function OnEnterRoundEndPhase()
    -- Called on clients when round ends

    -- 1. Determine winner team
    local winnerTeam = GetWinnerTeam()

    if winnerTeam == "Props" then
        -- Confetti/sparkles for prop team
        SpawnConfettiVFX(GetArenaCenter())
    elseif winnerTeam == "Hunters" then
        -- Hunter victory VFX
        SpawnHunterVictoryVFX()
    end

    -- 2. Show score tally with animated ribbon trails
    AnimateScoreTally()
end

-- Helper: Animated outline disable
function DisablePropOutlines(animated)
    local props = GetAllPossessableProps()

    if not animated then
        -- Instant disable
        for _, prop in ipairs(props) do
            local outline = prop:GetComponent(Outline)
            if outline then
                outline.enabled = false
            end
        end
        return
    end

    -- Animated sweep disable
    local sweepDuration = 1.5
    local startTime = Time.time

    for i, prop in ipairs(props) do
        local outline = prop:GetComponent(Outline)
        if outline then
            -- Stagger the fade based on prop position (creates wave effect)
            local delay = (i / #props) * 0.5

            Timer.After(delay, function()
                -- Fade outline alpha from 1 to 0
                VFX.ColorTween(
                    Color.new(0, 1, 0, 1),  -- Green, opaque
                    Color.new(0, 1, 0, 0),  -- Green, transparent
                    0.5,
                    function(color)
                        outline.OutlineColor = color
                    end,
                    "easeOutQuad",
                    function()
                        outline.enabled = false
                    end
                )
            end)
        end
    end
end
```

---

## PropHuntHUD Integration

### Timer Flash Effect

Make the timer flash red when time is running out.

```lua
--!Type(Client)

-- In PropHuntHUD.lua
local VFX = require("PropHuntVFXManager")

-- ... existing HUD code ...

local _isTimerFlashing = false

function UpdateTimer(secondsRemaining)
    local timerLabel = _document:Q("timer-label")
    if not timerLabel then return end

    timerLabel.text = FormatTime(secondsRemaining)

    -- Flash red when 10 seconds or less remain
    if secondsRemaining <= 10 and secondsRemaining > 0 then
        if not _isTimerFlashing then
            _isTimerFlashing = true
            StartTimerFlash(timerLabel)
        end
    else
        _isTimerFlashing = false
        timerLabel.style.color = Color.white
    end
end

function StartTimerFlash(timerLabel)
    if not _isTimerFlashing then return end

    -- Flash sequence: white -> red -> white (loops)
    local seq = VFX.CreateSequence()

    -- Fade to red
    local toRed = VFX.ColorTween(
        Color.white,
        Color.red,
        0.3,
        function(color)
            timerLabel.style.color = color
        end,
        "easeInQuad"
    )
    seq:add(toRed)

    -- Fade back to white
    local toWhite = VFX.ColorTween(
        Color.red,
        Color.white,
        0.3,
        function(color)
            timerLabel.style.color = color
        end,
        "easeOutQuad"
    )
    seq:add(toWhite)

    seq.onComplete = function()
        -- Loop if still flashing
        Timer.After(0.2, function()
            StartTimerFlash(timerLabel)
        end)
    end

    seq:start()
end
```

### Phase Banner Animation

Slide in a banner when phase changes.

```lua
--!Type(Client)

-- In PropHuntHUD.lua
local VFX = require("PropHuntVFXManager")

function ShowPhaseBanner(phaseName)
    local banner = _document:Q("phase-banner")
    local text = _document:Q("phase-text")

    if not banner or not text then return end

    text.text = phaseName

    -- Make visible but transparent
    banner.style.opacity = 0
    banner.style.display = "flex"

    -- Position off-screen top
    banner.style.translate = Vector2.new(0, -200)

    -- Animate in
    local group = VFX.CreateGroup()

    -- Slide down
    local slideDown = VFX.SlideIn(
        banner,
        Vector2.new(0, -200),  -- Start: off-screen top
        Vector2.new(0, 0),     -- End: on-screen
        0.6,
        "easeOutBack"
    )
    group:add(slideDown)

    -- Fade in
    local fadeIn = VFX.FadeIn(banner, 0.4, "easeOutQuad")
    group:add(fadeIn)

    group.onComplete = function()
        -- Hold for 2 seconds
        Timer.After(2.0, function()
            HidePhaseBanner(banner)
        end)
    end

    group:start()
end

function HidePhaseBanner(banner)
    -- Slide up and fade out
    local group = VFX.CreateGroup()

    local slideUp = VFX.SlideIn(
        banner,
        Vector2.new(0, 0),     -- Start: on-screen
        Vector2.new(0, -200),  -- End: off-screen top
        0.4,
        "easeInBack"
    )
    group:add(slideUp)

    local fadeOut = VFX.FadeOut(banner, 0.3, "easeInQuad")
    group:add(fadeOut)

    group.onComplete = function()
        banner.style.display = "none"
    end

    group:start()
end

-- Listen for state changes from server
local StateChangeEvent = Event.new("PH_StateChanged")

StateChangeEvent:Connect(function(newState, timer)
    local phaseName = GetPhaseName(newState)
    ShowPhaseBanner(phaseName)
end)

function GetPhaseName(state)
    if state == GameState.LOBBY then return "WAITING FOR PLAYERS"
    elseif state == GameState.HIDING then return "HIDE PHASE"
    elseif state == GameState.HUNTING then return "HUNT PHASE"
    elseif state == GameState.ROUND_END then return "ROUND OVER"
    end
    return "UNKNOWN"
end
```

---

## Testing VFX

### Debug Commands

Create a debug script to test VFX in isolation.

```lua
--!Type(Client)

-- DebugVFXTester.lua
local VFX = require("PropHuntVFXManager")

function self:ClientStart()
    print("[VFX Tester] Press 1-5 to test VFX")
end

function self:ClientUpdate()
    -- Test PlayerVanishVFX
    if Input.GetKeyDown(KeyCode.Alpha1) then
        local player = client.localPlayer
        if player and player.character then
            VFX.PlayerVanishVFX(player.character.transform.position, player.character)
            print("[VFX Test] PlayerVanishVFX")
        end
    end

    -- Test PropInfillVFX
    if Input.GetKeyDown(KeyCode.Alpha2) then
        local prop = GameObject.Find("TestProp")
        if prop then
            VFX.PropInfillVFX(prop.transform.position, prop)
            print("[VFX Test] PropInfillVFX")
        end
    end

    -- Test RejectionVFX
    if Input.GetKeyDown(KeyCode.Alpha3) then
        local prop = GameObject.Find("TestProp")
        if prop then
            VFX.RejectionVFX(prop.transform.position, prop)
            print("[VFX Test] RejectionVFX")
        end
    end

    -- Test TagHitVFX
    if Input.GetKeyDown(KeyCode.Alpha4) then
        local player = client.localPlayer
        if player and player.character then
            local pos = player.character.transform.position + Vector3.new(0, 1, 2)
            VFX.TagHitVFX(pos, nil)
            print("[VFX Test] TagHitVFX")
        end
    end

    -- Test TagMissVFX
    if Input.GetKeyDown(KeyCode.Alpha5) then
        local player = client.localPlayer
        if player and player.character then
            local pos = player.character.transform.position + Vector3.new(1, 0, 2)
            VFX.TagMissVFX(pos, Vector3.up)
            print("[VFX Test] TagMissVFX")
        end
    end
end
```

### UI Animation Tester

```lua
--!Type(Client)

-- DebugUITester.lua
local VFX = require("PropHuntVFXManager")

function self:ClientStart()
    print("[UI Tester] Press F1-F4 to test UI animations")

    -- Create test UI element
    local document = self.gameObject:GetComponent(UIDocument).rootVisualElement
    _testElement = document:Q("test-panel")

    if not _testElement then
        print("[UI Tester] WARNING: No 'test-panel' found in UI!")
    end
end

function self:ClientUpdate()
    if not _testElement then return end

    -- Test FadeIn
    if Input.GetKeyDown(KeyCode.F1) then
        VFX.FadeIn(_testElement, 0.5, "easeOutCubic")
        print("[UI Test] FadeIn")
    end

    -- Test FadeOut
    if Input.GetKeyDown(KeyCode.F2) then
        VFX.FadeOut(_testElement, 0.5, "easeInCubic")
        print("[UI Test] FadeOut")
    end

    -- Test SlideIn
    if Input.GetKeyDown(KeyCode.F3) then
        VFX.SlideIn(
            _testElement,
            Vector2.new(-300, 0),
            Vector2.new(0, 0),
            0.6,
            "easeOutBack"
        )
        print("[UI Test] SlideIn")
    end

    -- Test Sequence
    if Input.GetKeyDown(KeyCode.F4) then
        local seq = VFX.CreateSequence()
        seq:add(VFX.FadeOut(_testElement, 0.2))
        seq:add(VFX.FadeIn(_testElement, 0.3))
        seq:add(VFX.FadeOut(_testElement, 0.2))
        seq:add(VFX.FadeIn(_testElement, 0.3))
        seq:start()
        print("[UI Test] Sequence (blink)")
    end
end
```

---

## Best Practices

### 1. Optimistic Client-Side VFX

For responsive gameplay, play VFX immediately on the client, even before server confirmation:

```lua
-- GOOD: Immediate feedback
Input.Tapped:Connect(function(tap)
    local hit, hitInfo = Raycast(tap)
    if hit then
        VFX.TagHitVFX(hitInfo.point)  -- Play immediately
        RequestTagFromServer(hitInfo)  -- Then validate
    end
end)

-- BAD: Delayed feedback
Input.Tapped:Connect(function(tap)
    local hit, hitInfo = Raycast(tap)
    if hit then
        RequestTagFromServer(hitInfo, function(success)
            if success then
                VFX.TagHitVFX(hitInfo.point)  -- Too late!
            end
        end)
    end
end)
```

### 2. Clean Up References

Don't hold onto tween references indefinitely:

```lua
-- GOOD: Let tween clean up automatically
VFX.FadeIn(element, 0.5, "easeOut", function()
    print("Done!")
end)

-- OKAY: Store if you need to cancel it
local myTween = VFX.FadeIn(element, 5.0)
-- Later:
if playerLeftGame then
    myTween:stop()
    myTween = nil
end
```

### 3. Network Events for Multi-Client VFX

Always use events to sync VFX across clients:

```lua
-- SERVER
local TagVFXEvent = Event.new("PH_TagVFX")

function OnTagConfirmed(hunterId, propId, hitPoint)
    -- Fire to ALL clients so everyone sees the effect
    TagVFXEvent:FireAllClients(hunterId, propId, hitPoint)
end

-- CLIENT
TagVFXEvent:Connect(function(hunterId, propId, hitPoint)
    local prop = GetPropById(propId)
    VFX.TagHitVFX(hitPoint, prop)
end)
```

### 4. Don't Block Gameplay with VFX

Keep VFX short and non-blocking:

```lua
-- GOOD: Short, snappy VFX
VFX.TagHitVFX(position)  -- 0.25s
EliminatePlayer(propPlayer)  -- Happens immediately

-- BAD: Waiting for VFX to finish
VFX.TagHitVFX(position, function()
    EliminatePlayer(propPlayer)  -- Player has to wait 0.25s!
end)
```

---

## Troubleshooting

### VFX Not Playing

**Checklist:**
1. Is `PropHuntConfig._enableDebug` set to `true`? Check console for VFX logs.
2. Is the VFX function being called? Add `print()` statements.
3. For GameObject-based VFX, does the object exist and is it active?
4. For UI-based VFX, does the element exist in the document?

### VFX Playing on Wrong Client

**Issue:** VFX only plays for one player

**Solution:** Use `Event:FireAllClients()` instead of `Event:FireClient()`

```lua
-- Wrong: Only shooter sees VFX
function OnTagHit(shooter, target)
    VFX.TagHitVFX(target.position)  -- Only on shooter's client
end

-- Right: Everyone sees VFX
local TagVFXEvent = Event.new("PH_TagVFX")
function OnTagHit(shooter, target)
    TagVFXEvent:FireAllClients(target.position)  -- All clients
end
```

### Performance Issues

**Symptoms:** Frame drops, laggy animations

**Solutions:**
1. Reduce tween count - batch animations with TweenGroup
2. Use shorter durations (< 0.5s for most effects)
3. Don't create new tweens every frame in Update loops
4. Stop tweens when objects are destroyed

---

## Next Steps

1. **Choose an integration point** (start with PropHuntHUD for easy testing)
2. **Import VFX module** at the top of your script
3. **Call VFX functions** at appropriate moments
4. **Test in Unity Play mode** to see placeholder effects
5. **Replace placeholders** with particle prefabs when ready

For detailed API documentation, see `/Assets/PropHunt/Documentation/VFX_SYSTEM.md`.
