--!SerializeField
local trapSound : AudioShader = nil

--!SerializeField
local Moving : boolean = false
--!SerializeField
local Duration : number = 2
--!SerializeField
local pointB : Transform = nil

local playerTracker = require("PlayerTracker")

function self:ClientAwake()

    function self:OnTriggerEnter(other : Collider)
        local playerCharacter = other.gameObject:GetComponent(Character)
        if playerCharacter == nil then return end  -- Break if no Character component
        
        local player = playerCharacter.player
        if client.localPlayer == player then
            Audio:PlayShader(trapSound)
            playerTracker.RespawnPlayer()
        end
    end

    if(Moving)then
        local from = self.transform.position
        local to = pointB.position
        self.transform:TweenPosition(from, to)
            :Duration(Duration)
            :PingPong()
            :Loop()
            :EaseInOutCubic()
            :Play();
    end
end

function self:ServerAwake()
end