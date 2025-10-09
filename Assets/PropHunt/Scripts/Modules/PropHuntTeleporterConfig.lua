--[[
    PropHunt Teleporter Config (Server Component)
    Holds the SerializeFields and provides them to the Teleporter module
]]

--!Type(Server)

--!SerializeField
--!Tooltip("Lobby spawn position - drag LobbySpawn GameObject here")
local lobbySpawnPosition : Transform = nil

--!SerializeField
--!Tooltip("Arena spawn position - drag ArenaSpawn GameObject here")
local arenaSpawnPosition : Transform = nil

-- Make positions accessible to the Teleporter module
function GetLobbySpawn()
    return lobbySpawnPosition
end

function GetArenaSpawn()
    return arenaSpawnPosition
end

function self:ServerAwake()
    if lobbySpawnPosition then
        print("[TeleporterConfig] Lobby spawn configured at " .. tostring(lobbySpawnPosition.position))
    else
        print("[TeleporterConfig] WARNING: Lobby spawn position not set!")
    end

    if arenaSpawnPosition then
        print("[TeleporterConfig] Arena spawn configured at " .. tostring(arenaSpawnPosition.position))
    else
        print("[TeleporterConfig] WARNING: Arena spawn position not set!")
    end
end
