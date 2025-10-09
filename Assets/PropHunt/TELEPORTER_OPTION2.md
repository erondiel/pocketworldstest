# Option 2: Single Scene Position-Based Teleportation

If you want to use a **single Unity scene** instead of separate scenes, you need to modify the teleporter to use **Transform positions** instead of scene loading.

## Step 1: Replace PropHuntTeleporter.lua

Replace the contents of `PropHuntTeleporter.lua` with this simplified version:

```lua
--!Type(Module)

-- SerializeFields for spawn positions
--!SerializeField
--!Tooltip("Lobby spawn position (Transform or Vector3)")
local lobbySpawnPosition : Transform = nil

--!SerializeField
--!Tooltip("Arena spawn position (Transform or Vector3)")
local arenaSpawnPosition : Transform = nil

local function Log(msg)
    print("[PropHunt Teleporter] " .. tostring(msg))
end

-- Teleport player to a position
local function TeleportPlayerToPosition(player, targetPosition)
    if player == nil or player.character == nil then
        Log("ERROR: Cannot teleport nil player or character")
        return false
    end

    if targetPosition == nil then
        Log("ERROR: Target position is nil")
        return false
    end

    -- Get Vector3 from either Transform or direct Vector3
    local pos = targetPosition
    if type(targetPosition) == "userdata" and targetPosition.position then
        pos = targetPosition.position
    end

    player.character.transform.position = pos
    return true
end

function TeleportToArena(player)
    if arenaSpawnPosition == nil then
        Log("ERROR: Arena spawn position not configured!")
        return false
    end

    Log(string.format("Teleporting %s to Arena", player.name))
    return TeleportPlayerToPosition(player, arenaSpawnPosition)
end

function TeleportToLobby(player)
    if lobbySpawnPosition == nil then
        Log("ERROR: Lobby spawn position not configured!")
        return false
    end

    Log(string.format("Teleporting %s to Lobby", player.name))
    return TeleportPlayerToPosition(player, lobbySpawnPosition)
end

function TeleportAllToArena(players)
    if players == nil or #players == 0 then
        Log("WARN: No players to teleport to Arena")
        return 0
    end

    local count = 0
    for _, player in ipairs(players) do
        if TeleportToArena(player) then
            count = count + 1
        end
    end

    Log(string.format("Teleported %d players to Arena", count))
    return count
end

function TeleportAllToLobby(players)
    if players == nil or #players == 0 then
        Log("WARN: No players to teleport to Lobby")
        return 0
    end

    local count = 0
    for _, player in ipairs(players) do
        if TeleportToLobby(player) then
            count = count + 1
        end
    end

    Log(string.format("Teleported %d players to Lobby", count))
    return count
end

function GetLobbySceneName()
    return "Lobby" -- Not actually used
end

function GetArenaSceneName()
    return "Arena" -- Not actually used
end

return {
    TeleportToArena = TeleportToArena,
    TeleportToLobby = TeleportToLobby,
    TeleportAllToArena = TeleportAllToArena,
    TeleportAllToLobby = TeleportAllToLobby,
    GetLobbySceneName = GetLobbySceneName,
    GetArenaSceneName = GetArenaSceneName
}
```

## Step 2: Create Spawn Points in Unity

1. In your Unity scene, create two empty GameObjects:
   - **LobbySpawn** - Position at `(0, 0, 0)` or wherever lobby should be
   - **ArenaSpawn** - Position at `(100, 0, 0)` or wherever arena should be

2. Select **PropHuntModules** GameObject

3. Find the **PropHuntTeleporter** component in Inspector

4. Drag spawn points to the fields:
   - **Lobby Spawn Position**: Drag `LobbySpawn` GameObject
   - **Arena Spawn Position**: Drag `ArenaSpawn` GameObject

## Step 3: Build Your Single Scene

- Lobby area at one location (near LobbySpawn)
- Arena area at another location (near ArenaSpawn)
- Zone volumes in arena area only
- Props/Possessables in arena area only

**Done!** Players will teleport between positions in the same scene.
