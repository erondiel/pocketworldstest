--!Type(Client)
-- Indicates that this script runs only on the client side.

local anim = nil -- Reference to the Animator component.

local playerManager = require("PlayerManager") -- Accesses player management functions.

-- Called when the client object this script is attached to is initialized.
function self:Awake()
    -- Get the Animator component from the GameObject.
    local anim = self.gameObject:GetComponent(Animator)
    -- Get the CreateOrderGui component from the GameObject.
    local myGui = self.gameObject:GetComponent(CreateOrderGui)
    -- Get the TapHandler component from the GameObject.
    local tapHandle = self.gameObject:GetComponent(TapHandler)
    
    -- Set up a callback when the GameObject is tapped.
    tapHandle.Tapped:Connect(function()
        -- Check if the player's role is a Customer (0) to proceed.
        if playerManager.players[client.localPlayer].Role.value == 0 then
            -- Set the GUI visible.
            myGui.SetVisible(true)
            -- Trigger an interaction animation.
            anim:SetTrigger("interact")
        end
    end)
end
