--[[
    HunterTagSystem (Client)
    Tap-to-tag logic with cooldown and raycast. Remote call is scaffolded.
]]

--!Type(Module)

-- Import required modules
local Logger = require("PropHuntLogger")
local Config = require("PropHuntConfig")
local VFXManager = require("PropHuntVFXManager")
local PlayerManager = require("PropHuntPlayerManager")

-- Cooldown between tag attempts (seconds) - Now uses Config
--!SerializeField
--!Tooltip("Seconds between tag attempts (overridden by Config)")
local shootCooldown = 2.0

-- Network events (must match server names)
local stateChangedEvent = Event.new("PH_StateChanged")
local roleAssignedEvent = Event.new("PH_RoleAssigned")
local playerTaggedEvent = Event.new("PH_PlayerTagged")

-- Remote functions
local tagRequest = RemoteFunction.new("PH_TagRequest")
local tagMissedRequest = RemoteFunction.new("PH_TagMissed")

-- State tracking
local currentStateValue = nil
local lastShotTime = -9999
local currentState = "LOBBY"
local localRole = "unknown"

local function NormalizeState(value)
    if type(value) == "number" then
        if value == 1 then return "LOBBY"
        elseif value == 2 then return "HIDING"
        elseif value == 3 then return "HUNTING"
        elseif value == 4 then return "ROUND_END"
        end
    end
    return tostring(value)
end

local function IsHuntPhase()
    return localRole == "hunter" and currentState == "HUNTING"
end

--[[
    NOTE: Tagging is now handled by PropPossessionSystem
    Hunters tap on props during HUNTING phase, not on players.
    This system only handles VFX feedback for tag events.
]]

function self:ClientStart()
    Logger.Log("HunterTagSystem", "ClientStart")

    -- Listen for tag events (for VFX feedback)
    playerTaggedEvent:Connect(function(hunterId, propId)
        Logger.Log("HunterTagSystem", "Player tagged -> hunter:", tostring(hunterId), "prop:", tostring(propId))
    end)

    -- Setup NetworkValue tracking via PlayerManager
    local localPlayer = client.localPlayer
    if localPlayer then
        local playerInfo = PlayerManager.GetPlayerInfo(localPlayer)
        if playerInfo then
            -- Track game state via per-player NetworkValue
            if playerInfo.gameState then
                currentStateValue = playerInfo.gameState
                currentState = NormalizeState(currentStateValue.value)
                Logger.Log("HunterTagSystem", "Initial state from NetworkValue: " .. currentState)

                currentStateValue.Changed:Connect(function(newState, oldState)
                    currentState = NormalizeState(newState)
                    Logger.Log("HunterTagSystem", "State changed via NetworkValue: " .. currentState)
                end)
            end

            -- Track player role
            if playerInfo.role then
                localRole = playerInfo.role.value
                Logger.Log("HunterTagSystem", "Initial role from NetworkValue: " .. localRole)

                playerInfo.role.Changed:Connect(function(newRole, oldRole)
                    localRole = newRole
                    Logger.Log("HunterTagSystem", "Role changed via NetworkValue: " .. localRole)
                end)
            end
        end
    end

    -- Listen for state/role updates (backup event system)
    stateChangedEvent:Connect(function(newState, timer)
        currentState = NormalizeState(newState)
        Logger.Log("HunterTagSystem", "State updated via event: " .. currentState)
    end)

    roleAssignedEvent:Connect(function(role)
        localRole = tostring(role)
        Logger.Log("HunterTagSystem", "Role updated via event: " .. localRole)
    end)
end
