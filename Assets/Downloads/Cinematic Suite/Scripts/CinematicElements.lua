--!Type(Client)

--!SerializeField
local Letterbox:Animator = nil
--!SerializeField
local TransitionsPanel:Animator = nil
--!SerializeField
local maskRenderer:GameObject = nil
--!SerializeField
local fadePanel:GameObject = nil

local _cineCam:CinematicCamera = nil
local _maskRenderer:SpriteRenderer = nil
local _fadePanel:SpriteRenderer = nil

local _fadeTimer = 0
local _fadeTime = 0
--!SerializeField
local _defaultFadeCurve : AnimationCurve = nil
local _defaultMaskScale : number = 400 -- Increase this if you're struggling to cover the whole screen (i.e., in 16:9 setups)
local _currentMask : TransitionMaskType = nil
local _fadeCurve : AnimationCurve = nil
local _startColor : Color = Color.clear
local _endColor : Color = Color.black

function self:Awake()
    _maskRenderer = maskRenderer:GetComponent(SpriteRenderer)
    _fadePanel = fadePanel:GetComponent(SpriteRenderer)
    _cineCam = self.gameObject:GetComponentInParent(CinematicCamera, true)
end

function ShowLetterbox(show:boolean)
    Letterbox:SetBool("show", show)
end

function ShowTransitionMask(show:boolean, maskType:TransitionMaskType)
    if show and maskType then _currentMask = maskType end
    maskRenderer.transform.localEulerAngles = Vector3.zero
    newAngle = 0
    if show then
        newAngle = _currentMask.enterAngle
        _maskRenderer.sprite = _currentMask.maskTexture
        textureSize = _maskRenderer.sprite.bounds.size.x
        _maskRenderer.transform.localScale = Vector3.one * (_defaultMaskScale / (textureSize / 10.24)) -- Just a bit of magic math to make the transition mask cover 16:9 screens
        _maskRenderer.color = _currentMask.maskColor
    else
        newAngle = _currentMask.exitAngle
    end

    TransitionsPanel.gameObject.transform.localEulerAngles = Vector3.new(0,0, newAngle or 0)
    if _currentMask.keepUpright then
        newRot = Vector3.new(0,0,-newAngle)
        maskRenderer.transform.localEulerAngles = newRot
    end

    TransitionsPanel:SetBool("show", show) 
end

function Fade(fadeIn:boolean, fadeTime:number, fadeType)
    _fadeTime = fadeTime or 1
    _fadeTimer = 0
    self.gameObject.SetActive(fadePanel, true)
    newFadeType = fadeType or (_cineCam and _cineCam.defaultFadeType)
    _fadeCurve = _defaultFadeCurve
    if newFadeType then _fadeCurve = newFadeType.fadeCurve end

    if fadeIn then
        _startColor = _fadePanel.color
        _endColor = Color.clear
    else
        _startColor = Color.clear
        _endColor = newFadeType.fadeColor
    end
end

local function ResetFade()
    _fadePanel.color = _endColor
    _fadeTime = 0
    if _endColor.a == 0 then _fadePanel.gameObject:SetActive(false) end
end

function self:Update()
    if _fadeTime > 0 then
        _fadePanel.color = Color.Lerp(_startColor, _endColor, _fadeCurve:Evaluate(_fadeTimer / _fadeTime))

        _fadeTimer = _fadeTimer + Time.deltaTime
        if _fadeTimer >= _fadeTime then
            ResetFade()
        end
    end
end


