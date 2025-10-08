--!Type(Module)

local Utils = require("devx_utils")
local Logger = require("devx_logger")
local Config = require("devx_config")

local Events = require("devx_events_factory")
local PlayerTracker = require("devx_player_tracker")

local lb : Leaderboard = Leaderboard

-- Constants
local LEADERBOARD_OFFSET : number = 0
local LEADERBOARD_LIMIT : number = 10

local GetTopPlayersCallbacks = {}

type LeaderboardEntry = {
  id: string,
  name: string,
  score: number,
  rank: number
}

type TopPlayer = {
  id: string,
  name: string,
  score: number,
  rank: number
}

------------------------------------------------------
----------------------- SHARED -----------------------
--[[
  CheckForLeaderboardProperties: Checks for leaderboard properties.
  @param offset: The offset of the leaderboard.
  @param limit: The limit of the leaderboard.
  @return number, number
]]
local function CheckForLeaderboardProperties(offset: number | nil, limit: number | nil)
  if offset == nil or offset < 0 then
    offset = LEADERBOARD_OFFSET
  end

  if limit == nil or limit < 0 then
    limit = LEADERBOARD_LIMIT
  end

  return offset, limit
end

------------------------------------------------------
----------------------- CLIENT -----------------------
--[[
  FetchLeaderboard: Fetches the leaderboard.
  @param leaderboardOffset: The offset of the leaderboard.
  @param leaderboardLimit: The limit of the leaderboard.
]]
function FetchLeaderboard(leaderboardOffset: number | nil, leaderboardLimit: number | nil)
  leaderboardOffset, leaderboardLimit = CheckForLeaderboardProperties(leaderboardOffset, leaderboardLimit)

  Events.get("FetchLeaderboardRequest"):FireServer(leaderboardOffset, leaderboardLimit)
end

--[[
  GetTopPlayers: Gets the top players.
  @param limit: The limit of the top players.
  @param callback: The callback to call when the top players are fetched.
]]
function GetTopPlayers(limit: number, callback: (topPlayers: { TopPlayer } | nil) -> ())
  if not client then
    Logger.DeferPrint("GetTopPlayers: Must be called from client")
    return
  end

  local requestId = Utils.GenerateRandomRequestId()
  GetTopPlayersCallbacks[requestId] = callback

  Events.get("GetTopPlayersRequest"):FireServer(limit, requestId)
end

function ClientGetTopPlayersResponse(requestId: string, topPlayers: { TopPlayer } | nil)
  local callback = GetTopPlayersCallbacks[requestId]
  if callback then
    callback(topPlayers)
    GetTopPlayersCallbacks[requestId] = nil
  end
end

function self:ClientAwake()
  FetchLeaderboard()

  Events.get("GetTopPlayersResponse"):Connect(ClientGetTopPlayersResponse)
end
------------------------------------------------------
----------------------- SERVER -----------------------
function IncrementPlayerScore(player: Player, score: number, callback: (entry: LeaderboardEntry | nil, err: number) -> () | nil)
  local LeaderboardKey = Config.GetLeaderboardKey()
  lb.IncrementScoreForPlayer(LeaderboardKey, player, score, function(entry, err)
    if err ~= 0 then
      Logger.DeferPrint("IncrementPlayerScore: Error incrementing score for player " .. player.name .. " with score " .. score .. " and error " .. err)
      if callback then
        callback(nil, err)
      end
    end

    if callback then
      callback(entry, err)
    end
  end)
end

--[[
  UpdatePlayerScore: Updates the score of a player.
  @param player: The player to update the score of.
  @param score: The new score of the player.
]]
function UpdatePlayerScore(player: Player, score: number)
  local LeaderboardKey = Config.GetLeaderboardKey()
  lb.SetScoreForPlayer(LeaderboardKey, player, score, function(entry, err)
    if err ~= 0 then
      Logger.DeferPrint("UpdatePlayerScore: Error updating score for player " .. player.name .. " with score " .. score .. " and error " .. err)
      return
    end
  end)

  local playerInfo = PlayerTracker.getPlayerInfo(player)
  playerInfo.score.Value = score
end

--[[
  GetPlayerLeaderboardEntry: Gets the leaderboard entry for a player.
  @param player: The player to get the leaderboard entry for.
  @param callback: The callback to call when the leaderboard entry is fetched.
]]
function GetPlayerLeaderboardEntry(player: Player, callback: (entry: LeaderboardEntry | nil, err: number) -> () | nil)
  if not player then
    Logger.DeferPrint("GetPlayerLeaderboardEntry: Player is nil")
    if callback then
      callback(nil, 1)
    end
    return
  end
  
  local LeaderboardKey = Config.GetLeaderboardKey()
  lb.GetEntryForPlayer(LeaderboardKey, player, function(entry, err)
    if err ~= 0 then
      Logger.DeferPrint("GetPlayerLeaderboardEntry: Error fetching leaderboard entry for player " .. player.name .. " with error " .. err)
      if callback then
        callback(nil, err)
      end
      return
    end

    if callback then
      callback(entry, err)
    end
  end)
end

--[[
  GetTopPlayer: Gets the top player.
  @param callback: The callback to call when the top player is fetched.
]]
function GetTopPlayer(callback: (topPlayer: TopPlayer | nil) -> ())
  local LeaderboardKey = Config.GetLeaderboardKey()
  lb.GetEntries(LeaderboardKey, 0, 1, function(entries, err)
    if err ~= 0 or #entries == 0 then
      callback(nil)
      return
    end
    
    local topEntry = entries[1]
    local topPlayer = {
      id = topEntry.id,
      name = topEntry.name,
      score = topEntry.score,
      rank = topEntry.rank
    }
    
    callback(topPlayer)
  end)
end

function ServerGetTopPlayers(player: Player, limit: number, requestId: string)
  if not server then
    Logger.DeferPrint("ServerGetTopPlayers: Must be called from server")
    return
  end

  local LeaderboardKey = Config.GetLeaderboardKey()
  lb.GetEntries(LeaderboardKey, 0, limit, function(entries, err)
    if err ~= 0 then
      Logger.DeferPrint("ServerGetTopPlayers: Error fetching leaderboard entries with error " .. err)
      Events.get("GetTopPlayersResponse"):FireClient(player, requestId, {})
      return
    end

    local topPlayers = {}
    for _, entry in ipairs(entries) do
      local topPlayer = {
        id = entry.id,
        name = entry.name,
        score = entry.score,
        rank = entry.rank
      }

      table.insert(topPlayers, topPlayer)
    end

    Events.get("GetTopPlayersResponse"):FireClient(player, requestId, topPlayers)
  end)
end

function self:ServerAwake()
  Events.get("FetchLeaderboardRequest"):Connect(function(player: Player, leaderboardOffset: number, leaderboardLimit: number)
    leaderboardOffset, leaderboardLimit = CheckForLeaderboardProperties(leaderboardOffset, leaderboardLimit)

    local LeaderboardKey = Config.GetLeaderboardKey()
    lb.GetEntries(LeaderboardKey, leaderboardOffset, leaderboardLimit, function(entries, err)
      if err ~= 0 then
        Logger.DeferPrint("FetchLeaderboard: Error fetching leaderboard entries")
        return
      end

      local entriesTable : { LeaderboardEntry } = {}
      for _, entry in ipairs(entries) do
        local entryTable : LeaderboardEntry = {
          id = entry.id,
          name = entry.name,
          score = entry.score,
          rank = entry.rank
        }

        table.insert(entriesTable, entryTable)
      end

      Events.get("FetchLeaderboardResponse"):FireClient(player, entriesTable)
    end)

    lb.GetEntryForPlayer(LeaderboardKey, player, function(entry, err)
      if err ~= 0 then
        Logger.DeferPrint("FetchLeaderboard: Error fetching leaderboard entry for player " .. player.name .. " with error " .. err)
        Events.get("LeaderboardPlayerEntryResponse"):FireClient(player, nil)
        return
      end

      if not entry then
        Events.get("LeaderboardPlayerEntryResponse"):FireClient(player, nil)
        return
      end

      local entryTable : LeaderboardEntry = {
        id = entry.id,
        name = entry.name,
        score = entry.score,
        rank = entry.rank
      }

      Events.get("LeaderboardPlayerEntryResponse"):FireClient(player, entryTable)
    end)
  end)

  Events.get("PlayerJoined"):Connect(function(player: Player)
    GetPlayerLeaderboardEntry(player, function(entry, err)
      if err ~= 0 then
        Logger.DeferPrint("PlayerJoined: Error fetching leaderboard entry for player " .. player.name .. " with error " .. err)
        return
      end

      if not entry then
        Logger.DeferPrint("PlayerJoined: No leaderboard entry found for player " .. player.name)
        return
      end

      local playerInfo = PlayerTracker.getPlayerInfo(player)
      if not playerInfo then
        Logger.DeferPrint("PlayerJoined: No player info found for player " .. player.name)
        return
      end

      playerInfo.score.value = entry.score or 0
    end)
  end)
end

function self:ServerStart()
  Events.get("GetTopPlayersRequest"):Connect(ServerGetTopPlayers)
end