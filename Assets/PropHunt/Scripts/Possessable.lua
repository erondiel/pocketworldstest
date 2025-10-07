--[[
    Possessable (Module)
    Marker component attached to props that can be possessed by players.
]]

--!Type(Module)

--!SerializeField
--!Tooltip("Identifier used for server-side disguise validation")
local propId: string = ""

function self:GetPropId()
    return propId ~= nil and propId or ""
end

