--!SerializeField
local Stage : number = 0


local playerTracker = require("PlayerTracker")

function self:ClientAwake()
    
    function self:OnTriggerEnter(other : Collider)
        local playerCharacter = other.gameObject:GetComponent(Character)
        if playerCharacter == nil then return end  -- Break if no Character component
        
        local player = playerCharacter.player
        if client.localPlayer == player then
            playerTracker.UpdateStage(Stage)
        end
    end

end

function self:ServerAwake()
end