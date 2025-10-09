--!SerializeField
local checkpointSound : AudioShader = nil
--!SerializeField
local ChackPoint1 : Transform = nil
--!SerializeField
local ChackPoint2 : Transform = nil
--!SerializeField
local ChackPoint3 : Transform = nil
--!SerializeField
local ChackPoint4 : Transform = nil
--!SerializeField
local ChackPoint5 : Transform = nil
--!SerializeField
local ChackPoint6 : Transform = nil
--!SerializeField
local ChackPoint7 : Transform = nil
--!SerializeField
local ChackPoint8 : Transform = nil
--!SerializeField
local ChackPoint9 : Transform = nil
--!SerializeField
local ChackPoint10 : Transform = nil

CheckpointTransforms = {
    ChackPoint1,
    ChackPoint2,
    ChackPoint3,
    ChackPoint4,
    ChackPoint5,
    ChackPoint6,
    ChackPoint7,
    ChackPoint8,
    ChackPoint9,
    ChackPoint10
}

local updateStageReq = Event.new("UpdateStageReq")
local respawnReq = Event.new("RespawnReq")
local respawnEvent = Event.new("RespawnEvent")

local myUIController = nil

players = {} -- a table variable to store current players  and info
activePlayers = 0

local function TrackPlayers(game, characterCallback)
    game.PlayerConnected:Connect(function(player) -- When a player joins a scene add them to the players table
        activePlayers = activePlayers + 1
        players[player] = {
            player = player,
            stage = IntValue.new("stage" .. tostring(player.id), 0) --Score is a Network integer with an ID built of the player's ID to ensure uniqueness
        }
        -- Each player is a `Key` in the table, with the values `player` and `score`

        player.CharacterChanged:Connect(function(player, character) 
            local playerinfo = players[player] -- After the player's character is instantiated store their info from the player table (`player`,`score`)
            if (character == nil) then
                return --If no character instantiated return
            end 

            if characterCallback then -- If there is a character callback provided call it with a reference to the player info
                characterCallback(playerinfo)
            end
        end)
    end)

    game.PlayerDisconnected:Connect(function(player) -- Remove player from the current table if they disconnect
        players[player] = nil
        activePlayers = activePlayers - 1
    end)
end

--[[
    Client
]]
function self:ClientAwake()

    myUIController = self.gameObject:GetComponent(ObstacleHud)

    -- Create OnCharacterInstantiate as the callback for the Tracking function, to acces the playerinfo on client for each player that joins
    function OnCharacterInstantiate(playerinfo)
        local player = playerinfo.player
        local character = player.character

        --The function to run everytime someones score changes
        playerinfo.stage.Changed:Connect(function(newVal, oldVal)
            Audio:PlayShader(checkpointSound)
            if player == client.localPlayer then
                --Update my Slider
                print(client.localPlayer.name .. " is on Stage: " .. tostring(newVal))
                myUIController.UpdateMeter(newVal)
            end
        end)
    end

    function UpdateStage(stage)
        updateStageReq:FireServer(stage)
    end
    
    function RespawnPlayer()
        local stage = players[client.localPlayer].stage.value
        if stage == 0 then respawnReq:FireServer(Vector3.new(0, 0, 0)); return end
        respawnReq:FireServer(CheckpointTransforms[stage].position)
    end

    respawnEvent:Connect(function(player)
        local stage = players[player].stage.value
        if stage == 0 then player.character:Teleport(Vector3.new(0, 0, 0)); return end
        player.character:Teleport(CheckpointTransforms[stage].position)
    end)

    -- Track players on Client with a callback
    TrackPlayers(client, OnCharacterInstantiate)
end

--[[
    Server
]]
function self:ServerAwake()
    -- Track players on the server, with no callback
    TrackPlayers(server)

    updateStageReq:Connect(function(player, stage)
        players[player].stage.value = stage
    end)

    respawnReq:Connect(function(player, pos)
        player.character.transform.position = pos
        respawnEvent:FireAllClients(player)
    end)
end