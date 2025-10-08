--!Type(Module)

local Logger = require("devx_logger")

if client then
  Logger.DeferPrint("[ATTENTION] This should only be used on the server!")
  return
end

type Wallet = {
  gold: number,
  earned_gold: number,
  total: number
}

--[[
  TransferGold: Transfers gold to a player.
  @param player: The player to transfer gold to.
  @param amount: The amount of gold to transfer.
  @param callback: The callback to call when the gold is transferred.
]]
function TransferGold(player: Player | string, amount: number, callback: (success: boolean, message: string | nil) -> ())
  if typeof(player) == "string" then
    Wallet.TransferGold(player, amount, function(err)
      if err ~= WalletError.None then
        Logger.DeferPrint("TransferGold: Error transferring gold to player " .. player .. " with error " .. err)
        callback(false, "Error transferring gold to player " .. player .. " with error " .. err)
        return
      end

      callback(true, "Gold transferred to player " .. player .. " successfully")
    end)
  else
    Wallet.TransferGoldToPlayer(player, amount, function(err)
      if err ~= WalletError.None then
        Logger.DeferPrint("TransferGold: Error transferring gold to player " .. player.name .. " with error " .. err)
        callback(false, "Error transferring gold to player " .. player.name .. " with error " .. err)
        return
      end

      callback(true, "Gold transferred to player " .. player.name .. " successfully")
    end)
  end
end

--[[
  GetWallet: Gets the wallet of the world.
  @return { Wallet }
]]
function GetWallet(): Wallet
  local wallet = {
    gold = 0,
    earned_gold = 0,
    total = 0
  }

  Wallet.GetWallet(function(response, err)
    if err ~= WalletError.None then
      Logger.DeferPrint("GetWallet: Error getting wallet with error " .. err)
      return
    end

    wallet.gold = response.gold
    wallet.earned_gold = response.earnedGold
    wallet.total = response.earnedGold + response.gold

    return wallet
  end)

  return wallet
end