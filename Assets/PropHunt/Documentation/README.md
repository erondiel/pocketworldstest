# PropHunt - Technical Art Showcase

This folder contains all assets and scripts for the PropHunt multiplayer game built for Highrise Studio.

## 📚 Documentation

### Primary Guides
- **[COMPLETE_UNITY_SETUP.md](../COMPLETE_UNITY_SETUP.md)** - **START HERE** - Comprehensive Unity scene setup checklist
- **[SINGLE_SCENE_SETUP.md](../SINGLE_SCENE_SETUP.md)** - Teleportation system reference (single-scene approach)
- **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - System-by-system implementation guide with code examples
- **[CLAUDE.md](/CLAUDE.md)** - Architecture reference for AI assistants

### System Documentation
- **[ZONE_SYSTEM.md](ZONE_SYSTEM.md)** - Zone-based scoring multiplier system
- **[VFX_SYSTEM.md](VFX_SYSTEM.md)** - Visual effects system (V1: placeholder implementation)
- **[INPUT_SYSTEM.md](INPUT_SYSTEM.md)** - Input handling patterns for Highrise Studio

### Reference
- **[Game Design Document](Prop_Hunt__V1_Game_Design_Document_(Tech_ArtFocused).pdf)** - Complete V1 specifications (PDF)

## 📊 Current Implementation Status

### ✅ Complete (V1)
- Core game loop (LOBBY → HIDING → HUNTING → ROUND_END)
- State machine with phase timers
- Player management (ready system, join/leave)
- Network synchronization (Events, RemoteFunctions)
- Possession system with One-Prop Rule
- Hunter tagging (4.0m range, 0.5s cooldown, server validation)
- Zone system (NearSpawn/Mid/Far with scoring multipliers)
- Scoring system (zone-weighted, passive prop points, team bonuses)
- Teleportation (single-scene position-based)
- Basic UI (HUD, ready button)

### ⚠️ Placeholder (V2+)
- **VFX System** - Framework complete, but using basic tweens instead of particle systems
- **Custom Shaders** - Outline, dissolve, emissive shaders not implemented

### ❌ Not Implemented
- Recap screen (nice-to-have)
- Spectator mode (nice-to-have)
- Kill feed (nice-to-have)
- Taunt system (nice-to-have, disabled by default)

**See [CLAUDE.md](/CLAUDE.md) for complete architecture overview.**

## 🗂️ Folder Structure

```
PropHunt/
├── Docs/                    - Game Design Document (PDF)
├── Documentation/           - Implementation guides and references
│   ├── IMPLEMENTATION_GUIDE.md - System-by-system guide ⭐
│   ├── INPUT_SYSTEM.md     - Input patterns
│   └── README.md           - This file
├── Scenes/                 - Unity scenes (test.unity is main)
├── Scripts/                - Lua game logic (SOURCE OF TRUTH)
│   ├── PropHuntGameManager.lua  - State machine & game loop
│   ├── PropHuntConfig.lua       - Configuration values
│   ├── HunterTagSystem.lua      - Hunter tagging logic
│   ├── PropDisguiseSystem.lua   - Prop possession client-side
│   ├── Possessable.lua          - Prop component (needs enhancement)
│   ├── DebugCheats.lua          - Development helpers
│   ├── Modules/
│   │   ├── PropHuntPlayerManager.lua - Player tracking, ready system
│   │   └── PropHuntUIManager.lua     - HUD updates, UI control
│   └── GUI/
│       ├── PropHuntHUD.lua           - HUD display logic
│       ├── PropHuntReadyButton.lua   - Ready button functionality
│       ├── *.uxml                    - UI structure files
│       └── *.uss                     - UI styling files
├── Prefabs/
│   ├── Props/              - Disguisable prop prefabs (to be created)
│   └── UI/                 - UI element prefabs
├── Materials/
│   ├── Props/              - PBR materials for props
│   └── Environment/        - Environment materials
├── Shaders/                - Custom URP shaders (to be created)
├── VFX/                    - Particle effects (to be created)
├── Audio/
│   ├── Music/              - Background music
│   └── SFX/                - Sound effects
└── Environment/
    └── Modular/            - Modular environment pieces
```

## 🎯 Core Game Loop

```
LOBBY (≥2 ready, 30s countdown)
    ↓
HIDING (35s) - Props select disguises, Hunters in lobby
    ↓
HUNTING (240s) - Hunters tag props, props are static
    ↓
ROUND_END (15s) - Show scores, winner announcement
    ↓
Return to LOBBY
```

**Key V1 Constraint:** Props are **immobile during Hunt phase**. No unpossess once possessed.

## 🔧 Core Systems

### Game State Machine
**File:** `PropHuntGameManager.lua`
- Server-authoritative state management
- Phase timers and transitions
- Role assignment (2-20 player scaling per GDD)
- Win condition detection

### Player Management
**File:** `PropHuntPlayerManager.lua`
- Ready-up system for lobby
- Player join/leave tracking
- Network-synced ready state (BoolValue, TableValue)

### UI System
**Files:** `PropHuntUIManager.lua`, `PropHuntHUD.lua`, `PropHuntReadyButton.lua`
- Real-time HUD updates (state, timer, player counts)
- UI Toolkit (UXML/USS) components
- Ready button visibility control

### Possession System (In Progress)
**Files:** `Possessable.lua`, `PropDisguiseSystem.lua`
- Tap-to-select prop interface (client)
- Server-side validation and state tracking
- **Needs:** Enhanced Possessable component, No-Unpossess enforcement, teleportation

### Hunter Tagging (Needs Updates)
**File:** `HunterTagSystem.lua`
- Tap-to-shoot with cooldown
- **Current Issues:**
  - Raycast from camera (should be player body per GDD)
  - Distance: 100m (should be 4.0m per GDD)
  - Cooldown: 2.0s (should be 0.5s per GDD)

## 🎨 Technical Art Features (Planned)

### Shaders (URP)
- **Outline Shader:** Green during Hide phase (shader keyword toggle)
- **Dissolve Shader:** Prop transformations (vertical slice with sparks)
- **Emissive Shader:** Subtle heartbeat effect during Hunt

### VFX Specifications
- **Possession:** Vanish VFX (0.4s) + Infill VFX (radial mask)
- **Tagging:** Hit (ring shock 0.25s) + Miss (dust poof 0.15s)
- **Phase Transitions:** Lobby desaturation, arena vignette, outline fade
- **RoundEnd:** Confetti/sparkles for winners

### Materials
- PBR workflow for all props
- Mobile-optimized (reduce poly count, texture sizes)
- Zone-based prop variety

## 🧪 Development Assets

The `Assets/Downloads/` folder contains reference implementations from the Highrise ecosystem:

### Useful References
- **Matchmaking System** - Round-based gameplay, player ready system, HUD patterns
- **DevBasics Toolkit** - Player tracking, storage, leaderboard, events, utilities
- **Scene Teleporter** - Teleportation patterns (adapted for single-scene use)
- **Trigger Object** - Trigger detection patterns for zones
- **Range Indicator** - Area visualization (useful for zone debugging)
- **Checkpoint Spawner** - Storage persistence patterns
- **UI Panels** - Reusable UI components (confirmation, input, notifications)

**See [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for specific pattern usage.**

## 🚀 Quick Start (Development)

1. **Open Scene:** `Assets/PropHunt/Scenes/test.unity`
2. **Review Status:** Check implementation status above
3. **Read Implementation Guide:** [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)
4. **Current Focus:** Possession system (assets + mechanics)
5. **Next Priority:** Zone system (foundation for scoring)

## 📋 Immediate Tasks (October 8, 2024)

1. ✅ **Asset Implementation** - Import props, add Possessable components
2. 🔄 **Possession Mechanics** - Enhance Possessable.lua, server validation
3. ⏳ **Zone System** - Create ZoneVolume component, place zones
4. ⏳ **Hunter Fixes** - Align with GDD (raycast origin, R_tag, cooldown)

## 🎯 V1 Success Criteria

Per Game Design Document (GDD), V1 must have:
- [x] Role distribution (2-20 player scaling)
- [ ] Props immobile during Hunt
- [ ] Green outlines visible only to Props/Spectators during Hide
- [ ] Tagging from player origin with R_tag=4.0m and 0.5s cooldown
- [ ] Zone-weighted scoring (Near=1.5, Mid=1.0, Far=0.6) every 5s
- [ ] End conditions: All props found OR timer expires
- [ ] Winner: Highest individual score with tie-breakers
- [ ] Phase transition VFX trigger reliably
- [ ] One-Prop conflict shows rejection VFX

**Focus:** Technical art (VFX/shaders/transitions) over complex systems.

## 📅 Timeline

**Target Deadline:** October 14, 2024

**Current Phase:** Day 2 - Core mechanics implementation
**Next Milestone:** Day 4 - Stable gameplay loop (no visuals yet)
**Final Phase:** Days 6-7 - Visual polish and tech art showcase

See `/DEVELOPMENT_PLAN.md` for detailed schedule.

## 🔗 Related Documentation

- **Project Root:**
  - [CLAUDE.md](/CLAUDE.md) - Complete architecture reference
  - [DEVELOPMENT_PLAN.md](/DEVELOPMENT_PLAN.md) - 8-day timeline with daily goals

- **External Resources:**
  - [Highrise Studio Docs](https://create.highrise.game/learn/studio)
  - [Highrise Studio API](https://create.highrise.game/learn/studio-api)
  - [Highrise Forum](https://createforum.highrise.game)

---

**Version:** 1.1
**Last Updated:** October 8, 2024
**Maintainer:** PropHunt Development Team

