--[[
    PropHunt Game Manager
    Main server-side game loop controller
    Handles state machine: Lobby → Hiding → Hunting → RoundEnd → Repeat
]]

--!Type(Server)

-- Configuration
--!SerializeField
--!Tooltip("Time in seconds for the hiding phase")
local hidePhaseTime: number = 30

--!SerializeField
--!Tooltip("Time in seconds for the hunting phase")  
local huntPhaseTime: number = 120

--!SerializeField
--!Tooltip("Time in seconds for the round end phase")
local roundEndTime: number = 10

--!SerializeField
--!Tooltip("Minimum players required to start a round")
local minPlayersToStart: number = 2

-- Game States
local GameState = {
    LOBBY = 1,
    HIDING = 2,
    HUNTING = 3,
    ROUND_END = 4
}

-- State variables
local currentState = GameState.LOBBY
local stateTimer = 0
local roundNumber = 0

-- Player tracking
local activePlayers = {}
local propsTeam = {}
local huntersTeam = {}
local eliminatedPlayers = {}

-- Statistics
local propsWins = 0
local huntersWins = 0

local function getGlobalChannel(key, factory)
    local cached = _G[key]
    if cached then return cached end
    local created = factory()
    _G[key] = created
    return created
end

local stateChangedEvent = getGlobalChannel("__PH_EVT_STATE", function() return Event.new("PH_StateChanged") end)
local roleAssignedEvent = getGlobalChannel("__PH_EVT_ROLE", function() return Event.new("PH_RoleAssigned") end)
local playerTaggedEvent = getGlobalChannel("__PH_EVT_TAG", function() return Event.new("PH_PlayerTagged") end)
local debugEvent = getGlobalChannel("__PH_EVT_DEBUG", function() return Event.new("PH_Debug") end)
local tagRequest = getGlobalChannel("__PH_RF_TAG", function() return RemoteFunction.new("PH_TagRequest") end)
local disguiseRequest = getGlobalChannel("__PH_RF_DISGUISE", function() return RemoteFunction.new("PH_DisguiseRequest") end)
local forceStateRequest = getGlobalChannel("__PH_RF_FORCE", function() return RemoteFunction.new("PH_ForceState") end)

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
    print("🎮 PropHunt Game Manager - Server Started")
    -- Ensure sane defaults if not set from Inspector
    if not hidePhaseTime or hidePhaseTime <= 0 then hidePhaseTime = 30 end
    if not huntPhaseTime or huntPhaseTime <= 0 then huntPhaseTime = 120 end
    if not roundEndTime or roundEndTime <= 0 then roundEndTime = 10 end
    if not minPlayersToStart or minPlayersToStart < 1 then minPlayersToStart = 2 end
    
    -- Handle client tag requests
    tagRequest.OnInvokeServer = function(player, targetPlayerId)
        if currentState ~= GameState.HUNTING then
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
        if currentState ~= GameState.HIDING then
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
    
    -- Listen for player connections
    server.PlayerConnected:Connect(OnPlayerConnected)
    server.PlayerDisconnected:Connect(OnPlayerDisconnected)
    
    -- Listen for scene events
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
    if currentState == GameState.LOBBY then
        UpdateLobby()
    elseif currentState == GameState.HIDING then
        UpdateHiding()
    elseif currentState == GameState.HUNTING then
        UpdateHunting()
    elseif currentState == GameState.ROUND_END then
        UpdateRoundEnd()
    end

end

--[[
    LOBBY STATE
    Wait for minimum players, countdown to start
]]
function UpdateLobby()
    local playerCount = GetActivePlayerCount()
    
    if playerCount >= minPlayersToStart then
        -- Check if we should start countdown
        if stateTimer > 0 then
            stateTimer = stateTimer - Time.deltaTime
            
            if stateTimer <= 0 then
                StartNewRound()
            end
        else
            -- Start countdown
            stateTimer = 5 -- 5 second countdown
            print("⏱️ Game starting in " .. math.floor(stateTimer) .. " seconds!")
        end
    else
        -- Not enough players, reset timer
        stateTimer = 0
    end
end

--[[
    HIDING STATE
    Props have time to find hiding spots
]]
function UpdateHiding()
    stateTimer = stateTimer - Time.deltaTime
    
    if stateTimer <= 0 then
        TransitionToState(GameState.HUNTING)
    end
end

--[[
    HUNTING STATE
    Hunters search for props
]]
function UpdateHunting()
    stateTimer = stateTimer - Time.deltaTime
    
    -- Check win conditions
    if AreAllPropsEliminated() then
        EndRound("hunters")
    elseif stateTimer <= 0 then
        EndRound("props")
    end
end

--[[
    ROUND END STATE
    Display results, prepare for next round
]]
function UpdateRoundEnd()
    stateTimer = stateTimer - Time.deltaTime
    
    if stateTimer <= 0 then
        TransitionToState(GameState.LOBBY)
    end
end

--[[
    State Machine - Transition Handler
]]
function TransitionToState(newState)
    print("🔄 State Transition: " .. GetStateName(currentState) .. " → " .. GetStateName(newState))
    
    currentState = newState
    
    if newState == GameState.LOBBY then
        stateTimer = 0
        eliminatedPlayers = {}
        
    elseif newState == GameState.HIDING then
        stateTimer = hidePhaseTime
        print("🙈 HIDING PHASE - Props find your spots!")
        
    elseif newState == GameState.HUNTING then
        stateTimer = huntPhaseTime
        print("🔫 HUNTING PHASE - Hunters go!")
        
    elseif newState == GameState.ROUND_END then
        stateTimer = roundEndTime
    end
    
    -- Notify all clients of state change
    BroadcastStateChange(newState, stateTimer)
    debugEvent:FireAllClients("STATE", GetStateName(newState), stateTimer, roundNumber)
end

--[[
    Round Management
]]
function StartNewRound()
    roundNumber = roundNumber + 1
    print("🎯 Starting Round " .. roundNumber)
    
    -- Assign roles
    AssignRoles()
    
    -- Transition to hiding phase
    TransitionToState(GameState.HIDING)
    debugEvent:FireAllClients("ROUND_START", roundNumber)
end

function EndRound(winner)
    print("🏆 Round " .. roundNumber .. " ended - Winner: " .. winner)
    
    if winner == "hunters" then
        huntersWins = huntersWins + 1
        print("👁️ Hunters win! All props eliminated!")
    else
        propsWins = propsWins + 1
        print("📦 Props win! Survived until time ran out!")
    end
    
    print("📊 Score - Props: " .. propsWins .. " | Hunters: " .. huntersWins)
    
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
            print("📦 " .. player.name .. " is a PROP")
            debugEvent:FireAllClients("ROLE", player.id, "prop")
        else
            table.insert(huntersTeam, player)
            NotifyPlayerRole(player, "hunter")
            print("👁️ " .. player.name .. " is a HUNTER")
            debugEvent:FireAllClients("ROLE", player.id, "hunter")
        end
    end
end

--[[
    Player Management
]]
function OnPlayerConnected(player)
    print("✅ Player connected: " .. player.name)
    activePlayers[player.id] = player
end

function OnPlayerDisconnected(player)
    print("❌ Player disconnected: " .. player.name)
    activePlayers[player.id] = nil
    
    -- Remove from teams
    RemoveFromTeams(player)
end

function OnPlayerJoinedScene(scene, player)
    print("🌍 Player joined scene: " .. player.name)
end

function OnPlayerLeftScene(scene, player)
    print("🚪 Player left scene: " .. player.name)
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
    if currentState == GameState.HUNTING and AreAllPropsEliminated() then
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

