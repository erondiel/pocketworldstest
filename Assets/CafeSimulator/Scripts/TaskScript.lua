--!Type(ClientAndServer)
-- This script can run on both client and server sides.

--!SerializeField
local taskName : string = "" -- Name of the task.
--!SerializeField
local taskRole : number = 1 -- Role required to perform the task: 1 for Employee, 0 for Customer.
--!SerializeField
local proximityTask : boolean = false -- Whether the task requires the player to be in a specific location to initiate it.
--!SerializeField
local taskXPReq : number = 0 -- XP required to start the task.
--!SerializeField
local taskXPReward : number = 0 -- XP rewarded upon task completion.
--!SerializeField
local taskCashReward : number = 0 -- Cash rewarded upon task completion.
--!SerializeField
local tasktime : number = 0 -- Time it takes to complete the task in seconds.
--!SerializeField
local taskCooldowntime : number = 0 -- Cooldown time before the task can be initiated again.
--!SerializeField
local uiObject : GameObject = nil -- The UI GameObject associated with this task.

local taskUI = nil -- Variable to hold the task's UI component after it's initialized.

local isReady = true -- Flag to check if the task is ready to be started.
local inProgress = false -- Flag to check if the task is currently in progress.
local TaskTimer = nil -- Timer for the task duration.
local TaskCooldownTimer = nil -- Timer for the cooldown duration.

local playerManager = require("PlayerManager") -- Access player management functions.
local orderManager = require("OrderManager") -- Access order management functions.

local anim = nil -- Animator component for animations related to the task.

-- Initiates the task if conditions are met.
function DoTask()
    if playerManager.players[client.localPlayer].Role.value == taskRole then -- Check if the player's role matches the task's role requirement.
        anim:SetTrigger("interact")
        if isReady then
            if playerManager.players[client.localPlayer].WorkXP.value >= taskXPReq then -- Check if the player has the required XP.
                print(client.localPlayer.name .. " Started the task: " .. taskName)
                taskUI.StartMeter(tasktime, taskCooldowntime)
                isReady = false
                inProgress = true
                TaskTimer = Timer.After(tasktime, function() -- Start the task timer.
                    inProgress = false
                    playerManager.IncrementStat("WorkXP", taskXPReward) -- Increment the player's XP by the reward amount.
                    playerManager.IncrementStat("Cash", taskCashReward) -- Increment the player's cash by the reward amount.
                    orderManager.CompleteOrderClient(taskName) -- Mark the task as completed in the order manager.
                    TaskCooldownTimer = Timer.After(taskCooldowntime, function() isReady = true end) -- Start the cooldown timer.
                end)
            else
                print("Not enough XP. You have: " .. tostring(playerManager.players[client.localPlayer].WorkXP.value))
                print("You need: " .. tostring(taskXPReq))
            end
        else
            print("Not Ready!")
        end
    else
        print("You are not an Employee")
    end
end

-- Cancels the task and resets the related timers and flags.
function CancelTask()
    if TaskTimer then TaskTimer:Stop() end
    if TaskCooldownTimer then TaskCooldownTimer:Stop() end
    inProgress = false
    isReady = true
    taskUI.CancelMeter()
end

-- Initializes the task UI and other components when the client awakes.
function self:ClientAwake()
    anim = self.gameObject:GetComponent(Animator) -- Get the Animator component.
    taskUI = uiObject:GetComponent(TaskMeter) -- Get the TaskMeter component from the UI object.

    taskUI.UpdateTitles(taskName, taskXPReq) -- Update the UI with the task name and XP requirement.

    local TapHand = self.gameObject:GetComponent(TapHandler)
    TapHand.Tapped:Connect(function()
        DoTask() -- Start the task when the object is tapped.
    end)

    if proximityTask then
        function self:OnTriggerExit(other : Collider)
            print("TRIGGER")
            local playerCharacter = other.gameObject:GetComponent(Character)
            if playerCharacter == nil then return end  -- Exit if no Character component is found.

            local player = playerCharacter.player
            if client.localPlayer == player then
                -- If the client's player leaves the trigger area, cancel the task if it's in progress.
                if inProgress then CancelTask() end
            end
        end
    end
end
