# Teleporter Integration Code Snippets

Quick copy-paste snippets for integrating PropHuntTeleporter into PropHuntGameManager.

## 1. Import Statement

Add this at the top of `PropHuntGameManager.lua` with other module imports:

```lua
local Config = require("PropHuntConfig")
local PlayerManager = require("PropHuntPlayerManager")
local Teleporter = require("PropHuntTeleporter")  -- ADD THIS
```

## 2. TransitionToState Function (Complete Replacement)

Replace the entire `TransitionToState()` function with this version:

```lua
--[[
    State Machine - Transition Handler
]]
function TransitionToState(newState)
    local oldName = GetStateName(currentState)
    local newName = GetStateName(newState)
    Log(string.format("%s->%s", oldName, newName))

    currentState.value = newState

    if newState == GameState.LOBBY then
        stateTimer.value = 0
        eliminatedPlayers = {}
        -- Reset ready status when returning to lobby after a round
        PlayerManager.ResetAllPlayers()

        -- Teleport all players back to Lobby
        local allPlayers = GetActivePlayers()
        Teleporter.TeleportAllPlayersToLobby(allPlayers)

    elseif newState == GameState.HIDING then
        stateTimer.value = Config.GetHidePhaseTime()
        Log(string.format("HIDE %ds", Config.GetHidePhaseTime()))

        -- Teleport Props to Arena (Hunters stay in Lobby)
        Teleporter.TeleportPropsToArena(propsTeam)

    elseif newState == GameState.HUNTING then
        stateTimer.value = Config.GetHuntPhaseTime()
        Log(string.format("HUNT %ds", Config.GetHuntPhaseTime()))

        -- Teleport Hunters to Arena (Props already there)
        Teleporter.TeleportHuntersToArena(huntersTeam)

    elseif newState == GameState.ROUND_END then
        stateTimer.value = Config.GetRoundEndTime()
        Log(string.format("END %ds", Config.GetRoundEndTime()))
        -- Players stay in Arena during round end
    end

    -- Notify all clients of state change
    BroadcastStateChange(newState, stateTimer)
    debugEvent:FireAllClients("STATE", newName, stateTimer, roundNumber)
end
```

## 3. Optional: Custom Scene Names Configuration

Add this in `ServerStart()` if your Unity scenes have different names:

```lua
function self:ServerStart()
    Log("GM Started")

    -- Configure custom scene names (optional)
    -- Only needed if your scenes aren't named "Lobby" and "Arena"
    Teleporter.SetSceneNames("MyLobbyScene", "MyArenaScene")

    -- ... rest of ServerStart code
    Log(string.format("CFG H=%ds U=%ds E=%ds P=%d",
        Config.GetHidePhaseTime(),
        Config.GetHuntPhaseTime(),
        Config.GetRoundEndTime(),
        Config.GetMinPlayersToStart()))

    -- ... rest of existing code
end
```

## 4. Alternative: Minimal Changes (Just Add Teleport Calls)

If you prefer to keep your existing `TransitionToState()` function and just add teleportation:

```lua
-- In LOBBY state handler:
if newState == GameState.LOBBY then
    stateTimer.value = 0
    eliminatedPlayers = {}
    PlayerManager.ResetAllPlayers()

    -- ADD THIS:
    local allPlayers = GetActivePlayers()
    Teleporter.TeleportAllPlayersToLobby(allPlayers)
end

-- In HIDING state handler:
elseif newState == GameState.HIDING then
    stateTimer.value = Config.GetHidePhaseTime()
    Log(string.format("HIDE %ds", Config.GetHidePhaseTime()))

    -- ADD THIS:
    Teleporter.TeleportPropsToArena(propsTeam)
end

-- In HUNTING state handler:
elseif newState == GameState.HUNTING then
    stateTimer.value = Config.GetHuntPhaseTime()
    Log(string.format("HUNT %ds", Config.GetHuntPhaseTime()))

    -- ADD THIS:
    Teleporter.TeleportHuntersToArena(huntersTeam)
end
```

## 5. Debug/Testing: Manual Teleport Commands

Add these functions for testing teleportation manually:

```lua
-- Add to the bottom of PropHuntGameManager.lua for debugging

--[[
    Debug: Manual teleport functions
    Remove or comment out in production
]]
function DebugTeleportAllToArena()
    local allPlayers = GetActivePlayers()
    Teleporter.TeleportAllToArena(allPlayers)
    Log("DEBUG: Teleported all players to Arena")
end

function DebugTeleportAllToLobby()
    local allPlayers = GetActivePlayers()
    Teleporter.TeleportAllToLobby(allPlayers)
    Log("DEBUG: Teleported all players to Lobby")
end
```

Then call from Unity Console or another debug script:
```lua
local GameManager = require("PropHuntGameManager")
GameManager.DebugTeleportAllToArena()
```

## 6. Full PropHuntGameManager.lua Integration Example

Here's what the top section should look like after integration:

```lua
--[[
    PropHunt Game Manager
    Main server-side game loop controller
    Handles state machine: Lobby → Hiding → Hunting → RoundEnd → Repeat
]]

--!Type(Module)

local Config = require("PropHuntConfig")
local PlayerManager = require("PropHuntPlayerManager")
local Teleporter = require("PropHuntTeleporter")  -- ADDED

-- Enhanced logging
local function Log(msg)
    print(tostring(msg))
end

-- Game States
local GameState = {
    LOBBY = 1,
    HIDING = 2,
    HUNTING = 3,
    ROUND_END = 4
}

-- ... rest of file remains the same
```

## Usage Examples

### Example 1: Teleport Single Player
```lua
local player = GetPlayerById(playerId)
Teleporter.TeleportToArena(player)
```

### Example 2: Teleport Team
```lua
-- Teleport all Props
Teleporter.TeleportPropsToArena(propsTeam)

-- Teleport all Hunters
Teleporter.TeleportHuntersToArena(huntersTeam)
```

### Example 3: Teleport Everyone
```lua
local everyone = GetActivePlayers()
Teleporter.TeleportAllPlayersToLobby(everyone)
```

### Example 4: Check Current Scene Names
```lua
local lobbyScene = Teleporter.GetLobbySceneName()
local arenaScene = Teleporter.GetArenaSceneName()
print("Lobby: " .. lobbyScene .. ", Arena: " .. arenaScene)
```

## Testing in Unity Play Mode

1. Start Play mode
2. Check Unity Console for teleportation logs:
   - `[PropHunt Teleporter] Teleporting PlayerName to Arena`
   - `[PropHunt Teleporter] Teleported 3 players to Arena`
3. Observe player positions change in Scene view
4. Verify Game view shows correct scene/area for local player

## Common Patterns

### Pattern 1: Conditional Teleportation
```lua
-- Only teleport if player is still connected
if player ~= nil and activePlayers[player.id] ~= nil then
    Teleporter.TeleportToArena(player)
end
```

### Pattern 2: Teleport with Callback
```lua
-- Teleport then trigger event
Teleporter.TeleportPropsToArena(propsTeam)
debugEvent:FireAllClients("TELEPORT", "Props", "Arena")
```

### Pattern 3: Staggered Teleportation
```lua
-- Teleport players one at a time with delay (for VFX)
for i, player in ipairs(propsTeam) do
    Timer.After(i * 0.5, function()
        Teleporter.TeleportToArena(player)
    end)
end
```

## Error Handling

```lua
-- Safe teleportation with error checking
local function SafeTeleportToArena(player)
    if player == nil then
        Log("ERROR: Cannot teleport nil player")
        return false
    end

    local success = Teleporter.TeleportToArena(player)
    if not success then
        Log("ERROR: Failed to teleport " .. player.name)
        -- Handle failure (retry, notify player, etc.)
    end
    return success
end
```

## Next Steps After Integration

1. Copy SceneManager.lua to your PropHunt scripts or ensure it's accessible via require()
2. Set up SceneManager GameObject in Unity with scene names
3. Add the import and teleport calls to PropHuntGameManager
4. Test state transitions in Unity Play mode
5. Verify multiplayer behavior with Highrise's multiplayer simulation
6. Add VFX at teleport spawn points (see CLAUDE.md for VFX specs)
