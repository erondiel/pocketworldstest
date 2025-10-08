--!Type(Server)

local Logger = require("devx_logger")

local Events = require("devx_events_factory")
local PlayerTracker = require("devx_player_tracker")
local LeaderboardManager = require("devx_leaderboard_manager")

function self:Awake()
  PlayerTracker.track(server, nil)
end

function self:Start()
  Events.get("PlayerJoined"):Connect(function(player)
    Logger.DeferPrint("PlayerJoined: " .. player.name)

    local info = PlayerTracker.getPlayerInfo(player)
    if not info then
      Logger.DeferPrint("Player not found")
      return
    end

    Timer.Every(5, function()
      LeaderboardManager.IncrementPlayerScore(player, math.random(1, 100))
    end)
  end)
end