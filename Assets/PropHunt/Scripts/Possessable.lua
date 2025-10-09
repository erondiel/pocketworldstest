--[[
    Possessable Component
    Marker component attached to props that can be possessed by players.

    This is a simple marker component - the GameObject's InstanceID is used for identification.
    No manual configuration needed!

    IMPORTANT: This is a Component (not Module) so it can be attached to multiple props.
]]

--!Type(Server)

-- This component has no configuration fields
-- Props are identified by GameObject:GetInstanceID() in the game logic

function self:ServerAwake()
    -- Just a marker component, no initialization needed
end

