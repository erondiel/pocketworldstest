--!Type(Client)

--!SerializeField
local mainCam : GameObject = nil

function self:Update()
    if mainCam == nil then mainCam = GameObject.FindGameObjectWithTag("MainCamera") end
    self.transform:LookAt(-mainCam.transform.position);
end