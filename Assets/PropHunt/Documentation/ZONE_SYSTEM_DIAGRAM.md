# Zone System Architecture Diagram

Visual reference for the PropHunt zone detection and scoring system.

## System Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                          UNITY SCENE                             │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  Zone Vol 1 │  │  Zone Vol 2 │  │  Zone Vol 3 │             │
│  │  (NearSpawn)│  │    (Mid)    │  │    (Far)    │             │
│  │  Weight:1.5 │  │  Weight:1.0 │  │  Weight:0.6 │             │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘             │
│         │                │                │                     │
│         │    OnTriggerEnter/Exit Events   │                     │
│         └────────────────┴────────────────┘                     │
│                          │                                       │
└──────────────────────────┼───────────────────────────────────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │   ZoneManager   │
                  │    (Module)     │
                  ├─────────────────┤
                  │ Track Players   │
                  │ Store Zones     │
                  │ Return Weights  │
                  └────────┬────────┘
                           │
                           │ GetPlayerZone(player)
                           │ Returns: 1.5, 1.0, 0.6, or 1.0
                           │
                           ▼
              ┌────────────────────────────┐
              │    Scoring Systems         │
              ├────────────────────────────┤
              │ • Prop Tick Scoring        │
              │ • Hunter Find Scoring      │
              │ • Team Bonuses             │
              └────────────────────────────┘
```

## Component Relationships

```
ZoneVolume.lua (Server)
├── SerializeFields:
│   ├── zoneName: string      → "NearSpawn" | "Mid" | "Far"
│   ├── zoneWeight: number    → 1.5 | 1.0 | 0.6
│   └── enableDebug: boolean  → true | false
│
├── Events:
│   ├── OnTriggerEnter(Collider)  → ZoneManager.OnPlayerEnterZone()
│   └── OnTriggerExit(Collider)   → ZoneManager.OnPlayerExitZone()
│
└── Lifecycle:
    ├── ServerAwake()             → ZoneManager.RegisterZone()
    └── OnDestroy()               → ZoneManager.UnregisterZone()
```

```
ZoneManager.lua (Module)
├── Data Structures:
│   ├── registeredZones: { GameObject → { name, weight } }
│   └── playerZones: { Player → { zoneName, zoneWeight, zoneObject } }
│
├── Public API:
│   ├── GetPlayerZone(player) → number
│   ├── GetPlayerZoneName(player) → string
│   ├── RegisterZone(obj, name, weight)
│   ├── UnregisterZone(obj)
│   ├── OnPlayerEnterZone(player, name, weight, obj)
│   ├── OnPlayerExitZone(player, obj)
│   ├── ClearAllPlayerZones()
│   └── RemovePlayer(player)
│
└── Utilities:
    ├── GetZoneWeightByName(name) → number
    ├── SetDebugEnabled(bool)
    └── PrintDebugInfo()
```

## Zone Type Specifications

```
┌────────────────────────────────────────────────────────────┐
│                      ZONE TYPES                            │
├────────────┬──────────┬────────────┬───────────────────────┤
│ Zone Type  │  Weight  │  Risk      │  Typical Locations    │
├────────────┼──────────┼────────────┼───────────────────────┤
│ NearSpawn  │   1.5    │  HIGH      │ • Spawn rooms         │
│            │          │            │ • Open corridors      │
│            │          │            │ • Main halls          │
├────────────┼──────────┼────────────┼───────────────────────┤
│ Mid        │   1.0    │  MEDIUM    │ • Side rooms          │
│            │          │            │ • Staircases          │
│            │          │            │ • Transition areas    │
├────────────┼──────────┼────────────┼───────────────────────┤
│ Far        │   0.6    │  LOW       │ • Remote corners      │
│            │          │            │ • Hidden alcoves      │
│            │          │            │ • Basement/attic      │
├────────────┼──────────┼────────────┼───────────────────────┤
│ None       │   1.0    │  MEDIUM    │ • Outside zones       │
│ (default)  │          │            │ • Fallback value      │
└────────────┴──────────┴────────────┴───────────────────────┘
```

## Scoring Examples

### Prop Passive Scoring (Every 5 seconds)

```
Base Points: 10 (from PropHuntConfig)

┌─────────────┬────────┬─────────────────────────┐
│    Zone     │ Weight │   Points Earned/Tick    │
├─────────────┼────────┼─────────────────────────┤
│ NearSpawn   │  1.5   │  10 × 1.5 = 15 points   │
│ Mid         │  1.0   │  10 × 1.0 = 10 points   │
│ Far         │  0.6   │  10 × 0.6 = 6 points    │
│ None        │  1.0   │  10 × 1.0 = 10 points   │
└─────────────┴────────┴─────────────────────────┘

Over 60 seconds (12 ticks):
• NearSpawn: 15 × 12 = 180 points
• Mid:       10 × 12 = 120 points
• Far:        6 × 12 = 72 points
```

### Hunter Find Scoring (Per Tag)

```
Base Points: 120 (from PropHuntConfig)

┌─────────────┬────────┬──────────────────────────┐
│ Prop's Zone │ Weight │   Hunter Points Earned   │
├─────────────┼────────┼──────────────────────────┤
│ NearSpawn   │  1.5   │  120 × 1.5 = 180 points  │
│ Mid         │  1.0   │  120 × 1.0 = 120 points  │
│ Far         │  0.6   │  120 × 0.6 = 72 points   │
│ None        │  1.0   │  120 × 1.0 = 120 points  │
└─────────────┴────────┴──────────────────────────┘

Strategic Implications:
• Finding props in NearSpawn = 180 pts (worth it!)
• Finding props in Far = 72 pts (less valuable)
```

## Zone Overlap Behavior

### First-Zone Priority System

```
Scenario: Player walks through overlapping zones

Step 1: Player enters NearSpawn zone
┌─────────────────────────────────────┐
│       NearSpawn Zone (1.5x)         │
│                                     │
│           ●  ← Player               │
│                                     │
└─────────────────────────────────────┘
Result: Tracked in NearSpawn (1.5x)


Step 2: Player moves into overlapping Mid zone
┌─────────────────────────────────────┐
│       NearSpawn Zone (1.5x)         │
│                    ┌────────────────┼────┐
│                    │  Mid Zone (1.0x)    │
│           ●  ← Player (in overlap)       │
│                    │                     │
└────────────────────┼─────────────────────┘
                     └────────────────
Result: STILL in NearSpawn (1.5x)  ← First zone priority


Step 3: Player exits NearSpawn zone
                     ┌────────────────────┐
                     │  Mid Zone (1.0x)   │
                     │                    │
                     │    ●  ← Player     │
                     │                    │
                     └────────────────────┘
Result: NO ZONE (1.0x default)  ← Not auto-assigned to Mid


Step 4: Player re-enters Mid zone
                     ┌────────────────────┐
                     │  Mid Zone (1.0x)   │
                     │                    │
  ●  → Player enters │                    │
                     │                    │
                     └────────────────────┘
Result: Tracked in Mid (1.0x)  ← Now assigned to Mid
```

**Design Rationale:**
- Prevents zone-hopping exploits
- Simplifies server-side tracking
- Forces strategic hiding decisions

## Event Flow Diagram

```
PLAYER ENTERS ZONE:

1. Physics Engine
   └─→ OnTriggerEnter(Collider)
        └─→ ZoneVolume.lua
            ├─→ Extract Player from Character component
            ├─→ Check if already tracked locally
            └─→ Call ZoneManager.OnPlayerEnterZone()
                 └─→ ZoneManager.lua
                     ├─→ Check if player already in ANY zone
                     │   ├─→ YES: Ignore (first zone priority)
                     │   └─→ NO: Track in new zone
                     └─→ Update playerZones table


PLAYER EXITS ZONE:

1. Physics Engine
   └─→ OnTriggerExit(Collider)
        └─→ ZoneVolume.lua
            ├─→ Extract Player from Character component
            ├─→ Check if tracked locally
            └─→ Call ZoneManager.OnPlayerExitZone()
                 └─→ ZoneManager.lua
                     ├─→ Check if exiting CURRENT zone
                     │   ├─→ YES: Remove from playerZones
                     │   └─→ NO: Ignore (not current zone)
                     └─→ Player now has no zone (1.0 default)


SCORING QUERY:

1. Scoring System
   └─→ ZoneManager.GetPlayerZone(player)
        └─→ ZoneManager.lua
            ├─→ Lookup player in playerZones table
            │   ├─→ FOUND: Return zone weight
            │   └─→ NOT FOUND: Return 1.0 (default)
            └─→ Return to scoring system
```

## Unity Inspector Setup

```
GameObject: "Zone_Kitchen_NearSpawn"
├── Transform
│   ├── Position: (10, 0, 5)
│   ├── Rotation: (0, 0, 0)
│   └── Scale: (1, 1, 1)
│
├── Box Collider
│   ├── Is Trigger: ✓
│   ├── Center: (0, 2.5, 0)
│   └── Size: (8, 5, 6)
│
├── ZoneVolume (Script)
│   ├── Zone Name: "NearSpawn"
│   ├── Zone Weight: 1.5
│   └── Enable Debug: ✓
│
└── Layer: CharacterTrigger  ← REQUIRED!
```

## Integration Points

```
┌────────────────────────────────────────────────┐
│          PropHunt Game Systems                 │
├────────────────────────────────────────────────┤
│                                                │
│  PropHuntGameManager.lua                       │
│  ├─→ OnRoundEnd()                              │
│  │   └─→ ZoneManager.ClearAllPlayerZones()    │
│  │                                             │
│  └─→ OnPlayerDisconnect()                      │
│      └─→ ZoneManager.RemovePlayer(player)     │
│                                                │
│  PropDisguiseSystem.lua                        │
│  └─→ (Prop possession doesn't affect zones)   │
│                                                │
│  HunterTagSystem.lua (Server)                  │
│  └─→ OnPropTagged(hunter, prop)                │
│      └─→ weight = ZoneManager.GetPlayerZone(prop) │
│          └─→ points = basePoints × weight     │
│                                                │
│  PropScoringSystem.lua                         │
│  └─→ EveryNSeconds(5)                          │
│      └─→ for each liveProp:                    │
│          └─→ weight = ZoneManager.GetPlayerZone(prop) │
│              └─→ points = basePoints × weight │
│                                                │
│  PropHuntHUD.lua (Client)                      │
│  └─→ UpdateHUD()                               │
│      └─→ zoneName = ZoneManager.GetPlayerZoneName(localPlayer) │
│          └─→ Display "Zone: NearSpawn (1.5x)" │
│                                                │
└────────────────────────────────────────────────┘
```

## Debug Visualization

```
CONSOLE OUTPUT (with debug enabled):

[ZoneManager] Registered zone: NearSpawn (weight: 1.5)
[ZoneManager] Registered zone: Mid (weight: 1.0)
[ZoneManager] Registered zone: Far (weight: 0.6)
[ZoneVolume:NearSpawn] Zone initialized: NearSpawn (weight: 1.5)
[ZoneVolume:NearSpawn] Player Alice entered zone (weight: 1.5)
[ZoneManager] Player Alice entered zone: NearSpawn (weight: 1.5)

[PropScoringSystem] Alice earned 15 points (NearSpawn)

[ZoneVolume:NearSpawn] Player Alice exited zone
[ZoneManager] Player Alice exited zone: NearSpawn

[HunterTagSystem] Bob found Alice for 180 points (NearSpawn)
```

## Performance Considerations

```
OPTIMIZATIONS:
├── Server-Only Detection
│   └── ZoneVolume is Type(Server)
│       └── No client-side overhead
│
├── Simple Colliders
│   └── Box/Sphere preferred over Mesh
│       └── ~0.1ms per trigger check
│
├── Layer Filtering
│   └── CharacterTrigger layer only
│       └── Ignores non-player objects
│
└── Minimal Data Storage
    └── Player → Zone lookup table
        └── O(1) access time

LIMITS:
├── Recommended Max Zones: 20
├── Recommended Max Players: 20
└── Total Trigger Checks: ~400/frame (acceptable)
```

## Configuration Reference

```lua
-- PropHuntConfig.lua

-- Zone Weights (Inspector-editable)
local _zoneWeightNearSpawn : number = 1.5  -- High risk, high reward
local _zoneWeightMid : number = 1.0        -- Balanced
local _zoneWeightFar : number = 0.6        // Low risk, low reward

-- Scoring Base Values
local _propTickSeconds : number = 5        -- Tick interval
local _propTickPoints : number = 10        -- Base points/tick
local _hunterFindBase : number = 120       -- Base points/find

-- Getters
GetZoneWeightNearSpawn() : number → 1.5
GetZoneWeightMid() : number → 1.0
GetZoneWeightFar() : number → 0.6
```

## Quick Reference Card

```
╔════════════════════════════════════════════════════╗
║         ZONE SYSTEM QUICK REFERENCE                ║
╠════════════════════════════════════════════════════╣
║                                                    ║
║  SETUP:                                            ║
║  1. GameObject → Layer: CharacterTrigger           ║
║  2. Add Collider → Is Trigger: ✓                   ║
║  3. Add ZoneVolume → Configure name/weight         ║
║                                                    ║
║  WEIGHTS:                                          ║
║  • NearSpawn = 1.5x (high risk/reward)             ║
║  • Mid = 1.0x (balanced)                           ║
║  • Far = 0.6x (low risk/reward)                    ║
║  • None = 1.0x (default fallback)                  ║
║                                                    ║
║  API:                                              ║
║  • GetPlayerZone(player) → number                  ║
║  • GetPlayerZoneName(player) → string              ║
║  • ClearAllPlayerZones() → void                    ║
║  • RemovePlayer(player) → void                     ║
║                                                    ║
║  SCORING:                                          ║
║  • Prop: basePoints × zoneWeight                   ║
║  • Hunter: basePoints × propZoneWeight             ║
║                                                    ║
║  DEBUG:                                            ║
║  • ZoneManager.SetDebugEnabled(true)               ║
║  • ZoneManager.PrintDebugInfo()                    ║
║  • ZoneVolume → Enable Debug: ✓                    ║
║                                                    ║
╚════════════════════════════════════════════════════╝
```

---

**Visual Legend:**
- `●` = Player position
- `→` = Data flow direction
- `├─→` = Process step
- `└─→` = Final step
- `✓` = Required checkbox
