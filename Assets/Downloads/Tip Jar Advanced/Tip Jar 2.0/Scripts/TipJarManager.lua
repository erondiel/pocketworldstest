--!Type(Module)

-- Modules
local TipsMetaData = require("TipsMetaData")
local TipJarUtility = require("TipJarUtility")

--!Tooltip("If enabled, an audio will play when a tip is received")
--!SerializeField
local PlayAudioOnTip : boolean = false

--!Tooltip("Anything lower than this amount will not be announced")
--!SerializeField
local MinimumAnnouncementAmount : number = 100

--!Tooltip("The announcement UI to display the tip")
--!SerializeField
local _TipJarAnnouncement : GameObject = nil

--!Tooltip("The audio to play when a tip is received")
--!SerializeField
local _TipRecievedSound : AudioShader = nil

--!Tooltip("The audio volume to play the tip sound")
--!Range(0, 1)
--!SerializeField
local _AudioVolume : number = 0.5


-- Table to store the tips
local TopTippers = {}
local TippingMessages = {}
local PendingCustomMessages = {}  -- Store pending custom messages by player ID

--------------------------------------------------------------------
--------------------------- CALL BACKS -----------------------------
local GetTipJarDataCallbacks = {}


--------------------------------------------------------------------
------------------------------ CLIENT ------------------------------
-- Function to sort the top tippers by amount
function SortTopTippers(tippers)
  if #tippers == 0 then return print("[SortTopTippers]: No tippers found!") end

  table.sort(tippers, function(a, b)
      return a.Amount > b.Amount
  end)

  return tippers
end

function SortTippingMessages(messages)
  if #messages == 0 then 
    print("[SortTippingMessages]: No messages found!")
    return messages
  end

  table.sort(messages, function(a, b)
      return a.Time > b.Time
  end)
  
  return messages
end

-- Function to send only the top 50 tippers
function GetTopTippers()
    local sortedTippers = SortTopTippers(TopTippers)
    if sortedTippers == nil or #sortedTippers == 0 then sortedTippers = {} end

    local topTippers = {}

    for i = 1, TipJarUtility.GetTopTippersLimit() do
        if sortedTippers[i] then
            table.insert(topTippers, sortedTippers[i])
        end
    end
    
    return topTippers
end

function GetTippingMessages()
  local sortedMessages = SortTippingMessages(TippingMessages)

  if sortedMessages == nil or #sortedMessages == 0 then sortedMessages = {} end

  local messages = {}

  for i = 1, TipJarUtility.GetTippingMessagesLimit() do
    if sortedMessages[i] then
      table.insert(messages, sortedMessages[i])
    end
  end

  return messages
end

-- Function to prompt the purchase
function SendTip(data)
    -- Prompt the purchase
    local itemId = data.ItemId
    -- Do not rely on the purchase to be successful as client can sometimes fail
    Payments:PromptPurchase(itemId, function(paid)
        if paid then
            print("[SendTip]: Purchase successful!")
        else
            print("[SendTip]: Purchase failed!")
        end
    end)
end

function ClientGetTipJarData(callback)
    if not client then return end
    local requestId = TipJarUtility.GenerateRandomRequestId()
    GetTipJarDataCallbacks[requestId] = callback

    TipJarUtility.GetTipJarDataRequest:FireServer(requestId)
end

function ClientHandleGetTipJarDataResponse(requestId: string, data)
    local callback = GetTipJarDataCallbacks[requestId]
    if callback then
        callback(data.topTippers, data.tippingMessages)
        GetTipJarDataCallbacks[requestId] = nil
    end
end

function self:ClientAwake()
    TipJarUtility.SuccessfullPurchase:Connect(function(player, amount)
        if amount < MinimumAnnouncementAmount then return end

        local TipJarNotify = _TipJarAnnouncement:GetComponent(tipjarnotify)
        if not TipJarNotify then return end
        
        TipJarNotify.PopulateContent(player.name, player.user.id, amount)

        if PlayAudioOnTip then
            if not _TipRecievedSound then return end

            _TipRecievedSound.volume = _AudioVolume
            Audio:PlayShader(_TipRecievedSound)
        end
    end)
end

function self:ClientStart()
    TipJarUtility.GetTipJarDataResponse:Connect(ClientHandleGetTipJarDataResponse)
end

--------------------------------------------------------------------
------------------------------ SERVER ------------------------------
function ServerHandlePurchase(purchase, player: Player)
    local productId = purchase.product_id
    print("[ServerHandlePurchase]: Purchase made by player " .. tostring(player) .. " for product " .. tostring(productId))

    local itemToGive = TipsMetaData.GetGoldBarMetadata()[productId]
    if not itemToGive then
        Payments.AcknowledgePurchase(purchase, false)
        error("[ServerHandlePurchase]: Item not found!" .. tostring(productId))
        return
    end

    local tipper = {
        Id = player.user.id,
        Name = player.name,
    }

    Payments.AcknowledgePurchase(purchase, true, function(ackErr: PaymentsError)
        if ackErr ~= PaymentsError.None then
            error("[ServerHandlePurchase]: Acknowledge purchase failed!" .. tostring(ackErr))
            return
        end

        local tipAmount = itemToGive.Amount
        local found = false
        for i, tipper in ipairs(TopTippers) do
            if tipper.Id == player.user.id then
                tipper.Amount = tipper.Amount + tipAmount
                found = true
                break
            end
        end

        if not found then
            table.insert(TopTippers, {
                Id = player.user.id,
                Name = player.name,
                Amount = tipAmount
            })
        end

        -- Sort the top tippers
        TopTippers = SortTopTippers(TopTippers)

        Storage.SetValue("Tippers", TopTippers)
        -- Check for pending custom message
        local customMessageData = PendingCustomMessages[player.user.id]
        local message = player.name .. " sent a tip to " .. TipJarUtility.GetCreatorName() .. "!"
        
        -- If we have a pending message for this product and it's recent (within last 30 seconds)
        if customMessageData and customMessageData.productId == productId and 
           (os.time() - customMessageData.timestamp) < 30 then
            message = customMessageData.message
            -- Clear the pending message
            PendingCustomMessages[player.user.id] = nil
        end

        -- Update the tipping messages
        table.insert(TippingMessages, {
            Amount = tipAmount,
            Message = message,
            Time = os.time(),
            PlayerId = player.user.id,
            PlayerName = player.name
        })

        -- Sort the tipping messages
        TippingMessages = SortTippingMessages(TippingMessages)
        Storage.SetValue("TippingMessages", TippingMessages)

        -- Only broadcast the tip announcement to all clients
        TipJarUtility.SuccessfullPurchase:FireAllClients(player, tipAmount)
    end) 
end

function self:ServerAwake()
    Payments.PurchaseHandler = ServerHandlePurchase
    
    -- Handle custom messages from clients
    TipJarUtility.SendCustomMessageEvent:Connect(function(player, data)
        local productId = data.productId
        local customMessage = data.message
        
        -- Store the message temporarily with the player ID as the key
        PendingCustomMessages[player.user.id] = {
            productId = productId,
            message = customMessage,
            timestamp = os.time()  -- Add timestamp to expire old messages
        }
    end)

    -- Load initial data from storage (no longer triggered by join)
    Storage.GetValue("Tippers", function(value)
        if value == nil then value = {} end
        TopTippers = value
    end)

    Storage.GetValue("TippingMessages", function(value)
        if value == nil then value = {} end
        TippingMessages = value
    end)
end

function ServerHandleGetTipJarDataRequest(player: Player, requestId: string)
    if not server then return end
    local topTippers = GetTopTippers()
    local tippingMessages = GetTippingMessages()

    local data = {
        topTippers = topTippers,
        tippingMessages = tippingMessages
    }

    TipJarUtility.GetTipJarDataResponse:FireClient(player, requestId, data)
end


function self:ServerStart()
    TipJarUtility.GetTipJarDataRequest:Connect(ServerHandleGetTipJarDataRequest)
end