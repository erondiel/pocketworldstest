--!Type(UI)
local SceneManager = require("SceneManager")

--!SerializeField
local buttonIcon : Texture = nil
--!SerializeField
--!Tooltip(Name of the scene you want to teleport to)
local sceneName : string = ''

--!Bind
local _SceneSwitchButton : VisualElement = nil
--!Bind
local _ButtonIcon : UIImage = nil

function self:OnTriggerEnter(collider: Collider)
    local playerCharacter = collider.gameObject:GetComponent(Character)
    if playerCharacter == nil then return end

    local player = playerCharacter.player
    if player == client.localPlayer then
        _SceneSwitchButton:RemoveFromClassList("hide")
    end
end

function self:OnTriggerExit(collider: Collider)
    local playerCharacter = collider.gameObject:GetComponent(Character)
    if playerCharacter == nil then return end

    local player = playerCharacter.player
    if player == client.localPlayer then
        _SceneSwitchButton:AddToClassList("hide")
    end
end

function self:Awake()
    _ButtonIcon.image = buttonIcon

    _SceneSwitchButton:RegisterPressCallback(function()
        SceneManager.movePlayerToScene(sceneName)
    end)
end