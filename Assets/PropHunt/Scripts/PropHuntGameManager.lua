--[[
    PropHunt Game Manager
    Main server-side game loop controller
    Handles state machine: Lobby → Hiding → Hunting → RoundEnd → Repeat
]]

--!Type(Module)

local Config = require("PropHuntConfig")
local PlayerManager = require("PropHuntPlayerManager")
local ScoringSystem = require("PropHuntScoringSystem")
local Teleporter = require("PropHuntTeleporter")
local ZoneManager = require("ZoneManager")
local VFXManager = require("PropHuntVFXManager")

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

-- Prop possession tracking (One-Prop Rule)
-- Maps propIdentifier -> playerId to ensure only one player per prop
local possessedProps = {}

-- Statistics
local propsWins = 0
local huntersWins = 0

-- Scoring tick timer
local propScoringTimer = nil
local lastTickTime = 0

-- Network Events (must be at module scope)
local stateChangedEvent = Event.new("PH_StateChanged")
local roleAssignedEvent = Event.new("PH_RoleAssigned")
local playerTaggedEvent = Event.new("PH_PlayerTagged")
local debugEvent = Event.new("PH_Debug")
local recapScreenEvent = Event.new("PH_RecapScreen")

-- Remote Functions
local tagRequest = RemoteFunction.new("PH_TagRequest")
local disguiseRequest = RemoteFunction.new("PH_DisguiseRequest")
local forceStateRequest = RemoteFunction.new("PH_ForceState")
local tagMissedRequest = RemoteFunction.new("PH_TagMissed")

-- Utility: get Player by id
local function GetPlayerById(id)
    for _, p in pairs(activePlayers) do
        if p.id == id or p.userId == id then
            return p
        end
    end
    return nil
end

--[[
    Initialization
]]
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

        -- Server-side distance validation (V1 SPEC: R_tag = 4.0m)
        if player.character and target.character then
            local hunterPos = player.character.transform.position
            local targetPos = target.character.transform.position
            local distance = Vector3.Distance(hunterPos, targetPos)

            if distance > Config.GetTagRange() then
                Log(string.format("TAG DENIED: %s -> %s (%.2fm > %.2fm)", player.name, target.name, distance, Config.GetTagRange()))
                return false, "Too far"
            end
        end

        -- Process tag
        OnPlayerTagged(player, target)
        return true, "Tagged"
    end

    -- Handle client disguise requests
    disguiseRequest.OnInvokeServer = function(player, propIdentifier)
        if currentState.value ~= GameState.HIDING then
            return false, "Not hiding phase"
        end
        if not IsPlayerInTeam(player, propsTeam) then
            return false, "Not a prop"
        end

        -- One-Prop Rule: Check if this prop is already possessed by another player
        if possessedProps[propIdentifier] then
            local ownerPlayerId = possessedProps[propIdentifier]
            if ownerPlayerId ~= player.id then
                Log(string.format("PROP CONFLICT: %s tried to possess '%s' (owned by player %s)",
                    player.name, tostring(propIdentifier), tostring(ownerPlayerId)))
                return false, "Prop already possessed"
            else
                -- Same player trying to re-select the same prop (allowed, no-op)
                Log(string.format("PROP RESELECT: %s re-selected their prop '%s'", player.name, tostring(propIdentifier)))
                return true, "Already possessed"
            end
        end

        -- Mark prop as possessed by this player
        possessedProps[propIdentifier] = player.id
        Log(string.format("PROP POSSESSED: %s -> '%s'", player.name, tostring(propIdentifier)))

        -- TODO: Apply disguise on player's character (teleport player to prop, hide character, etc.)

        return true, "Disguised"
    end
    
    -- Listen for scene player events (Module type uses scene, not server)
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

    -- Handle tag miss reporting
    tagMissedRequest.OnInvokeServer = function(player)
        if currentState.value ~= GameState.HUNTING then
            return false, "Not hunting phase"
        end

        if not IsPlayerInTeam(player, huntersTeam) then
            return false, "Not a hunter"
        end

        OnPlayerTagMissed(player)
        return true, "Miss recorded"
    end

    -- Initialize lobby state
    TransitionToState(GameState.LOBBY)
end

--[[
    Server tick
]]
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

--[[
    LOBBY STATE
    Wait for minimum players, countdown to start
]]
function UpdateLobby()
    local playerCount = GetActivePlayerCount()
    local readyCount = PlayerManager.GetReadyPlayerCount()
    
    if readyCount >= Config.GetMinPlayersToStart() then
        -- Check if we should start countdown
        if stateTimer.value > 0 then
            stateTimer.value = stateTimer.value - Time.deltaTime
            
            if stateTimer.value <= 0 then
                StartNewRound()
            end
        else
            -- Start countdown
            stateTimer.value = 5 -- 5 second countdown
            Log(string.format("START %ds [%d ready/%d total]", math.floor(stateTimer.value), readyCount, playerCount))
            BroadcastStateChange(GameState.LOBBY, stateTimer)
        end
    else
        -- Not enough players, reset timer
        if stateTimer.value ~= 0 then
            stateTimer.value = 0
            Log(string.format("WAIT [%d ready/%d total, need %d]", readyCount, playerCount, Config.GetMinPlayersToStart()))
            BroadcastStateChange(GameState.LOBBY, stateTimer)
        end
    end
end

--[[
    HIDING STATE
    Props have time to find hiding spots
]]
function UpdateHiding()
    stateTimer.value = stateTimer.value - Time.deltaTime
    
    if stateTimer.value <= 0 then
        TransitionToState(GameState.HUNTING)
    end
end

--[[
    HUNTING STATE
    Hunters search for props
]]
function UpdateHunting()
    stateTimer.value = stateTimer.value - Time.deltaTime

    -- Award prop tick scores every 5 seconds
    local currentTime = Time.time
    if currentTime - lastTickTime >= Config.GetPropTickSeconds() then
        lastTickTime = currentTime
        AwardPropTickScores()
    end

    -- Check win conditions
    if AreAllPropsEliminated() then
        EndRound("hunters")
    elseif stateTimer.value <= 0 then
        EndRound("props")
    end
end

--[[
    ROUND END STATE
    Display results, prepare for next round
]]
function UpdateRoundEnd()
    stateTimer.value = stateTimer.value - Time.deltaTime
    
    if stateTimer.value <= 0 then
        TransitionToState(GameState.LOBBY)
    end
end

--[[
    State Machine - Transition Handler
]]
function TransitionToState(newState)
    local oldName = GetStateName(currentState)
    local newName = GetStateName(newState)
    Log(string.format("%s->%s", oldName, newName))

    currentState.value = newState

    if newState == GameState.LOBBY then
        stateTimer.value = 0
        eliminatedPlayers = {}

        -- Teleport all players to lobby
        Teleporter.TeleportAllToLobby(GetActivePlayers())

        -- Reset scores for all players
        ScoringSystem.ResetAllScores()

        -- Clear zone tracking
        ZoneManager.ClearAllZones()

        -- Reset ready status when returning to lobby after a round
        PlayerManager.ResetAllPlayers()

        -- Trigger lobby VFX
        VFXManager.TriggerLobbyTransition()

    elseif newState == GameState.HIDING then
        stateTimer.value = Config.GetHidePhaseTime()
        Log(string.format("HIDE %ds", Config.GetHidePhaseTime()))

        -- Reset prop possession tracking for new round
        possessedProps = {}

        -- Teleport props to arena
        Teleporter.TeleportToArena(propsTeam)

        -- Trigger hide phase VFX
        VFXManager.TriggerHidePhaseStart(propsTeam)

    elseif newState == GameState.HUNTING then
        stateTimer.value = Config.GetHuntPhaseTime()
        Log(string.format("HUNT %ds", Config.GetHuntPhaseTime()))

        -- Teleport hunters to arena
        Teleporter.TeleportToArena(huntersTeam)

        -- Initialize scoring timer
        lastTickTime = Time.time

        -- Trigger hunt phase VFX
        VFXManager.TriggerHuntPhaseStart()

    elseif newState == GameState.ROUND_END then
        stateTimer.value = Config.GetRoundEndTime()
        Log(string.format("END %ds", Config.GetRoundEndTime()))

        -- Clear zone tracking
        ZoneManager.ClearAllZones()
    end

    -- Notify all clients of state change
    BroadcastStateChange(newState, stateTimer)
    debugEvent:FireAllClients("STATE", newName, stateTimer, roundNumber)
end

--[[
    Round Management
]]
function StartNewRound()
    roundNumber = roundNumber + 1
    Log(string.format("ROUND %d", roundNumber))

    -- Initialize scores for all players
    local players = GetActivePlayers()
    for _, player in ipairs(players) do
        ScoringSystem.InitializePlayer(player.id)
    end

    -- Clear zone tracking from previous round
    ZoneManager.ClearAllZones()

    -- Assign roles
    AssignRoles()

    -- Transition to hiding phase
    TransitionToState(GameState.HIDING)
    debugEvent:FireAllClients("ROUND_START", roundNumber)
end

function EndRound(winner)
    if winner == "hunters" then
        huntersWins = huntersWins + 1
        Log("HUNTERS WIN!")

        -- Award team bonuses to hunters
        for _, hunter in ipairs(huntersTeam) do
            ScoringSystem.AwardTeamBonus(hunter.id, "hunter")
        end

        -- Award accuracy bonuses to hunters
        for _, hunter in ipairs(huntersTeam) do
            ScoringSystem.AwardAccuracyBonus(hunter.id)
        end

    else
        propsWins = propsWins + 1
        Log("PROPS WIN!")

        -- Award survival bonuses to alive props
        for _, prop in ipairs(propsTeam) do
            ScoringSystem.AwardSurvivalBonus(prop.id)
            ScoringSystem.AwardTeamBonus(prop.id, "prop_survivor")
        end

        -- Award partial team bonuses to eliminated props
        for _, prop in ipairs(eliminatedPlayers) do
            if IsPlayerInOriginalPropsTeam(prop) then
                ScoringSystem.AwardTeamBonus(prop.id, "prop_eliminated")
            end
        end
    end

    Log(string.format("SCORE Props:%d Hunt:%d", propsWins, huntersWins))

    -- Get winner from scoring system
    local winnerData = ScoringSystem.GetWinner()

    -- Fire recap screen event with winner data
    recapScreenEvent:FireAllClients(winner, winnerData)

    TransitionToState(GameState.ROUND_END)
    debugEvent:FireAllClients("ROUND_END", winner, propsWins, huntersWins)
end

--[[
    Role Assignment
    Split players into Props and Hunters
]]
function AssignRoles()
    propsTeam = {}
    huntersTeam = {}

    local players = GetActivePlayers()
    local playerCount = #players

    -- V1 SPEC: Role distribution based on player count
    local huntersCount = 1  -- Default

    if playerCount == 2 then
        huntersCount = 1  -- 1 Hunter, 1 Prop
    elseif playerCount == 3 then
        huntersCount = 1  -- 1 Hunter, 2 Props
    elseif playerCount == 4 then
        huntersCount = 1  -- 1 Hunter, 3 Props
    elseif playerCount == 5 then
        huntersCount = 1  -- 1 Hunter, 4 Props
    elseif playerCount >= 6 and playerCount <= 10 then
        huntersCount = 2  -- 2 Hunters, rest Props
    elseif playerCount > 10 then
        huntersCount = 3  -- 3 Hunters, rest Props
    end

    -- Shuffle players for random assignment
    ShuffleTable(players)

    -- Assign roles
    for i, player in ipairs(players) do
        if i <= huntersCount then
            table.insert(huntersTeam, player)
            NotifyPlayerRole(player, "hunter")
            Log(string.format("HUNTER: %s", player.name))
            debugEvent:FireAllClients("ROLE", player.id, "hunter")
        else
            table.insert(propsTeam, player)
            NotifyPlayerRole(player, "prop")
            Log(string.format("PROP: %s", player.name))
            debugEvent:FireAllClients("ROLE", player.id, "prop")
        end
    end

    Log(string.format("ROLES: %d Hunters, %d Props (total %d players)",
        #huntersTeam, #propsTeam, playerCount))
end

--[[
    Player Management
]]
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

    -- Remove player from zones
    ZoneManager.RemovePlayerFromAllZones(player.id)

    local count = GetActivePlayerCount()
    Log(string.format("LEFT %s (%d)", player.name, count))
end

--[[
    Tag/Elimination System
]]
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

    -- Get prop's zone weight for scoring
    local zoneWeight = ZoneManager.GetPlayerZoneWeight(prop.id)

    -- Award hunter tag score with zone weight
    ScoringSystem.AwardHunterTag(hunter.id, zoneWeight)

    -- Track hunter hit for accuracy
    ScoringSystem.TrackHunterHit(hunter.id)

    table.insert(eliminatedPlayers, prop)
    RemoveFromTeams(prop)

    -- Remove prop from zone tracking
    ZoneManager.RemovePlayerFromAllZones(prop.id)

    -- Notify clients
    BroadcastPlayerTagged(hunter, prop)
    debugEvent:FireAllClients("TAG", hunter.id, prop.id)

    -- Check if round should end
    if currentState.value == GameState.HUNTING and AreAllPropsEliminated() then
        EndRound("hunters")
    end
end

function OnPlayerTagMissed(hunter)
    -- Apply miss penalty
    ScoringSystem.ApplyMissPenalty(hunter.id)

    -- Track hunter miss for accuracy
    ScoringSystem.TrackHunterMiss(hunter.id)

    Log(string.format("MISS: %s", hunter.name))
end

--[[
    Utility Functions
]]
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
    -- Remove from props team
    for i, p in ipairs(propsTeam) do
        if p.id == player.id then
            table.remove(propsTeam, i)
            break
        end
    end
    
    -- Remove from hunters team
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

--[[
    Client Communication
    (To be implemented with RemoteFunction when we add client scripts)
]]
function BroadcastStateChange(newState, timer)
    stateChangedEvent:FireAllClients(newState, timer)
end

function NotifyPlayerRole(player, role)
    roleAssignedEvent:FireClient(player, role)
end

function BroadcastPlayerTagged(hunter, prop)
    playerTaggedEvent:FireAllClients(hunter.id, prop.id)
end

--[[
    Public API for other scripts to call
]]
function self:GetCurrentState()
    return currentState
end

function self:GetStateTimer()
    return stateTimer
end

function self:GetPropsTeam()
    return propsTeam
end

function self:GetHuntersTeam()
    return huntersTeam
end

function self:TagPlayer(hunter, prop)
    OnPlayerTagged(hunter, prop)
end

--[[
    Public Getters for UI/Client Scripts
]]
function GetCurrentState() : number
    return currentState.value
end

function GetStateTimer() : number
    return stateTimer.value
end

function UpdatePlayerCount()
    playerCount.value = GetActivePlayerCount()
end

--[[
    Scoring Helper Functions
]]
function AwardPropTickScores()
    for _, prop in ipairs(propsTeam) do
        local zoneWeight = ZoneManager.GetPlayerZoneWeight(prop.id)
        ScoringSystem.AwardPropTick(prop.id, zoneWeight)
    end
end

function IsPlayerInOriginalPropsTeam(player)
    -- Check eliminated players list to see if they were originally a prop
    for _, p in ipairs(eliminatedPlayers) do
        if p.id == player.id then
            return true
        end
    end
    return false
end

