--!Type(ScriptableObject)

--!SerializeField
local _name : string = "NewType"
--!SerializeField
local _translationCurve : AnimationCurve = nil
--!SerializeField
local _rotationCurve : AnimationCurve = nil
--!SerializeField
local _zoomCurve : AnimationCurve = nil

local function GetName() : string
    return _name
end
Name = GetName()

local function GetTranslationCurve() : AnimationCurve
    return _translationCurve
end
TranslationCurve = GetTranslationCurve()

local function GetRotationCurve() : AnimationCurve
    return _rotationCurve
end
RotationCurve = GetRotationCurve()

local function GetZoomCurve() : AnimationCurve
    return _zoomCurve
end
ZoomCurve = GetZoomCurve()