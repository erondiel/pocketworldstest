--[[
    PropHunt Game Manager
    Main server-side game loop controller
    Handles state machine: Lobby → Hiding → Hunting → RoundEnd → Repeat
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
        -- TODO: Validate propIdentifier and apply disguise on player's character
        -- Placeholder success
        print("[Server] Disguise requested by", player.name, "->", tostring(propIdentifier))
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
        -- Reset ready status when returning to lobby after a round
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
    else
        propsWins = propsWins + 1
        Log("PROPS WIN!")
    end
    
    Log(string.format("SCORE Props:%d Hunt:%d", propsWins, huntersWins))
    
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
    
    -- Calculate team sizes (roughly 60% props, 40% hunters)
    local propsCount = math.max(1, math.floor(playerCount * 0.6))
    
    -- Shuffle players
    ShuffleTable(players)
    
    -- Assign roles
    for i, player in ipairs(players) do
        if i <= propsCount then
            table.insert(propsTeam, player)
            NotifyPlayerRole(player, "prop")
            Log(string.format("PROP: %s", player.name))
            debugEvent:FireAllClients("ROLE", player.id, "prop")
        else
            table.insert(huntersTeam, player)
            NotifyPlayerRole(player, "hunter")
            Log(string.format("HUNTER: %s", player.name))
            debugEvent:FireAllClients("ROLE", player.id, "hunter")
        end
    end
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

