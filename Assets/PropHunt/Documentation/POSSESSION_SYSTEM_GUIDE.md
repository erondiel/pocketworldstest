# PropHunt Possession System Guide

## Overview

The possession system allows prop players to "become" props during the HIDING phase, making them indistinguishable from regular environment objects.

## Validated Systems

### 1. Emission Control ✓

**Purpose**: Turn off prop glow to blend in with environment

**Implementation**:
- Material property: `_EmissionStrength`
- Default: 2.0 (visible glow)
- Possessed: 0.0 (no glow, blends in)

**Test Script**: `Assets/PropHunt/Scripts/Testing/PropEmissionTest.lua`

**Code Example**:
```lua
-- Disable emission (hide)
local material = renderer.material
material:SetFloat("_EmissionStrength", 0.0)

-- Enable emission (show)
material:SetFloat("_EmissionStrength", 2.0)
```

**Material Requirements**:
1. Use URP Lit shader
2. Enable "Emission" in material inspector
3. Set emission color (will be preserved)
4. Set initial strength (e.g., 2.0)

---

### 2. UI GameObject Control ✓

**Purpose**: Show/hide UI elements like spectator toggle

**Implementation**:
- Direct GameObject.SetActive() calls
- Store references to avoid GameObject.Find() on disabled objects

**Test Script**: `Assets/PropHunt/Scripts/Testing/SpectatorToggleTest.lua`

**Code Example**:
```lua
-- Hide UI
local uiGameObject = GameObject.Find("SpectatorToggle")
uiGameObject:SetActive(false)

-- Show UI (must store reference first!)
uiGameObject:SetActive(true)
```

**Best Practices**:
- Store GameObject references when first found
- Don't rely on GameObject.Find() for disabled objects
- Use for hiding UI during gameplay phases

---

### 3. Avatar Hiding & Movement Disable ✓

**Purpose**: Hide player avatar and disable movement when possessed

**Implementation**:
1. Disable NavMesh GameObject (prevents tap-to-move)
2. Disable character GameObject (hides avatar)

**Test Script**: `Assets/PropHunt/Scripts/Testing/AvatarPossessionTest.lua`

**Code Example**:
```lua
-- Hide avatar and disable movement
function HideAvatar()
    local player = client.localPlayer
    local character = player.character

    -- Disable NavMesh GameObject
    local navMeshGO = GameObject.Find("NavMesh")
    if navMeshGO then
        navMeshGO:SetActive(false)
    end

    -- Hide character
    character.gameObject:SetActive(false)
end

-- Restore avatar and enable movement
function ShowAvatar()
    -- Must store navMeshGO reference before disabling!
    if navMeshGO then
        navMeshGO:SetActive(true)
    end

    character.gameObject:SetActive(true)
end
```

**Critical Notes**:
- **Store NavMesh GameObject reference** before disabling
- GameObject.Find() cannot find disabled objects
- Disabling NavMesh prevents tap-to-move input system
- Disabling character hides avatar completely

---

## Complete Possession Flow

### Phase 1: Setup (Editor)

1. **Prop GameObject Setup**:
   ```
   PropObject
   ├── MeshRenderer (with emissive material)
   ├── Collider (for TapHandler - BoxCollider, SphereCollider, etc.)
   ├── TapHandler component (built-in Highrise component)
   │   ├── Move To: ✓ (checked)
   │   ├── Distance: 3.0 (interaction range)
   │   └── Move Target: (auto-set to GameObject position)
   ├── PropPossessionSystem.lua script
   └── PropObject_Outline (child)
       └── MeshRenderer (outline mesh)
   ```

2. **TapHandler Configuration**:
   - **Move To**: Enable this checkbox (player auto-walks to prop)
   - **Distance**: Set to 2-3 meters (required distance to interact)
   - **Move Target**: Leave default (uses GameObject position) or customize
   - **Has Anchors**: Leave unchecked (not using anchor system)

3. **Material Setup**:
   - Shader: Universal Render Pipeline/Lit
   - Enable Emission
   - Set Emission Color (e.g., cyan 0,1,1)
   - Set Emission Strength (e.g., 2.0)

4. **Tag Setup**:
   - Add "Possessable" tag to prop GameObject

### Phase 2: Interaction Flow (Runtime)

1. **Player Taps Prop (anywhere on screen)**:
   - TapHandler detects tap on prop collider
   - TapHandler checks distance requirement
   - If distance > configured distance (e.g., 3m):
     - TapHandler automatically moves player to prop
     - Player walks to `moveTarget` position
   - When player arrives OR if already in range:
     - TapHandler fires `Tapped` event

2. **PropPossessionSystem Validation**:
   - Receives `Tapped` event (player is already at prop!)
   - Checks:
     - Is HIDING phase?
     - Is player a prop?
     - Already possessed a prop this round?
     - Is this prop already possessed?
   - If any check fails: Show rejection VFX, return

3. **Server Request**:
   ```lua
   possessionRequest:InvokeServer(propInstanceID, function(ok, msg)
       -- Handle response
   end)
   ```
   - Server validates possession
   - Returns success/failure

4. **Possession (if approved)**:
   - VFX: Player vanish effect at player position
   - VFX: Prop infill effect at prop position
   - Hide player avatar (character.gameObject:SetActive(false))
   - Disable NavMesh GameObject (prevents tap-to-move)
   - Set prop emission strength to 0 (blends with environment)
   - Disable prop outline (outline hidden)
   - Mark: hasPossessedThisRound = true (One-Prop Rule enforced)

### Phase 3: During Hunt

- Player is invisible
- Player cannot move
- Prop looks like normal environment object
- Camera stays at prop position
- Player sees from prop's perspective

### Phase 4: Round End

- Restore all states:
  - Show player avatar
  - Enable NavMesh GameObject
  - Restore prop emission
  - Enable prop outline
  - Reset hasPossessedThisRound flag

---

## Server-Side Requirements

### RemoteFunction Handler

```lua
local possessionRequest = RemoteFunction.new("PH_PossessionRequest")

possessionRequest.OnInvokeServer = function(player, propInstanceID)
    -- 1. Validate phase
    if currentPhase ~= GameState.HIDING then
        return false, "Not in hiding phase"
    end

    -- 2. Validate player role
    local playerInfo = PlayerManager.GetPlayerInfo(player)
    if not playerInfo or playerInfo.role ~= "prop" then
        return false, "Only props can possess"
    end

    -- 3. Check if prop already possessed
    if possessedProps[propInstanceID] then
        return false, "Prop already taken"
    end

    -- 4. Find prop GameObject by instance ID
    local prop = FindPropByInstanceID(propInstanceID)
    if not prop then
        return false, "Invalid prop"
    end

    -- 5. Validate prop has Possessable tag
    if prop.tag ~= "Possessable" then
        return false, "Not a possessable prop"
    end

    -- 6. Mark as possessed
    possessedProps[propInstanceID] = player
    playerPossessions[player] = propInstanceID

    -- 7. Broadcast to all clients (optional)
    local possessionEvent = Event.new("PH_PropPossessed")
    possessionEvent:FireAllClients(player, propInstanceID)

    return true, "Possessed successfully"
end
```

### State Management

```lua
-- Track possessed props
local possessedProps = {}  -- [propInstanceID] = player
local playerPossessions = {}  -- [player] = propInstanceID

-- Reset on new round
function OnStateChanged(newState)
    if newState == GameState.HIDING then
        possessedProps = {}
        playerPossessions = {}
    end
end

-- Handle player disconnect
function OnPlayerLeft(player)
    local propID = playerPossessions[player]
    if propID then
        possessedProps[propID] = nil
        playerPossessions[player] = nil
    end
end
```

---

## Network Replication

### Current Limitation

The test scripts are **client-side only**. Avatar visibility changes are NOT replicated to other clients.

### Production Solution

For multiplayer, avatar hiding must be controlled server-side:

```lua
-- Server broadcasts avatar hide to all clients
local avatarVisibilityEvent = Event.new("PH_AvatarVisibility")

function SetPlayerAvatarVisibility(player, visible)
    avatarVisibilityEvent:FireAllClients(player, visible)
end

-- All clients listen
avatarVisibilityEvent:Connect(function(targetPlayer, visible)
    if targetPlayer.character then
        targetPlayer.character.gameObject:SetActive(visible)
    end
end)
```

This ensures all players see the prop player disappear when they possess a prop.

---

## Common Issues & Solutions

### Issue: Emission not changing
**Solution**:
- Check material has Emission enabled in Unity Inspector
- Verify `_EMISSION` keyword is enabled on material
- Ensure material has `_EmissionStrength` property

### Issue: NavMesh not re-enabling
**Solution**:
- Store NavMesh GameObject reference **before** disabling it
- GameObject.Find() cannot find disabled objects
- Use a persistent variable to keep the reference

### Issue: Tap-to-move still works when possessed
**Solution**:
- Ensure NavMesh GameObject is disabled, not just NavMeshSurface component
- The GameObject name must be exactly "NavMesh"

### Issue: Avatar visible to other players
**Solution**:
- Implement server-side avatar visibility control
- Broadcast visibility events to all clients
- See "Network Replication" section above

### Issue: Can possess multiple props
**Solution**:
- Check `hasPossessedThisRound` flag before allowing possession
- Flag should be set to `true` after first successful possession
- Reset flag when entering new HIDING phase

---

## Performance Considerations

1. **Material Instances**:
   - Using `renderer.material` creates material instances
   - One instance per possessed prop is acceptable
   - For 20 props: 20 material instances (manageable)

2. **GameObject.Find()**:
   - Store references instead of calling repeatedly
   - Find "NavMesh" once, reuse reference

3. **Event Listeners**:
   - Connect events once in Awake/Start
   - Don't create new listeners every frame

---

## Testing Checklist

- [ ] Emission turns off when simulated
- [ ] Emission restores to original value
- [ ] NavMesh GameObject disables (no tap-to-move)
- [ ] NavMesh GameObject re-enables
- [ ] Avatar disappears
- [ ] Avatar reappears
- [ ] Outline hides when possessed
- [ ] Outline shows when restored
- [ ] Can only possess once per round
- [ ] Cannot possess during HUNTING phase
- [ ] Server validates prop availability

---

## File Structure

```
Assets/PropHunt/
├── Scripts/
│   ├── PropPossessionSystem.lua       (Main possession logic)
│   └── Testing/
│       ├── PropEmissionTest.lua       (Emission control test)
│       ├── SpectatorToggleTest.lua    (UI control test)
│       └── AvatarPossessionTest.lua   (Avatar hide test)
└── Documentation/
    └── POSSESSION_SYSTEM_GUIDE.md     (This file)
```

---

## Next Steps

1. **Implement server-side handler** for `PH_PossessionRequest`
2. **Add network replication** for avatar visibility
3. **Create VFX effects** for vanish/infill (currently placeholders)
4. **Test in multiplayer** to ensure synchronization
5. **Add camera parenting** to prop (for first-person view from prop)
6. **Polish UI feedback** for possession success/failure
