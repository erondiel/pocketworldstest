# Scene Teleporter Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      PropHunt Game System                        │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ├── Uses
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│              PropHuntTeleporter Module (Wrapper)                 │
│  Location: Assets/PropHunt/Scripts/Modules/                     │
│                                                                  │
│  Public API:                                                     │
│  • TeleportToArena(player)                                       │
│  • TeleportToLobby(player)                                       │
│  • TeleportAllToArena(players[])                                 │
│  • TeleportAllToLobby(players[])                                 │
│  • TeleportPropsToArena(propsTeam)                               │
│  • TeleportHuntersToArena(huntersTeam)                           │
│  • TeleportAllPlayersToLobby(allPlayers)                         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ├── Requires
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│           SceneManager Module (Scene Teleporter Asset)           │
│  Location: Assets/Downloads/Scene Teleporter/Scripts/           │
│                                                                  │
│  Core Function:                                                  │
│  • movePlayerToScene(sceneName)                                  │
│                                                                  │
│  Server Functions:                                               │
│  • server.LoadSceneAdditive(sceneName)                           │
│  • server.MovePlayerToScene(player, sceneInfo)                   │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ├── Uses
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Highrise Studio SDK                           │
│                                                                  │
│  Built-in Functions:                                             │
│  • server.LoadSceneAdditive()                                    │
│  • server.MovePlayerToScene()                                    │
│  • Event.new()                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow: Teleportation Sequence

### Client-Initiated Teleportation (Original SceneManager)

```
Client                  Server
  │                       │
  │  Click trigger/UI     │
  │                       │
  │─────────────────────►│
  │  movePlayerToScene()  │
  │  (FireServer event)   │
  │                       │
  │                       │ Validate scene exists
  │                       │ Get sceneInfo from scenes table
  │                       │
  │                       │ server.MovePlayerToScene(player, sceneInfo)
  │                       │
  │◄─────────────────────│
  │  Position update      │
  │  (Network sync)       │
  │                       │
  │  Player teleported!   │
```

### Server-Initiated Teleportation (PropHunt Usage)

```
PropHuntGameManager      PropHuntTeleporter     SceneManager      Server
        │                        │                    │              │
        │ TransitionToState()    │                    │              │
        │ (e.g., HIDING)         │                    │              │
        │                        │                    │              │
        │ TeleportPropsToArena() │                    │              │
        │───────────────────────►│                    │              │
        │                        │                    │              │
        │                        │ For each prop:     │              │
        │                        │ movePlayerToScene("Arena")        │
        │                        │───────────────────►│              │
        │                        │                    │              │
        │                        │                    │ Get sceneInfo│
        │                        │                    │ scenes["Arena"]
        │                        │                    │              │
        │                        │                    │ MovePlayerToScene()
        │                        │                    │─────────────►│
        │                        │                    │              │
        │                        │                    │              │ Teleport!
        │                        │                    │              │
        │                        │ Log: "Teleported X players"       │
        │◄───────────────────────│                    │              │
        │                        │                    │              │
        │ Continue state logic   │                    │              │
```

## Scene Setup Architectures

### Option A: Single Scene with Spawn Areas (Recommended V1)

```
test.unity Scene
┌───────────────────────────────────────────────────────────────────┐
│                                                                    │
│  Lobby Area                          Arena Area                   │
│  ┌──────────────────┐               ┌──────────────────┐          │
│  │                  │               │                  │          │
│  │  LobbySpawn      │  1000 units   │  ArenaSpawn      │          │
│  │  Position:       │──────────────►│  Position:       │          │
│  │  (0, 0, 0)       │               │  (1000, 0, 0)    │          │
│  │                  │               │                  │          │
│  │  - Ready UI      │               │  - Props         │          │
│  │  - Spawn markers │               │  - Hiding spots  │          │
│  │  - Lobby props   │               │  - Zone volumes  │          │
│  │                  │               │                  │          │
│  └──────────────────┘               └──────────────────┘          │
│                                                                    │
│  SceneManager GameObject                                          │
│  └── sceneNames: ["Lobby", "Arena"]                               │
│                                                                    │
└───────────────────────────────────────────────────────────────────┘

Teleportation:
• "Lobby" → Moves player to LobbySpawn position
• "Arena" → Moves player to ArenaSpawn position
• Both areas in same Unity scene
• No actual scene loading, just position changes
```

### Option B: Multiple Scenes (Post-V1)

```
┌───────────────────────────────────────────────────────────────────┐
│                         Unity Project                              │
│                                                                    │
│  Lobby.unity Scene                                                 │
│  ┌──────────────────┐                                              │
│  │                  │                                              │
│  │  Default Spawn   │                                              │
│  │  Position: (0,0,0)│                                             │
│  │                  │                                              │
│  │  - Ready UI      │                                              │
│  │  - Spawn markers │         Loaded Additively                   │
│  │  - Lobby props   │              at Runtime                     │
│  │                  │         ┌──────────────────┐                │
│  └──────────────────┘         │                  │                │
│                               │  SceneManager    │                │
│  Arena.unity Scene            │  GameObject      │                │
│  ┌──────────────────┐         │                  │                │
│  │                  │         │  sceneNames:     │                │
│  │  Default Spawn   │◄────────│  - "Lobby"       │                │
│  │  Position: (0,0,0)│         │  - "Arena"       │                │
│  │                  │         │                  │                │
│  │  - Props         │         └──────────────────┘                │
│  │  - Hiding spots  │                                              │
│  │  - Zone volumes  │                                              │
│  │                  │                                              │
│  └──────────────────┘                                              │
│                                                                    │
└───────────────────────────────────────────────────────────────────┘

Teleportation:
• "Lobby" → Moves player to Lobby.unity scene
• "Arena" → Moves player to Arena.unity scene
• Scenes loaded additively (both in memory)
• True scene separation
```

## PropHuntGameManager Integration

### Code Flow with Teleportation

```lua
PropHuntGameManager.lua
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  local Config = require("PropHuntConfig")                        │
│  local PlayerManager = require("PropHuntPlayerManager")          │
│  local Teleporter = require("PropHuntTeleporter")  ◄─── NEW     │
│                                                                  │
│  function TransitionToState(newState)                            │
│      if newState == GameState.LOBBY then                         │
│          -- Reset game state                                     │
│          stateTimer.value = 0                                    │
│          eliminatedPlayers = {}                                  │
│          PlayerManager.ResetAllPlayers()                         │
│                                                                  │
│          -- Teleport all to Lobby                                │
│          local allPlayers = GetActivePlayers()                   │
│          Teleporter.TeleportAllPlayersToLobby(allPlayers) ◄─ NEW│
│                                                                  │
│      elseif newState == GameState.HIDING then                    │
│          stateTimer.value = Config.GetHidePhaseTime()            │
│                                                                  │
│          -- Teleport Props to Arena                              │
│          Teleporter.TeleportPropsToArena(propsTeam)       ◄─ NEW│
│                                                                  │
│      elseif newState == GameState.HUNTING then                   │
│          stateTimer.value = Config.GetHuntPhaseTime()            │
│                                                                  │
│          -- Teleport Hunters to Arena                            │
│          Teleporter.TeleportHuntersToArena(huntersTeam)   ◄─ NEW│
│                                                                  │
│      elseif newState == GameState.ROUND_END then                 │
│          stateTimer.value = Config.GetRoundEndTime()             │
│          -- Players stay in Arena                                │
│      end                                                         │
│                                                                  │
│      BroadcastStateChange(newState, stateTimer)                  │
│  end                                                             │
└─────────────────────────────────────────────────────────────────┘
```

## State Transition with Player Locations

```
Game State Timeline
────────────────────────────────────────────────────────────────────

LOBBY
├── Location: All players in Lobby area
├── Duration: Variable (wait for ready + 30s countdown)
├── Actions: Ready up, wait for minimum players
└── Teleport: None
    │
    ├── Minimum ready reached (≥2)
    ├── Countdown: 30 seconds
    └── Roles assigned: Props vs Hunters
    │
    ▼
HIDING
├── Location: Props in Arena, Hunters in Lobby
├── Duration: 35 seconds
├── Actions: Props select disguises, hide
├── Teleport: Props → Arena (Hunters stay)
└── Visual: Props see green outlines
    │
    ├── Hide timer expires
    └── Outlines fade out
    │
    ▼
HUNTING
├── Location: All players in Arena
├── Duration: 240 seconds (4 minutes)
├── Actions: Hunters tag Props, Props survive
├── Teleport: Hunters → Arena (Props already there)
└── Win Condition: All props found OR timer expires
    │
    ├── Round ends
    └── Calculate scores
    │
    ▼
ROUND_END
├── Location: All players in Arena
├── Duration: 15 seconds
├── Actions: Display results, winner announcement
├── Teleport: None (stay in Arena)
└── UI: Recap screen with scores
    │
    ├── Round end timer expires
    └── Reset ready status
    │
    ▼
LOBBY (repeat)
├── Location: All players in Lobby
├── Teleport: All → Lobby
└── Ready for next round
```

## File Dependencies

```
PropHuntGameManager.lua
        │
        ├── requires: PropHuntConfig.lua
        ├── requires: PropHuntPlayerManager.lua
        └── requires: PropHuntTeleporter.lua
                │
                └── requires: SceneManager.lua
                        │
                        ├── uses: Event.new()
                        ├── uses: server.LoadSceneAdditive()
                        └── uses: server.MovePlayerToScene()
```

## Unity Hierarchy Setup

```
Hierarchy (test.unity)
├── SceneManager (GameObject)
│   └── SceneManager (Component)
│       └── Scene Names: ["Lobby", "Arena"]
│
├── GameManagers (Empty GameObject)
│   └── PropHuntGameManager (GameObject)
│       └── PropHuntGameManager (Component)
│
├── Spawns (Empty GameObject)
│   ├── LobbySpawn (Empty GameObject)
│   │   ├── Transform: Position (0, 0, 0)
│   │   └── Tag: LobbySpawn
│   └── ArenaSpawn (Empty GameObject)
│       ├── Transform: Position (1000, 0, 0)
│       └── Tag: ArenaSpawn
│
├── Lobby_Environment (Empty GameObject)
│   ├── Floor
│   ├── Walls
│   ├── Decorations
│   └── UI
│       └── ReadyButton
│
└── Arena_Environment (Empty GameObject)
    ├── Floor
    ├── Walls
    ├── Props (Possessables)
    │   ├── Prop_Chair_01 (Possessable component)
    │   ├── Prop_Table_01 (Possessable component)
    │   └── Prop_Lamp_01 (Possessable component)
    └── Zones
        ├── Zone_NearSpawn (Collider, ZoneManager)
        ├── Zone_Mid (Collider, ZoneManager)
        └── Zone_Far (Collider, ZoneManager)
```

## Network Event Flow

```
State Change Triggered (Server)
        │
        ▼
TransitionToState(newState)
        │
        ├─► Update state variables
        │   • currentState.value = newState
        │   • stateTimer.value = newTime
        │
        ├─► Teleport players (NEW)
        │   │
        │   └─► PropHuntTeleporter
        │       │
        │       └─► SceneManager.movePlayerToScene()
        │           │
        │           └─► Event: "MovePlayerToSceneEvent"
        │               │
        │               └─► Server receives
        │                   │
        │                   └─► server.MovePlayerToScene()
        │                       │
        │                       └─► Network sync
        │                           │
        │                           └─► Client updates
        │
        └─► Broadcast state change
            │
            └─► stateChangedEvent:FireAllClients()
                │
                └─► All clients receive
                    │
                    └─► Update UI
```

## Performance Characteristics

```
Operation                    Cost          Frequency       Impact
─────────────────────────────────────────────────────────────────
LoadSceneAdditive()          Medium        Once (startup)   Low
MovePlayerToScene()          Very Low      Per transition   Minimal
Position update (network)    Very Low      Per teleport     Minimal
Memory (single scene)        Low           Constant         Minimal
Memory (multiple scenes)     Medium        Constant         Low
```

## Error Handling Flow

```
TeleportToArena(player)
        │
        ├─► Check: player != nil?
        │   │
        │   ├─ Yes ──► Continue
        │   │
        │   └─ No ──► Log error, return false
        │
        ├─► SceneManager.movePlayerToScene("Arena")
        │   │
        │   ├─► Check: Scene exists in scenes table?
        │   │   │
        │   │   ├─ Yes ──► Get sceneInfo
        │   │   │
        │   │   └─ No ──► Error: "Scene not found"
        │   │
        │   └─► server.MovePlayerToScene(player, sceneInfo)
        │       │
        │       ├─ Success ──► Player teleported
        │       │
        │       └─ Failure ──► Network error / invalid player
        │
        └─► Log success, return true
```

## Module Type vs Script Type

```
SceneManager.lua
├── Type: Module
├── Runs on: Both Client and Server
├── Event Handler: Server-side (movePlayerToSceneEvent:Connect)
└── Scene Loading: Server-side (server.LoadSceneAdditive)

PropHuntTeleporter.lua
├── Type: Module
├── Runs on: Both Client and Server
├── Called from: PropHuntGameManager (Module type)
└── Delegates to: SceneManager (Module type)

PropHuntGameManager.lua
├── Type: Module
├── Runs on: Both Client and Server
├── Teleportation: Server-side logic (state transitions)
└── Uses: PropHuntTeleporter functions
```

## Summary

This architecture provides a clean separation of concerns:

1. **SceneManager** - Low-level scene loading and player movement
2. **PropHuntTeleporter** - PropHunt-specific wrapper with role-based functions
3. **PropHuntGameManager** - Game state machine that triggers teleportation

The system is designed to be:
- **Modular** - Easy to replace or extend components
- **Testable** - Each layer can be tested independently
- **Maintainable** - Clear responsibilities and dependencies
- **Performant** - Minimal overhead, optimized for mobile
- **Flexible** - Supports both single scene and multiple scene setups
