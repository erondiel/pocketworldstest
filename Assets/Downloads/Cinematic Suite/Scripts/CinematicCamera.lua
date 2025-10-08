--!Type(Client)

local cinematicSuiteEvents = require("CinematicSuiteEvents")
--!SerializeField
--!Tooltip("Whether to snap the cinematic camera to the orientation & perspective of the main camera when enabled")
local _snapToMain:boolean = true
--!SerializeField
--!Tooltip("Whether to return the cinematic camera to the orientation of the main camera when a cutscene has finished")
local _returnToMain:boolean = true
--!SerializeField
--!Tooltip("How long should it take to return to the main camera's orientation?")
local _returnTime:number = 1
--!SerializeField
--!Tooltip("Which transition type should be used when none is specified?")
local _defaultTransitionType:CameraTransitionType = nil
--!SerializeField
--!Tooltip("Which transition type should be used when none is specified?")
local _defaultTransitionMask:TransitionMaskType = nil
function GetDefaultMask() return _defaultTransitionMask end
defaultMask = GetDefaultMask()
--!SerializeField
--!Tooltip("Which fade type should be used when none is specified?")
local _defaultFadeType:FadeType = nil
function GetDefaultFadeType() return _defaultFadeType end
defaultFadeType = GetDefaultFadeType()

local _cameraComponent:Camera = nil
local _mainCamera:GameObject = nil
local _transitionType:CameraTransitionType = nil
local _cinematicElements : CinematicElements = nil
local _activeCinematic = nil
local _cinematicEvents : {CinematicEvent} = nil
local _eventIndex:number = 1
local _waitTimer:number = 0

local startFOV = nil
local targetFOV = nil
local defaultFOV = nil

local startPos = nil
local targetPos = nil
local defaultPos = nil

local startRot = nil
local targetRot = nil
local defaultRot = nil

local tweening = false
local tweenTimer = 0
local tweenTime = 1

local _currentCameraConfig = nil
local _aimTarget = nil
local _tempTarget = nil
local _preventingInput = true

-- Define the CinematicEventType enum
local CinematicEventType = {
    [1] = "WAIT",
    [2] = "CAMERA_SNAP",
    [3] = "CAMERA_TRANSITION",
    [4] = "CAMERA_TARGET",
    [5] = "FADE_OUT",
    [6] = "FADE_IN",
    [7] = "LETTERBOX",
    [8] = "TRANSITION_MASK",
    [9] = "CUSTOM"
}

function self:Awake()
    _cameraComponent = self:GetComponent(Camera)
    _cinematicElements = self:GetComponentInChildren(CinematicElements)
    _mainCamera = Camera.main.gameObject
    _cameraComponent.enabled = false
    _transitionType = _defaultTransitionType
end

function PlayCinematic(cinematic : CinematicSequence)

    print("Playing Cinematic: ".. cinematic.name)
    print("Event count: "..#cinematic.Events)
    _eventIndex = 1
    _waitTimer = 0
    _activeCinematic = cinematic
    _cinematicEvents = cinematic.Events
    if not cinematic.AllowInput then
        _preventingInput = true
        pcc = GameObject.FindObjectOfType(PlayerCharacterController);
        pcc:GetComponent(PlayerCharacterController).options.enabled = false;
    end
    cinematicSuiteEvents.FireStartEvent(cinematic.name)

end

function ExecuteEvent(cinematicEvent : CinematicEvent)

    eventType = cinematicEvent.eventType or 1
    duration = cinematicEvent.duration or 1
    print("Execute event: " .. CinematicEventType[eventType]) 

    -- To do: Consider replacing this ridiculous tower of if statements with a function table
    if eventType == 1 then -- Wait
        _waitTimer = duration
    end
    if eventType == 2 then -- Snap to new CameraAnchor
        cinematicEvent.waitForFinish = false -- This event is instantaneous
        SnapToAnchor(cinematicEvent.target:GetComponent(CameraAnchor)) 
    end
    if eventType == 3 then -- Move to new CameraAnchor
        TransitionToAnchor(cinematicEvent.target:GetComponent(CameraAnchor), duration, cinematicEvent.transitionType) 
    end
    if eventType == 4 then -- Set a new aim target (or clear the current one)
        cinematicEvent.waitForFinish = true -- This event must be allowed to finish before continuing
        if cinematicEvent.target ~= nil then 
            LockToTarget(cinematicEvent.target.transform, duration) 
        else 
            ReleaseTarget() 
        end
    end
    if eventType == 5 then -- Fade Out
        _cinematicElements.Fade(false, duration, cinematicEvent.fadeType)
    end
    if eventType == 6 then -- Fade In
        _cinematicElements.Fade(true, duration, nil)
    end
    if eventType == 7 then -- Show/hide letterbox
        _cinematicElements.ShowLetterbox(cinematicEvent.show)
    end
    if eventType == 8 then -- Show/hide transition mask
        _cinematicElements.ShowTransitionMask(cinematicEvent.show, cinematicEvent.maskType)
    end
    if eventType == 9 then -- Custom event
        cinematicSuiteEvents.FireCustomEvent(cinematicEvent.customEvent)
    end

    if cinematicEvent.waitForFinish then _waitTimer = duration end

end

function self:LateUpdate()

    if _activeCinematic ~= nil then -- If we have an active cutscene
        if _waitTimer <= 0 then -- If the previous event in the cutscene has finished (i.e., it's time for the next event)
            _waitTimer = 0
            if _eventIndex > #_cinematicEvents then -- If we've already fired the last event in this cutscene

                if _returnToMain and _currentCameraConfig ~= nil then -- If the cinematic camera has been moved and should smoothly return to the main camera's orientation                                        
                    ReturnToMainCamera()
                    _waitTimer = _returnTime -- Wait another moment for the cinematic camera to find home
                    return
                end

                if _activeCinematic ~= nil then _activeCinematic.OnFinish() end -- Finish the cutscene
                cinematicSuiteEvents.FireEndEvent(_activeCinematic.name) -- Alert all listeners that the cutscene has ended
                _activeCinematic = nil
                Disable()
                return
            end
            ExecuteEvent(_cinematicEvents[_eventIndex]) -- Execute the next event in the cutscene
            _eventIndex = _eventIndex + 1
        else
            _waitTimer = _waitTimer - Time.deltaTime -- Wait until the previous event has finished
        end
    end

    if tweening then
        if tweenTimer < tweenTime then
            tweenTimer += Time.deltaTime
            local progress = tweenTimer / tweenTime;
            self.transform.position = Vector3.Lerp(startPos, targetPos, _transitionType.TranslationCurve:Evaluate(progress));
            self.transform.rotation = Quaternion.Lerp(startRot, targetRot, _transitionType.RotationCurve:Evaluate(progress));
            _cameraComponent.fieldOfView = Mathf.Lerp(startFOV, targetFOV, _transitionType.ZoomCurve:Evaluate(progress));
        end
        
        if tweenTimer >= tweenTime then
            tweening = false
            tweenTimer = 0.0

            self.transform.position = targetPos;
            self.transform.rotation = targetRot;
            _cameraComponent.fieldOfView = targetFOV;

            if _tempTarget ~= nil then
                _aimTarget = _tempTarget
                _tempTarget = nil
            end
        end
    end

    if _aimTarget ~= nil then self.transform:LookAt(_aimTarget.transform) end
end

function SnapToMainCamera()

    _cameraComponent.fieldOfView = defaultFOV;
    _cameraComponent.transform.position = defaultPos
    _cameraComponent.transform.rotation = defaultRot

end

function CacheDefaults()

    defaultFOV = Camera.main.fieldOfView
    defaultPos = Camera.main.transform.position
    defaultRot = Camera.main.transform.rotation

end

function ReturnToMainCamera()
    
    _transitionType = _defaultTransitionType

    SetOrigin()

    targetFOV = defaultFOV
    targetPos = defaultPos
    targetRot = defaultRot

    StartTweening(_returnTime)

    _currentCameraConfig = nil

end

function SetOrigin()
    startFOV = _cameraComponent.fieldOfView
    startPos = _cameraComponent.transform.position
    startRot = _cameraComponent.transform.rotation
end

function SetDestination(fov:number, position:Vector3, rotation:Quaternion)
    targetFOV = fov
    targetPos = position
    targetRot = rotation
end

function SetDestinationAnchor(anchor:CameraAnchor)
    SetDestination(anchor.FOV, anchor.Pos, anchor.Rot)
end

function SnapTo(fov:number, position:Vector3, rotation:Quaternion)
    _cameraComponent.fieldOfView = fov
    _cameraComponent.transform.position = position
    _cameraComponent.transform.rotation = rotation
end

function SnapToAnchor(newConfig:CameraAnchor)
    SnapTo(newConfig.FOV, newConfig.Pos, newConfig.Rot)
end

function StartTweening(duration:number)
    tweenTimer = 0.0
    tweenTime = duration or 1
    tweening = true
end

function TransitionToAnchor(newConfig:CameraAnchor, transitionTime:number, newTransitionType:CameraTransitionType)
    --if newConfig == _currentCameraConfig then return end
    _currentCameraConfig = newConfig
    _transitionType = newTransitionType or _defaultTransitionType

    SetOrigin()
    SetDestinationAnchor(newConfig)
    StartTweening(transitionTime or 1)
end

function LockToTarget(newTarget:Transform, lockTime:number)
    if lockTime ~= nil and lockTime > 0 then
        SetOrigin()
        oldRot = self.transform.rotation
        if newTarget ~= nil then self.transform:LookAt(newTarget.transform) end
        newRot = self.transform.rotation
        SetDestination(startFOV, startPos, newRot)
        self.transform.rotation = oldRot
        _transitionType = _defaultTransitionType
        StartTweening(lockTime)
        _tempTarget = newTarget
    else
        _aimTarget = newTarget
        if _aimTarget ~= nil then self.transform:LookAt(_aimTarget.transform) end
    end
end

function ReleaseTarget()
    if _aimTarget ~= nil then _aimTarget = nil end
end

function Enable()
    CacheDefaults()
    if _snapToMain then 
        SnapToMainCamera() 
        _mainCamera:SetActive(false)
    end
    _cameraComponent.enabled = true
end

function Disable()
    ReleaseTarget()
    if _snapToMain then
        _mainCamera:SetActive(true)
    end
    _cameraComponent.enabled = false
    _currentCameraConfig = nil
    
    if _preventingInput then
        pcc = GameObject.FindObjectOfType(PlayerCharacterController);
        pcc:GetComponent(PlayerCharacterController).options.enabled = true
        _preventingInput = false
    end
end

-- Function to iterate through _cinematicEvents and print event types
function PrintEventTypes(cinematicEvents)
    for index, event in ipairs(cinematicEvents) do
        -- Get the event type number
        local eventTypeNumber = event.eventType
        print("Event Type Number: "..eventTypeNumber)
        -- Convert the number to the corresponding event type string
        local eventTypeName = CinematicEventType[eventTypeNumber]
        -- Print the event type
        print(string.format("Event %d: %s", index, eventTypeName or "UNKNOWN"))
    end
end