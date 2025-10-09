--!Type(Module)

-- ========== IMPORTS ==========
local PropHuntConfig = require("PropHuntConfig")

-- ========== PLAYER SCORE DATA STRUCTURE ==========
-- Stores score data for each player
local playerScores = {} -- [playerId] = { score, hits, misses, ticks, lastScoreTime }
local scoreValues = {}  -- [playerId] = NumberValue (for network sync)

-- ========== INITIALIZATION ==========

--- Initialize scoring for all players at round start
--- @param players table Array of Player objects
function InitializeScores(players)
    playerScores = {}
    scoreValues = {}

    for i = 1, #players do
        local player = players[i]
        local playerId = player.user.id

        -- Initialize score data
        playerScores[playerId] = {
            score = 0,
            hits = 0,
            misses = 0,
            ticks = 0,
            lastScoreTime = Time.time
        }

        -- Create NumberValue for network synchronization
        local scoreValue = NumberValue.new("PH_Score_" .. playerId, 0)
        scoreValues[playerId] = scoreValue
    end

    PropHuntConfig.DebugLog("ScoringSystem: Initialized scores for " .. #players .. " players")
end

--- Reset all scores (called when returning to lobby)
function ResetAllScores()
    for playerId, scoreValue in pairs(scoreValues) do
        scoreValue.value = 0
        if playerScores[playerId] then
            playerScores[playerId].score = 0
            playerScores[playerId].hits = 0
            playerScores[playerId].misses = 0
            playerScores[playerId].ticks = 0
            playerScores[playerId].lastScoreTime = Time.time
        end
    end

    PropHuntConfig.DebugLog("ScoringSystem: Reset all scores")
end

-- ========== PROP SCORING ==========

--- Award passive tick score to a prop based on zone weight
--- @param player Player The prop player
--- @param zoneWeight number Zone multiplier (1.5 Near, 1.0 Mid, 0.6 Far)
function AwardPropTickScore(player, zoneWeight)
    local playerId = player.user.id
    local scoreData = playerScores[playerId]

    if not scoreData then
        PropHuntConfig.DebugLog("ScoringSystem: ERROR - No score data for player " .. playerId)
        return
    end

    local basePoints = PropHuntConfig.GetPropTickPoints()
    local points = math.floor(basePoints * zoneWeight)

    -- Update score
    scoreData.score = scoreData.score + points
    scoreData.ticks = scoreData.ticks + 1
    scoreData.lastScoreTime = Time.time

    -- Sync to network
    if scoreValues[playerId] then
        scoreValues[playerId].value = scoreData.score
    end

    PropHuntConfig.DebugLog(string.format(
        "ScoringSystem: Prop %s tick +%d (zone %.1fx) | Total: %d",
        player.name, points, zoneWeight, scoreData.score
    ))
end

--- Award survival bonus to a prop who survived the round
--- @param player Player The surviving prop player
function AwardPropSurvivalBonus(player)
    local playerId = player.user.id
    local scoreData = playerScores[playerId]

    if not scoreData then
        PropHuntConfig.DebugLog("ScoringSystem: ERROR - No score data for player " .. playerId)
        return
    end

    local bonus = PropHuntConfig.GetPropSurviveBonus()

    -- Update score
    scoreData.score = scoreData.score + bonus
    scoreData.lastScoreTime = Time.time

    -- Sync to network
    if scoreValues[playerId] then
        scoreValues[playerId].value = scoreData.score
    end

    PropHuntConfig.DebugLog(string.format(
        "ScoringSystem: Prop %s survival bonus +%d | Total: %d",
        player.name, bonus, scoreData.score
    ))
end

-- ========== HUNTER SCORING ==========

--- Award tag score to a hunter based on zone weight
--- @param player Player The hunter player
--- @param zoneWeight number Zone multiplier of tagged prop's location
function AwardHunterTagScore(player, zoneWeight)
    local playerId = player.user.id
    local scoreData = playerScores[playerId]

    if not scoreData then
        PropHuntConfig.DebugLog("ScoringSystem: ERROR - No score data for player " .. playerId)
        return
    end

    local basePoints = PropHuntConfig.GetHunterFindBase()
    local points = math.floor(basePoints * zoneWeight)

    -- Update score
    scoreData.score = scoreData.score + points
    scoreData.lastScoreTime = Time.time

    -- Sync to network
    if scoreValues[playerId] then
        scoreValues[playerId].value = scoreData.score
    end

    PropHuntConfig.DebugLog(string.format(
        "ScoringSystem: Hunter %s tag +%d (zone %.1fx) | Total: %d",
        player.name, points, zoneWeight, scoreData.score
    ))
end

--- Apply miss penalty to a hunter
--- @param player Player The hunter player
function ApplyHunterMissPenalty(player)
    local playerId = player.user.id
    local scoreData = playerScores[playerId]

    if not scoreData then
        PropHuntConfig.DebugLog("ScoringSystem: ERROR - No score data for player " .. playerId)
        return
    end

    local penalty = PropHuntConfig.GetHunterMissPenalty()

    -- Update score
    scoreData.score = scoreData.score + penalty -- penalty is negative
    scoreData.lastScoreTime = Time.time

    -- Sync to network
    if scoreValues[playerId] then
        scoreValues[playerId].value = scoreData.score
    end

    PropHuntConfig.DebugLog(string.format(
        "ScoringSystem: Hunter %s miss penalty %d | Total: %d",
        player.name, penalty, scoreData.score
    ))
end

--- Track a successful hunter hit (for accuracy bonus)
--- @param player Player The hunter player
function TrackHunterHit(player)
    local playerId = player.user.id
    local scoreData = playerScores[playerId]

    if not scoreData then
        PropHuntConfig.DebugLog("ScoringSystem: ERROR - No score data for player " .. playerId)
        return
    end

    scoreData.hits = scoreData.hits + 1

    PropHuntConfig.DebugLog(string.format(
        "ScoringSystem: Hunter %s hit tracked | Hits: %d Misses: %d",
        player.name, scoreData.hits, scoreData.misses
    ))
end

--- Track a hunter miss (for accuracy bonus)
--- @param player Player The hunter player
function TrackHunterMiss(player)
    local playerId = player.user.id
    local scoreData = playerScores[playerId]

    if not scoreData then
        PropHuntConfig.DebugLog("ScoringSystem: ERROR - No score data for player " .. playerId)
        return
    end

    scoreData.misses = scoreData.misses + 1

    PropHuntConfig.DebugLog(string.format(
        "ScoringSystem: Hunter %s miss tracked | Hits: %d Misses: %d",
        player.name, scoreData.hits, scoreData.misses
    ))
end

--- Calculate and award accuracy bonus to a hunter at round end
--- @param player Player The hunter player
function AwardHunterAccuracyBonus(player)
    local playerId = player.user.id
    local scoreData = playerScores[playerId]

    if not scoreData then
        PropHuntConfig.DebugLog("ScoringSystem: ERROR - No score data for player " .. playerId)
        return
    end

    local hits = scoreData.hits
    local misses = scoreData.misses
    local totalAttempts = hits + misses

    if totalAttempts == 0 then
        PropHuntConfig.DebugLog(string.format(
            "ScoringSystem: Hunter %s accuracy bonus +0 (no attempts)",
            player.name
        ))
        return
    end

    local maxBonus = PropHuntConfig.GetHunterAccuracyBonusMax()
    local accuracy = hits / math.max(1, totalAttempts)
    local bonus = math.floor(accuracy * maxBonus)

    -- Update score
    scoreData.score = scoreData.score + bonus
    scoreData.lastScoreTime = Time.time

    -- Sync to network
    if scoreValues[playerId] then
        scoreValues[playerId].value = scoreData.score
    end

    PropHuntConfig.DebugLog(string.format(
        "ScoringSystem: Hunter %s accuracy bonus +%d (%.1f%% = %d/%d) | Total: %d",
        player.name, bonus, accuracy * 100, hits, totalAttempts, scoreData.score
    ))
end

-- ========== TEAM BONUSES ==========

--- Award team bonuses based on win condition
--- @param winningTeam string "Hunter" or "Prop"
--- @param hunters table Array of hunter Player objects
--- @param props table Array of all prop Player objects
--- @param eliminatedProps table Array of eliminated prop Player objects
function AwardTeamBonuses(winningTeam, hunters, props, eliminatedProps)
    if winningTeam == "Hunter" then
        -- Hunter team win: All props were found
        local bonus = PropHuntConfig.GetHunterTeamWinBonus()

        for i = 1, #hunters do
            local hunter = hunters[i]
            local playerId = hunter.user.id
            local scoreData = playerScores[playerId]

            if scoreData then
                scoreData.score = scoreData.score + bonus
                scoreData.lastScoreTime = Time.time

                if scoreValues[playerId] then
                    scoreValues[playerId].value = scoreData.score
                end

                PropHuntConfig.DebugLog(string.format(
                    "ScoringSystem: Hunter %s team win bonus +%d | Total: %d",
                    hunter.name, bonus, scoreData.score
                ))
            end
        end

        -- Award accuracy bonuses to all hunters
        for i = 1, #hunters do
            AwardHunterAccuracyBonus(hunters[i])
        end

    elseif winningTeam == "Prop" then
        -- Prop team win: At least one prop survived
        local survivorBonus = PropHuntConfig.GetPropTeamWinBonusSurvived()
        local foundBonus = PropHuntConfig.GetPropTeamWinBonusFound()

        -- Create lookup table for eliminated props
        local eliminatedLookup = {}
        for i = 1, #eliminatedProps do
            eliminatedLookup[eliminatedProps[i].user.id] = true
        end

        for i = 1, #props do
            local prop = props[i]
            local playerId = prop.user.id
            local scoreData = playerScores[playerId]

            if scoreData then
                local bonus = 0
                local status = ""

                if eliminatedLookup[playerId] then
                    -- Found prop gets smaller bonus
                    bonus = foundBonus
                    status = "found"
                else
                    -- Surviving prop gets larger bonus
                    bonus = survivorBonus
                    status = "survived"
                end

                scoreData.score = scoreData.score + bonus
                scoreData.lastScoreTime = Time.time

                if scoreValues[playerId] then
                    scoreValues[playerId].value = scoreData.score
                end

                PropHuntConfig.DebugLog(string.format(
                    "ScoringSystem: Prop %s team win bonus (%s) +%d | Total: %d",
                    prop.name, status, bonus, scoreData.score
                ))
            end
        end

        -- Still award accuracy bonuses to hunters even if they lost
        for i = 1, #hunters do
            AwardHunterAccuracyBonus(hunters[i])
        end
    end
end

-- ========== WINNER DETERMINATION ==========

--- Get the winner with tie-breaker logic
--- @return table Winner info: { player, score, tieBreaker1, tieBreaker2 } or nil if no players
function GetWinner()
    local allPlayers = {}

    -- Collect all player data
    for playerId, scoreData in pairs(playerScores) do
        table.insert(allPlayers, {
            playerId = playerId,
            score = scoreData.score,
            tieBreaker1 = math.max(scoreData.hits, scoreData.ticks), -- Most tags (hunter) or ticks (prop)
            tieBreaker2 = scoreData.lastScoreTime -- Earliest last scoring event (lower is earlier)
        })
    end

    -- No players
    if #allPlayers == 0 then
        PropHuntConfig.DebugLog("ScoringSystem: No players to determine winner")
        return nil
    end

    -- Sort by: score (desc), tieBreaker1 (desc), tieBreaker2 (asc - earlier is better)
    table.sort(allPlayers, function(a, b)
        if a.score ~= b.score then
            return a.score > b.score
        end
        if a.tieBreaker1 ~= b.tieBreaker1 then
            return a.tieBreaker1 > b.tieBreaker1
        end
        return a.tieBreaker2 < b.tieBreaker2 -- Earlier timestamp wins
    end)

    local winner = allPlayers[1]

    PropHuntConfig.DebugLog(string.format(
        "ScoringSystem: Winner determined - ID: %s Score: %d TB1: %d TB2: %.2f",
        winner.playerId, winner.score, winner.tieBreaker1, winner.tieBreaker2
    ))

    return winner
end

--- Get a player's current score
--- @param player Player The player
--- @return number The player's score
function GetPlayerScore(player)
    local playerId = player.user.id
    local scoreData = playerScores[playerId]

    if not scoreData then
        return 0
    end

    return scoreData.score
end

--- Get all scores sorted by score (highest first)
--- @return table Array of { playerId, score, hits, misses, ticks }
function GetAllScores()
    local allScores = {}

    for playerId, scoreData in pairs(playerScores) do
        table.insert(allScores, {
            playerId = playerId,
            score = scoreData.score,
            hits = scoreData.hits,
            misses = scoreData.misses,
            ticks = scoreData.ticks
        })
    end

    -- Sort by score descending
    table.sort(allScores, function(a, b)
        return a.score > b.score
    end)

    return allScores
end

--- Get detailed score data for a player (for debugging/UI)
--- @param player Player The player
--- @return table Score data { score, hits, misses, ticks, lastScoreTime } or nil
function GetPlayerScoreData(player)
    local playerId = player.user.id
    return playerScores[playerId]
end

-- ========== CLEANUP ==========

--- Clean up scoring data for a disconnected player
--- @param player Player The disconnected player
function CleanupPlayer(player)
    local playerId = player.user.id

    if playerScores[playerId] then
        playerScores[playerId] = nil
    end

    if scoreValues[playerId] then
        scoreValues[playerId] = nil
    end

    PropHuntConfig.DebugLog("ScoringSystem: Cleaned up player " .. playerId)
end

-- ========== TEAM BONUSES (INDIVIDUAL) ==========

--- Award team bonus for individual team bonuses
--- @param player Player The player object
--- @param bonusType string "hunter" | "prop_survivor" | "prop_eliminated"
function AwardTeamBonus(player, bonusType)
    if not player then return end

    local playerId = player.user.id
    local scoreData = playerScores[playerId]
    if not scoreData then return end

    local bonus = 0
    if bonusType == "hunter" then
        bonus = PropHuntConfig.GetHunterTeamWinBonus()
    elseif bonusType == "prop_survivor" then
        bonus = PropHuntConfig.GetPropTeamWinBonusSurvived()
    elseif bonusType == "prop_eliminated" then
        bonus = PropHuntConfig.GetPropTeamWinBonusFound()
    end

    scoreData.score = scoreData.score + bonus
    scoreData.lastScoreTime = Time.time

    if scoreValues[playerId] then
        scoreValues[playerId].value = scoreData.score
    end

    PropHuntConfig.DebugLog(string.format(
        "ScoringSystem: Player %s team bonus (%s) +%d | Total: %d",
        player.name, bonusType, bonus, scoreData.score
    ))
end

-- ========== MODULE EXPORTS ==========

return {
    -- Core initialization
    InitializeScores = InitializeScores,
    ResetAllScores = ResetAllScores,

    -- Prop scoring
    AwardPropTickScore = AwardPropTickScore,
    AwardPropSurvivalBonus = AwardPropSurvivalBonus,

    -- Hunter scoring
    AwardHunterTagScore = AwardHunterTagScore,
    ApplyHunterMissPenalty = ApplyHunterMissPenalty,
    TrackHunterHit = TrackHunterHit,
    TrackHunterMiss = TrackHunterMiss,
    AwardHunterAccuracyBonus = AwardHunterAccuracyBonus,

    -- Team bonuses
    AwardTeamBonuses = AwardTeamBonuses,
    AwardTeamBonus = AwardTeamBonus,

    -- Winner determination
    GetWinner = GetWinner,
    GetPlayerScore = GetPlayerScore,
    GetAllScores = GetAllScores,
    GetPlayerScoreData = GetPlayerScoreData,

    -- Cleanup
    CleanupPlayer = CleanupPlayer
}
