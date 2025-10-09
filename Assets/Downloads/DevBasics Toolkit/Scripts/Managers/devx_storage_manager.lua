--!Type(Module)

local Utils = require("devx_utils")
local Config = require("devx_config")
local Logger = require("devx_logger")

local Events = require("devx_events_factory")
local PlayerTracker = require("devx_player_tracker")

--!Tooltip("Whether to add a new entry to the storage if no value is found")
--!SerializeField
local _RegisterPlayerStorageOnEmpty : boolean = true


local IncrementCurrencyCallbacks = {}
local DecrementCurrencyCallbacks = {}

type Response = { success: boolean, message: string }
type IncrementCurrencyCallback = (response: Response) -> ()
type DecrementCurrencyCallback = (response: Response) -> ()

--------------------------------------------------------------------
------------------------------ CLIENT ------------------------------

--[[
  IncrementPlayerCurrency: Increments the currency of a player.
  @param amount: number
  @param callback: function
]]
function IncrementPlayerCurrency(amount: number, callback: IncrementCurrencyCallback)
  if not client then
    Logger.DeferPrint("IncrementPlayerCurrency: Must be called from client")
    return
  end

  local requestId = Utils.GenerateRandomRequestId()
  IncrementCurrencyCallbacks[requestId] = callback

  Events.get("CurrencyIncrementedRequest"):FireServer(amount, requestId)
end

--[[
  DecrementPlayerCurrency: Decrements the currency of a player.
  @param amount: number
  @param callback: function
]]
function DecrementPlayerCurrency(amount: number, callback: DecrementCurrencyCallback)
  if not client then
    Logger.DeferPrint("DecrementPlayerCurrency: Must be called from client")
    return
  end

  local requestId = Utils.GenerateRandomRequestId()
  DecrementCurrencyCallbacks[requestId] = callback
  
  Events.get("CurrencyDecrementedRequest"):FireServer(amount, requestId)
end

--[[
  HandleIncrementCurrencyResponse: Handles the response from the server.
  @param requestId: string
  @param response: Response
]]
function HandleIncrementCurrencyResponse(requestId: string, response: Response)
  if requestId == nil then return end

  local callback = IncrementCurrencyCallbacks[requestId]
  if callback then 
    callback(response) -- returns response.success and response.message
    IncrementCurrencyCallbacks[requestId] = nil
  end
end

--[[
  HandleDecrementCurrencyResponse: Handles the response from the server.
  @param requestId: string
  @param response: Response
]]
function HandleDecrementCurrencyResponse(requestId: string, response: Response)
  if requestId == nil then return end
  
  local callback = DecrementCurrencyCallbacks[requestId]
  if callback then 
    callback(response) -- returns response.success and response.message
    DecrementCurrencyCallbacks[requestId] = nil
  end
end

function self:ClientStart()
  Events.get("CurrencyIncrementedResponse"):Connect(HandleIncrementCurrencyResponse)
  Events.get("CurrencyDecrementedResponse"):Connect(HandleDecrementCurrencyResponse)
end


--------------------------------------------------------------------
------------------------------ SERVER ------------------------------

--[[
  IncrementCurrencyCB: Increments the currency of a player.
  @param player: Player
  @param amount: number
  @param requestId: string
  @return void
]]
function ServerIncrementCurrency(player: Player, amount: number, requestId: string | nil)
  if not server then
    Logger.DeferPrint("ServerIncrementCurrency: Must be called from server")
    return
  end

  local currencyKey = Config.GetStorageCurrencyKey()
  local balance = PlayerTracker.getPlayerInfo(player).currency.value

  local newBalance = balance + amount

  Storage.IncrementPlayerValue(player, currencyKey, amount, function(err)
    if err ~= StorageError.None then
      Logger.DeferPrint("Failed to increment currency for " .. player.name)
      Events.get("CurrencyIncrementedResponse"):FireClient(player, requestId, { success = false, message = "Failed to increment currency" })
      return
    end

    PlayerTracker.getPlayerInfo(player).currency.value = newBalance
    Events.get("CurrencyIncrementedResponse"):FireClient(player, requestId, { success = true, message = "Currency incremented successfully" })
  end)
end

--[[
  ServerDecrementCurrency: Decrements the currency of a player.
  @param player: Player
  @param amount: number
  @param requestId: string
  @return void
]]
function ServerDecrementCurrency(player: Player, amount: number, requestId: string | nil)
  if not server then
    Logger.DeferPrint("ServerDecrementCurrency: Must be called from server")
    return
  end

  local currencyKey = Config.GetStorageCurrencyKey()
  local balance = PlayerTracker.getPlayerInfo(player).currency.value

  local newBalance = balance - amount

  Storage.IncrementPlayerValue(player, currencyKey, -amount, function(err)
    if err ~= StorageError.None then
      Logger.DeferPrint("Failed to decrement currency for " .. player.name)
      Events.get("CurrencyDecrementedResponse"):FireClient(player, requestId, { success = false, message = "Failed to decrement currency" })
      return
    end

    if newBalance < 0 then
      newBalance = 0
    end

    PlayerTracker.getPlayerInfo(player).currency.value = newBalance
    Events.get("CurrencyDecrementedResponse"):FireClient(player, requestId, { success = true, message = "Currency decremented successfully" })
  end)
end

--[[
  LoadPlayerCurrency: Loads the currency of a player.
  @param player: Player
]]
function LoadPlayerCurrency(player: Player)
  if not server then
    Logger.DeferPrint("LoadPlayerCurrency: Must be called from server")
    return
  end

  local currencyKey = Config.GetStorageCurrencyKey()
  
  Storage.GetPlayerValue(player, currencyKey, function(value)
    if value then
      Logger.DeferPrint("Loaded currency for " .. player.name .. " with value " .. value)
      PlayerTracker.getPlayerInfo(player).currency.value = value
    else
      Logger.DeferPrint("No currency found for " .. player.name)
      if _RegisterPlayerStorageOnEmpty then
        Storage.SetPlayerValue(player, currencyKey, 0)
        PlayerTracker.getPlayerInfo(player).currency.value = 0
      end
    end
  end)
end

function self:ServerAwake()
  Events.get("PlayerJoined"):Connect(LoadPlayerCurrency)
  Events.get("CurrencyIncrementedRequest"):Connect(ServerIncrementCurrency)
  Events.get("CurrencyDecrementedRequest"):Connect(ServerDecrementCurrency)
end