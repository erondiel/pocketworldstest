--!Type(ScriptableObject)

--!SerializeField
local _fadeCurve : AnimationCurve = nil
function GetCurve() : AnimationCurve 
    return _fadeCurve 
end
fadeCurve = GetCurve()

--!SerializeField
local _fadeColor : Color = nil
function GetFadeColor() : Color 
    return _fadeColor 
end
fadeColor = GetFadeColor()