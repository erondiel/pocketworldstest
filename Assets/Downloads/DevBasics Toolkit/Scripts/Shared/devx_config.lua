--!Type(Module)

--!Tooltip("Used to identify currency products e.g. devx_currency_100")
--!SerializeField
local _CurrencyPrefix : string = "devx_currency"

--[[
  GetCurrencyPrefix: Returns the currency prefix.
  @return string
]]
function GetCurrencyPrefix(): string
  return _CurrencyPrefix
end

--!Tooltip("Used to identify the currency storage key e.g. Currency")
--!SerializeField
local _StorageCurrencyKey : string = "Currency"

--[[
  GetStorageCurrencyKey: Returns the storage currency key.
  @return string
]]
function GetStorageCurrencyKey(): string
  return _StorageCurrencyKey
end

--!Tooltip("Used to identify the leaderboard storage key e.g. Leaderboard")
--!SerializeField
local _LeaderboardKey : string = "Leaderboard"

--[[
  GetLeaderboardKey: Returns the leaderboard key.
  @return string
]]
function GetLeaderboardKey(): string
  return _LeaderboardKey
end

--!Tooltip("Used to identify the permissions storage key e.g. Permissions")
--!SerializeField
local _PermissionsStorageKey : string = "devx_permissions"

--[[
  GetPermissionsStorageKey: Returns the permissions storage key.
  @return string
]]
function GetPermissionsStorageKey(): string
  return _PermissionsStorageKey
end

--!Tooltip("Used to identify the highest permission e.g. perm_superadmin")
--!SerializeField
local _HighestPermission : string = "perm_superadmin"

--[[
  GetHighestPermission: Returns the highest permission.
  @return string
]]
function GetHighestPermission(): string
  return _HighestPermission
end

type Permission = {
  [string]: { string }
}

-- Permissions
local DevX_DefaultPermissions : Permission = {
  ["iHsein"] = {
    --"perm_superadmin",
    "perm_update_permissions",
    "perm_give_currency",
    --"perm_open_debug_ui"
  },
  -- Add more permissions if needed
}

--[[
  GetDefaultPermissions: Returns the default permissions.
  @return Permission
]]
function GetDefaultPermissions(): Permission
  return DevX_DefaultPermissions
end

local DevX_Permissions = {
  "perm_superadmin",
  "perm_update_permissions",
  "perm_give_currency",
  "perm_open_debug_ui"
}

--[[
  GetPermissions: Returns the list of permissions.
  @return { string }
]]
function GetPermissions(): { string }
  return DevX_Permissions
end

-- Events
local DevX_Events = {
  -- Player
  "PlayerJoined",

  -- Payments
  "SuccessfullPurchase",

  -- Storage
  "CurrencyIncrementedRequest",
  "CurrencyDecrementedRequest",
  "CurrencyIncrementedResponse",
  "CurrencyDecrementedResponse",

  -- Permissions
  "GetPermissionsRequest",
  "GetPermissionsResponse",
  "GrantPermissionRequest",
  "GrantPermissionResponse",
  "RemovePermissionRequest",
  "RemovePermissionResponse",

  -- Inventory
  "GiveItemRequest",
  "TakeItemRequest",

  -- Leaderboard
  "FetchLeaderboardRequest",
  "FetchLeaderboardResponse",
  "LeaderboardPlayerEntryResponse",
  "GetTopPlayersRequest",
  "GetTopPlayersResponse"
}

--[[
  GetEvents: Returns the list of events.
  @return { string }
]]
function GetEvents(): { string }
  return DevX_Events
end


-- Static items that should not be removed when amount reaches 0
local DevX_Inventory_StaticItems = {
  -- Add static item IDs here if needed
  "devx_currency_100"
}

function GetInventoryStaticItems(): { string }
  return DevX_Inventory_StaticItems
end

--[[
  IsInventoryStaticItem: Returns true if the item is a static item.
  @param itemId: The ID of the item.
  @return boolean
]]
function IsInventoryStaticItem(itemId: string): boolean
  for index, staticItem in DevX_Inventory_StaticItems do
    if staticItem == itemId then
      return true
    end
  end

  return false
end