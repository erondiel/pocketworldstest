--!Type(Module)

local movePlayerToSceneEvent = Event.new("MovePlayerToSceneEvent")

--!SerializeField
local sceneNames : {string} = nil

local scenes = {}

function movePlayerToScene(sceneName)
    movePlayerToSceneEvent:FireServer(sceneName)
end

function self:ServerAwake()
    for i = 1, #sceneNames do
        local sceneInfo = server.LoadSceneAdditive(sceneNames[i])
        scenes[sceneNames[i]] = sceneInfo
    end

    movePlayerToSceneEvent:Connect(function(player, sceneName)
        local sceneInfo = scenes[sceneName]

        server.MovePlayerToScene(player, sceneInfo)
    end)
end