# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PropHunt V1** - A round-based hide-and-seek multiplayer game for Highrise Studio platform where Props hide as objects and Hunters try to find them. Built with Unity 2022.3+ using Highrise Studio SDK (com.pz.studio@0.23.0) and Universal Render Pipeline (URP 14.0.9).

**Tech Stack**: Unity C# (Editor tools), Lua (game logic), UXML/USS (UI)

## Architecture

### State Machine (Server-Authoritative)
The game is controlled by a finite state machine in `PropHuntGameManager.lua`:
- **LOBBY** → Players ready up (minimum 2 players)
- **HIDING** → Props teleport to arena and select disguises (35s default)
- **HUNTING** → Hunters teleport to arena and tag props (240s default)
- **ROUND_END** → Display results and scores (15s default)

All state transitions are server-authoritative. The server validates all gameplay actions (tagging, possession, distances) to prevent cheating.

### Module System

Core modules live in `Assets/PropHunt/Scripts/Modules/` and are attached to a **PropHuntModules GameObject** in the Unity scene:

**Server Modules** (--!Type(Module) with ServerAwake/ServerFixedUpdate):
- `PropHuntConfig.lua` - Central configuration with SerializeFields for all game parameters
- `PropHuntGameManager.lua` - Main state machine controller
- `PropHuntPlayerManager.lua` - Tracks player ready states and connections
- `PropHuntScoringSystem.lua` - Zone-weighted scoring with tie-breaker logic
- `PropHuntTeleporter.lua` - Single-scene position-based teleportation (Lobby ↔ Arena)
- `ZoneManager.lua` - Tracks player positions in scoring zones (NearSpawn/Mid/Far)
- `PropHuntUIManager.lua` - Server-side UI event coordination
- `PropHuntVFXManager.lua` - Visual effects coordination (uses DevBasics Tweens library)

**Client Systems** (--!Type(Module) with ClientStart):
- `HunterTagSystem.lua` - Tap-to-tag input with 4.0m range validation and 0.5s cooldown
- `PropDisguiseSystem.lua` - Tap-to-select prop possession during Hide phase
- `PropHuntRangeIndicator.lua` - Shows 4m visual indicator around hunters

**Components** (--!Type(Server) or --!Type(Client) attached to scene GameObjects):
- `ZoneVolume.lua` - Trigger collider component for scoring zones
- `PropHuntReadyButton.lua` - Lobby ready button UI

### Network Synchronization

Uses Highrise SDK's built-in sync primitives:
- `NumberValue.new()` - Auto-synced numbers (state, timer, scores)
- `BoolValue.new()` - Auto-synced booleans (ready status, possession state)
- `TableValue.new()` - Auto-synced tables (ready players list)
- `Event.new()` - Server→Client broadcasts (state changes, role assignments, tags)
- `RemoteFunction.new()` - Client→Server requests (tag attempts, possession requests, ready toggle)

### Scoring System

**Zone-Based Multipliers**:
- NearSpawn: 1.5x (high risk, high reward)
- Mid: 1.0x (balanced)
- Far: 0.6x (safe, low reward)

**Prop Scoring**:
- Passive: +10 × ZoneWeight every 5 seconds during Hunt phase
- Survival: +100 if alive when timer expires

**Hunter Scoring**:
- Tag: +120 × ZoneWeight per successful tag
- Miss: -8 points per failed tag
- Accuracy Bonus: floor((Hits / (Hits+Misses)) × 50) at round end

**Team Bonuses**:
- Hunter Team Win (all props found): +50 per hunter
- Prop Team Win (≥1 survivor): +30 per survivor, +15 per found prop

**Winner Determination**:
1. Highest score
2. Tie-breaker 1: Most tags (hunter) or survival ticks (prop)
3. Tie-breaker 2: Earliest last scoring event timestamp
4. Tie-breaker 3: Declare draw

### Teleporter System

Uses **single-scene position-based teleportation** (not SceneManager):
- Two spawn points: `LobbySpawn` and `ArenaSpawn` (empty GameObjects with Transform positions)
- Configured via SerializeFields in PropHuntConfig.lua (drag GameObjects in Unity Inspector)
- Teleports players by setting `player.character.transform.position`
- Arena should be 50-100+ units away from Lobby to prevent visibility between areas

## Unity Scene Setup

### Required Scene Structure:
```
Hierarchy:
├── PropHuntModules (GameObject with all module scripts attached)
├── LobbySpawn (Empty GameObject - position marker)
├── ArenaSpawn (Empty GameObject - position marker, 50-100 units from lobby)
├── Zones (parent GameObject)
│   ├── Zone_NearSpawn (BoxCollider trigger + ZoneVolume.lua)
│   ├── Zone_Mid (BoxCollider trigger + ZoneVolume.lua)
│   └── Zone_Far (BoxCollider trigger + ZoneVolume.lua)
└── Props (parent GameObject)
    ├── Prop_Cube_01 (with Possessable tag)
    ├── Prop_Sphere_02 (with Possessable tag)
    └── ... (5-30 props with Possessable tag)
```

### Automated Setup:
Use `Assets/PropHunt/Editor/PropHuntSceneSetupWizard.cs`:
1. Right-click in Project → Create → PropHunt → Scene Setup Wizard
2. Select asset → Click "Setup Scene" button in Inspector
3. Manually add ZoneVolume components to zones with correct weights
4. Manually add Possessable tag to props
5. Configure PropHuntTeleporter spawn positions in Inspector

See `Assets/PropHunt/COMPLETE_UNITY_SETUP.md` for detailed checklist.

## Key Design Constraints

1. **Props are STATIC during Hunt phase** - No movement allowed (V1 constraint)
2. **One-Prop Rule** - Players can only possess ONE prop per round, no unpossessing
3. **Server Validation** - All critical actions validated server-side:
   - Tag distance ≤ 4.0m (R_tag)
   - Tag cooldown ≥ 0.5s
   - Phase validation (can only tag during HUNTING)
   - Role validation (only Hunters tag, only Props possess)
4. **Raycast Origin** - Hunter tags raycast from **player body position** (NOT camera) toward tap point
5. **Mobile-First** - Optimized for mobile performance, uses tap input

## Role Distribution Algorithm

Based on player count (V1 spec implemented in AssignRoles() in PropHuntGameManager.lua:424):
- 2 players: 1 Hunter, 1 Prop
- 3 players: 1 Hunter, 2 Props
- 4 players: 1 Hunter, 3 Props
- 5 players: 1 Hunter, 4 Props
- 6-10 players: 2 Hunters, rest Props
- 10-20 players: 3 Hunters, rest Props

## Development Workflow

### Reading Configuration
All tunable parameters are in `PropHuntConfig.lua` with Unity Inspector SerializeFields. To change game balance, modify values in Unity Inspector on the PropHuntModules GameObject.

### Adding New Modules
1. Create Lua file in `Assets/PropHunt/Scripts/Modules/`
2. Start with `--!Type(Module)` directive
3. Add to PropHuntModules GameObject in Unity
4. Require in other modules: `local MyModule = require("MyModuleName")`
5. Export public API via `return { FunctionName = FunctionName }`

### Adding Zone Volumes
1. Create GameObject with BoxCollider (isTrigger = true)
2. Attach `ZoneVolume.lua` component
3. Set zoneName ("NearSpawn", "Mid", or "Far")
4. Set zoneWeight (1.5, 1.0, or 0.6)
5. Position in Arena area (not Lobby)

### Network Events Pattern
```lua
-- Server (Module):
local myEvent = Event.new("MyEvent")
myEvent:FireAllClients(arg1, arg2)

-- Client (Module):
local myEvent = Event.new("MyEvent")
myEvent:Connect(function(arg1, arg2)
    -- Handle event
end)
```

### Remote Function Pattern
```lua
-- Server (Module):
local myRequest = RemoteFunction.new("MyRequest")
myRequest.OnInvokeServer = function(player, arg1)
    -- Validate request
    return true, "Success message"
end

-- Client (Module):
local myRequest = RemoteFunction.new("MyRequest")
myRequest:InvokeServer(arg1, function(ok, message)
    print("Result:", ok, message)
end)
```

## Git Workflow

Recent commits follow pattern:
- `fix(Component): description` for bug fixes
- `feat(Component): description` for new features

**IMPORTANT:** Do NOT create git commits automatically. Only commit when explicitly requested by the user.

Modified files tracked in git status show extensive work-in-progress on:
- Cinematic Suite integration
- DevBasics Toolkit integration
- PropHunt core systems

## Testing & Debugging

### Console Output Pattern
Look for these log prefixes:
- `[PropHunt]` - GameManager logs
- `[PropHuntConfig]` - Configuration logs
- `[ScoringSystem]` - Score tracking
- `[ZoneManager]` - Zone tracking
- `[HunterTagSystem]` - Tag attempts
- `[PropDisguiseSystem]` - Possession attempts
- `[PropHunt Teleporter]` - Teleportation logs

### Debug Mode
Enable via PropHuntConfig._enableDebug SerializeField (default: true)

### Common Issues
1. **"Module not registered"** - Module not attached to PropHuntModules GameObject
2. **"Arena spawn position not configured"** - Drag spawn GameObjects to PropHuntTeleporter fields
3. **Zone detection not working** - Ensure BoxCollider has "Is Trigger" = true
4. **Tag validation failing** - Check distance ≤ 4.0m and phase = HUNTING

## Important File Locations

**Core Logic**: `Assets/PropHunt/Scripts/`
**Modules**: `Assets/PropHunt/Scripts/Modules/`
**UI**: `Assets/PropHunt/Scripts/GUI/`
**Editor Tools**: `Assets/PropHunt/Editor/`
**Documentation**: `Assets/PropHunt/Documentation/`
**Setup Guides**:
- `Assets/PropHunt/COMPLETE_UNITY_SETUP.md`
- `Assets/PropHunt/SINGLE_SCENE_SETUP.md`
- `IMPLEMENTATION_PLAN.md` (root)

## External Dependencies

**Downloaded Assets** (in `Assets/Downloads/`):
- Checkpoint Spawner
- Cinematic Suite (camera/animation system)
- DevBasics Toolkit (tweens, UI managers, audio)
- Matchmaking System
- Range Indicator
- Scene Teleporter (legacy - replaced with single-scene teleporter)
- Server Startup UI
- Tip Jar Advanced
- Trigger Object
- UI Panels
- World Config

**Key External Modules Used**:
- `devx_tweens` from DevBasics Toolkit for VFX animations
- Range Indicator for hunter tag radius visualization

## VFX System Status

VFX framework integrated via `PropHuntVFXManager.lua` with placeholder functions:
- Lobby/phase transitions
- Possession effects (player vanish, prop infill)
- Tag effects (hit/miss)
- Rejection effects (double-possess)

Particle systems and custom shaders deferred to post-V1. VFX currently uses DevBasics Tweens library for basic animations.

## Current Implementation Status

✅ **Complete** (95%):
- State machine and game loop
- Network synchronization
- Scoring system with zone multipliers
- Role assignment algorithm
- Tagging validation (4.0m range, 0.5s cooldown)
- Possession system with One-Prop Rule
- Teleportation (single-scene)
- Zone detection system
- Ready-up system
- Basic UI (HUD, ready button)

⏳ **Remaining for V1**:
- Unity scene setup with zones and props
- VFX particle systems (using placeholders)
- Custom shaders (outline, dissolve, emissive)
- Role-specific UI polish
- Taunt system (nice-to-have, disabled by default)

## Code Style Notes

- Lua functions use PascalCase (e.g., `GetPlayerScore`)
- Local functions use camelCase (e.g., `onPlayerTagged`)
- Network events use PascalCase with PH_ prefix (e.g., `PH_StateChanged`)
- Module exports always end with explicit return table
- Type annotations used where supported: `function Foo(arg : Type) : ReturnType`
- SerializeFields use `--!SerializeField` and `--!Tooltip()` directives for Unity Inspector

