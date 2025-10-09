--!Type(Server)

local Utils = require("devx_utils")
local Config = require("devx_config")
local Logger = require("devx_logger")

local ProductManager = require("devx_product_manager")
local StorageManager = require("devx_storage_manager")


function ServerHandlePurchase(purchase, player: Player)
  local productId = purchase.product_id
  local deal = ProductManager.GetDeal(productId)

  if not deal then
    Logger.DeferPrint("Invalid product ID: " .. productId)
    return
  end

  local callBack = nil

  local currencyPrefix = Config.GetCurrencyPrefix()
  if Utils.IsProductWithPrefix(productId, currencyPrefix) then
    local amount = deal.value
    StorageManager.ServerIncrementCurrency(player, amount, nil)
  end

  Payments.AcknowledgePurchase(purchase, true, function(ackErr: PaymentsError)
    if ackErr ~= PaymentsError.None then
      Logger.DeferPrint("Failed to acknowledge purchase for " .. productId)
      return
    end

    if callBack then
      callBack(purchase)
    end
  end)
end

function self:Awake()
  Payments.PurchaseHandler = ServerHandlePurchase
end