--!Type(Client)

--!SerializeField
--!Range(1,150)
local _fieldOfView : number = 70

local function GetFOV()
    return _fieldOfView
end

local function GetPosition()
    return self.transform.position
end

local function GetRotation()
    return self.transform.rotation
end

FOV = GetFOV()
Pos = GetPosition()
Rot = GetRotation()