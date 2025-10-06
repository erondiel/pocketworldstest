# Highrise Studio Input System - PropHunt Implementation

## 📱 Available Input Methods

Based on Highrise's built-in systems, here are the input methods available for PropHunt:

### **1. Tap/Click Input (Mobile & Desktop)**
```lua
-- Example from PlayerCharacterController.lua
Input.Tapped:Connect(function(tap : TapEvent)
    -- tap.position: Vector2 - Screen position
    -- Raycast from tap position to detect what was clicked
end)
```

**Use Cases for PropHunt:**
- Props: Select which object to disguise as
- Hunters: Click to shoot/tag props
- UI: Button interactions

---

### **2. Long Press Input**
```lua
Input.LongPressBegan:Connect(function(event : LongPressBeganEvent)
    -- User started holding press
end)

Input.LongPressContinue:Connect(function(event : LongPressContinueEvent)
    -- Press is being held (continuous)
end)

Input.LongPressEnded:Connect(function(event : LongPressEndedEvent)
    -- Press released
end)
```

**Use Cases for PropHunt:**
- Props: Hold to confirm disguise selection
- Hunters: Hold to charge special abilities
- General: Context menus

---

### **3. Joystick/Movement Input**
```lua
-- Using InputAction for movement
local moveAction : InputAction = Input.GetAction("Move")

if moveAction then
    local movement : Vector2 = moveAction:ReadVector2()
    -- movement.x: left/right
    -- movement.y: forward/backward
end
```

**Use Cases for PropHunt:**
- Character movement (already handled by PlayerCharacterController)
- Props moving while disguised

---

### **4. Pointer Events (UI Elements)**
```lua
-- On UI elements
element.RegisterCallback(PointerDownEvent, function(evt)
    -- Mouse/touch down on UI element
end)

element.RegisterCallback(PointerUpEvent, function(evt)
    -- Mouse/touch released on UI element
end)
```

**Use Cases for PropHunt:**
- UI buttons
- Prop selection menu
- Role indicators

---

## 🎯 PropHunt-Specific Input Requirements

### **For Props (Hide Phase):**
1. **Tap on object** → Select prop to disguise as
2. **Confirm selection** → Transform into prop
3. **Movement** → Move while disguised (limited?)

### **For Hunters (Hunt Phase):**
1. **Tap/Click** → Shoot/tag a prop
2. **Raycast detection** → Check if hit a disguised prop
3. **Cooldown** → Prevent spam shooting (anti-grief)

---

## 🔧 Implementation Strategy

### **HunterTagSystem.lua** (Client-side shooting)
```lua
--!Type(Client)

local shootCooldown = 2.0
local lastShotTime = 0

function self:ClientStart()
    Input.Tapped:Connect(OnTapToShoot)
end

function OnTapToShoot(tap : TapEvent)
    -- Check cooldown
    if Time.time < lastShotTime + shootCooldown then
        return -- Still on cooldown
    end
    
    -- Raycast from camera through tap position
    local camera = Camera.main
    local ray = camera:ScreenPointToRay(tap.position)
    local hit : RaycastHit
    local didHit = Physics.Raycast(ray, hit, 100) -- 100 units max distance
    
    if didHit then
        -- Check if we hit a prop (character with prop tag)
        local hitObject = hit.collider.gameObject
        
        -- Send to server for validation
        TagPropRemote:InvokeServer(hitObject)
        
        -- Play hit effect
        SpawnHitEffect(hit.point)
        
        lastShotTime = Time.time
    end
end
```

### **PropDisguiseSystem.lua** (Client-side prop selection)
```lua
--!Type(Client)

local selectedProp : GameObject = nil

function self:ClientStart()
    Input.Tapped:Connect(OnTapToSelect)
end

function OnTapToSelect(tap : TapEvent)
    -- Only during hide phase
    if not IsHidePhase() then return end
    
    -- Raycast to see what was tapped
    local camera = Camera.main
    local ray = camera:ScreenPointToRay(tap.position)
    local hit : RaycastHit
    local didHit = Physics.Raycast(ray, hit, 50)
    
    if didHit then
        local hitObject = hit.collider.gameObject
        
        -- Check if it's a valid prop
        if IsValidProp(hitObject) then
            selectedProp = hitObject
            ShowConfirmationUI(hitObject)
        end
    end
end

function OnConfirmDisguise()
    if selectedProp then
        -- Request disguise from server
        DisguiseRemote:InvokeServer(selectedProp)
    end
end
```

---

## 📊 Input System Architecture

```
Client Input
    ↓
Input.Tapped / Input.LongPress
    ↓
Client Lua Script (validation)
    ↓
RemoteFunction → Server
    ↓
Server Lua Script (authoritative check)
    ↓
Event → All Clients (sync state)
```

---

## ⚡ Key APIs to Use

### **From Highrise Globals:**
- `Input.Tapped:Connect(callback)` - Tap/click events
- `Input.LongPressBegan:Connect(callback)` - Long press
- `Physics.Raycast(ray, hit, distance)` - Hit detection
- `Camera.main:ScreenPointToRay(position)` - Screen to world ray

### **From Unity:**
- `Time.time` - Current game time (for cooldowns)
- `Vector2`, `Vector3` - Math operations
- `GameObject`, `Transform` - Object manipulation

---

## 🎮 Input Configuration

### **Layers for Raycasting:**
```lua
-- From PlayerCharacterController example:
local shootMask = bit32.bor(
    bit32.lshift(1, LayerMask.NameToLayer("Default")),
    bit32.lshift(1, LayerMask.NameToLayer("Character")),
    bit32.lshift(1, LayerMask.NameToLayer("Tappable"))
)
```

**For PropHunt:**
- Props on "Character" layer
- Disguised props tagged/layered differently
- UI on separate layer (ignore in raycast)

---

## 🚨 Anti-Grief Measures

### **Cooldown System:**
```lua
local cooldownTime = 2.0
local lastActionTime = 0

function AttemptAction()
    if Time.time < lastActionTime + cooldownTime then
        -- Show cooldown UI
        return false
    end
    lastActionTime = Time.time
    return true
end
```

### **Server Validation:**
- All tags validated server-side
- Check if hunter is actually a hunter
- Check if target is actually a prop
- Check distance (prevent cheating)

---

## 📚 References

- **Input API:** https://liveops-create.highrise.game/learn/studio-api/classes/InputAction
- **Joystick Support:** https://createforum.highrise.game/t/studio-package-0-12-2/1911
- **Example:** `Library/PackageCache/com.pz.studio@be2e4f637d27/Runtime/Lua/PlayerCharacterController.lua`

---

## ✅ Implementation Checklist

- [ ] Hunter tap-to-shoot system with raycast
- [ ] Hunter shoot cooldown (2 second minimum)
- [ ] Prop tap-to-select disguise system
- [ ] Prop disguise confirmation UI
- [ ] Server-side tag validation
- [ ] Visual feedback for hits/misses
- [ ] Input masking during wrong phases

---

*Last Updated: Day 1 - October 6, 2024*

