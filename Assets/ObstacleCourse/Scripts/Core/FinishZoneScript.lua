--!Type(ClientAndServer)

--!SerializeField
local winParticle : ParticleSystem = nil
--!SerializeField
local winSound : AudioShader = nil

local winReq = Event.new("WinReq")
local winEvent = Event.new("WinEvent")

function self:ClientStart()

    function self:OnTriggerEnter(other : Collider)
        local playerCharacter = other.gameObject:GetComponent(Character)
        if playerCharacter == nil then return end  -- Break if no Character component
        
        local player = playerCharacter.player
        if client.localPlayer == player then
            winReq:FireServer()
        end
    end

    function playWinEffect()
        --Play Win Effect
        winParticle:Play(true)
        Audio:PlayShader(winSound)
    end
    winEvent:Connect(function()
        playWinEffect()
    end)
end


function self:ServerStart()
    winReq:Connect(function()
        winEvent:FireAllClients()
    end)
end