# PropHunt Recap Screen - Integration Checklist

Use this checklist to ensure proper integration of the recap screen system.

## ✅ Pre-Integration Verification

### Files Created
- [x] `/Assets/PropHunt/Scripts/GUI/PropHuntRecapScreen.lua` (6.2 KB)
- [x] `/Assets/PropHunt/Documentation/RECAP_SCREEN_INTEGRATION.md` (13 KB)
- [x] `/Assets/PropHunt/Documentation/RECAP_SCREEN_EXAMPLE.lua` (17 KB)
- [x] `/Assets/PropHunt/Documentation/RECAP_SCREEN_QUICKSTART.md` (6.2 KB)
- [x] `/Assets/PropHunt/Documentation/RECAP_SCREEN_SUMMARY.md` (8.2 KB)
- [x] `/RECAP_SCREEN_README.md` (8.7 KB)

### Dependencies Check
- [ ] UI Panels asset exists at `/Assets/Downloads/UI Panels/`
- [ ] PropHuntConfig.lua exists and has scoring values
- [ ] PropHuntGameManager.lua exists
- [ ] Unity 2022.3+ with Highrise Studio SDK installed

## 📋 Integration Steps

### Step 1: Unity Scene Setup
- [ ] Open `Assets/PropHunt/Scenes/test.unity`
- [ ] Locate or create UI GameObject (e.g., "PropHuntUI")
- [ ] Add **PropHuntRecapScreen** component (auto-generated C#)
- [ ] Verify **UI Panels** GameObject is in scene hierarchy
- [ ] Ensure UI Panels GameObject is **active** (checked)
- [ ] Save scene

### Step 2: Server Code - Add Score Tracking
Open `PropHuntGameManager.lua` and add:

- [ ] **Line ~36**: Add player scores table
  ```lua
  local playerScores = {} -- { [userId] = { name, score, role, hits, misses } }
  ```

- [ ] **Line ~50**: Add tag miss request
  ```lua
  local tagMissRequest = RemoteFunction.new("PH_TagMiss")
  ```

### Step 3: Server Code - Initialize Scores
In `self:ServerStart()` function:

- [ ] Add tag miss handler (after tagRequest.OnInvokeServer)
  ```lua
  tagMissRequest.OnInvokeServer = function(player)
      if currentState.value ~= GameState.HUNTING then return false end
      if playerScores[player.id] then
          playerScores[player.id].misses = playerScores[player.id].misses + 1
          playerScores[player.id].score = playerScores[player.id].score + Config.GetHunterMissPenalty()
      end
      return true
  end
  ```

### Step 4: Server Code - Track Player Stats
In `StartNewRound()` function (before AssignRoles):

- [ ] Initialize player scores
  ```lua
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

### Step 5: Server Code - Track Roles
In `AssignRoles()` function:

- [ ] Track prop roles (in props assignment loop)
  ```lua
  if playerScores[player.id] then
      playerScores[player.id].role = "prop"
  end
  ```

- [ ] Track hunter roles (in hunters assignment loop)
  ```lua
  if playerScores[player.id] then
      playerScores[player.id].role = "hunter"
  end
  ```

### Step 6: Server Code - Track Hits
In `OnPlayerTagged()` function (after validation):

- [ ] Add hit tracking and scoring
  ```lua
  if playerScores[hunter.id] then
      playerScores[hunter.id].hits = playerScores[hunter.id].hits + 1
      playerScores[hunter.id].score = playerScores[hunter.id].score + Config.GetHunterFindBase()
  end
  ```

### Step 7: Server Code - Calculate and Send Recap
Replace `EndRound()` function:

- [ ] Update EndRound to calculate recap data
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

### Step 8: Server Code - Add Calculation Function
After `EndRound()` function:

- [ ] Add complete `CalculateRecapData()` function
  - See `RECAP_SCREEN_EXAMPLE.lua` for full implementation
  - Apply team bonuses
  - Calculate hunter accuracy
  - Sort players by score
  - Determine tie-breakers
  - Build recap data structure

## 🧪 Testing Checklist

### Console Verification
- [ ] Unity Console shows: `[PropHuntRecapScreen] Initialized`
- [ ] Unity Console shows: `[UIPanels] Initializing UI Panels system`
- [ ] No errors in console related to PropHuntRecapScreen

### Gameplay Testing
- [ ] Start Unity play mode
- [ ] Join with 2+ players
- [ ] Ready up all players
- [ ] Wait for round to start (Hiding → Hunting)
- [ ] Complete round (all props found OR timer expires)

### Display Verification
- [ ] Recap screen appears on round end
- [ ] Winner name displayed correctly
- [ ] Winner score shown
- [ ] Tie-breaker text appears (if applicable)
- [ ] Team bonuses section shows
- [ ] All player scores listed
- [ ] Players sorted highest to lowest
- [ ] Role icons visible (🔫 hunter, 📦 prop)
- [ ] Hunter accuracy stats displayed
- [ ] Hit/miss counts correct
- [ ] Accuracy percentage shown
- [ ] Accuracy bonus points displayed

### Functionality Testing
- [ ] Recap auto-dismisses after 10 seconds
- [ ] Can manually close recap with X button
- [ ] Multiple rounds work correctly
- [ ] Scores reset properly between rounds
- [ ] Different winners display correctly

### Scoring Validation
- [ ] Hunter hit tracking works
- [ ] Hunter miss tracking works (if implemented)
- [ ] Team bonuses applied correctly
- [ ] Accuracy bonus calculates correctly
- [ ] Prop survival bonus applies
- [ ] Tie-breaker logic functions

## 🔧 Configuration Checklist

### PropHuntConfig.lua Values
Verify these values are set:

- [ ] `_hunterTeamWinBonus = 50`
- [ ] `_propTeamWinBonusSurvived = 30`
- [ ] `_propTeamWinBonusFound = 15`
- [ ] `_hunterFindBase = 120`
- [ ] `_hunterMissPenalty = -8`
- [ ] `_hunterAccuracyBonusMax = 50`
- [ ] `_propTickSeconds = 5`
- [ ] `_propTickPoints = 10`
- [ ] `_propSurviveBonus = 100`

### Optional: Customize Display
- [ ] Adjust auto-dismiss duration (line 82 in PropHuntRecapScreen.lua)
- [ ] Modify message formatting in `BuildRecapMessage()`
- [ ] Change notification type based on conditions
- [ ] Add custom data to recap structure

## 🐛 Troubleshooting Checklist

### Issue: Recap Screen Not Appearing
- [ ] PropHuntRecapScreen component attached in scene?
- [ ] UI Panels GameObject active?
- [ ] Event name matches: "PH_RecapScreen"?
- [ ] Console shows any errors?
- [ ] EndRound() function firing event?
- [ ] RecapData structure valid?

### Issue: Wrong Scores Displayed
- [ ] playerScores initialized in StartNewRound()?
- [ ] Roles tracked in AssignRoles()?
- [ ] Hits tracked in OnPlayerTagged()?
- [ ] Print playerScores before sending
- [ ] Check CalculateRecapData() logic

### Issue: Missing Hunter Stats
- [ ] huntersTeam populated correctly?
- [ ] Hit/miss tracking active?
- [ ] CalculateRecapData includes hunter loop?
- [ ] Hunter stats array built correctly?

### Issue: Auto-Dismiss Not Working
- [ ] Duration > 0 in ShowNotification?
- [ ] Timer conflicts checked?
- [ ] UI Panels properly initialized?
- [ ] Console shows timer start message?

## 📚 Documentation Reference

### Quick Start (5 min read)
- [ ] Read: `RECAP_SCREEN_QUICKSTART.md`

### Complete Guide (15 min read)
- [ ] Read: `RECAP_SCREEN_INTEGRATION.md`

### Code Reference (10 min review)
- [ ] Review: `RECAP_SCREEN_EXAMPLE.lua`

### Overview (5 min read)
- [ ] Read: `RECAP_SCREEN_SUMMARY.md`

## ✨ Optional Enhancements

### V1 Polish (Optional)
- [ ] Add zone-based scoring multipliers
- [ ] Implement prop survival time tracking
- [ ] Add sound effects on display
- [ ] Customize notification colors by winner
- [ ] Add player avatars/icons

### V2 Features (Future)
- [ ] Create custom UXML panel
- [ ] Add slide-in/fade animations
- [ ] Implement podium view for top 3
- [ ] Add interactive player stats
- [ ] Display taunt system stats
- [ ] Show progression/XP gained
- [ ] Add achievement notifications
- [ ] Implement round history

## 🎯 Success Criteria

### Must Have (V1)
- [x] Display winner with score
- [x] Show all player scores sorted
- [x] Display hunter accuracy stats
- [x] Show team bonuses
- [x] Auto-dismiss after 10 seconds
- [x] Tie-breaker logic
- [x] Network synchronization
- [x] Manual close option

### Integration Complete When
- [ ] All checkboxes in "Integration Steps" checked
- [ ] All tests in "Testing Checklist" passing
- [ ] No console errors
- [ ] Recap displays correctly in play mode
- [ ] Multiple rounds work without issues

## 📝 Final Notes

### Remember
- Always edit `.lua` files, never generated C# files
- Server calculates scores, client displays recap
- Event name must match on both server and client
- Test with minimum 2 players for valid results

### Next Steps After Integration
1. Test thoroughly with multiple players
2. Adjust scoring values in PropHuntConfig.lua
3. Customize message formatting as desired
4. Consider V2 enhancements

### Support
- Check console for `[PropHuntRecapScreen]` messages
- Review RECAP_SCREEN_INTEGRATION.md for detailed help
- Use RECAP_SCREEN_EXAMPLE.lua as reference
- Print recapData before sending for debugging

---

**Status**: Ready for integration
**Estimated Integration Time**: 30-45 minutes
**Documentation Complete**: Yes
**Testing Instructions**: Included

Start with: `RECAP_SCREEN_QUICKSTART.md` → Then follow this checklist
