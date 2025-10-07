--!Type(Module)

--!Tooltip("Time in seconds for the hiding phase")
--!SerializeField
local _hidePhaseTime : number = 30
--!Tooltip("Time in seconds for the hunting phase")
--!SerializeField
local _huntPhaseTime : number = 120
--!Tooltip("Time in seconds for the round end phase")
--!SerializeField
local _roundEndTime : number = 10
--!Tooltip("Minimum players required to start a round")
--!SerializeField
local _minPlayersToStart : number = 2
--!Tooltip("Enable debug logging")
--!SerializeField
local _enableDebug : boolean = true

function GetHidePhaseTime() : number
    return _hidePhaseTime
end

function GetHuntPhaseTime() : number
    return _huntPhaseTime
end

function GetRoundEndTime() : number
    return _roundEndTime
end

function GetMinPlayersToStart() : number
    return _minPlayersToStart
end

function IsDebugEnabled() : boolean
    return _enableDebug
end

function DebugLog(message : string)
    if _enableDebug then
        print("[PropHunt] " .. message)
    end
end

