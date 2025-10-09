# PropHunt Recap Screen - Quick Start Guide

## What Was Created

### New Files
1. **PropHuntRecapScreen.lua** - Main recap screen module
   - Location: `/Assets/PropHunt/Scripts/GUI/PropHuntRecapScreen.lua`
   - Type: Module (Client-side)
   - Uses UI Panels notification system

2. **Integration Documentation**
   - `RECAP_SCREEN_INTEGRATION.md` - Complete integration guide
   - `RECAP_SCREEN_EXAMPLE.lua` - Full GameManager example with scoring

## How It Works

### Architecture
```
Server (PropHuntGameManager)
    ↓ Track player scores during round
    ↓ Calculate final scores & bonuses
    ↓ Fire Event: "PH_RecapScreen" with recapData
    ↓
Client (PropHuntRecapScreen)
    ↓ Receive recapData via Event listener
    ↓ Build formatted message
    ↓ Show UI Panels notification
    ↓ Auto-dismiss after 10 seconds
```

### What It Displays
- **Winner announcement** with name and final score
- **Tie-breaker info** if scores are tied
- **Team bonuses** applied to winning team
- **All player scores** sorted highest to lowest with role icons
- **Hunter accuracy stats** (hits, misses, accuracy %, bonus points)

## Quick Integration (5 Steps)

### Step 1: Attach Component to Scene
1. Open `Assets/PropHunt/Scenes/test.unity`
2. Find UI GameObject (or create one)
3. Add Component → Search "PropHuntRecapScreen"
4. Verify "UI Panels" GameObject is in scene and active

### Step 2: Add Player Score Tracking
In `PropHuntGameManager.lua`, add after line 36:
```lua
local playerScores = {} -- { [userId] = { name, score, role, hits, misses } }
```

### Step 3: Initialize Scores on Round Start
In `StartNewRound()` function, add before `AssignRoles()`:
```lua
-- Initialize player scores
playerScores = {}
for _, player in pairs(activePlayers) do
    playerScores[player.id] = {
        name = player.name,
        id = player.id,
        score = 0,
        hits = 0,
        misses = 0,
        role = nil
    }
end
```

### Step 4: Track Roles and Stats
In `AssignRoles()`, add role tracking:
```lua
-- For props:
if playerScores[player.id] then
    playerScores[player.id].role = "prop"
end

-- For hunters:
if playerScores[player.id] then
    playerScores[player.id].role = "hunter"
end
```

In `OnPlayerTagged()`, track hits:
```lua
if playerScores[hunter.id] then
    playerScores[hunter.id].hits = playerScores[hunter.id].hits + 1
    playerScores[hunter.id].score = playerScores[hunter.id].score + Config.GetHunterFindBase()
end
```

### Step 5: Send Recap Data on Round End
Replace `EndRound()` function (see RECAP_SCREEN_EXAMPLE.lua for full code):
```lua
function EndRound(winner)
    -- Existing win tracking...

    local recapData = CalculateRecapData(winner)
    TransitionToState(GameState.ROUND_END)

    -- Send to clients
    local recapEvent = Event.new("PH_RecapScreen")
    recapEvent:FireAllClients(recapData)
end
```

Add the `CalculateRecapData()` function from the example file.

## Testing

### Quick Test
1. Start play mode in Unity
2. Ready up with 2+ players
3. Let round complete (or force end with debug)
4. Recap screen should appear for 10 seconds

### Debug Test
```lua
-- In Unity Console or debug script:
local RecapScreen = require("PropHuntRecapScreen")

local testData = {
    winner = { name = "TestWinner", score = 250, role = "hunter" },
    winningTeam = "hunters",
    playerScores = {
        { name = "TestWinner", score = 250, role = "hunter" },
        { name = "Player2", score = 180, role = "prop" }
    },
    teamBonuses = {
        hunters = 50
    },
    hunterStats = {
        { name = "TestWinner", hits = 4, misses = 1, accuracy = 0.8, accuracyBonus = 40 }
    }
}

RecapScreen.ShowRecap(testData)
```

## Files Reference

### Must Read
- **RECAP_SCREEN_INTEGRATION.md** - Complete integration guide with troubleshooting

### Code Examples
- **RECAP_SCREEN_EXAMPLE.lua** - Full GameManager implementation with all changes

### Implementation
- **PropHuntRecapScreen.lua** - The actual recap screen module (DO NOT EDIT directly)

## Key Configuration

All scoring values in `PropHuntConfig.lua`:
```lua
_hunterTeamWinBonus = 50              -- Bonus per hunter when hunters win
_propTeamWinBonusSurvived = 30        -- Bonus for surviving props
_propTeamWinBonusFound = 15           -- Bonus for found props when props win
_hunterAccuracyBonusMax = 50          -- Max accuracy bonus for hunters
_hunterFindBase = 120                 -- Base points for finding a prop
_hunterMissPenalty = -8               -- Penalty for missing
```

## Event Structure

Server sends this via `Event.new("PH_RecapScreen")`:
```lua
{
    winner = { name, id, score, role },
    tieBreaker = "reason" or nil,
    winningTeam = "props" or "hunters",
    playerScores = [ { name, score, role, hits, misses }, ... ],
    teamBonuses = { hunters, propsSurvived, propsFound },
    hunterStats = [ { name, hits, misses, accuracy, accuracyBonus }, ... ]
}
```

## Customization

### Change Display Duration
In `PropHuntRecapScreen.lua`, line 82:
```lua
panels.ShowNotification(type, title, message, 15) -- Change 10 to desired seconds
```

### Add More Data
Extend the `recapData` structure:
```lua
-- In CalculateRecapData():
recapData.customStats = {
    roundDuration = currentRoundTime,
    totalTags = totalTagCount,
    mvpPlayer = topPlayer
}

-- In BuildRecapMessage():
if recapData.customStats then
    table.insert(lines, "Round Time: " .. recapData.customStats.roundDuration)
end
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No recap screen | Verify UI Panels is in scene and PropHuntRecapScreen component is attached |
| Wrong scores | Check `playerScores` initialization in `StartNewRound()` |
| Missing data | Print `recapData` on server before sending |
| Not auto-dismissing | Check timer duration is > 0 in ShowNotification |

## Next Steps

1. **Copy code** from RECAP_SCREEN_EXAMPLE.lua into PropHuntGameManager.lua
2. **Test** in Unity play mode
3. **Customize** scoring and display as needed
4. **Add zone weights** for location-based scoring (V2 feature)
5. **Create custom panel** for more advanced UI (future enhancement)

## Support

- Check console for `[PropHuntRecapScreen]` debug messages
- Review RECAP_SCREEN_INTEGRATION.md for detailed troubleshooting
- Verify all event names match between server and client
- Ensure PropHuntConfig.lua has all scoring values defined
