--!Type(Module)

--!SerializeField
local startupUIOBJ : GameObject = nil

export type StartMessageData = {
    title: string,
    message: string,
    header: string,
    live: boolean,
}

local sendStartMessageEvent = Event.new("SendStartMessage")

local startMessageUI : ServerStartupUI

function self:ClientAwake()
    startMessageUI = startupUIOBJ:GetComponent(ServerStartupUI)
    startupUIOBJ:SetActive(false)
    sendStartMessageEvent:Connect(function(startMessageData)
        Timer.After(0.5, function()
            if startMessageUI then
                startupUIOBJ:SetActive(true)
                startMessageUI.DisplayStartMessage(startMessageData)
            end
        end)
    end)
end


function self:ServerAwake()
    local startmessage
    Storage.GetValue("start_message", function(startMessageData)
        if startMessageData then
            startmessage = startMessageData
            print("Start message data loaded from storage:", startmessage)
            if startmessage.live == false then
                print("Start message is not live, not sending to players.")
                return
            end
            sendStartMessageEvent:FireAllClients(startmessage)
        else
            startMessageData = {
                title = "Welcome to the Game!",
                message = "This is a sample message to welcome players.",
                header = "Welcome",
                live = false,
            }
            Storage.SetValue("start_message", startMessageData)
        end

    end)

    scene.PlayerJoined:Connect(function(scene, player)
        if startmessage then
            if startmessage.live == false then
                print("Start message is not live, not sending to player:", player.Name)
                return
            end
            print("Sending start message to player:", player.Name)
            sendStartMessageEvent:FireClient(player, startmessage)
        end
    end)
end