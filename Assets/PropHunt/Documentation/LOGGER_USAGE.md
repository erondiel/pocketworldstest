# PropHunt Logger Usage Guide

## Overview

The `PropHuntLogger` module provides centralized logging with per-system toggles, allowing you to enable/disable logs for specific systems without modifying code.

## Features

- **Per-System Toggles**: Enable/disable logs for individual systems (GameManager, VFXManager, etc.)
- **Log Levels**: INFO, WARN, ERROR, DEBUG with individual toggles
- **Unity Inspector**: All toggles are SerializeFields - configure in Unity Inspector
- **Global Overrides**: Enable/disable all logs at once
- **Zero Performance Impact**: When disabled, logging has minimal overhead

## Setup

1. **Attach to Scene**: The `PropHuntLogger.lua` module must be attached to the **PropHuntModules** GameObject in your scene
2. **Configure Toggles**: In Unity Inspector, expand PropHuntLogger and toggle systems on/off

## Configuration (Unity Inspector)

### System Toggles
- `Enable Game Manager` - Logs from game state machine
- `Enable Player Manager` - Logs from player tracking
- `Enable Scoring System` - Logs from scoring/stats
- `Enable Teleporter` - Logs from teleportation
- `Enable VFX Manager` - Logs from visual effects
- `Enable Zone Manager` - Logs from zone detection
- `Enable UI Manager` - Logs from UI coordination
- `Enable Hunter Tag System` - Logs from tagging
- `Enable Prop Possession System` - Logs from possession
- `Enable Prop Disguise System` - Logs from disguise selection
- `Enable Range Indicator` - Logs from hunter range indicator
- `Enable Ready Button` - Logs from lobby ready button
- `Enable Spectator Button` - Logs from spectator toggle
- `Enable Recap Screen` - Logs from round-end recap
- `Enable HUD` - Logs from main HUD
- `Enable Config` - Logs from configuration

### Log Level Toggles
- `Show Info` - Standard informational messages
- `Show Warn` - Warnings (non-critical issues)
- `Show Error` - Errors (always recommended)
- `Show Debug` - Verbose debugging messages

### Global Overrides
- `Enable All Logs` - Overrides all system toggles to ON
- `Disable All Logs` - Overrides everything to OFF (nuclear option)

## Usage in Code

### Basic Usage

```lua
local Logger = require("PropHuntLogger")

-- Standard log message
Logger.Log("GameManager", "Player joined the game")

-- Warning
Logger.Warn("ScoringSystem", "Score exceeded maximum value")

-- Error
Logger.Error("Teleporter", "Spawn point not found!")

-- Debug (verbose)
Logger.Debug("VFXManager", "Tween started with duration 0.3s")
```

### Formatted Logging

```lua
-- Use Logf for formatted strings
Logger.Logf("GameManager", "Player %s joined (ID: %d)", player.name, player.id)
```

### Conditional Expensive Operations

If your log message requires expensive computation (e.g., iterating large tables), check if logging is enabled first:

```lua
if Logger.IsEnabled("ScoringSystem") then
    local detailedStats = ComputeExpensiveStats()  -- Only runs if enabled
    Logger.Debug("ScoringSystem", "Stats: " .. detailedStats)
end
```

### Replacing Existing Logs

**Before:**
```lua
local function Log(msg)
    print("[PropHuntGameManager] " .. msg)
end

Log("Game started")
```

**After:**
```lua
local Logger = require("PropHuntLogger")

local function Log(msg)
    Logger.Log("GameManager", msg)
end

Log("Game started")
```

## Output Format

All logs follow this format:
```
[SystemName] [LEVEL] Message
```

**Examples:**
```
[GameManager] [INFO] Player joined the game
[Teleporter] [WARN] Spawn point distance is very far
[ScoringSystem] [ERROR] Invalid score value: -999
[VFXManager] [DEBUG] Tween sequence started with 3 tweens
```

## Best Practices

### 1. Use Appropriate Log Levels

- **INFO**: Normal game flow events (player joined, state changed, round started)
- **WARN**: Non-critical issues that might cause problems (missing optional config, unusual values)
- **ERROR**: Critical issues that break functionality (spawn points not found, network errors)
- **DEBUG**: Verbose debugging info (variable values, intermediate calculations, timing info)

### 2. Keep System Names Consistent

Use the same system name throughout your module:
```lua
-- Good
Logger.Log("GameManager", "Starting round")
Logger.Warn("GameManager", "Not enough players")

-- Bad (inconsistent naming)
Logger.Log("GameManager", "Starting round")
Logger.Warn("PropHuntGameManager", "Not enough players")
```

### 3. Use Aliases for Shorter Names

The logger supports aliases:
- "PropHunt" → GameManager
- "VFX" → VFXManager
- "PropHuntTeleporter" → Teleporter

### 4. Default Toggle State

**Recommended defaults:**
- **Production**: Disable DEBUG logs, enable INFO/WARN/ERROR
- **Development**: Enable all logs for systems you're working on
- **Performance Testing**: Disable all logs except ERROR

### 5. Avoid Logging in Hot Paths

Don't log every frame:
```lua
-- Bad (logs 60 times per second!)
function self:Update()
    Logger.Debug("GameManager", "Update called")
end

-- Good (logs only on state change)
function TransitionToState(newState)
    Logger.Log("GameManager", "State changed to " .. newState)
end
```

## Migration Guide

To migrate existing logging to the new system:

### Step 1: Import Logger
```lua
local Logger = require("PropHuntLogger")
```

### Step 2: Update Log Calls
```lua
-- Old
print("[PropHuntGameManager] Player joined")

-- New
Logger.Log("GameManager", "Player joined")
```

### Step 3: Replace Custom Log Functions
```lua
-- Old
local function Log(msg)
    print("[MySystem] " .. msg)
end

-- New
local function Log(msg)
    Logger.Log("MySystem", msg)
end
```

### Step 4: Add Your System to Logger

If your system isn't in the toggle list, add it to `PropHuntLogger.lua`:

```lua
--!SerializeField
--!Tooltip("Enable/disable logging for MyNewSystem")
local _enableMyNewSystem : boolean = true

-- Add to systemToggles table
["MyNewSystem"] = function() return _enableMyNewSystem end,
```

## Troubleshooting

### Logs Not Showing

1. Check `Disable All Logs` is OFF
2. Check the specific system toggle is ON
3. Check the log level toggle is ON (e.g., `Show Debug` for Debug logs)
4. Verify PropHuntLogger module is attached to PropHuntModules GameObject

### Too Many Logs

1. Set `Enable All Logs` to OFF
2. Disable individual noisy systems (e.g., RangeIndicator, HUD)
3. Disable DEBUG logs if only interested in events

### Performance Issues

If logging is causing performance problems:
1. Set `Disable All Logs` to ON (nuclear option)
2. Or disable verbose systems individually
3. Check for logging in Update() or FixedUpdate() loops

## Examples

### Example 1: GameManager Integration

```lua
local Logger = require("PropHuntLogger")

function StartNewRound()
    Logger.Log("GameManager", string.format("Starting round %d", roundNumber))

    -- Expensive debug logging
    if Logger.IsEnabled("GameManager") then
        local playerList = GetPlayerListString()
        Logger.Debug("GameManager", "Players: " .. playerList)
    end
end

function OnError()
    Logger.Error("GameManager", "Failed to start round - not enough players")
end
```

### Example 2: Teleporter Integration

```lua
local Logger = require("PropHuntLogger")

local function Log(msg)
    Logger.Log("Teleporter", msg)
end

function TeleportToArena(player)
    if not player then
        Logger.Error("Teleporter", "Cannot teleport nil player")
        return false
    end

    Log(string.format("Teleporting %s to Arena", player.name))
    return true
end
```

### Example 3: VFX Manager Integration

```lua
local Logger = require("PropHuntLogger")

local function DebugVFX(message)
    Logger.Debug("VFXManager", message)
end

function ScreenFadeTransition(duration)
    DebugVFX(string.format("Fade transition starting (%.2fs)", duration))
    -- ... rest of function
end
```

## Summary

The PropHuntLogger provides a clean, performant way to manage debugging output across your entire project. Configure it once in Unity Inspector, and control all logging without touching code.

**Key Benefits:**
- Toggle systems individually
- Zero code changes to enable/disable logs
- Consistent log formatting
- Performance-friendly when disabled
- Unity Inspector integration
