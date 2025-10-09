--!Type(Client)

local Logger = require("devx_logger")

local Events = require("devx_events_factory")
local ProductManager = require("devx_product_manager")

function self:Start()
  Events.get("SuccessfullPurchase"):Connect(function(id: string, amount: number)
    local deal = ProductManager.GetDeal(id)
    if deal then
      Logger.DeferPrint("Successfull purchase for " .. deal.name)
    else
      Logger.DeferPrint("Failed to purchase " .. id)
    end
  end)
end