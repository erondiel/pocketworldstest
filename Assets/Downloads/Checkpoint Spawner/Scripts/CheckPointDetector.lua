--!Type(Client)

local CheckPointManager = require("CheckPointsManager")

--!Tooltip("A unique identifier for the check point")
--!SerializeField
local _CheckPointID : number = 1

function self:Start()
  function self:OnTriggerEnter(other: Collider)
    local char = other.gameObject:GetComponent(Character)
    if char == nil then return end

    local player = char.player

    if player.isLocal then
      CheckPointManager.SetNewCheckPoint(_CheckPointID)
    end
  end
end