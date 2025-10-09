# PropHunt Recap Screen Integration Guide

## Overview

The PropHunt recap screen displays round-end results using the UI Panels notification system. It shows winner information, player scores, team bonuses, and hunter accuracy statistics.

## Files Created

- **PropHuntRecapScreen.lua** - Main recap screen module (`Assets/PropHunt/Scripts/GUI/PropHuntRecapScreen.lua`)

## Architecture

### Module Type
- **Type**: Module (Client-side)
- **Dependencies**:
  - `panels` (UI Panels system from `/Assets/Downloads/UI Panels/`)
  - `PropHuntConfig` (for configuration values)

### Network Communication
The recap screen listens for server events via:
```lua
local recapEvent = Event.new("PH_RecapScreen")
```

## Integration Steps

### Step 1: Update PropHuntGameManager.lua

Add player scoring tracking and recap data preparation to the server-side game manager.

#### 1.1 Add Player Score Tracking

Add to module scope (around line 36):
```lua
-- Player scores tracking
local playerScores = {} -- { [userId] = { name, score, role, hits, misses } }
```

#### 1.2 Initialize Player Scores on Round Start

In `StartNewRound()` function (around line 258), add:
```lua
function StartNewRound()
    roundNumber = roundNumber + 1
    Log(string.format("ROUND %d", roundNumber))

    -- Initialize player scores for this round
    playerScores = {}
    for _, player in pairs(activePlayers) do
        playerScores[player.id] = {
            name = player.name,
            id = player.id,
            score = 0,
            hits = 0,
            misses = 0,
            role = nil -- Will be set during role assignment
        }
    end

    -- Assign roles
    AssignRoles()

    -- Transition to hiding phase
    TransitionToState(GameState.HIDING)
    debugEvent:FireAllClients("ROUND_START", roundNumber)
end
```

#### 1.3 Update Role Assignment to Track Roles

In `AssignRoles()` function (around line 288), add role tracking:
```lua
for i, player in ipairs(players) do
    if i <= propsCount then
        table.insert(propsTeam, player)
        if playerScores[player.id] then
            playerScores[player.id].role = "prop"
        end
        NotifyPlayerRole(player, "prop")
        Log(string.format("PROP: %s", player.name))
        debugEvent:FireAllClients("ROLE", player.id, "prop")
    else
        table.insert(huntersTeam, player)
        if playerScores[player.id] then
            playerScores[player.id].role = "hunter"
        end
        NotifyPlayerRole(player, "hunter")
        Log(string.format("HUNTER: %s", player.name))
        debugEvent:FireAllClients("ROLE", player.id, "hunter")
    end
end
```

#### 1.4 Track Hunter Hits/Misses

Update `OnPlayerTagged()` to track hits:
```lua
function OnPlayerTagged(hunter, prop)
    -- Existing validation code...

    -- Track hunter hit
    if playerScores[hunter.id] then
        playerScores[hunter.id].hits = playerScores[hunter.id].hits + 1
    end

    -- Existing tag processing code...
end
```

Add a new remote function for tracking misses (add near line 50):
```lua
local tagMissRequest = RemoteFunction.new("PH_TagMiss")
```

In `self:ServerStart()`, add handler:
```lua
-- Handle tag miss tracking
tagMissRequest.OnInvokeServer = function(player)
    if currentState.value ~= GameState.HUNTING then
        return false
    end

    if playerScores[player.id] then
        playerScores[player.id].misses = playerScores[player.id].misses + 1
    end

    return true
end
```

#### 1.5 Calculate and Send Recap Data

Replace the `EndRound()` function (around line 269) with:
```lua
function EndRound(winner)
    local winningTeam = winner

    if winner == "hunters" then
        huntersWins = huntersWins + 1
        Log("HUNTERS WIN!")
    else
        propsWins = propsWins + 1
        Log("PROPS WIN!")
    end

    Log(string.format("SCORE Props:%d Hunt:%d", propsWins, huntersWins))

    -- Calculate final scores and bonuses
    local recapData = CalculateRecapData(winningTeam)

    -- Transition to round end
    TransitionToState(GameState.ROUND_END)

    -- Send recap data to clients
    local recapEvent = Event.new("PH_RecapScreen")
    recapEvent:FireAllClients(recapData)

    debugEvent:FireAllClients("ROUND_END", winner, propsWins, huntersWins)
end
```

#### 1.6 Add Score Calculation Function

Add this new function after `EndRound()`:
```lua
function CalculateRecapData(winningTeam)
    -- Apply team bonuses
    if winningTeam == "hunters" then
        for _, hunter in ipairs(huntersTeam) do
            if playerScores[hunter.id] then
                playerScores[hunter.id].score = playerScores[hunter.id].score + Config.GetHunterTeamWinBonus()
            end
        end
    else -- props win
        for _, prop in ipairs(propsTeam) do
            if playerScores[prop.id] then
                -- Surviving props get full bonus
                playerScores[prop.id].score = playerScores[prop.id].score + Config.GetPropTeamWinBonusSurvived()
            end
        end

        -- Found props get smaller bonus
        for _, eliminated in ipairs(eliminatedPlayers) do
            if playerScores[eliminated.id] then
                playerScores[eliminated.id].score = playerScores[eliminated.id].score + Config.GetPropTeamWinBonusFound()
            end
        end
    end

    -- Calculate hunter accuracy bonuses and stats
    local hunterStats = {}
    for _, hunter in ipairs(huntersTeam) do
        if playerScores[hunter.id] then
            local hits = playerScores[hunter.id].hits or 0
            local misses = playerScores[hunter.id].misses or 0
            local totalShots = hits + misses
            local accuracy = totalShots > 0 and (hits / totalShots) or 0

            -- Apply accuracy bonus
            local accuracyBonus = math.floor(accuracy * Config.GetHunterAccuracyBonusMax())
            playerScores[hunter.id].score = playerScores[hunter.id].score + accuracyBonus

            table.insert(hunterStats, {
                name = hunter.name,
                hits = hits,
                misses = misses,
                accuracy = accuracy,
                accuracyBonus = accuracyBonus
            })
        end
    end

    -- Sort player scores by score (highest first)
    local sortedScores = {}
    for _, scoreData in pairs(playerScores) do
        table.insert(sortedScores, scoreData)
    end

    table.sort(sortedScores, function(a, b)
        return a.score > b.score
    end)

    -- Determine winner and tie-breaker
    local winner = sortedScores[1]
    local tieBreaker = nil

    if #sortedScores > 1 and sortedScores[1].score == sortedScores[2].score then
        -- Tie detected - apply tie-breaker logic
        if sortedScores[1].role == "hunter" then
            tieBreaker = "Most tags"
        else
            tieBreaker = "Survival bonus"
        end
    end

    -- Build recap data structure
    local recapData = {
        winner = winner,
        tieBreaker = tieBreaker,
        winningTeam = winningTeam,
        playerScores = sortedScores,
        teamBonuses = {
            hunters = Config.GetHunterTeamWinBonus(),
            propsSurvived = Config.GetPropTeamWinBonusSurvived(),
            propsFound = Config.GetPropTeamWinBonusFound()
        },
        hunterStats = hunterStats
    }

    return recapData
end
```

### Step 2: Attach RecapScreen to Scene

1. Open Unity Editor
2. Navigate to `Assets/PropHunt/Scenes/test.unity`
3. Find or create a GameObject for UI management (e.g., "PropHuntUI" or "GameManager")
4. Add the **PropHuntRecapScreen** component (the auto-generated C# wrapper)
5. Ensure the **UI Panels** GameObject is active in the scene (required dependency)

### Step 3: Update HunterTagSystem.lua (Optional)

To track misses, update the hunter tag system to send miss events:

```lua
-- In HunterTagSystem.lua, when raycast misses:
local tagMissRequest = RemoteFunction.new("PH_TagMiss")

-- After a miss is detected:
local success = tagMissRequest:InvokeServer()
```

## Recap Data Structure

The server sends this data structure to clients:

```lua
{
    winner = {
        name = "PlayerName",
        id = "userId",
        score = 150,
        role = "hunter" or "prop"
    },
    tieBreaker = "Most tags" or nil,
    winningTeam = "props" or "hunters",
    playerScores = {
        { name = "Player1", score = 150, role = "hunter", hits = 3, misses = 1 },
        { name = "Player2", score = 120, role = "prop" }
    },
    teamBonuses = {
        hunters = 50,
        propsSurvived = 30,
        propsFound = 15
    },
    hunterStats = {
        { name = "Hunter1", hits = 3, misses = 1, accuracy = 0.75, accuracyBonus = 37 }
    }
}
```

## Display Features

The recap screen displays:

1. **Winner Announcement**: Player name and final score
2. **Tie-breaker Info**: If applicable, shows how the tie was broken
3. **Team Bonuses**: Shows bonuses applied to winning team
4. **Final Scores**: All players sorted by score with role icons
   - 🔫 = Hunter
   - 📦 = Prop
5. **Hunter Accuracy**: Hit/miss ratio and accuracy bonus for each hunter

## Auto-Dismiss Behavior

- The recap screen automatically dismisses after **10 seconds**
- Players can manually close it by clicking the close button
- Timer is managed both by UI Panels system and internally for tracking

## Manual Control

You can manually show/hide the recap screen:

```lua
local RecapScreen = require("PropHuntRecapScreen")

-- Show manually
RecapScreen.ShowRecap(customRecapData)

-- Hide manually
RecapScreen.HideRecap()

-- Get current data
local data = RecapScreen.GetCurrentRecapData()
```

## Testing

### Test with Debug Events

1. Use the existing debug system to trigger ROUND_END state
2. Force a round end with specific winner
3. Verify recap screen appears with correct data

### Manual Testing

```lua
-- In Unity Console or debug script:
local testData = {
    winner = { name = "TestPlayer", score = 200, role = "hunter" },
    winningTeam = "hunters",
    playerScores = {
        { name = "TestPlayer", score = 200, role = "hunter" },
        { name = "Player2", score = 150, role = "prop" }
    },
    hunterStats = {
        { name = "TestPlayer", hits = 5, misses = 2, accuracy = 0.71, accuracyBonus = 35 }
    }
}

local RecapScreen = require("PropHuntRecapScreen")
RecapScreen.ShowRecap(testData)
```

## Customization

### Modify Display Duration

Change the duration parameter in `PropHuntRecapScreen.lua`:

```lua
panels.ShowNotification(
    notificationType,
    BuildTitleText(recapData),
    message,
    15 -- Change to desired seconds
)
```

### Change Notification Style

Modify the notification type based on conditions:

```lua
-- Current: SUCCESS for props, INFO for hunters
-- Add more conditions:
if recapData.winner.score > 500 then
    notificationType = panels.GetNotificationTypes().SUCCESS
elseif recapData.winner.score < 100 then
    notificationType = panels.GetNotificationTypes().WARNING
end
```

### Add Custom Formatting

Modify `BuildRecapMessage()` to add:
- Player avatars
- Zone information
- Time survived
- Custom achievements

## Troubleshooting

### Recap Screen Not Appearing

1. **Check UI Panels GameObject**: Ensure it's active in the scene
2. **Verify Event Name**: Server and client must use same event name ("PH_RecapScreen")
3. **Console Logs**: Look for "[PropHuntRecapScreen]" messages
4. **Network Events**: Verify `Event.new("PH_RecapScreen")` exists in both server and client

### Data Not Displaying Correctly

1. **Check Data Structure**: Print `recapData` in server before sending
2. **Validate Player Scores**: Ensure `playerScores` table is populated
3. **Role Assignment**: Verify roles are set during `AssignRoles()`

### Auto-Dismiss Not Working

1. **Timer Conflicts**: Check if multiple timers are interfering
2. **UI Panels System**: Verify panels.lua is properly initialized
3. **Duration Value**: Ensure duration > 0 in ShowNotification call

## Future Enhancements

### V2 Features to Add

1. **Zone Display**: Show which zone each player was in when tagged/survived
2. **Time Stats**: Display how long each prop survived
3. **Taunt Stats**: If taunt system is enabled, show successful taunts
4. **MVP Badge**: Highlight the MVP with special styling
5. **Progression**: Show XP/level progression if added
6. **Achievements**: Display round-specific achievements earned

### UI Improvements

1. **Custom Panel**: Create dedicated UXML panel instead of using notification
2. **Animations**: Add slide-in/fade effects
3. **Sounds**: Play victory/defeat sounds based on outcome
4. **Podium View**: Top 3 players with podium visual
5. **Interactive Elements**: Allow clicking players to see detailed stats

## Configuration

All scoring values are configured in `PropHuntConfig.lua`:

```lua
-- Team Bonuses
_hunterTeamWinBonus = 50
_propTeamWinBonusSurvived = 30
_propTeamWinBonusFound = 15

-- Hunter Scoring
_hunterAccuracyBonusMax = 50
```

Adjust these values to balance gameplay and scoring.
