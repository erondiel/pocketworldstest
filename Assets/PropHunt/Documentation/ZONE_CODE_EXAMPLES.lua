--[[
    ZONE SYSTEM CODE EXAMPLES

    Complete code snippets for integrating the zone system into PropHunt.
    Copy-paste ready examples for common integration scenarios.
]]

--============================================================================--
--                         PROP SCORING INTEGRATION                          --
--============================================================================--

-- Example 1: Prop Tick Scoring (Every 5 seconds)
--!Type(Server)

local ZoneManager = require("Modules.ZoneManager")
local Config = require("PropHuntConfig")

-- Track when last tick occurred
local lastTickTime = 0

function self:ServerUpdate()
    local currentTime = Time.time
    local tickInterval = Config.GetPropTickSeconds()

    if currentTime - lastTickTime >= tickInterval then
        lastTickTime = currentTime
        AwardPropTickPoints()
    end
end

function AwardPropTickPoints()
    -- Get all players who are alive props
    local alivProps = GetAliveProps()  -- Your implementation

    for _, prop in ipairs(alivProps) do
        -- Get base points and zone weight
        local basePoints = Config.GetPropTickPoints()  -- 10
        local zoneWeight = ZoneManager.GetPlayerZone(prop)  -- 1.5, 1.0, 0.6, or 1.0

        -- Calculate final points
        local totalPoints = basePoints * zoneWeight

        -- Award points
        AddPlayerScore(prop, totalPoints)

        -- Debug/logging
        local zoneName = ZoneManager.GetPlayerZoneName(prop)
        print(prop.name .. " earned " .. tostring(totalPoints) .. " points (" .. zoneName .. ")")
    end
end

--============================================================================--
--                        HUNTER SCORING INTEGRATION                         --
--============================================================================--

-- Example 2: Hunter Find Scoring (On Tag)
--!Type(Server)

local ZoneManager = require("Modules.ZoneManager")
local Config = require("PropHuntConfig")

-- Called when hunter successfully tags a prop
function OnPropTagged(hunter : Player, prop : Player)
    -- Get base points
    local basePoints = Config.GetHunterFindBase()  -- 120

    -- Get prop's zone weight (NOT hunter's zone)
    local zoneWeight = ZoneManager.GetPlayerZone(prop)

    -- Calculate final points
    local totalPoints = basePoints * zoneWeight

    -- Award points to hunter
    AddPlayerScore(hunter, totalPoints)

    -- Kill feed / UI notification
    local zoneName = ZoneManager.GetPlayerZoneName(prop)
    ShowKillFeed(hunter, prop, zoneName, totalPoints)

    -- Debug
    print(hunter.name .. " found " .. prop.name .. " for " .. tostring(totalPoints) .. " points (" .. zoneName .. ")")
end

-- Example 3: Miss Penalty (No Zone Weight)
function OnHunterMiss(hunter : Player)
    local penalty = Config.GetHunterMissPenalty()  -- -8
    AddPlayerScore(hunter, penalty)

    print(hunter.name .. " missed, penalty: " .. tostring(penalty))
end

--============================================================================--
--                            UI INTEGRATION                                 --
--============================================================================--

-- Example 4: Display Current Zone in HUD (Client)
--!Type(Client)

local ZoneManager = require("Modules.ZoneManager")

--!SerializeField
local _HUD : GameObject = nil
local _HudScript : PropHuntHUD = nil

function self:ClientAwake()
    _HudScript = _HUD:GetComponent(PropHuntHUD)
end

function self:ClientUpdate()
    UpdateZoneDisplay()
end

function UpdateZoneDisplay()
    local player = client.localPlayer
    if not player then return end

    -- Get zone info
    local zoneName = ZoneManager.GetPlayerZoneName(player)
    local zoneWeight = ZoneManager.GetPlayerZone(player)

    -- Format display text
    local zoneText = "Zone: " .. zoneName
    if zoneName ~= "None" then
        zoneText = zoneText .. " (" .. string.format("%.1fx", zoneWeight) .. ")"
    end

    -- Update UI
    _HudScript.UpdateZoneLabel(zoneText)
    -- Example output: "Zone: NearSpawn (1.5x)"
end

-- Example 5: Kill Feed with Zone Info (Client)
--!Type(Client)

local ZoneManager = require("Modules.ZoneManager")

local killFeedEvent = Event.new("PH_KillFeed")

function self:ClientStart()
    killFeedEvent:Connect(OnKillFeedEntry)
end

function OnKillFeedEntry(hunterId : number, propId : number, zoneName : string, points : number)
    -- Get player names
    local hunter = GetPlayerById(hunterId)
    local prop = GetPlayerById(propId)

    if not hunter or not prop then return end

    -- Format message
    local message = hunter.name .. " found " .. prop.name .. " in " .. zoneName .. " (+" .. tostring(points) .. ")"

    -- Display in kill feed
    ShowKillFeedMessage(message)
    -- Example: "Alice found Bob in NearSpawn (+180)"
end

--============================================================================--
--                         ROUND MANAGEMENT                                  --
--============================================================================--

-- Example 6: Clear Zones on Round End (Server)
--!Type(Server)

local ZoneManager = require("Modules.ZoneManager")

function OnRoundEnd()
    -- Clear all zone tracking
    ZoneManager.ClearAllPlayerZones()

    print("[GameManager] Zone tracking reset for new round")

    -- Continue with other round end logic...
end

-- Example 7: Handle Player Disconnects (Server)
--!Type(Server)

local ZoneManager = require("Modules.ZoneManager")

function self:ServerAwake()
    server.PlayerDisconnected:Connect(OnPlayerDisconnect)
end

function OnPlayerDisconnect(player : Player)
    print("[GameManager] Player disconnected: " .. player.name)

    -- Remove from zone tracking
    ZoneManager.RemovePlayer(player)

    -- Continue with other disconnect logic...
end

--============================================================================--
--                         ADVANCED EXAMPLES                                 --
--============================================================================--

-- Example 8: Zone-Based Team Bonuses (Server)
--!Type(Server)

local ZoneManager = require("Modules.ZoneManager")
local Config = require("PropHuntConfig")

function AwardTeamBonuses(winners : string)
    if winners == "hunters" then
        -- All hunters get bonus
        local bonus = Config.GetHunterTeamWinBonus()  -- 50

        for _, hunter in ipairs(GetAllHunters()) do
            AddPlayerScore(hunter, bonus)
        end

    elseif winners == "props" then
        -- Props get bonuses based on survival
        local survivedBonus = Config.GetPropTeamWinBonusSurvived()  -- 30
        local foundBonus = Config.GetPropTeamWinBonusFound()  -- 15

        for _, prop in ipairs(GetAllProps()) do
            if IsAlive(prop) then
                AddPlayerScore(prop, survivedBonus)
            else
                AddPlayerScore(prop, foundBonus)
            end
        end
    end
end

-- Example 9: Zone Statistics for End Screen (Server)
--!Type(Server)

local ZoneManager = require("Modules.ZoneManager")

function GenerateRoundStats() : { [Player]: table }
    local stats = {}

    for _, player in ipairs(GetAllPlayers()) do
        local zoneName = ZoneManager.GetPlayerZoneName(player)
        local zoneWeight = ZoneManager.GetPlayerZone(player)

        stats[player] = {
            finalZone = zoneName,
            zoneWeight = zoneWeight,
            score = GetPlayerScore(player)
        }
    end

    return stats
end

-- Example 10: Dynamic Zone Weight Adjustment (Advanced)
--!Type(Server)

local ZoneManager = require("Modules.ZoneManager")

-- Adjust zone weights based on player count (optional feature)
function AdjustZoneWeights(playerCount : number)
    local nearSpawnWeight = 1.5
    local midWeight = 1.0
    local farWeight = 0.6

    -- With fewer players, make far zones more rewarding
    if playerCount < 4 then
        farWeight = 0.8
        nearSpawnWeight = 1.3
    -- With many players, make near zones less rewarding
    elseif playerCount > 10 then
        nearSpawnWeight = 1.3
        farWeight = 0.5
    end

    print("[ZoneSystem] Adjusted weights for " .. tostring(playerCount) .. " players")
    print("  NearSpawn: " .. tostring(nearSpawnWeight))
    print("  Mid: " .. tostring(midWeight))
    print("  Far: " .. tostring(farWeight))
end

--============================================================================--
--                         DEBUG & TESTING                                   --
--============================================================================--

-- Example 11: Debug Zone System (Server)
--!Type(Server)

local ZoneManager = require("Modules.ZoneManager")

-- Enable debug mode
function EnableZoneDebug()
    ZoneManager.SetDebugEnabled(true)
    print("[Debug] Zone system debug enabled")
end

-- Print full system state
function PrintZoneDebug()
    ZoneManager.PrintDebugInfo()
end

-- Test zone weights
function TestZoneWeights()
    print("[Debug] Testing zone weights:")

    for _, player in ipairs(GetAllPlayers()) do
        local zoneName = ZoneManager.GetPlayerZoneName(player)
        local zoneWeight = ZoneManager.GetPlayerZone(player)

        print("  " .. player.name .. ": " .. zoneName .. " (" .. tostring(zoneWeight) .. "x)")
    end
end

-- Example 12: Cheat/Debug Commands (Server)
--!Type(Server)

local ZoneManager = require("Modules.ZoneManager")

local debugCommand = RemoteFunction.new("PH_DebugZone")

debugCommand.OnInvokeServer = function(player : Player, command : string)
    if not IsAdmin(player) then
        return false, "Not authorized"
    end

    if command == "print" then
        ZoneManager.PrintDebugInfo()
        return true, "Debug info printed"

    elseif command == "clear" then
        ZoneManager.ClearAllPlayerZones()
        return true, "All zones cleared"

    elseif command == "stats" then
        local stats = ZoneManager.GetZoneStats()
        local msg = "Zones: " .. tostring(stats.totalZones) .. ", Players: " .. tostring(stats.playersInZones)
        return true, msg

    else
        return false, "Unknown command"
    end
end

--============================================================================--
--                         COMPLETE INTEGRATION                              --
--============================================================================--

-- Example 13: Complete PropHuntGameManager Integration (Server)
--!Type(Server)

local ZoneManager = require("Modules.ZoneManager")
local Config = require("PropHuntConfig")

-- State machine
local GameState = {
    LOBBY = 1,
    HIDING = 2,
    HUNTING = 3,
    ROUND_END = 4
}

local currentState = GameState.LOBBY
local propTickTimer = 0

-- Lifecycle
function self:ServerAwake()
    server.PlayerDisconnected:Connect(OnPlayerDisconnect)
end

function self:ServerUpdate()
    if currentState == GameState.HUNTING then
        UpdatePropScoring()
    end
end

-- Player disconnect
function OnPlayerDisconnect(player : Player)
    print("[GameManager] Player disconnected: " .. player.name)
    ZoneManager.RemovePlayer(player)
end

-- Prop scoring during hunt phase
function UpdatePropScoring()
    propTickTimer = propTickTimer + Time.deltaTime
    local tickInterval = Config.GetPropTickSeconds()

    if propTickTimer >= tickInterval then
        propTickTimer = 0

        for _, prop in ipairs(GetAliveProps()) do
            local basePoints = Config.GetPropTickPoints()
            local zoneWeight = ZoneManager.GetPlayerZone(prop)
            local totalPoints = basePoints * zoneWeight

            AddPlayerScore(prop, totalPoints)

            local zoneName = ZoneManager.GetPlayerZoneName(prop)
            print(prop.name .. " earned " .. tostring(totalPoints) .. " (" .. zoneName .. ")")
        end
    end
end

-- Hunter tags prop
function OnPropTagged(hunter : Player, prop : Player)
    local basePoints = Config.GetHunterFindBase()
    local zoneWeight = ZoneManager.GetPlayerZone(prop)
    local totalPoints = basePoints * zoneWeight

    AddPlayerScore(hunter, totalPoints)
    EliminateProp(prop)

    local zoneName = ZoneManager.GetPlayerZoneName(prop)
    BroadcastKillFeed(hunter, prop, zoneName, totalPoints)
end

-- Round end
function OnRoundEnd()
    currentState = GameState.ROUND_END

    -- Clear zone tracking
    ZoneManager.ClearAllPlayerZones()

    -- Award bonuses, show results, etc.
    AwardTeamBonuses()
    ShowRecapScreen()
end

--============================================================================--
--                         UTILITY FUNCTIONS                                 --
--============================================================================--

-- Example 14: Helper Functions for Zone Info

-- Get zone display string for UI
function GetZoneDisplayString(player : Player) : string
    local zoneName = ZoneManager.GetPlayerZoneName(player)
    local zoneWeight = ZoneManager.GetPlayerZone(player)

    if zoneName == "None" then
        return "Zone: None"
    else
        return "Zone: " .. zoneName .. " (" .. string.format("%.1fx", zoneWeight) .. ")"
    end
end

-- Get zone color for UI (optional visual coding)
function GetZoneColor(player : Player) : Color
    local zoneName = ZoneManager.GetPlayerZoneName(player)

    if zoneName == "NearSpawn" then
        return Color.new(1, 0.3, 0.3)  -- Red (danger)
    elseif zoneName == "Mid" then
        return Color.new(1, 1, 0.3)  -- Yellow (caution)
    elseif zoneName == "Far" then
        return Color.new(0.3, 1, 0.3)  -- Green (safe)
    else
        return Color.white  -- Default
    end
end

-- Calculate expected points per minute by zone
function CalculatePointsPerMinute(zoneName : string, role : string) : number
    if role == "prop" then
        local basePoints = Config.GetPropTickPoints()  -- 10
        local tickInterval = Config.GetPropTickSeconds()  -- 5
        local ticksPerMinute = 60 / tickInterval  -- 12
        local zoneWeight = ZoneManager.GetZoneWeightByName(zoneName)

        return basePoints * zoneWeight * ticksPerMinute
        -- NearSpawn: 10 × 1.5 × 12 = 180 pts/min
        -- Mid:       10 × 1.0 × 12 = 120 pts/min
        -- Far:       10 × 0.6 × 12 = 72 pts/min
    end

    return 0
end

-- Get strategic recommendation for player
function GetZoneRecommendation(player : Player, timeRemaining : number) : string
    local currentZone = ZoneManager.GetPlayerZoneName(player)

    if timeRemaining < 30 then
        return "Low time! Stay hidden in Far zones for survival bonus."
    elseif timeRemaining > 180 then
        return "Lots of time! Risk NearSpawn zones for high points."
    else
        return "Mid-game: Balance risk/reward in Mid zones."
    end
end

--============================================================================--
--                         USAGE SUMMARY                                     --
--============================================================================--

--[[
    QUICK INTEGRATION STEPS:

    1. SCORING:
       - Prop tick: basePoints × ZoneManager.GetPlayerZone(prop)
       - Hunter find: basePoints × ZoneManager.GetPlayerZone(prop)

    2. UI:
       - Display: ZoneManager.GetPlayerZoneName(player)
       - Weight: ZoneManager.GetPlayerZone(player)

    3. CLEANUP:
       - Round end: ZoneManager.ClearAllPlayerZones()
       - Disconnect: ZoneManager.RemovePlayer(player)

    4. DEBUG:
       - Enable: ZoneManager.SetDebugEnabled(true)
       - Print: ZoneManager.PrintDebugInfo()
]]

--============================================================================--
--                         END OF EXAMPLES                                   --
--============================================================================--
