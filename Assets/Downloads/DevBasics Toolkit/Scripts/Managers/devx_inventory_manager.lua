--!Type(Module)

local Utils = require("devx_utils")
local Logger = require("devx_logger")
local Config = require("devx_config")

local Events = require("devx_events_factory")
local PlayerTracker = require("devx_player_tracker")

-- Constants
local INVENTORY_FETCH_LIMIT : number = 100
local TRANSACTION_COMMIT_INTERVAL : number = 3

type GiveTransaction = {
  player_id: string,
  item_id: string,
  amount: number
}

type TakeTransaction = {
  player_id: string,
  item_id: string,
  amount: number
}

local GiveTransactionsToCommit : { GiveTransaction } = {}
local TakeTransactionsToCommit : { TakeTransaction } = {}

type Item = {
  id: string,
  amount: number
}

------------------------------------------------------
----------------------- CLIENT -----------------------
--[[
  GivePlayerItem: Gives an item to a player (client)
  @param target: The player to give the item to.
  @param item: The item to give.
  @param targetPlayerId: The ID of the player to give the item to.
]]
function GivePlayerItem(target: Player, item: Item, targetPlayerId: string | nil)
  if not client then
    Logger.DeferPrint("GivePlayerItem: Must be called from client")
    return
  end

  Events.get("GiveItemRequest"):FireServer(target, item, targetPlayerId)
end

--[[
  TakePlayerItem: Takes an item from a player (client)
  @param player: The player to take the item from.
  @param item: The item to take.
]]
function TakePlayerItem(target: Player, item: Item)
  if not client then
    Logger.DeferPrint("TakePlayerItem: Must be called from client")
    return
  end

  Events.get("TakeItemRequest"):FireServer(target, item)
end

------------------------------------------------------
----------------------- SERVER -----------------------
--[[
  UpdatePlayerInventory: Updates the inventory of a player.
  @param player: The player to update the inventory of.
  @param items: The items to update the inventory with.
]]
local function UpdatePlayerInventory(player: Player, items: { Item })
  local playerInfo = PlayerTracker.getPlayerInfo(player)
  if not playerInfo then
    Logger.DeferPrint(player.name .. " not found in player tracker")
    return
  end

  local clientItems = {}
  for index, item in items do
    clientItems[index] = {
      id = item.id,
      amount = item.amount
    }
  end

  playerInfo.inventory.value = clientItems
end

--[[
  UpdatePlayerInventoryTemporarily: Updates the inventory of a player temporarily.
  @param target: The player to update the inventory of.
  @param item: The item to update the inventory with.
]]
local function UpdatePlayerInventoryTemporarily(target: Player, item: Item)
  local playerInventory = PlayerTracker.getPlayerInventory(target)
  local items = playerInventory.value

  local itemExists : boolean = false

  for index, entry in items do
    if entry.id == item.id then
      entry.amount = entry.amount + item.amount

      if entry.amount <= 0 and not Config.IsInventoryStaticItem(entry.id) then
        table.remove(items, index)
      end

      itemExists = true
      break
    end
  end

  if not itemExists and item.amount > 0 then
    table.insert(items, {
      id = item.id,
      amount = item.amount
    })
  end

  PlayerTracker.getPlayerInfo(target).inventory.value = items
end

--[[
  ServerGivePlayerItem: Gives an item to a player.
  @param target: The player to give the item to.
  @param item: The item to give.
  @param targetPlayerId: The ID of the player to give the item to.
]]
function ServerGivePlayerItem(target: Player, item: Item, targetPlayerId: string | nil)
  local targetPlayer : Player | nil = target

  if not targetPlayer then
    local players = PlayerTracker.getPlayers()
    for plr, info in players do
      if targetPlayerId and plr.user.id == targetPlayerId then
        targetPlayer = plr
        break
      end
    end
  end

  if targetPlayer then
    table.insert(GiveTransactionsToCommit, {
      player_id = targetPlayer.user.id,
      item_id = item.id,
      amount = item.amount
    })

    UpdatePlayerInventoryTemporarily(targetPlayer, item)
  end
end

--[[
  ServerTakePlayerItem: Takes an item from a player.
  @param target: The player to take the item from.
  @param item: The item to take.
]]
local function ServerTakePlayerItem(target: Player, item: Item)
  table.insert(TakeTransactionsToCommit, {
    player_id = target.user.id,
    item_id = item.id,
    amount = item.amount
  })

  UpdatePlayerInventoryTemporarily(target, {id = item.id, amount = -item.amount})
end

--[[
  CommitQueuedTransactions: Commits the queued transactions.
]]
local function CommitQueuedTransactions()
  if #GiveTransactionsToCommit == 0 and #TakeTransactionsToCommit == 0 then return end

  local compiledTransactions = InventoryTransaction.new()

  for _, transaction in GiveTransactionsToCommit do
    compiledTransactions:Give(transaction.player_id, transaction.item_id, transaction.amount)
  end

  for _, transaction in TakeTransactionsToCommit do
    compiledTransactions:Take(transaction.player_id, transaction.item_id, transaction.amount)
  end

  Inventory.CommitTransaction(compiledTransactions)

  GiveTransactionsToCommit = {}
  TakeTransactionsToCommit = {}
end

--[[
  GetAllPlayerItems: Gets all items from a player.
  @param player: The player to get the items from.
  @param limit: The limit of items to get.
  @param cursorId: The cursor ID to get the next items from.
  @param accumulatedItems: The accumulated items.
  @param callback: The callback to call when the items are fetched.
]]
local function GetAllPlayerItems(player: Player, limit: number, cursorId: string | nil, accumulatedItems: { Item }, callback: (player: Player, items: { Item }) -> ())
  accumulatedItems = accumulatedItems or {}

  Inventory.GetPlayerItems(player, limit, cursorId, function(items, newCursorId, error)
    if items == nil then return end

    for _, item in items do
      table.insert(accumulatedItems, item)
    end

    if newCursorId ~= nil then
      GetAllPlayerItems(player, limit, newCursorId, accumulatedItems, callback)
    else
      callback(player, accumulatedItems)
    end
  end)
end

function self:ServerAwake()
  scene.PlayerJoined:Connect(function(scene, player)
    GetAllPlayerItems(player, INVENTORY_FETCH_LIMIT, nil, {}, UpdatePlayerInventory)
  end)

  Timer.Every(TRANSACTION_COMMIT_INTERVAL, CommitQueuedTransactions)

  Events.get("GiveItemRequest"):Connect(function(player, target, item, targetPlayerId)
    ServerGivePlayerItem(target, item, targetPlayerId)
  end)

  Events.get("TakeItemRequest"):Connect(function(player, target, item)
    ServerTakePlayerItem(target, item)
  end)
end