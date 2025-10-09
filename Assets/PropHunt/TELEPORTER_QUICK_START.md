# Scene Teleporter Quick Start Guide

## 5-Minute Setup

### Unity Setup (3 minutes)
1. Open `Assets/PropHunt/Scenes/test.unity`
2. Create GameObject: "SceneManager"
3. Add Component: "SceneManager" (from SceneManager.lua)
4. In Inspector, set `sceneNames` array:
   - Size: 2
   - Element 0: "Lobby"
   - Element 1: "Arena"
5. Create spawn points:
   - GameObject "LobbySpawn" at position (0, 0, 0)
   - GameObject "ArenaSpawn" at position (1000, 0, 0)
6. Save scene

### Code Integration (2 minutes)
1. Open `Assets/PropHunt/Scripts/PropHuntGameManager.lua`
2. Add import at top (line ~11):
   ```lua
   local Teleporter = require("PropHuntTeleporter")
   ```
3. Find `TransitionToState()` function (line ~223)
4. Add teleport calls in each state block:

   **In LOBBY block:**
   ```lua
   if newState == GameState.LOBBY then
       -- ... existing code ...
       local allPlayers = GetActivePlayers()
       Teleporter.TeleportAllPlayersToLobby(allPlayers)
   ```

   **In HIDING block:**
   ```lua
   elseif newState == GameState.HIDING then
       -- ... existing code ...
       Teleporter.TeleportPropsToArena(propsTeam)
   ```

   **In HUNTING block:**
   ```lua
   elseif newState == GameState.HUNTING then
       -- ... existing code ...
       Teleporter.TeleportHuntersToArena(huntersTeam)
   ```

5. Save file
6. Return to Unity (C# will regenerate automatically)

### Test (1 minute)
1. Press Play in Unity
2. Watch Console for:
   - `[PropHunt Teleporter] Teleporting X players...`
3. Test state transitions
4. Verify players move between Lobby and Arena

## Quick Reference

**Module Location:** `/Assets/PropHunt/Scripts/Modules/PropHuntTeleporter.lua`

**Available Functions:**
- `TeleportToArena(player)` - Single player → Arena
- `TeleportToLobby(player)` - Single player → Lobby
- `TeleportAllToArena(players)` - All players → Arena
- `TeleportAllToLobby(players)` - All players → Lobby
- `TeleportPropsToArena(propsTeam)` - Props team → Arena
- `TeleportHuntersToArena(huntersTeam)` - Hunters team → Arena
- `TeleportAllPlayersToLobby(allPlayers)` - Everyone → Lobby

**Game Flow:**
- LOBBY: All in Lobby
- HIDING: Props → Arena, Hunters in Lobby
- HUNTING: All in Arena
- ROUND_END: All stay in Arena
- Back to LOBBY: All → Lobby

## Detailed Guides

For more information, see:

- **Unity Setup:** `Documentation/TELEPORTER_UNITY_SETUP.md`
- **Code Examples:** `Documentation/TELEPORTER_CODE_SNIPPETS.md`
- **Full Integration:** `Documentation/TELEPORTER_INTEGRATION.md`
- **Architecture:** `Documentation/TELEPORTER_ARCHITECTURE.md`
- **Summary:** `/TELEPORTER_INTEGRATION_SUMMARY.md` (project root)

## Troubleshooting

**Players not teleporting?**
- Check SceneManager GameObject exists
- Verify scene names array is set
- Check Unity Console for errors

**Wrong spawn location?**
- Verify spawn point positions in Scene view
- Check spawn point GameObjects exist

**Errors in Console?**
- Ensure SceneManager component is attached
- Verify PropHuntTeleporter.lua is in Modules folder
- Check that C# scripts regenerated (look in Packages/com.pz.studio.generated/)

## Support

If you need help, check the detailed documentation files listed above. Each file includes troubleshooting sections and common issues.
