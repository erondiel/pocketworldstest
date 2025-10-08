# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **PropHunt multiplayer game** built for **Highrise Studio**, a Unity-based platform for creating multiplayer social games. The project is a technical art showcase featuring custom shaders, VFX, and Lua-based game logic.

**Platform:** Unity 2022.3+ with Highrise Studio SDK (com.pz.studio@0.23.0)
**Primary Language:** Lua for game logic, C# for Unity integration (auto-generated)
**Rendering:** Universal Render Pipeline (URP)

## Building and Running

### Opening the Project
1. Open the project in Unity 2022.3 or later
2. Ensure the Highrise Studio package is properly installed (should auto-resolve from npm.highrise.game)
3. Open the main scene: `Assets/PropHunt/Scenes/test.unity`

### Testing
- **In-Editor Testing:** Use Unity Play mode with Highrise multiplayer simulation
- **Live Testing:** Publish to Highrise platform via the Highrise Studio publish tools in Unity
- No traditional build process - games are deployed to Highrise's cloud platform

### Common Development Commands
Since this is a Unity project, there are no npm/build commands. Work is done entirely within the Unity Editor.

## Architecture Overview

### Highrise Studio Lua Framework

This project uses Highrise's Lua scripting system, which compiles Lua scripts into C# wrapper classes at runtime. Key concepts:

**Script Type Annotations:**
```lua
--!Type(Server)  -- Server-side only script
--!Type(Client)  -- Client-side only script
--!Type(Module)  -- Shared code (no side designation)
```

**SerializeField for Unity Inspector:**
```lua
--!SerializeField
local myVariable : GameObject = nil
```

**Global Objects Available:**
- `server` - Server instance (server scripts only): PlayerConnected, PlayerDisconnected events
- `client` - Client instance (client scripts only): localPlayer, PlayerConnected events
- `scene` - Active scene (both sides): PlayerJoined, PlayerLeft events
- `self` - Current LuaBehaviour instance (Unity GameObject access)

### Code Generation System

Lua scripts in `Assets/PropHunt/Scripts/` are automatically compiled to C# wrappers in `Packages/com.pz.studio.generated/Runtime/Highrise.Lua.Generated/`. **Never edit generated C# files** - they will be overwritten. Always edit the source `.lua` files.

### Game Architecture

The PropHunt game uses a **server-authoritative state machine** with client-side prediction for responsiveness:

#### Core State Machine
Located in: `Assets/PropHunt/Scripts/PropHuntGameManager.lua`

**Game States:**
1. **LOBBY** - Waiting for players to ready up
2. **HIDING** - Props select disguises and hide
3. **HUNTING** - Hunters search and tag props
4. **ROUND_END** - Display results, prepare for next round

**State Flow:**
```
LOBBY (≥2 ready, 30s countdown) → HIDING (35s) → HUNTING (240s/4min) → ROUND_END (15s) → LOBBY
```

**Core V1 Constraint:** Props are **static (immobile) during Hunt phase**. No unpossess allowed once possessed.

**Role Distribution (at Hide start):**
- 2 players → 1 Hunter, 1 Prop
- 3 players → 1 Hunter, 2 Props
- 4 players → 1 Hunter, 3 Props
- 5 players → 1 Hunter, 4 Props
- 6-10 players → 2 Hunters, rest Props
- 10-20 players → 3 Hunters, rest Props

**Scene Topology:** Single Unity scene with Lobby and Arena areas separated in world space. Teleports move players between areas on state transitions.

**Win Conditions:**
- Round ends when: All props found OR hunt timer expires
- Winner: Single player with highest total score (individual, not team)

#### Module System

The game uses a modular architecture:

**PropHuntConfig.lua** (Module)
- Centralized configuration: phase timers, player counts, debug settings
- Exposes SerializeFields to Unity Inspector for tweaking

**PropHuntGameManager.lua** (Module - Server logic)
- Main state machine and game loop
- Role assignment (60% props, 40% hunters)
- Win condition detection
- Network event management via `Event.new()` and `RemoteFunction.new()`

**PropHuntPlayerManager.lua** (Module - Shared)
- Player tracking (ready state, disconnections)
- Ready-up system for lobby
- Uses `BoolValue` and `TableValue` for automatic client-server sync

**PropHuntUIManager.lua** (Module - Client logic)
- HUD updates (timer, state, player counts)
- UI element visibility control (ready button)
- Listens to server state change events

**HunterTagSystem.lua** (Client + Server)
- Client: Tap-to-shoot with raycast detection
- Server: Tag validation and elimination logic
- Cooldown system to prevent spam (2 second default)

**PropDisguiseSystem.lua** (Client + Server)
- Client: Tap-to-select prop interface
- Server: Disguise validation and application
- Triggers VFX/shader transformations
- **One-Prop Rule (No-Unpossess)**: Once possessed during Hide, unpossessing is disabled for the round

**Possessable.lua** (Component on props)
- Properties: `IsPossessed` (bool), `OwnerPlayerId` (nullable)
- References: `Outline`, `HitPoint` (Transform), `MainCollider`
- Visual states controlled by shader keywords

### Input System

See `Assets/PropHunt/Documentation/INPUT_SYSTEM.md` for comprehensive input documentation.

**Key Input APIs:**
```lua
-- Tap/Click detection
Input.Tapped:Connect(function(tap : TapEvent)
    local camera = Camera.main
    local ray = camera:ScreenPointToRay(tap.position)
    -- Raycast from tap position
end)

-- Long press
Input.LongPressBegan:Connect(function(event : LongPressBeganEvent)
    -- Handle long press
end)

-- Movement (handled by PlayerCharacterController)
local moveAction = Input.GetAction("Move")
local movement = moveAction:ReadVector2()
```

**Hunter Tagging (V1 Spec):**
- **Raycast Origin:** From player body origin (NOT camera) toward click world point
- **Tag Range:** R_tag = 4.0m maximum distance
- **Tag Cooldown:** 0.5s between attempts (prevents spam)
- **Validation:** Must have Possessable component AND IsPossessed == true
- **Feedback VFX:**
  - Hit: Compressed ring shock at HitPoint (0.25s), 3-5 micro-spark motes, chromatic ripples
  - Miss: Dust poof decal (0.15s), color-neutral

**Anti-Grief Measures:**
- Server-side validation for all tags (distance, cooldown, possession state)
- Distance checks to prevent cheating (R_tag = 4.0m enforced)
- Phase-based input masking (no tagging during Hide)

### Network Synchronization

Highrise uses automatic synchronization for specific types:

**Automatic Sync:**
```lua
-- These sync automatically between server and all clients
local stateValue = NumberValue.new("PH_CurrentState", GameState.LOBBY)
local timerValue = NumberValue.new("PH_StateTimer", 0)
local readyPlayers = TableValue.new("PH_ReadyPlayers", {})
local isReady = BoolValue.new("IsReady" .. player.user.id, false, player)
```

**Manual Events:**
```lua
-- Server → All Clients
local event = Event.new("PH_StateChanged")
event:FireAllClients(newState, timer)

-- Server → Specific Client
event:FireClient(player, role)

-- Client → Server (Request-Response)
local remoteFunc = RemoteFunction.new("PH_TagRequest")
remoteFunc.OnInvokeServer = function(player, targetId)
    return true, "Tagged"
end
```

### UI System

The project uses **UI Toolkit (UXML/USS)** for UI elements, not Unity's legacy UI system.

**UI Files:**
- `.uxml` - UI structure (like HTML)
- `.uss` - UI styling (like CSS)
- `.lua` - UI behavior and logic

**Example UI Component:**
```lua
--!SerializeField
local _HUD : GameObject = nil

local _HudScript : PropHuntHUD = nil

function self:ClientAwake()
    _HudScript = _HUD:GetComponent(PropHuntHUD)
end

function UpdateHUD()
    _HudScript.UpdateHud(stateText, timerText, playersText)
end
```

## File Organization

```
Assets/PropHunt/
├── Scenes/              # Unity scenes (test.unity is main)
├── Scripts/             # Lua game logic (SOURCE OF TRUTH)
│   ├── PropHuntGameManager.lua
│   ├── PropHuntConfig.lua
│   ├── HunterTagSystem.lua
│   ├── PropDisguiseSystem.lua
│   ├── Possessable.lua
│   ├── DebugCheats.lua
│   ├── Modules/
│   │   ├── PropHuntPlayerManager.lua
│   │   └── PropHuntUIManager.lua
│   └── GUI/
│       ├── PropHuntHUD.lua
│       ├── PropHuntReadyButton.lua
│       ├── *.uxml (UI structure)
│       └── *.uss (UI styles)
├── Documentation/
│   ├── README.md        # Project overview
│   └── INPUT_SYSTEM.md  # Input system guide
├── Prefabs/             # Reusable game objects
├── Materials/           # PBR materials
├── Shaders/             # Custom shaders (URP)
└── VFX/                 # Visual effects

Packages/com.pz.studio.generated/
└── Runtime/Highrise.Lua.Generated/
    # AUTO-GENERATED C# wrappers - DO NOT EDIT

Assets/OneCommander/     # Unity editor plugin for file management
```

## Key Development Patterns

### Creating a New Lua Script

1. Create `.lua` file in `Assets/PropHunt/Scripts/`
2. Add type annotation: `--!Type(Server)`, `--!Type(Client)`, or `--!Type(Module)`
3. Highrise will auto-generate C# wrapper on next compile
4. Attach the generated component to a GameObject in Unity

### Module Communication

```lua
-- In ModuleA.lua
--!Type(Module)

function PublicFunction()
    print("Called from another module")
end

-- In ModuleB.lua
--!Type(Module)
local ModuleA = require("ModuleA")

function self:ServerStart()
    ModuleA.PublicFunction()
end
```

### Debugging

**Print Statements:**
```lua
print("Debug message")  -- Shows in Unity Console
```

**Debug Events:**
```lua
local debugEvent = Event.new("PH_Debug")
debugEvent:FireAllClients("TAG", hunterId, propId)
```

**Configuration:**
```lua
-- PropHuntConfig.lua
local _enableDebug : boolean = true

function DebugLog(message : string)
    if _enableDebug then
        print("[PropHunt] " .. message)
    end
end
```

### Timers

```lua
-- Repeating timer
local timer = Timer.Every(1, function()
    print("Called every second")
end)

-- Stop timer
timer:Stop()

-- Use Time.deltaTime for frame-based updates
function self:ServerFixedUpdate()
    stateTimer.value = stateTimer.value - Time.deltaTime
end
```

## Common Pitfalls

1. **Editing Generated C# Files**: Always edit `.lua` files, never the generated C# wrappers
2. **Wrong Script Type**: Use Module for shared code, Server for authoritative logic, Client for UI/input
3. **Missing Network Sync**: Use NumberValue/BoolValue/TableValue for auto-sync, or Events for manual control
4. **Cooldown Timers**: Always validate on server-side with `Time.time` to prevent client tampering
5. **Raycasting Layers**: Use proper layer masks to avoid hitting UI elements or wrong objects
6. **Mobile Performance**: Optimize for mobile - this platform targets phones/tablets
7. **Outline Visibility**: Hunters NEVER see outlines (even during Hide). Only Props and Spectators see green outlines during Hide phase
8. **Raycast Origin**: Hunter tagging raycasts from **player body origin**, NOT from camera
9. **No-Unpossess Rule**: Once a prop is possessed during Hide, unpossessing is disabled for the entire round

## Implementation Priorities (V1 Exit Criteria)

Based on the Game Design Document, these are the core requirements for V1:

**Must Have:**
- [ ] Role distribution matches spec (2-20 player scaling)
- [ ] Props immobile during Hunt phase
- [ ] Green outlines visible only to Props/Spectators during Hide
- [ ] Tagging from player origin with R_tag=4.0m and 0.5s cooldown
- [ ] Zone-weighted scoring (Near=1.5, Mid=1.0, Far=0.6) every 5s
- [ ] End conditions: All props found OR timer expires
- [ ] Winner: Highest individual score with tie-breaker logic
- [ ] Phase transition VFX trigger reliably
- [ ] One-Prop conflict shows rejection VFX and maintains ownership

**Nice-to-Have (Post V1):**
- [ ] Taunt system with visual lure and scoring
- [ ] Movement-enabled props
- [ ] Richer kill feed with area icons
- [ ] AFK handling and join-in-progress

**Focus:** Technical art (VFX/shaders/transitions) over complex gameplay systems.

## Commit Conventions

This project uses conventional commits via commitizen:

```bash
npm run commit  # Launches interactive commit prompt
```

**Commit Types:**
- `feat:` New features
- `fix:` Bug fixes
- `refactor:` Code restructuring
- `docs:` Documentation changes
- `style:` Code style/formatting
- `test:` Testing changes

## Game Design Parameters (V1 Defaults)

These values are defined in the Game Design Document and should be reflected in `PropHuntConfig.lua`:

```json
{
  "Lobby": { "MinReadyToStart": 2, "Countdown": 30 },
  "Phases": { "Hide": 35, "Hunt": 240, "RoundEnd": 15 },
  "Tagging": { "R_tag": 4.0, "Cooldown": 0.5 },
  "Scoring": {
    "PropTickSeconds": 5,
    "PropTickPoints": 10,
    "PropSurviveBonus": 100,
    "HunterFindBase": 120,
    "HunterMissPenalty": -8,
    "HunterAccuracyBonusMax": 50
  },
  "Zones": {
    "NearSpawn": 1.5,
    "Mid": 1.0,
    "Far": 0.6
  },
  "Taunt": { "Cooldown": 13, "Window": 10, "Reward": 20, "Enabled": false }
}
```

## External Resources

- **Game Design Document**: `Assets/PropHunt/Docs/Prop_Hunt__V1_Game_Design_Document_(Tech_ArtFocused).pdf`
- **Highrise Studio Docs**: https://create.highrise.game/learn/studio
- **Highrise Studio API**: https://create.highrise.game/learn/studio-api
- **Highrise Forum**: https://createforum.highrise.game
- **Development Plan**: See `DEVELOPMENT_PLAN.md` for project timeline and goals

## Technical Art Focus

This project emphasizes visual quality as a technical art showcase with **crisp, readable shapes and short, satisfying impacts (no excessive bloom)**.

### VFX/Shader Specification

**Possession VFX (Hide Phase):**
- **Outline Shader:** Green outline + mild fresnel sparkle on all possessables during Hide (shader keyword toggle)
- **Player Vanish VFX:** Vertical slice dissolve with soft sparks (0.4s)
- **Prop Infill VFX:** Radial mask inwards, emissive rim grows then normalizes
- **Rejection VFX:** Brief red edge flash + "thunk" sound for double-possess attempts

**Phase Transition VFX:**
- **Lobby → Hide:** World desaturates in Lobby, Arena gains quick pulse-in gradient, teleport beams on Props/Spectators
- **Hide → Hunt:** Arena vignette expands, outlines globally fade with synchronized dissolve sweep
- **RoundEnd:** Confetti/sparkles for winner team, subtle screen-space ribbon trails on score tally

**Prop Status Shaders:**
- **Hide:** Green outline + mild fresnel sparkle
- **Hunt (Possessed):** No outline, subtle heartbeat emissive (very faint to avoid reveals)

**Spectator Visual Filter:**
- Slightly cooler LUT
- Faint edge glow on Props/Hunters (non-informational, aesthetic only)

**Taunt System (Nice-to-Have):**
- Pulsing ring around prop (~3m radius) with rising wisps
- Cooldown: 12-15s, visible to Hunters/Spectators only
- Gameplay: If Hunter doesn't tag within 10s window, prop gets +20 points

### Scoring System (Zone-Based)

**Zone Weights:** Props gain points based on location
- NearSpawn: 1.5x multiplier
- Mid: 1.0x multiplier
- Far: 0.6x multiplier

**Prop Scoring:**
- Passive: Every 5s alive → +10 × ZoneWeight
- Survive Bonus: Not found when timer ends → +100

**Hunter Scoring:**
- Find Prop: +120 × ZoneWeight (of prop's position at tag)
- Miss Click: -8 points
- Accuracy Bonus: End-of-round +floor((Hits / max(1, Hits+Misses)) × 50)

**Team Bonuses:**
- Hunter Team Win (all props found): +50 to each Hunter
- Prop Team Win (any prop survives): +30 to each surviving Prop, +15 to found Props

**Zone Authoring:** Use invisible colliders/volumes with ZoneVolume script containing ZoneWeight property. Tags: Zone_NearSpawn, Zone_Mid, Zone_Far.

### Custom Shaders (URP)
- Dissolve shader for prop transformations
- Outline/highlight shader with shader keyword toggling
- Emissive rim shader for infill effects
- Materials: PBR workflow optimized for mobile

### HUD/UI Requirements (Minimal V1)

**Lobby:** "Join as Spectator" toggle + Ready button

**All Phases:** Round timer display

**Prop UI:** Status ("Possessed"), Zone label, optional Taunt button + cooldown

**Hunter UI:** Tag cooldown indicator, Remaining props counter, Hit/Miss tally

**Kill Feed:** "HunterX found PropY (Kitchen – NearSpawn)"

**Recap Screen:** Winner announcement with highest score + tie-breaker display

When implementing features, prioritize visual feedback and polish over complex systems.
