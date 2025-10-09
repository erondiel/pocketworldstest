--!Type(ScriptableObject)

--!SerializeField
local _description : string = "New Mask"
function GetDesc() : string 
    return _description 
end
description = GetDesc()

--!SerializeField
local _maskTexture : Sprite = nil
function GetMaskTexture() : Sprite 
    return _maskTexture 
end
maskTexture = GetMaskTexture()

--!SerializeField
local _maskColor : Color = Color.black
function GetMaskColor() : Color 
    return _maskColor 
end
maskColor = GetMaskColor()

--!SerializeField
--!Range(-180, 180)
--!Tooltip("The angle at which the mask will enter view. 0 is from the left, 90 is from the bottom, 180 is right, and -90 is top.")
local _enterAngle : number = 0
function GetEnterAngle() : number 
    return _enterAngle 
end
enterAngle = GetEnterAngle()

--!SerializeField
--!Range(-180, 180)
--!Tooltip("The angle at which the mask will exit view. 0 is to the right, 90 is to the top, 180 is left, and -90 is bottom.")
local _exitAngle : number = 0
function GetExitAngle() : number 
    return _exitAngle 
end
exitAngle = GetExitAngle()

--!SerializeField
--!Tooltip("Attempt to keep the transition mask upright. This is useful for custom transitions with text, logos, etc.")
local _keepUpright : boolean = false
function GetKeepUpright() : boolean 
    return _keepUpright 
end
keepUpright = GetKeepUpright()