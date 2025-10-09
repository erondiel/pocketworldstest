# Zone System Integration - Quick Start Guide

Quick reference for integrating the zone system into PropHunt scoring.

## 1. Unity Setup (5 minutes)

### Create Zone Volumes

```
1. Hierarchy → Right-click → Create Empty
2. Name: "Zone_[Location]_[Type]" (e.g., "Zone_Kitchen_NearSpawn")
3. Add Component → Box Collider
   - ✓ Is Trigger
   - Adjust Size to cover area
4. Set Layer → CharacterTrigger
5. Add Component → ZoneVolume
   - Zone Name: "NearSpawn" / "Mid" / "Far"
   - Zone Weight: 1.5 / 1.0 / 0.6
```

### Repeat for Each Zone Type

**NearSpawn Zones** (1.5x multiplier)
- Spawn areas
- Open rooms
- High-traffic corridors

**Mid Zones** (1.0x multiplier)
- Transitional areas
- Side rooms
- Medium cover

**Far Zones** (0.6x multiplier)
- Remote corners
- Hidden spots
- Hard-to-reach areas

## 2. Scoring Integration (10 minutes)

### Prop Tick Scoring

Add zone weight to prop scoring:

```lua
local ZoneManager = require("Modules.ZoneManager")
local Config = require("PropHuntConfig")

-- Every 5 seconds, award points to living props
function CalculatePropTickScore(player : Player) : number
    local basePoints = Config.GetPropTickPoints()  -- 10
    local zoneWeight = ZoneManager.GetPlayerZone(player)  -- 1.5, 1.0, or 0.6

    return basePoints * zoneWeight
end

-- Example results:
-- NearSpawn: 10 * 1.5 = 15 points/tick
-- Mid:       10 * 1.0 = 10 points/tick
-- Far:       10 * 0.6 = 6 points/tick
```

### Hunter Find Scoring

Add zone weight to hunter tagging:

```lua
-- When hunter tags a prop
function CalculateHunterFindScore(prop : Player) : number
    local basePoints = Config.GetHunterFindBase()  -- 120
    local zoneWeight = ZoneManager.GetPlayerZone(prop)  -- Use PROP's zone

    return basePoints * zoneWeight
end

-- Example results:
-- Found in NearSpawn: 120 * 1.5 = 180 points
-- Found in Mid:       120 * 1.0 = 120 points
-- Found in Far:       120 * 0.6 = 72 points
```

## 3. UI Integration (5 minutes)

### Display Current Zone

```lua
local ZoneManager = require("Modules.ZoneManager")

function UpdatePlayerHUD(player : Player)
    local zoneName = ZoneManager.GetPlayerZoneName(player)  -- "NearSpawn", "Mid", "Far", "None"
    local zoneWeight = ZoneManager.GetPlayerZone(player)    -- 1.5, 1.0, 0.6, or 1.0

    -- Update UI
    zoneLabel.text = "Zone: " .. zoneName .. " (" .. string.format("%.1fx", zoneWeight) .. ")"
end
```

### Kill Feed with Zone

```lua
function ShowKillFeed(hunter : Player, prop : Player)
    local zoneName = ZoneManager.GetPlayerZoneName(prop)

    local message = hunter.name .. " found " .. prop.name .. " in " .. zoneName
    -- "Alice found Bob in NearSpawn"
end
```

## 4. Round Management (5 minutes)

### Clear Zones on Round End

```lua
local ZoneManager = require("Modules.ZoneManager")

function OnRoundEnd()
    -- Clear all player zone assignments
    ZoneManager.ClearAllPlayerZones()

    print("Zones reset for new round")
end
```

### Handle Disconnects

```lua
server.PlayerDisconnected:Connect(function(player : Player)
    ZoneManager.RemovePlayer(player)
end)
```

## 5. Testing Checklist

- [ ] Zones visible in Scene view (Gizmos enabled)
- [ ] Walk through each zone, check console logs
- [ ] Verify correct weights in scoring
- [ ] Test zone transitions (walk between zones)
- [ ] Test overlapping zones (first zone should stick)
- [ ] Test round reset (zones clear properly)
- [ ] Test disconnect (player removed from tracking)

## 6. Debug Commands

Enable debug logging:

```lua
local ZoneManager = require("Modules.ZoneManager")

-- Enable ZoneManager debug
ZoneManager.SetDebugEnabled(true)

-- Print full system state
ZoneManager.PrintDebugInfo()

-- In Unity Inspector:
-- ZoneVolume → Enable Debug: ✓
```

## Example: Complete Scoring Function

```lua
local ZoneManager = require("Modules.ZoneManager")
local Config = require("PropHuntConfig")

-- Prop passive scoring (called every 5 seconds)
function AwardPropTickPoints(player : Player)
    if not IsPlayerAliveProp(player) then
        return
    end

    local basePoints = Config.GetPropTickPoints()  -- 10
    local zoneWeight = ZoneManager.GetPlayerZone(player)
    local totalPoints = basePoints * zoneWeight

    AddPlayerScore(player, totalPoints)

    local zoneName = ZoneManager.GetPlayerZoneName(player)
    print(player.name .. " earned " .. tostring(totalPoints) .. " points (" .. zoneName .. ")")
end

-- Hunter find scoring (called when tag succeeds)
function AwardHunterFindPoints(hunter : Player, prop : Player)
    local basePoints = Config.GetHunterFindBase()  -- 120
    local zoneWeight = ZoneManager.GetPlayerZone(prop)  -- Prop's location matters
    local totalPoints = basePoints * zoneWeight

    AddPlayerScore(hunter, totalPoints)

    local zoneName = ZoneManager.GetPlayerZoneName(prop)
    print(hunter.name .. " found " .. prop.name .. " for " .. tostring(totalPoints) .. " points (" .. zoneName .. ")")
end
```

## Default Zone Weights

From **PropHuntConfig.lua**:

| Zone Type | Weight | Points/Tick (base 10) | Hunter Find (base 120) |
|-----------|--------|----------------------|------------------------|
| NearSpawn | 1.5    | 15 points            | 180 points             |
| Mid       | 1.0    | 10 points            | 120 points             |
| Far       | 0.6    | 6 points             | 72 points              |
| None      | 1.0    | 10 points (fallback) | 120 points (fallback)  |

## API Reference

### ZoneManager Functions

```lua
-- Get zone weight for scoring (1.5, 1.0, 0.6, or 1.0 default)
GetPlayerZone(player : Player) : number

-- Get zone name for UI ("NearSpawn", "Mid", "Far", or "None")
GetPlayerZoneName(player : Player) : string

-- Clear all players (call on round end)
ClearAllPlayerZones()

-- Remove player (call on disconnect)
RemovePlayer(player : Player)

-- Get weight by name (helper)
GetZoneWeightByName(zoneName : string) : number

-- Debug
SetDebugEnabled(enabled : boolean)
PrintDebugInfo()
```

## Common Gotchas

1. **Layer must be CharacterTrigger** - Otherwise triggers won't fire
2. **Collider must have "Is Trigger" enabled** - Otherwise it's a collision, not a trigger
3. **Zone names are case-sensitive** - Use exactly "NearSpawn", "Mid", "Far"
4. **First zone wins on overlap** - Player stays in first zone entered until they leave it
5. **Clear zones between rounds** - Always call `ClearAllPlayerZones()` on round reset
6. **Use prop's zone for hunter scoring** - Not hunter's zone

## Files Reference

```
Assets/PropHunt/Scripts/
├── ZoneVolume.lua                    # Attach to zone GameObjects
├── PropHuntConfig.lua                # Zone weight configuration
└── Modules/
    └── ZoneManager.lua               # Import in scoring scripts
```

## Full Documentation

For detailed information, see:
- **ZONE_SYSTEM.md** - Complete zone system documentation
- **PropHuntConfig.lua** - Zone weight configuration
- **INPUT_SYSTEM.md** - Input handling reference

---

**Ready to integrate?** Follow steps 1-4 above, then test with step 5!
