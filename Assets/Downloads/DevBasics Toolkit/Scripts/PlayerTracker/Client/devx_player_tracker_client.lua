--!Type(Client)

local Logger = require("devx_logger")
local Events = require("devx_events_factory")

local PlayerTracker = require("devx_player_tracker")
local StorageManager = require("devx_storage_manager")
local InventoryManager = require("devx_inventory_manager")
local PermissionsManager = require("devx_permissions_manager")

function self:Awake()
  function OnCharacterSpawn(playerInfo)
    local player = playerInfo.player
    local char = playerInfo.player.character

    print("OnCharacterSpawn", player.name)
    if not PlayerTracker.getPlayerInfo(player) then return end

    playerInfo.currency.Changed:Connect(function(newValue, oldValue)
      Logger.DeferPrint("Currency changed from " .. oldValue .. " to " .. newValue .. " for " .. player.name)
    end)
  end

  PlayerTracker.track(client, OnCharacterSpawn)
end

function self:Start()
  Events.get("PlayerJoined"):FireServer()

  Timer.After(3, function()
    StorageManager.IncrementPlayerCurrency(50, function(response)
      if response.success then
        Logger.DeferPrint("Currency incremented successfully")
      else
        Logger.DeferPrint("Currency increment failed")
      end
    end)
  end)

  Timer.After(5, function()
    PermissionsManager.GetPermission(client.localPlayer.name, "perm_give_currency", function(success, message)
      Logger.DeferPrint("GetPermission: " .. message)
    end)
  end)

  Timer.After(7, function()
    Timer.After(5, function()
      InventoryManager.GivePlayerItem(client.localPlayer, {id = "devx_currency_100", amount = 100}, nil)
    end)
  end)
end