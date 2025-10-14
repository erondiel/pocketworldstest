--!Type(Module)

-- ========== LOBBY SETTINGS ==========
--!Tooltip("Minimum players required to start a round")
--!SerializeField
local _minPlayersToStart : number = 2
--!Tooltip("Lobby countdown time in seconds")
--!SerializeField
local _lobbyCountdown : number = 30

-- ========== PHASE TIMERS ==========
--!Tooltip("Time in seconds for the hiding phase")
--!SerializeField
local _hidePhaseTime : number = 35
--!Tooltip("Time in seconds for the hunting phase")
--!SerializeField
local _huntPhaseTime : number = 240
--!Tooltip("Time in seconds for the round end phase")
--!SerializeField
local _roundEndTime : number = 15

-- ========== TAGGING SETTINGS ==========
--!Tooltip("Maximum tag range in meters")
--!SerializeField
local _tagRange : number = 4.0
--!Tooltip("Tag cooldown in seconds")
--!SerializeField
local _tagCooldown : number = 0.5

-- ========== SCORING: PROPS ==========
--!Tooltip("Seconds between prop tick scoring")
--!SerializeField
local _propTickSeconds : number = 5
--!Tooltip("Base points per tick")
--!SerializeField
local _propTickPoints : number = 10
--!Tooltip("Bonus for surviving the round")
--!SerializeField
local _propSurviveBonus : number = 100

-- ========== SCORING: HUNTERS ==========
--!Tooltip("Base points for finding a prop")
--!SerializeField
local _hunterFindBase : number = 120
--!Tooltip("Penalty for missing a tag")
--!SerializeField
local _hunterMissPenalty : number = -8
--!Tooltip("Maximum accuracy bonus")
--!SerializeField
local _hunterAccuracyBonusMax : number = 50

-- ========== ZONE WEIGHTS ==========
--!Tooltip("Enable zone-based scoring multipliers (disable if zones block prop interaction)")
--!SerializeField
local _zonesEnabled : boolean = false
--!Tooltip("Zone weight for Near Spawn areas")
--!SerializeField
local _zoneWeightNearSpawn : number = 1.5
--!Tooltip("Zone weight for Mid areas")
--!SerializeField
local _zoneWeightMid : number = 1.0
--!Tooltip("Zone weight for Far areas")
--!SerializeField
local _zoneWeightFar : number = 0.6

-- ========== TEAM BONUSES ==========
--!Tooltip("Hunter team win bonus per hunter")
--!SerializeField
local _hunterTeamWinBonus : number = 50
--!Tooltip("Prop team win bonus for survivors")
--!SerializeField
local _propTeamWinBonusSurvived : number = 30
--!Tooltip("Prop team win bonus for found props")
--!SerializeField
local _propTeamWinBonusFound : number = 15

-- ========== TAUNT SYSTEM (Nice-to-Have) ==========
--!Tooltip("Enable taunt system")
--!SerializeField
local _tauntEnabled : boolean = false
--!Tooltip("Taunt cooldown in seconds")
--!SerializeField
local _tauntCooldown : number = 13
--!Tooltip("Taunt window in seconds")
--!SerializeField
local _tauntWindow : number = 10
--!Tooltip("Taunt reward points")
--!SerializeField
local _tauntReward : number = 20

-- ========== DEBUG ==========
--!Tooltip("Enable debug logging")
--!SerializeField
local _enableDebug : boolean = true

-- ========== GETTERS: LOBBY ==========
function GetMinPlayersToStart() : number
    return _minPlayersToStart
end

function GetLobbyCountdown() : number
    return _lobbyCountdown
end

-- ========== GETTERS: PHASES ==========
function GetHidePhaseTime() : number
    return _hidePhaseTime
end

function GetHuntPhaseTime() : number
    return _huntPhaseTime
end

function GetRoundEndTime() : number
    return _roundEndTime
end

-- ========== GETTERS: TAGGING ==========
function GetTagRange() : number
    return _tagRange
end

function GetTagCooldown() : number
    return _tagCooldown
end

-- ========== GETTERS: SCORING PROPS ==========
function GetPropTickSeconds() : number
    return _propTickSeconds
end

function GetPropTickPoints() : number
    return _propTickPoints
end

function GetPropSurviveBonus() : number
    return _propSurviveBonus
end

-- ========== GETTERS: SCORING HUNTERS ==========
function GetHunterFindBase() : number
    return _hunterFindBase
end

function GetHunterMissPenalty() : number
    return _hunterMissPenalty
end

function GetHunterAccuracyBonusMax() : number
    return _hunterAccuracyBonusMax
end

-- ========== GETTERS: ZONES ==========
function AreZonesEnabled() : boolean
    return _zonesEnabled
end

function GetZoneWeightNearSpawn() : number
    return _zoneWeightNearSpawn
end

function GetZoneWeightMid() : number
    return _zoneWeightMid
end

function GetZoneWeightFar() : number
    return _zoneWeightFar
end

-- ========== GETTERS: TEAM BONUSES ==========
function GetHunterTeamWinBonus() : number
    return _hunterTeamWinBonus
end

function GetPropTeamWinBonusSurvived() : number
    return _propTeamWinBonusSurvived
end

function GetPropTeamWinBonusFound() : number
    return _propTeamWinBonusFound
end

-- ========== GETTERS: TAUNT ==========
function IsTauntEnabled() : boolean
    return _tauntEnabled
end

function GetTauntCooldown() : number
    return _tauntCooldown
end

function GetTauntWindow() : number
    return _tauntWindow
end

function GetTauntReward() : number
    return _tauntReward
end

-- ========== DEBUG ==========
function IsDebugEnabled() : boolean
    return _enableDebug
end

function DebugLog(message : string)
    if _enableDebug then
        print("[PropHunt] " .. message)
    end
end

-- ========== MODULE EXPORTS ==========

return {
    -- Lobby settings
    GetMinPlayersToStart = GetMinPlayersToStart,
    GetLobbyCountdown = GetLobbyCountdown,

    -- Phase timers
    GetHidePhaseTime = GetHidePhaseTime,
    GetHuntPhaseTime = GetHuntPhaseTime,
    GetRoundEndTime = GetRoundEndTime,

    -- Tagging settings
    GetTagRange = GetTagRange,
    GetTagCooldown = GetTagCooldown,

    -- Prop scoring
    GetPropTickSeconds = GetPropTickSeconds,
    GetPropTickPoints = GetPropTickPoints,
    GetPropSurviveBonus = GetPropSurviveBonus,

    -- Hunter scoring
    GetHunterFindBase = GetHunterFindBase,
    GetHunterMissPenalty = GetHunterMissPenalty,
    GetHunterAccuracyBonusMax = GetHunterAccuracyBonusMax,

    -- Zone weights
    AreZonesEnabled = AreZonesEnabled,
    GetZoneWeightNearSpawn = GetZoneWeightNearSpawn,
    GetZoneWeightMid = GetZoneWeightMid,
    GetZoneWeightFar = GetZoneWeightFar,

    -- Team bonuses
    GetHunterTeamWinBonus = GetHunterTeamWinBonus,
    GetPropTeamWinBonusSurvived = GetPropTeamWinBonusSurvived,
    GetPropTeamWinBonusFound = GetPropTeamWinBonusFound,

    -- Taunt system
    IsTauntEnabled = IsTauntEnabled,
    GetTauntCooldown = GetTauntCooldown,
    GetTauntWindow = GetTauntWindow,
    GetTauntReward = GetTauntReward,

    -- Debug
    IsDebugEnabled = IsDebugEnabled,
    DebugLog = DebugLog
}

