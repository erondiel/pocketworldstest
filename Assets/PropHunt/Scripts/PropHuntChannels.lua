--!Type(Module)

local stateChangedEvent = Event.new("PH_StateChanged")
local roleAssignedEvent = Event.new("PH_RoleAssigned")
local playerTaggedEvent = Event.new("PH_PlayerTagged")
local debugEvent = Event.new("PH_Debug")
local tagRequest = RemoteFunction.new("PH_TagRequest")
local disguiseRequest = RemoteFunction.new("PH_DisguiseRequest")
local forceStateRequest = RemoteFunction.new("PH_ForceState")

local Channels = {}

function Channels.StateChanged()
    return stateChangedEvent
end

function Channels.RoleAssigned()
    return roleAssignedEvent
end

function Channels.PlayerTagged()
    return playerTaggedEvent
end

function Channels.DebugEvent()
    return debugEvent
end

function Channels.TagRequest()
    return tagRequest
end

function Channels.DisguiseRequest()
    return disguiseRequest
end

function Channels.ForceStateRequest()
    return forceStateRequest
end

return Channels
