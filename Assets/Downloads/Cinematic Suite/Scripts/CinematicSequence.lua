--!Type(Client)

--!SerializeField
--!Tooltip("The cinematic camera that will play this cutscene")
local _targetCamera:GameObject = nil
--!SerializeField
--!Tooltip("Should we try to play this cutscene as soon as its game object is enabled in the hierarchy?")
local _playOnEnable:boolean = true
--!SerializeField
--!Tooltip("Should the player be able to interact with taphandlers while this cutscene is active?")
local _allowPlayerInput:boolean = false
function GetAllowInput()
    return _allowPlayerInput
end
AllowInput = GetAllowInput()

--!SerializeField
local _defaultTransitionType:CameraTransitionType = nil
--!SerializeField
local _defaultMaskType:TransitionMaskType = nil
--!SerializeField
local _defaultFadeType:FadeType = nil

--!SerializeField
local _events:{CinematicEvent} = {}
function GetEvents()
    _events = {}
    for i = 1, self.transform.childCount do
        child = self.transform:GetChild(i-1)
        child.gameObject:SetActive(true)
        table.insert(_events, child:GetComponent(CinematicEvent))
    end
    return _events
end
Events = GetEvents()

local _init = false

-- Example usage within OnEnable
function self:OnEnable()
    if not _init then 
        _init = true
        defer(function()
            self.gameObject:SetActive(false) 
        end)
    elseif _playOnEnable then
        print(self.gameObject.name .. " enabled!")
        if _targetCamera ~= nil then
            _targetCamera.gameObject:SetActive(true)
            cinecam = _targetCamera:GetComponent(CinematicCamera)
            _defaultMaskType = cinecam.defaultMask
            cinecam.Enable()
            cinecam.PlayCinematic(self)
        end
    end
end

function OnFinish()
    if _playOnEnable then self.gameObject:SetActive(false) end
end