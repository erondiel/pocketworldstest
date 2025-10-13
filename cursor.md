# cursor.md

This file provides guidance to Cursor when working with code in this PropHunt repository.

## Project Overview

**PropHunt V1** - A round-based hide-and-seek multiplayer game for Highrise Studio platform where Props hide as objects and Hunters try to find them. Built with Unity 2022.3+ using Highrise Studio SDK (com.pz.studio@0.23.0) and Universal Render Pipeline (URP 14.0.9).

**Tech Stack**: Unity C# (Editor tools), Lua (game logic), UXML/USS (UI)

## Quick Start for Cursor

### Key Files to Focus On
- **Main Game Logic**: `Assets/PropHunt/Scripts/Modules/PropHuntGameManager.lua`
- **Configuration**: `Assets/PropHunt/Scripts/Modules/PropHuntConfig.lua`
- **Player Management**: `Assets/PropHunt/Scripts/Modules/PropHuntPlayerManager.lua`
- **Scoring**: `Assets/PropHunt/Scripts/Modules/PropHuntScoringSystem.lua`
- **UI**: `Assets/PropHunt/Scripts/GUI/PropHuntReadyButton.lua`

### Architecture Overview

**State Machine**: LOBBY → HIDING → HUNTING → ROUND_END
- Server-authoritative with validation
- All gameplay actions validated server-side
- Network sync via Highrise SDK primitives

**Module System**: All core modules attached to `PropHuntModules` GameObject
- Server modules: GameManager, PlayerManager, ScoringSystem, etc.
- Client modules: HunterTagSystem, PropDisguiseSystem, RangeIndicator
- Components: ZoneVolume, PropHuntReadyButton

## Development Patterns

### Network Communication
```lua
-- Server events
local myEvent = Event.new("MyEvent")
myEvent:FireAllClients(arg1, arg2)

-- Client events
local myEvent = Event.new("MyEvent")
myEvent:Connect(function(arg1, arg2) end)

-- Remote functions
local myRequest = RemoteFunction.new("MyRequest")
myRequest.OnInvokeServer = function(player, arg1) return true, "Success" end
```

### Module Creation
1. Create Lua file in `Assets/PropHunt/Scripts/Modules/`
2. Start with `--!Type(Module)` directive
3. Add to PropHuntModules GameObject in Unity
4. Export API: `return { FunctionName = FunctionName }`

### Code Style
- Lua functions: PascalCase (`GetPlayerScore`)
- Local functions: camelCase (`onPlayerTagged`)
- Network events: PascalCase with PH_ prefix (`PH_StateChanged`)
- SerializeFields: `--!SerializeField` and `--!Tooltip()`

## Key Constraints

1. **Props are STATIC during Hunt phase** - No movement (V1 constraint)
2. **One-Prop Rule** - Players can only possess ONE prop per round
3. **Server Validation** - All actions validated server-side:
   - Tag distance ≤ 4.0m
   - Tag cooldown ≥ 0.5s
   - Phase/role validation
4. **Raycast Origin** - From player body position (NOT camera)
5. **Mobile-First** - Tap input, mobile performance

## Scoring System

**Zone Multipliers**:
- NearSpawn: 1.5x (high risk/reward)
- Mid: 1.0x (balanced)
- Far: 0.6x (safe, low reward)

**Prop Scoring**: +10 × ZoneWeight every 5s + 100 survival bonus
**Hunter Scoring**: +120 × ZoneWeight per tag, -8 per miss, accuracy bonus

## Scene Setup

**Required Hierarchy**:
```
PropHuntModules (all module scripts)
├── LobbySpawn (position marker)
├── ArenaSpawn (50-100 units from lobby)
├── Zones/
│   ├── Zone_NearSpawn (BoxCollider trigger + ZoneVolume.lua)
│   ├── Zone_Mid (BoxCollider trigger + ZoneVolume.lua)
│   └── Zone_Far (BoxCollider trigger + ZoneVolume.lua)
└── Props/
    ├── Prop_Cube_01 (with Possessable tag)
    └── ... (5-30 props with Possessable tag)
```

**Automated Setup**: Use `Assets/PropHunt/Editor/PropHuntSceneSetupWizard.cs`

## Debug & Testing

**Console Log Prefixes**:
- `[PropHunt]` - GameManager
- `[PropHuntConfig]` - Configuration
- `[ScoringSystem]` - Score tracking
- `[ZoneManager]` - Zone tracking
- `[HunterTagSystem]` - Tag attempts

**Common Issues**:
- "Module not registered" → Module not attached to PropHuntModules
- "Arena spawn position not configured" → Drag spawn GameObjects to PropHuntTeleporter
- "Zone detection not working" → Ensure BoxCollider "Is Trigger" = true
- "Tag validation failing" → Check distance ≤ 4.0m and phase = HUNTING

## Implementation Status

✅ **Complete (95%)**:
- State machine and game loop
- Network synchronization
- Scoring system with zone multipliers
- Role assignment algorithm
- Tagging validation
- Possession system
- Teleportation (single-scene)
- Zone detection
- Ready-up system
- Basic UI

⏳ **Remaining for V1**:
- Unity scene setup with zones and props
- VFX particle systems (using placeholders)
- Custom shaders
- Role-specific UI polish

## File Locations

- **Core Logic**: `Assets/PropHunt/Scripts/`
- **Modules**: `Assets/PropHunt/Scripts/Modules/`
- **UI**: `Assets/PropHunt/Scripts/GUI/`
- **Editor Tools**: `Assets/PropHunt/Editor/`
- **Documentation**: `Assets/PropHunt/Documentation/`

## External Dependencies

**Key Assets Used**:
- DevBasics Toolkit (tweens, UI managers, audio)
- Range Indicator (hunter tag radius visualization)
- Cinematic Suite (camera/animation system)

**VFX System**: Integrated via `PropHuntVFXManager.lua` with DevBasics Tweens for animations.

