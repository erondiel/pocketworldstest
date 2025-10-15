# Remote Execution Pattern - PropHunt

## Overview
This document explains the remote execution pattern used in PropHunt for secure client-server operations, comparing implementations in Type UI and Type Module scripts.

## Pattern Architecture

### Flow
1. **Client Request** → Client calls `Event:FireServer()`
2. **Server Validation** → Server validates permissions, game state, player role
3. **Server Execution** → Server executes action on target client via `Event:Connect()`

### Why This Pattern?
- **Security**: Prevents unauthorized GameObject manipulation
- **Validation**: Server acts as authority for game rules
- **Synchronization**: Ensures all clients see consistent state

---

## Implementation Comparison

### Type UI: PropHuntReadyButton.lua

**Location**: `Assets/PropHunt/Scripts/GUI/PropHuntReadyButton.lua`

#### Client Side (UI Script)
```lua
--!Type(UI)

local PlayerManager = require("PropHuntPlayerManager")

function ReadyUpButton()
    -- Direct call to Event from Module
    PlayerManager.ReadyUpRequest:FireServer()
end

_button:RegisterPressCallback(ReadyUpButton)
```

#### Server Side (Module)
```lua
-- In PropHuntPlayerManager.lua
ReadyUpRequest = Event.new("PH_ReadyUpRequest")

function ReadyUpPlayerRequest(player : Player)
    -- Validate spectator status
    if players[player].isSpectator.value then
        return
    end
    
    -- Toggle ready state
    players[player].isReady.value = not players[player].isReady.value
    
    -- Update shared TableValue (auto-syncs to all clients)
    readyPlayers.value = readyPlayersTable
end

function self:ServerAwake()
    ReadyUpRequest:Connect(ReadyUpPlayerRequest)
end
```

**Key Points**:
- Type UI can `require()` Modules and access their exported Events
- Event is created in Module and exported in return table
- Server updates NetworkValues (BoolValue, TableValue) which auto-sync

---

### Type Module: PropPossessionSystem.lua

**Location**: `Assets/PropHunt/Scripts/PropPossessionSystem.lua`

#### Events (Module-scoped)
```lua
--!Type(Module)

-- Module-scoped Events (not exported)
local hideAvatarRequest = Event.new("PH_HideAvatarRequest")
local restoreAvatarRequest = Event.new("PH_RestoreAvatarRequest")
```

#### Client Side (Request)
```lua
local function RequestHideAvatar()
    print("[PropPossessionSystem] CLIENT: Requesting hide avatar")
    hideAvatarRequest:FireServer()
end

-- Called after successful possession
RequestHideAvatar()
```

#### Server Side (Validation)
```lua
local function HandleHideAvatarRequest(player)
    print("[PropPossessionSystem] SERVER: Hide avatar request from " .. player.name)
    
    -- Validate player is a prop
    local playerInfo = PlayerManager.GetPlayerInfo(player)
    if not playerInfo or playerInfo.role.value ~= "prop" then
        print("[PropPossessionSystem] SERVER: Denied - player is not a prop")
        return
    end
    
    -- Validate game state (2 = HIDING)
    local gameState = GameManager.GetCurrentState()
    if gameState ~= 2 then
        print("[PropPossessionSystem] SERVER: Denied - not HIDING phase")
        return
    end
    
    -- Execute on target client
    print("[PropPossessionSystem] SERVER: Authorized - executing hide avatar for " .. player.name)
    HidePlayerAvatarExecute(player)
end
```

#### Client Side (Execution)
```lua
function HidePlayerAvatarExecute(player)
    -- Only execute for local player
    if player ~= client.localPlayer then
        return
    end
    
    if not player.character then
        return
    end

    -- Disable NavMesh GameObject
    if navMeshGameObject then
        navMeshGameObject:SetActive(false)
    end

    -- Disable character GameObject
    local characterGameObject = player.character.gameObject
    if characterGameObject then
        characterGameObject:SetActive(false)
    end
end
```

#### Lifecycle Hooks
```lua
function self:ClientStart()
    -- Listen for avatar visibility commands from server
    hideAvatarRequest:Connect(HidePlayerAvatarExecute)
    restoreAvatarRequest:Connect(RestorePlayerAvatarExecute)
end

function self:ServerAwake()
    -- Handle avatar visibility requests from clients
    hideAvatarRequest:Connect(HandleHideAvatarRequest)
    restoreAvatarRequest:Connect(HandleRestoreAvatarRequest)
end
```

**Key Points**:
- Events are module-scoped (not exported) - only accessible within this file
- Both client and server logic live in the same Module file
- Server validates before calling execution function
- Execution function checks `client.localPlayer` to ensure local-only execution

---

## Type UI vs Type Module: Limitations & Capabilities

### Type UI
✅ **Can**:
- `require()` Modules
- Access exported Module functions and Events
- Use `client.localPlayer` and client-side APIs
- Register UI callbacks (`RegisterPressCallback`, etc.)

❌ **Cannot**:
- Define server-side logic (no `self:ServerAwake()`)
- Export functions for other scripts to use
- Create Events that other scripts can access

**Use Case**: UI elements that need to trigger Module functions

---

### Type Module
✅ **Can**:
- Define both client and server logic in same file
- Create Events for internal use
- Export functions and Events for other scripts
- Use `self:ClientStart()`, `self:ServerAwake()`, etc.
- `require()` other Modules

❌ **Cannot**:
- Directly bind to UI elements (use Type UI for that)

**Use Case**: Game systems with client-server logic, reusable managers

---

## Best Practices

### When to Use Remote Execution
Use this pattern when:
- Manipulating GameObjects (`SetActive`, `transform`, etc.)
- Changing player state that affects gameplay
- Operations that need server authority
- Actions that could be exploited if client-controlled

### When NOT to Use
Skip this pattern for:
- Pure visual effects (particles, sounds) that don't affect gameplay
- UI state changes (button colors, text)
- Read-only operations (getting player info)

### Event Naming Convention
- Prefix with `PH_` (PropHunt namespace)
- Suffix with `Request` for client→server requests
- Suffix with `Result` or `Response` for server→client responses
- Examples: `PH_PossessionRequest`, `PH_HideAvatarRequest`

### Validation Checklist
Server should validate:
1. ✅ Player role (prop, hunter, spectator)
2. ✅ Game state (LOBBY, HIDING, HUNTING, ROUND_END)
3. ✅ Player-specific state (already possessed, etc.)
4. ✅ Resource availability (prop not taken, etc.)

---

## Migration Guide

### Converting Local Execution to Remote Execution

**Before** (Local execution - insecure):
```lua
function HidePlayerAvatar()
    local player = client.localPlayer
    player.character.gameObject:SetActive(false)
end

-- Called directly
HidePlayerAvatar()
```

**After** (Remote execution - secure):
```lua
-- 1. Create Events
local hideAvatarRequest = Event.new("PH_HideAvatarRequest")

-- 2. Client request function
local function RequestHideAvatar()
    hideAvatarRequest:FireServer()
end

-- 3. Server validation function
local function HandleHideAvatarRequest(player)
    -- Validate here
    if not IsValid(player) then return end
    
    -- Execute on target client
    HidePlayerAvatarExecute(player)
end

-- 4. Client execution function
function HidePlayerAvatarExecute(player)
    if player ~= client.localPlayer then return end
    player.character.gameObject:SetActive(false)
end

-- 5. Wire up in lifecycle
function self:ClientStart()
    hideAvatarRequest:Connect(HidePlayerAvatarExecute)
end

function self:ServerAwake()
    hideAvatarRequest:Connect(HandleHideAvatarRequest)
end

-- 6. Call request instead of direct execution
RequestHideAvatar()
```

---

## Related Files
- `Assets/PropHunt/Scripts/GUI/PropHuntReadyButton.lua` - Type UI example
- `Assets/PropHunt/Scripts/PropPossessionSystem.lua` - Type Module example
- `Assets/PropHunt/Scripts/Modules/PropHuntPlayerManager.lua` - Module with exported Events

---

## Summary

| Aspect | Type UI | Type Module |
|--------|---------|-------------|
| **Server Logic** | ❌ No | ✅ Yes |
| **Client Logic** | ✅ Yes | ✅ Yes |
| **Export Functions** | ❌ No | ✅ Yes |
| **UI Binding** | ✅ Yes | ❌ No |
| **Require Modules** | ✅ Yes | ✅ Yes |
| **Event Scope** | Must import | Can create locally |

**Both types can use the remote execution pattern** - the difference is where the server validation logic lives (in a separate Module for UI, or in the same file for Module).

