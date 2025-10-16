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
local PropPossessionSystem = require("PropPossessionSystem")

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
local quickStartActive = false  -- Track if we're in 5s quick-start mode

-- Player tracking
local activePlayers = {}
local propsTeam = {}
local huntersTeam = {}
local eliminatedPlayers = {}

-- Statistics
local propsWins = 0
local huntersWins = 0

-- Scoring tick timer
local propScoringTimer = nil
local lastTickTime = 0

-- Network Events
local stateChangedEvent = Event.new("PH_StateChanged")
local roleAssignedEvent = Event.new("PH_RoleAssigned")
local playerTaggedEvent = Event.new("PH_PlayerTagged")
local debugEvent = Event.new("PH_Debug")
local recapScreenEvent = Event.new("PH_RecapScreen")

-- Remote Functions
local tagRequest = RemoteFunction.new("PH_TagRequest")
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

    -- Register spectator toggle callback
    PlayerManager.RegisterSpectatorToggleCallback(OnSpectatorToggled)

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
    New flow:
    - At least 2 ready players → Start countdown (default 30s)
    - If ALL players ready up before timer expires → Skip countdown and start immediately (with 5s delay)
    - Timer reaches 0 → Start round
]]
function UpdateLobby()
    local totalPlayers = GetActivePlayerCount()
    local readyCount = PlayerManager.GetReadyPlayerCount()
    local minRequired = Config.GetMinPlayersToStart()

    -- NEW: Check if ALL players are ready (skip countdown)
    if readyCount >= minRequired and readyCount >= totalPlayers and totalPlayers >= minRequired then
        -- All players ready - skip countdown and start immediately with 5s delay
        if not quickStartActive then
            -- First time all players are ready - start quick countdown
            quickStartActive = true
            stateTimer.value = 5
            Log(string.format("ALL READY [%d/%d] - Starting in 5s", readyCount, totalPlayers))
            BroadcastStateChange(GameState.LOBBY, stateTimer)
        else
            -- Quick countdown already started - tick down
            stateTimer.value = stateTimer.value - Time.deltaTime
            if stateTimer.value <= 0 then
                quickStartActive = false
                StartNewRound()
            end
        end
    elseif readyCount >= minRequired then
        -- At least minimum players ready - run countdown
        quickStartActive = false  -- Cancel quick start if someone un-readied

        if stateTimer.value > 0 and stateTimer.value <= Config.GetLobbyCountdown() then
            stateTimer.value = stateTimer.value - Time.deltaTime

            if stateTimer.value <= 0 then
                StartNewRound()
            end
        else
            -- Start countdown
            stateTimer.value = Config.GetLobbyCountdown()
            Log(string.format("COUNTDOWN %ds [%d ready/%d total]", math.floor(stateTimer.value), readyCount, totalPlayers))
            BroadcastStateChange(GameState.LOBBY, stateTimer)
        end
    else
        -- Not enough ready players, reset timer
        quickStartActive = false
        if stateTimer.value ~= 0 then
            stateTimer.value = 0
            Log(string.format("WAIT [%d ready/%d total, need %d]", readyCount, totalPlayers, minRequired))
            BroadcastStateChange(GameState.LOBBY, stateTimer)
        end
    end
end

--[[
    HIDING STATE
    Props have time to find hiding spots
]]
-- Track how many props have possessed
local propsHiddenCount = 0

function UpdateHiding()
    stateTimer.value = stateTimer.value - Time.deltaTime

    -- Auto-transition when all props are hidden
    local totalProps = #propsTeam
    if totalProps > 0 and propsHiddenCount >= totalProps then
        Log(string.format("ALL PROPS HIDDEN (%d/%d) - Auto-transitioning to HUNTING", propsHiddenCount, totalProps))
        TransitionToState(GameState.HUNTING)
        return
    end

    -- Timer expired, transition anyway
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

        -- Restore all possessed players' avatars
        PropPossessionSystem.RestoreAllPossessedPlayers()

        -- Teleport all players to lobby
        Teleporter.TeleportAllToLobby(GetActivePlayers())

        -- Reset scores for all players
        ScoringSystem.ResetAllScores()

        -- Clear zone tracking
        ZoneManager.ClearAllPlayerZones()

        -- Reset ready status when returning to lobby after a round
        PlayerManager.ResetAllPlayers()

        -- Trigger lobby VFX
        VFXManager.TriggerLobbyTransition()

    elseif newState == GameState.HIDING then
        stateTimer.value = Config.GetHidePhaseTime()
        Log(string.format("HIDE %ds", Config.GetHidePhaseTime()))

        -- Reset props hidden counter
        propsHiddenCount = 0

        -- Reset prop possessions from previous round
        PropPossessionSystem.ResetPossessions()

        -- Teleport props to arena
        Teleporter.TeleportAllToArena(propsTeam)

        -- NOTE: Spectators (including non-ready players) stay in lobby
        -- They are NOT teleported to arena

        -- Trigger hide phase VFX
        VFXManager.TriggerHidePhaseStart(propsTeam)

    elseif newState == GameState.HUNTING then
        stateTimer.value = Config.GetHuntPhaseTime()
        Log(string.format("HUNT %ds", Config.GetHuntPhaseTime()))

        -- Delay hunter teleport by 5 seconds to avoid seeing possession VFX
        Timer.After(5.0, function()
            -- Teleport hunters to arena after delay
            Teleporter.TeleportAllToArena(huntersTeam)
            Log("Hunters teleported to Arena after 5s delay")
        end)

        -- Initialize scoring timer
        lastTickTime = Time.time

        -- Trigger hunt phase VFX
        VFXManager.TriggerHuntPhaseStart()

    elseif newState == GameState.ROUND_END then
        stateTimer.value = Config.GetRoundEndTime()
        Log(string.format("END %ds", Config.GetRoundEndTime()))

        -- Clear zone tracking
        ZoneManager.ClearAllPlayerZones()

        -- Trigger end round VFX
        -- Determine winning team from EndRound function context
        local winningTeam = "unknown"
        local winningPlayers = {}
        if huntersWins > propsWins then
            winningTeam = "Hunters"
            winningPlayers = huntersTeam
        elseif propsWins > huntersWins then
            winningTeam = "Props"
            winningPlayers = propsTeam
        end
        VFXManager.TriggerEndRoundVFX(winningTeam, winningPlayers)
    end

    -- Notify all clients of state change (both methods for compatibility)
    PlayerManager.BroadcastGameState(newState)
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
    ScoringSystem.InitializeScores(players)

    -- Clear zone tracking from previous round
    ZoneManager.ClearAllPlayerZones()

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
            ScoringSystem.AwardTeamBonus(hunter, "hunter")
        end

        -- Award accuracy bonuses to hunters
        for _, hunter in ipairs(huntersTeam) do
            ScoringSystem.AwardHunterAccuracyBonus(hunter)
        end

    else
        propsWins = propsWins + 1
        Log("PROPS WIN!")

        -- Award survival bonuses to alive props
        for _, prop in ipairs(propsTeam) do
            ScoringSystem.AwardPropSurvivalBonus(prop)
            ScoringSystem.AwardTeamBonus(prop, "prop_survivor")
        end

        -- Award partial team bonuses to eliminated props
        for _, prop in ipairs(eliminatedPlayers) do
            if IsPlayerInOriginalPropsTeam(prop) then
                ScoringSystem.AwardTeamBonus(prop, "prop_eliminated")
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
    Only READY players are assigned roles
    Non-ready players are forced into spectator mode
]]
function AssignRoles()
    propsTeam = {}
    huntersTeam = {}

    local players = GetActivePlayers()
    local readyPlayers = PlayerManager.GetReadyPlayers()

    -- Filter players: only ready players get roles
    local playingPlayers = {}
    local spectators = {}

    for _, player in ipairs(players) do
        local playerInfo = PlayerManager.GetPlayerInfo(player)
        local isReady = playerInfo and playerInfo.isReady.value
        local isSpectator = PlayerManager.IsPlayerSpectator(player)

        if isSpectator then
            -- Already a spectator
            table.insert(spectators, player)
            PlayerManager.SetPlayerRole(player, "spectator")
            NotifyPlayerRole(player, "spectator")
            Log(string.format("SPECTATOR: %s", player.name))
        elseif not isReady then
            -- Not ready - force into spectator mode
            Log(string.format("NOT READY: %s → forced spectator (staying in Lobby)", player.name))
            PlayerManager.ForceSpectatorMode(player)
            PlayerManager.SetPlayerRole(player, "spectator")
            NotifyPlayerRole(player, "spectator")
            table.insert(spectators, player)
        else
            -- Ready and not spectator - eligible to play
            table.insert(playingPlayers, player)
        end
    end

    local playerCount = #playingPlayers

    -- Need at least 2 players to start (excluding spectators)
    if playerCount < 2 then
        Log(string.format("WARN: Only %d non-spectator players, need 2 minimum", playerCount))
        return
    end

    -- V1 SPEC: Role distribution based on player count (excluding spectators)
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
    ShuffleTable(playingPlayers)

    -- Assign roles
    for i, player in ipairs(playingPlayers) do
        if i <= huntersCount then
            table.insert(huntersTeam, player)
            PlayerManager.SetPlayerRole(player, "hunter")
            NotifyPlayerRole(player, "hunter")
            Log(string.format("HUNTER: %s", player.name))
            debugEvent:FireAllClients("ROLE", player.id, "hunter")
        else
            table.insert(propsTeam, player)
            PlayerManager.SetPlayerRole(player, "prop")
            NotifyPlayerRole(player, "prop")
            Log(string.format("PROP: %s", player.name))
            debugEvent:FireAllClients("ROLE", player.id, "prop")
        end
    end

    Log(string.format("ROLES: %d Hunters, %d Props, %d Spectators (total %d players)",
        #huntersTeam, #propsTeam, #spectators, #players))
end

--[[
    Player Management
]]
function OnPlayerJoinedScene(sceneObj, player)
    activePlayers[player.id] = player
    UpdatePlayerCount()
    local count = GetActivePlayerCount()
    Log(string.format("JOIN %s (%d)", player.name, count))

    -- If game is in progress (not lobby), force player into spectator mode
    -- Keep them in Lobby (don't teleport to arena)
    if currentState.value ~= GameState.LOBBY then
        Log(string.format("MID-GAME JOIN: %s → forcing spectator mode (staying in Lobby)", player.name))

        -- Small delay to ensure player is fully tracked by PlayerManager
        Timer.After(0.5, function()
            -- Force spectator mode (but don't teleport - keep them in lobby)
            local success = PlayerManager.ForceSpectatorMode(player)
            if success then
                Log(string.format("Mid-game joiner %s set as spectator and remains in Lobby", player.name))
            end
        end)
    end
end

function OnPlayerLeftScene(sceneObj, player)
    activePlayers[player.id] = nil
    UpdatePlayerCount()
    RemoveFromTeams(player)

    -- Remove player from zones
    ZoneManager.RemovePlayer(player)

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
    local zoneWeight = ZoneManager.GetPlayerZone(prop)

    -- Award hunter tag score with zone weight
    ScoringSystem.AwardHunterTagScore(hunter, zoneWeight)

    -- Track hunter hit for accuracy
    ScoringSystem.TrackHunterHit(hunter)

    table.insert(eliminatedPlayers, prop)
    RemoveFromTeams(prop)

    -- Remove prop from zone tracking
    ZoneManager.RemovePlayer(prop)

    -- Notify clients
    BroadcastPlayerTagged(hunter, prop)
    debugEvent:FireAllClients("TAG", hunter.id, prop.id)

    -- Check if round should end (with 3s delay when last prop is tagged)
    if currentState.value == GameState.HUNTING and AreAllPropsEliminated() then
        Log("All props eliminated! Ending round in 3 seconds...")
        Timer.After(3.0, function()
            EndRound("hunters")
        end)
    end
end

function OnPlayerTagMissed(hunter)
    -- Apply miss penalty
    ScoringSystem.ApplyHunterMissPenalty(hunter)

    -- Track hunter miss for accuracy
    ScoringSystem.TrackHunterMiss(hunter)

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
        local zoneWeight = ZoneManager.GetPlayerZone(prop)
        ScoringSystem.AwardPropTickScore(prop, zoneWeight)
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

--[[
    Spectator Helper Functions
]]
function GetSpectatorPlayers()
    local spectators = {}
    local allPlayers = GetActivePlayers()
    for _, player in ipairs(allPlayers) do
        if PlayerManager.IsPlayerSpectator(player) then
            table.insert(spectators, player)
        end
    end
    return spectators
end

-- Server-side handler for spectator toggle
-- Teleports spectator to arena when they toggle spectator mode ON
function OnSpectatorToggled(player, isNowSpectator)
    if isNowSpectator then
        -- Player became spectator - teleport to arena
        Teleporter.TeleportToArena(player)
        Log(string.format("SPECTATOR ON: %s teleported to Arena", player.name))
    else
        -- Player left spectator mode
        -- If in lobby, teleport to lobby (they might be stuck in arena)
        if currentState.value == GameState.LOBBY then
            Teleporter.TeleportToLobby(player)
            Log(string.format("SPECTATOR OFF: %s teleported to Lobby", player.name))
        end
    end
end

--[[
    Prop Possession Tracking
    Called by PropPossessionSystem when a prop successfully hides
]]
function OnPropHidden()
    propsHiddenCount = propsHiddenCount + 1
    local totalProps = #propsTeam
    Log(string.format("PROP HIDDEN (%d/%d)", propsHiddenCount, totalProps))
end

-- ========== MODULE EXPORTS ==========
-- Public API for other scripts (UIManager, ValidationTest, etc.)

return {
    -- State queries
    GetCurrentState = GetCurrentState,
    GetStateTimer = GetStateTimer,
    GetActivePlayerCount = GetActivePlayerCount,
    GetActivePlayers = GetActivePlayers,

    -- Team queries
    GetPropsTeam = function() return propsTeam end,
    GetHuntersTeam = function() return huntersTeam end,

    -- Game state
    GameState = GameState,

    -- Prop possession tracking
    OnPropHidden = OnPropHidden,

    -- Tag system (already used by PropPossessionSystem)
    OnPlayerTagged = OnPlayerTagged
}

