--!Type(Client)

--!SerializeField
--!Tooltip("The type of this cinematic event")
local _eventType:number = 1
local function GetEventType() : number
    return _eventType 
end
eventType = GetEventType()

--!SerializeField
--!Tooltip("The type of camera transition")
local _transitionType : CameraTransitionType = nil
function GetTransitionType() 
    return _transitionType 
end
transitionType = GetTransitionType()

--!SerializeField
--!Tooltip("The type of transition mask")
local _maskType : TransitionMaskType = nil
function GetMaskType() 
    return _maskType 
end
maskType = GetMaskType()

--!SerializeField
--!Tooltip("The type of fade out")
local _fadeType : FadeType = nil
function GetFadeType() 
    return _fadeType 
end
fadeType = GetFadeType()

--!SerializeField
--!Tooltip("Whether or not to show this effect")
local _show:boolean = false
function GetShow() return _show end
show = GetShow()

--!SerializeField
--!Tooltip("The target of this event")
local _target:GameObject = nil
function GetTarget() return _target end
target = GetTarget()

--!SerializeField
--!Tooltip("The duration of this event")
local _duration:number = 1
function GetDuration() return _duration end
duration = GetDuration()

--!SerializeField
--!Tooltip("Should the cinematic sequence pause until this event is finished?")
local _waitForFinish:boolean = false
function GetWaitForFinish() return _waitForFinish end
waitForFinish = GetWaitForFinish()

--!SerializeField
--!Tooltip("A custom string to attach to the CustomEventFactory event - choose anything")
local _customEvent:string = ""
function GetCustomEvent() return _customEvent end
customEvent = GetCustomEvent()