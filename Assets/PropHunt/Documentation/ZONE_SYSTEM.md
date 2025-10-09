# PropHunt Zone Volume System

The Zone Volume system provides location-based scoring multipliers for PropHunt. Players in different areas of the map receive different score weights based on strategic value.

## Overview

**Zone Types:**
- **NearSpawn** - Areas close to spawn points (1.5x multiplier)
- **Mid** - Middle areas of the map (1.0x multiplier)
- **Far** - Remote/hidden areas (0.6x multiplier)

**Default Behavior:**
- Players not in any zone receive 1.0x multiplier (same as Mid)
- Players in overlapping zones use the FIRST zone they entered
- Zone weights are configurable via `PropHuntConfig.lua`

## Architecture

### Components

1. **ZoneVolume.lua** (Server-side Component)
   - Attached to GameObjects with trigger colliders
   - Detects player enter/exit events
   - Communicates with ZoneManager

2. **ZoneManager.lua** (Module)
   - Centralized player zone tracking
   - Provides zone weight lookup for scoring
   - Handles zone registration/cleanup

### File Locations

```
Assets/PropHunt/Scripts/
├── ZoneVolume.lua               # Zone trigger component
└── Modules/
    └── ZoneManager.lua          # Zone tracking manager
```

## Unity Setup

### Creating a Zone Volume

1. **Create GameObject**
   - In Unity Hierarchy: Right-click → Create Empty
   - Name it descriptively (e.g., "Zone_Kitchen_NearSpawn")

2. **Add Collider Component**
   - Add Component → Box Collider (or Sphere/Capsule/Mesh Collider)
   - ✅ Enable "Is Trigger" checkbox
   - Adjust size to cover desired area

3. **Set Layer**
   - In Inspector, set Layer to **CharacterTrigger**
   - This ensures only player characters trigger the zone

4. **Attach ZoneVolume Script**
   - Add Component → Search "ZoneVolume"
   - Configure in Inspector:
     - **Zone Name**: "NearSpawn", "Mid", or "Far"
     - **Zone Weight**: 1.5 (NearSpawn), 1.0 (Mid), or 0.6 (Far)
     - **Enable Debug**: (optional) For testing/debugging

5. **Position Zone**
   - Move and scale the GameObject to cover the intended area
   - Use Scene view gizmos to visualize trigger bounds

### Layer Setup (Important!)

The GameObject **must** be on the **CharacterTrigger** layer:

```
Layer: CharacterTrigger
```

This ensures the `OnTriggerEnter` / `OnTriggerExit` events only fire for player characters, not other objects.

### Collider Types

**Recommended Colliders:**
- **Box Collider** - Best for rectangular rooms/areas
- **Sphere Collider** - Good for circular zones around objects
- **Mesh Collider** - For complex shapes (performance impact)

**All colliders must have "Is Trigger" enabled!**

## ZoneVolume Configuration

### Inspector Fields

```lua
-- Zone Name (string)
-- Options: "NearSpawn", "Mid", "Far"
-- This determines the zone type for UI/logging
zoneName = "Mid"

-- Zone Weight (number)
-- Score multiplier for this zone
-- Default values:
--   NearSpawn = 1.5
--   Mid = 1.0
--   Far = 0.6
zoneWeight = 1.0

-- Enable Debug (boolean)
-- Print debug logs for this specific zone
enableDebug = false
```

### Example Configurations

**Near Spawn Zone (High Risk, High Reward):**
```
Zone Name: "NearSpawn"
Zone Weight: 1.5
```

**Mid Zone (Balanced):**
```
Zone Name: "Mid"
Zone Weight: 1.0
```

**Far Zone (Safe, Lower Reward):**
```
Zone Name: "Far"
Zone Weight: 0.6
```

## ZoneManager API

### Core Functions

#### GetPlayerZone(player)
Returns the zone weight for a player (for scoring calculations).

```lua
local ZoneManager = require("Modules.ZoneManager")

local player = GetSomePlayer()
local weight = ZoneManager.GetPlayerZone(player)  -- Returns 1.5, 1.0, 0.6, or 1.0 (default)

-- Use in scoring:
local basePoints = 10
local zonePoints = basePoints * weight
```

#### GetPlayerZoneName(player)
Returns the zone name for a player (for UI/logging).

```lua
local zoneName = ZoneManager.GetPlayerZoneName(player)  -- "NearSpawn", "Mid", "Far", or "None"

-- Use in UI:
print("Player is in zone: " .. zoneName)
```

#### RegisterZone(zoneObject, zoneName, zoneWeight)
Automatically called by ZoneVolume on ServerAwake. Manual use not typically needed.

```lua
ZoneManager.RegisterZone(self.gameObject, "Mid", 1.0)
```

#### UnregisterZone(zoneObject)
Automatically called by ZoneVolume on destroy. Manual use not typically needed.

```lua
ZoneManager.UnregisterZone(self.gameObject)
```

### Utility Functions

#### ClearAllPlayerZones()
Clear all player zone tracking (useful for round reset).

```lua
ZoneManager.ClearAllPlayerZones()
```

#### RemovePlayer(player)
Remove a specific player from tracking (useful for disconnections).

```lua
ZoneManager.RemovePlayer(player)
```

#### GetZoneWeightByName(zoneName)
Get default zone weight from config by name.

```lua
local weight = ZoneManager.GetZoneWeightByName("NearSpawn")  -- Returns 1.5
```

#### SetDebugEnabled(enabled)
Enable/disable debug logging for ZoneManager.

```lua
ZoneManager.SetDebugEnabled(true)
```

#### PrintDebugInfo()
Print complete zone system state (zones, players, assignments).

```lua
ZoneManager.PrintDebugInfo()
```

## Scoring Integration

### Prop Scoring Example

Props gain points every 5 seconds based on their zone:

```lua
local ZoneManager = require("Modules.ZoneManager")
local Config = require("PropHuntConfig")

function CalculatePropTickScore(player : Player) : number
    local basePoints = Config.GetPropTickPoints()  -- 10
    local zoneWeight = ZoneManager.GetPlayerZone(player)

    return basePoints * zoneWeight
    -- NearSpawn: 10 * 1.5 = 15 points
    -- Mid:       10 * 1.0 = 10 points
    -- Far:       10 * 0.6 = 6 points
end
```

### Hunter Scoring Example

Hunters receive zone-weighted points for finding props:

```lua
function CalculateHunterFindScore(player : Player, prop : Player) : number
    local basePoints = Config.GetHunterFindBase()  -- 120
    local zoneWeight = ZoneManager.GetPlayerZone(prop)  -- Prop's zone, not hunter's

    return basePoints * zoneWeight
    -- Finding prop in NearSpawn: 120 * 1.5 = 180 points
    -- Finding prop in Mid:       120 * 1.0 = 120 points
    -- Finding prop in Far:       120 * 0.6 = 72 points
end
```

### Round Reset Integration

Clear zones when round ends:

```lua
function OnRoundEnd()
    ZoneManager.ClearAllPlayerZones()
    print("Zone tracking reset for new round")
end
```

### Player Disconnect Integration

Remove player from zone tracking:

```lua
server.PlayerDisconnected:Connect(function(player : Player)
    ZoneManager.RemovePlayer(player)
end)
```

## UI Integration

### Display Player's Current Zone

```lua
local ZoneManager = require("Modules.ZoneManager")

function UpdatePlayerZoneUI(player : Player)
    local zoneName = ZoneManager.GetPlayerZoneName(player)
    local zoneWeight = ZoneManager.GetPlayerZone(player)

    -- Update UI element
    zoneLabel.text = "Zone: " .. zoneName .. " (" .. tostring(zoneWeight) .. "x)"
end
```

### Kill Feed with Zone Info

```lua
function ShowKillFeedEntry(hunter : Player, prop : Player)
    local zoneName = ZoneManager.GetPlayerZoneName(prop)

    local message = hunter.name .. " found " .. prop.name .. " (" .. zoneName .. ")"
    -- Display: "Alice found Bob (NearSpawn)"
end
```

## Zone Overlap Behavior

**First-Zone Priority:**
When a player enters overlapping zones, they are assigned to the **first zone they entered**.

**Example:**
1. Player enters "NearSpawn" zone (weight 1.5)
2. Player walks into overlapping "Mid" zone (weight 1.0)
3. Player remains in "NearSpawn" with weight 1.5
4. Player exits "NearSpawn" zone
5. Player is now in no zone (weight 1.0 default) even though still in "Mid" zone
6. Player re-enters "Mid" zone
7. Player is now tracked in "Mid" zone (weight 1.0)

**Design Rationale:**
- Prevents zone-switching exploits
- Simplifies scoring logic
- Encourages strategic positioning

**Recommendation:**
Design zones to minimize overlap. Use distinct areas for each zone type.

## Debugging

### Enable Debug Logging

**Per-Zone Debug:**
```
In Unity Inspector:
ZoneVolume → Enable Debug: ✓
```

**Global Zone Manager Debug:**
```lua
local ZoneManager = require("Modules.ZoneManager")
ZoneManager.SetDebugEnabled(true)
```

### Debug Console Output

**ZoneVolume Logs:**
```
[ZoneVolume:NearSpawn] Zone initialized: NearSpawn (weight: 1.5)
[ZoneVolume:NearSpawn] Player Alice entered zone (weight: 1.5)
[ZoneVolume:NearSpawn] Player Alice exited zone
```

**ZoneManager Logs:**
```
[ZoneManager] Registered zone: NearSpawn (weight: 1.5)
[ZoneManager] Player Alice entered zone: NearSpawn (weight: 1.5)
[ZoneManager] Player Alice exited zone: NearSpawn
```

### Print Debug Info

Print complete zone system state:

```lua
ZoneManager.PrintDebugInfo()

-- Output:
-- [ZoneManager] === Zone Debug Info ===
-- [ZoneManager] Total zones: 3
-- [ZoneManager] Players in zones: 2
-- [ZoneManager] Registered zones:
-- [ZoneManager]   - NearSpawn (weight: 1.5)
-- [ZoneManager]   - Mid (weight: 1.0)
-- [ZoneManager]   - Far (weight: 0.6)
-- [ZoneManager] Player zones:
-- [ZoneManager]   - Alice in NearSpawn (weight: 1.5)
-- [ZoneManager]   - Bob in Far (weight: 0.6)
-- [ZoneManager] =====================
```

## Configuration

Zone weights are defined in **PropHuntConfig.lua**:

```lua
-- ========== ZONE WEIGHTS ==========
--!Tooltip("Zone weight for Near Spawn areas")
--!SerializeField
local _zoneWeightNearSpawn : number = 1.5

--!Tooltip("Zone weight for Mid areas")
--!SerializeField
local _zoneWeightMid : number = 1.0

--!Tooltip("Zone weight for Far areas")
--!SerializeField
local _zoneWeightFar : number = 0.6
```

**Adjusting Weights:**
1. Open Unity Inspector
2. Find GameObject with PropHuntConfig component
3. Modify zone weight values
4. Changes apply immediately in Play mode

## Best Practices

### Zone Design

1. **Cover Key Areas**
   - Place NearSpawn zones near spawn points and open areas
   - Use Mid zones for transitional spaces
   - Reserve Far zones for hiding spots and remote corners

2. **Avoid Excessive Overlap**
   - Minimize zone intersections
   - Use distinct boundaries when possible
   - Test player movement paths

3. **Balance Risk/Reward**
   - NearSpawn (high risk, high reward): Easy to find, more points
   - Far (low risk, low reward): Hard to find, fewer points
   - Mid (balanced): Medium visibility, medium points

### Performance

1. **Use Simple Colliders**
   - Prefer Box/Sphere over Mesh Colliders
   - Keep zone count reasonable (< 20 zones)

2. **Layer Filtering**
   - Always use CharacterTrigger layer
   - Prevents unnecessary trigger events

3. **Cleanup**
   - Zones auto-cleanup on destroy
   - Clear zones between rounds with `ClearAllPlayerZones()`

### Testing

1. **Visual Debugging**
   - Enable Gizmos in Scene view to see trigger bounds
   - Use different colored materials for zone types (optional)

2. **Console Testing**
   - Enable debug logging during development
   - Use `PrintDebugInfo()` to verify zone assignments

3. **Playtest Scenarios**
   - Test zone transitions (walk between zones)
   - Test overlapping zones (verify first-zone priority)
   - Test round reset (verify cleanup)

## Common Issues

### Players Not Triggering Zones

**Symptoms:** OnTriggerEnter never fires

**Solutions:**
- ✅ Verify GameObject layer is "CharacterTrigger"
- ✅ Verify collider "Is Trigger" is enabled
- ✅ Check player character has a Rigidbody or Character component
- ✅ Ensure ZoneVolume script is attached and active

### Incorrect Zone Weights

**Symptoms:** Wrong multiplier values

**Solutions:**
- ✅ Check ZoneVolume Inspector settings match zone type
- ✅ Verify zoneName matches exactly: "NearSpawn", "Mid", or "Far"
- ✅ Check PropHuntConfig zone weight values

### Players Stuck in Zones

**Symptoms:** Player zone not clearing on exit

**Solutions:**
- ✅ Ensure OnTriggerExit is firing (enable debug)
- ✅ Check for collider issues (overlapping zones)
- ✅ Call `ClearAllPlayerZones()` between rounds
- ✅ Call `RemovePlayer()` on disconnect

### Zone Not Registering

**Symptoms:** ZoneManager doesn't recognize zone

**Solutions:**
- ✅ Ensure ZoneVolume script is ServerAwake (Type=Server)
- ✅ Check console for registration messages
- ✅ Use `PrintDebugInfo()` to verify registration
- ✅ Restart scene if hot-reload fails

## Example: Complete Zone Setup

### Step-by-Step Example

**Creating a "Kitchen" NearSpawn Zone:**

1. Create Empty GameObject
   - Name: "Zone_Kitchen_NearSpawn"

2. Add Box Collider
   - Size: (10, 5, 10)
   - Is Trigger: ✓

3. Set Layer
   - Layer: CharacterTrigger

4. Add ZoneVolume Script
   - Zone Name: "NearSpawn"
   - Zone Weight: 1.5
   - Enable Debug: ✓ (for testing)

5. Position in Scene
   - Place over kitchen area
   - Adjust scale to cover room

6. Test
   - Enter Play mode
   - Walk player through zone
   - Check console: "[ZoneVolume:NearSpawn] Player ... entered zone (weight: 1.5)"

7. Verify Scoring
   ```lua
   -- In scoring system:
   local weight = ZoneManager.GetPlayerZone(player)
   print("Player zone weight: " .. tostring(weight))  -- Should be 1.5
   ```

## Integration Checklist

- [ ] ZoneVolume.lua exists at `/Assets/PropHunt/Scripts/ZoneVolume.lua`
- [ ] ZoneManager.lua exists at `/Assets/PropHunt/Scripts/Modules/ZoneManager.lua`
- [ ] Zone GameObjects created in Unity scene
- [ ] All zones have colliders with "Is Trigger" enabled
- [ ] All zones on "CharacterTrigger" layer
- [ ] Zone weights configured (1.5 / 1.0 / 0.6)
- [ ] Scoring system calls `GetPlayerZone()` for multipliers
- [ ] Round reset calls `ClearAllPlayerZones()`
- [ ] Player disconnect calls `RemovePlayer()`
- [ ] UI displays zone names via `GetPlayerZoneName()`
- [ ] Debug logging tested and working
- [ ] Zone overlap behavior verified
- [ ] Performance tested with multiple players

## Future Enhancements

**Potential Features (Post V1):**
- Dynamic zone weight adjustments based on player count
- Zone-specific VFX (entry/exit effects)
- Zone-based mini-objectives (e.g., "Control Point" zones)
- Heatmap visualization of zone usage
- Per-zone sound ambience/music
- Zone hazards or power-ups

## Support

For issues or questions:
1. Check console logs (enable debug mode)
2. Run `ZoneManager.PrintDebugInfo()` for diagnostics
3. Verify Unity Inspector settings
4. Review this documentation

## Related Documentation

- **PropHunt Config**: `/Assets/PropHunt/Scripts/PropHuntConfig.lua`
- **Input System**: `/Assets/PropHunt/Documentation/INPUT_SYSTEM.md`
- **Game Design Doc**: `/Assets/PropHunt/Docs/Prop_Hunt__V1_Game_Design_Document_(Tech_ArtFocused).pdf`
