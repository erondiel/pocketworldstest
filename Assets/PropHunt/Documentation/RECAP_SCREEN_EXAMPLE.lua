--[[
    EXAMPLE: PropHuntGameManager.lua Integration

    This file shows the complete integration of the recap screen
    into the PropHuntGameManager. Copy the relevant sections
    into your actual PropHuntGameManager.lua file.
]]

--!Type(Module)

local Config = require("PropHuntConfig")
local PlayerManager = require("PropHuntPlayerManager")

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

-- State variables (NetworkValues for automatic client sync)
local currentState = NumberValue.new("PH_CurrentState", GameState.LOBBY)
local stateTimer = NumberValue.new("PH_StateTimer", 0)
local playerCount = NumberValue.new("PH_PlayerCount", 0)
local roundNumber = 0

-- Player tracking
local activePlayers = {}
local propsTeam = {}
local huntersTeam = {}
local eliminatedPlayers = {}

-- === NEW: Player Scores Tracking ===
local playerScores = {} -- { [userId] = { name, score, role, hits, misses } }

-- Statistics
local propsWins = 0
local huntersWins = 0

-- Network Events (must be at module scope)
local stateChangedEvent = Event.new("PH_StateChanged")
local roleAssignedEvent = Event.new("PH_RoleAssigned")
local playerTaggedEvent = Event.new("PH_PlayerTagged")
local debugEvent = Event.new("PH_Debug")

-- Remote Functions
local tagRequest = RemoteFunction.new("PH_TagRequest")
local disguiseRequest = RemoteFunction.new("PH_DisguiseRequest")
local forceStateRequest = RemoteFunction.new("PH_ForceState")

-- === NEW: Tag Miss Tracking ===
local tagMissRequest = RemoteFunction.new("PH_TagMiss")

-- Utility: get Player by id
local function GetPlayerById(id)
    for _, p in pairs(activePlayers) do
        if p.id == id or p.userId == id then
            return p
        end
    end
    return nil
end

function self:ServerStart()
    Log("GM Started")
    Log(string.format("CFG H=%ds U=%ds E=%ds P=%d", Config.GetHidePhaseTime(), Config.GetHuntPhaseTime(), Config.GetRoundEndTime(), Config.GetMinPlayersToStart()))

    -- Handle client tag requests
    tagRequest.OnInvokeServer = function(player, targetPlayerId)
        if currentState.value ~= GameState.HUNTING then
            return false, "Not hunting phase"
        end

        if not IsPlayerInTeam(player, huntersTeam) then
            return false, "Not a hunter"
        end

        local target = GetPlayerById(targetPlayerId)
        if not target then
            return false, "Target not found"
        end
        if not IsPlayerInTeam(target, propsTeam) then
            return false, "Target not a prop"
        end

        -- Process tag
        OnPlayerTagged(player, target)
        return true, "Tagged"
    end

    -- === NEW: Handle tag miss tracking ===
    tagMissRequest.OnInvokeServer = function(player)
        if currentState.value ~= GameState.HUNTING then
            return false
        end

        if playerScores[player.id] then
            playerScores[player.id].misses = playerScores[player.id].misses + 1
            -- Apply miss penalty
            playerScores[player.id].score = playerScores[player.id].score + Config.GetHunterMissPenalty()
        end

        return true
    end

    -- Handle client disguise requests
    disguiseRequest.OnInvokeServer = function(player, propIdentifier)
        if currentState.value ~= GameState.HIDING then
            return false, "Not hiding phase"
        end
        if not IsPlayerInTeam(player, propsTeam) then
            return false, "Not a prop"
        end
        print("[Server] Disguise requested by", player.name, "->", tostring(propIdentifier))
        return true, "Disguised"
    end

    -- Listen for scene player events
    scene.PlayerJoined:Connect(OnPlayerJoinedScene)
    scene.PlayerLeft:Connect(OnPlayerLeftScene)

    -- Handle force state (debug)
    forceStateRequest.OnInvokeServer = function(player, requestedState)
        local target = nil
        if type(requestedState) == "number" then
            target = requestedState
        elseif type(requestedState) == "string" then
            local s = string.upper(requestedState)
            if s == "LOBBY" then target = GameState.LOBBY
            elseif s == "HIDING" then target = GameState.HIDING
            elseif s == "HUNTING" then target = GameState.HUNTING
            elseif s == "ROUND_END" or s == "ROUNDEND" or s == "END" then target = GameState.ROUND_END
            end
        end
        if not target then
            return false, "Invalid state"
        end
        TransitionToState(target)
        return true, "OK"
    end

    -- Initialize lobby state
    TransitionToState(GameState.LOBBY)
end

-- === MODIFIED: StartNewRound with Score Initialization ===
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

-- === MODIFIED: AssignRoles with Score Role Tracking ===
function AssignRoles()
    propsTeam = {}
    huntersTeam = {}

    local players = GetActivePlayers()
    local playerCount = #players

    -- Calculate team sizes (roughly 60% props, 40% hunters)
    local propsCount = math.max(1, math.floor(playerCount * 0.6))

    -- Shuffle players
    ShuffleTable(players)

    -- Assign roles
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
end

-- === MODIFIED: OnPlayerTagged with Hit Tracking ===
function OnPlayerTagged(hunter, prop)
    -- Verify hunter is actually a hunter and prop is a prop
    if not IsPlayerInTeam(hunter, huntersTeam) then
        print("⚠️ Invalid tag: " .. hunter.name .. " is not a hunter")
        return
    end

    if not IsPlayerInTeam(prop, propsTeam) then
        print("⚠️ Invalid tag: " .. prop.name .. " is not a prop")
        return
    end

    -- Valid tag
    print("💥 " .. hunter.name .. " tagged " .. prop.name .. "!")

    -- Track hunter hit and add base score
    if playerScores[hunter.id] then
        playerScores[hunter.id].hits = playerScores[hunter.id].hits + 1
        -- Add base find score (zone weight can be added later)
        playerScores[hunter.id].score = playerScores[hunter.id].score + Config.GetHunterFindBase()
    end

    table.insert(eliminatedPlayers, prop)
    RemoveFromTeams(prop)

    -- Notify clients
    BroadcastPlayerTagged(hunter, prop)
    debugEvent:FireAllClients("TAG", hunter.id, prop.id)

    -- Check if round should end
    if currentState.value == GameState.HUNTING and AreAllPropsEliminated() then
        EndRound("hunters")
    end
end

-- === MODIFIED: EndRound with Recap Data ===
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

-- === NEW: Calculate Recap Data Function ===
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
        local scoreData = playerScores[hunter.id]
        if scoreData then
            local hits = scoreData.hits or 0
            local misses = scoreData.misses or 0
            local totalShots = hits + misses
            local accuracy = totalShots > 0 and (hits / totalShots) or 0

            -- Apply accuracy bonus
            local accuracyBonus = math.floor(accuracy * Config.GetHunterAccuracyBonusMax())
            scoreData.score = scoreData.score + accuracyBonus

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
        if a.score == b.score then
            -- Tie-breaker: hunters with more hits win
            if a.role == "hunter" and b.role == "hunter" then
                return a.hits > b.hits
            end
            -- Otherwise maintain order
            return false
        end
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
            tieBreaker = "Survival time"
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

-- [Rest of the utility functions remain the same as original]

function GetActivePlayers()
    local players = {}
    for userId, player in pairs(activePlayers) do
        table.insert(players, player)
    end
    return players
end

function GetActivePlayerCount()
    local count = 0
    for _ in pairs(activePlayers) do
        count = count + 1
    end
    return count
end

function IsPlayerInTeam(player, team)
    for _, p in ipairs(team) do
        if p.id == player.id then
            return true
        end
    end
    return false
end

function RemoveFromTeams(player)
    for i, p in ipairs(propsTeam) do
        if p.id == player.id then
            table.remove(propsTeam, i)
            break
        end
    end

    for i, p in ipairs(huntersTeam) do
        if p.id == player.id then
            table.remove(huntersTeam, i)
            break
        end
    end
end

function AreAllPropsEliminated()
    return #propsTeam == 0 and GetActivePlayerCount() > 0
end

function ShuffleTable(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

function GetStateName(state)
    if state == GameState.LOBBY then return "LOBBY"
    elseif state == GameState.HIDING then return "HIDING"
    elseif state == GameState.HUNTING then return "HUNTING"
    elseif state == GameState.ROUND_END then return "ROUND_END"
    else return "UNKNOWN"
    end
end

function BroadcastStateChange(newState, timer)
    stateChangedEvent:FireAllClients(newState, timer)
end

function NotifyPlayerRole(player, role)
    roleAssignedEvent:FireClient(player, role)
end

function BroadcastPlayerTagged(hunter, prop)
    playerTaggedEvent:FireAllClients(hunter.id, prop.id)
end

function TransitionToState(newState)
    local oldName = GetStateName(currentState)
    local newName = GetStateName(newState)
    Log(string.format("%s->%s", oldName, newName))

    currentState.value = newState

    if newState == GameState.LOBBY then
        stateTimer.value = 0
        eliminatedPlayers = {}
        PlayerManager.ResetAllPlayers()

    elseif newState == GameState.HIDING then
        stateTimer.value = Config.GetHidePhaseTime()
        Log(string.format("HIDE %ds", Config.GetHidePhaseTime()))

    elseif newState == GameState.HUNTING then
        stateTimer.value = Config.GetHuntPhaseTime()
        Log(string.format("HUNT %ds", Config.GetHuntPhaseTime()))

    elseif newState == GameState.ROUND_END then
        stateTimer.value = Config.GetRoundEndTime()
        Log(string.format("END %ds", Config.GetRoundEndTime()))
    end

    BroadcastStateChange(newState, stateTimer)
    debugEvent:FireAllClients("STATE", newName, stateTimer, roundNumber)
end

function UpdateLobby()
    local playerCount = GetActivePlayerCount()
    local readyCount = PlayerManager.GetReadyPlayerCount()

    if readyCount >= Config.GetMinPlayersToStart() then
        if stateTimer.value > 0 then
            stateTimer.value = stateTimer.value - Time.deltaTime

            if stateTimer.value <= 0 then
                StartNewRound()
            end
        else
            stateTimer.value = 5
            Log(string.format("START %ds [%d ready/%d total]", math.floor(stateTimer.value), readyCount, playerCount))
            BroadcastStateChange(GameState.LOBBY, stateTimer)
        end
    else
        if stateTimer.value ~= 0 then
            stateTimer.value = 0
            Log(string.format("WAIT [%d ready/%d total, need %d]", readyCount, playerCount, Config.GetMinPlayersToStart()))
            BroadcastStateChange(GameState.LOBBY, stateTimer)
        end
    end
end

function UpdateHiding()
    stateTimer.value = stateTimer.value - Time.deltaTime

    if stateTimer.value <= 0 then
        TransitionToState(GameState.HUNTING)
    end
end

function UpdateHunting()
    stateTimer.value = stateTimer.value - Time.deltaTime

    if AreAllPropsEliminated() then
        EndRound("hunters")
    elseif stateTimer.value <= 0 then
        EndRound("props")
    end
end

function UpdateRoundEnd()
    stateTimer.value = stateTimer.value - Time.deltaTime

    if stateTimer.value <= 0 then
        TransitionToState(GameState.LOBBY)
    end
end

function self:ServerFixedUpdate()
    if currentState.value == GameState.LOBBY then
        UpdateLobby()
    elseif currentState.value == GameState.HIDING then
        UpdateHiding()
    elseif currentState.value == GameState.HUNTING then
        UpdateHunting()
    elseif currentState.value == GameState.ROUND_END then
        UpdateRoundEnd()
    end
end

function OnPlayerJoinedScene(sceneObj, player)
    activePlayers[player.id] = player
    UpdatePlayerCount()
    local count = GetActivePlayerCount()
    Log(string.format("JOIN %s (%d)", player.name, count))
end

function OnPlayerLeftScene(sceneObj, player)
    activePlayers[player.id] = nil
    UpdatePlayerCount()
    RemoveFromTeams(player)
    local count = GetActivePlayerCount()
    Log(string.format("LEFT %s (%d)", player.name, count))
end

-- Public API
function GetCurrentState() : number
    return currentState.value
end

function GetStateTimer() : number
    return stateTimer.value
end

function UpdatePlayerCount()
    playerCount.value = GetActivePlayerCount()
end
