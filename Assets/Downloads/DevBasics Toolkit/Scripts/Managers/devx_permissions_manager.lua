--!Type(Module)

local Utils = require("devx_utils")
local Config = require("devx_config")
local Logger = require("devx_logger")

local Events = require("devx_events_factory")
local StorageManager = require("devx_storage_manager")

local GetPermissionCallbacks = {}
local GrantPermissionCallbacks = {}
local RemovePermissionCallbacks = {}
local CachedPermissions = {}

local IntervalToRefreshPermissions : number = 10 -- In seconds

--------------------------------------------------------------------
------------------------------ CLIENT ------------------------------

--[[
  GetPermission: Gets a permission for a player.
  @param playername: string
  @param permission: string
  @param callback: (success: boolean, message: string) -> ()
]]
function GetPermission(playername: string, permission: string, callback: (success: boolean, message: string) -> ())
  if not client then
    Logger.DeferPrint("GetPermissions: Must be called from client")
    return
  end
  
  local requestId = Utils.GenerateRandomRequestId()
  GetPermissionCallbacks[requestId] = callback

  Events.get("GetPermissionsRequest"):FireServer(playername, permission, requestId)
end

--[[
  GetPermissionResponse: Handles the response from the server.
  @param requestId: string
  @param response: Response
]]
local function GetPermissionResponse(requestId: string, success: boolean, message: string)
  local callback = GetPermissionCallbacks[requestId]
  if callback then
    callback(success, message)
    GetPermissionCallbacks[requestId] = nil
  end
end

--[[
  GrantPermission: Grants a permission to a player.
  @param playername: string
  @param permission: string
  @param callback: (success: boolean, message: string) -> ()
]]
function GrantPermission(playername: string, permission: string, callback: (success: boolean, message: string) -> ())
  if not client then
    Logger.DeferPrint("GrantPermission: Must be called from client")
    return
  end

  local requestId = Utils.GenerateRandomRequestId()
  GrantPermissionCallbacks[requestId] = callback

  Events.get("GrantPermissionRequest"):FireServer(playername, permission, requestId)
end

--[[
  GrantPermissionResponse: Handles the response from the server.
  @param requestId: string
  @param response: Response
]]
local function GrantPermissionResponse(requestId: string, success: boolean, message: string)
  local callback = GrantPermissionCallbacks[requestId]
  if callback then
    callback(success, message)
    GrantPermissionCallbacks[requestId] = nil
  end
end

--[[
  RemovePermission: Removes a permission from a player.
  @param playername: string
  @param permission: string
  @param callback: (success: boolean, message: string) -> ()
]]
function RemovePermission(playername: string, permission: string, callback: (success: boolean, message: string) -> ())
  if not client then
    Logger.DeferPrint("RemovePermission: Must be called from client")
    return
  end
  
  local requestId = Utils.GenerateRandomRequestId()
  RemovePermissionCallbacks[requestId] = callback

  Events.get("RemovePermissionRequest"):FireServer(playername, permission, requestId)
end

--[[
  RemovePermissionResponse: Handles the response from the server.
  @param requestId: string
  @param response: Response
]]
local function RemovePermissionResponse(requestId: string, success: boolean, message: string)
  local callback = RemovePermissionCallbacks[requestId]
  if callback then
    callback(success, message)
    RemovePermissionCallbacks[requestId] = nil
  end
end

function self:ClientAwake()
  Events.get("GetPermissionsResponse"):Connect(GetPermissionResponse)
  Events.get("GrantPermissionResponse"):Connect(GrantPermissionResponse)
  Events.get("RemovePermissionResponse"):Connect(RemovePermissionResponse)
end

--------------------------------------------------------------------
------------------------------ SERVER ------------------------------

--[[
  GetCachedPermissions: Returns the cached permissions.
  @return { [string]: { string } }
]]
function GetCachedPermissions(): { [string]: { string } }
  return CachedPermissions
end

--[[
  GetPlayerPermissions: Returns the permissions of a player.
  @param playerName: string
  @return { string }
]]
function GetPlayerPermissionsServer(playerName: string): { string }
  local permissions = GetCachedPermissions()
  local playerPermissions = permissions[playerName]

  if playerPermissions then
    return playerPermissions
  end

  return {}
end

--[[
  PlayerHasPermission: Checks if a player has a permission.
  @param playerName: string
  @param permission: string
  @return boolean
]]
function PlayerHasPermissionServer(player: Player, playerName: string, permission: string, requestId: string)
  if not server then 
    Logger.DeferPrint("PlayerHasPermission: Must be called from server")
    return Events.get("GetPermissionsResponse"):FireClient(player, requestId, false, "Must be called from server")
  end

  local allPermissions = Config.GetPermissions()

  if not table.find(allPermissions, permission) then 
    Logger.DeferPrint("PlayerHasPermission: Unknown permission '" .. permission .. "'")
    return Events.get("GetPermissionsResponse"):FireClient(player, requestId, false, "Unknown permission '" .. permission .. "'")
  end

  local playerPermissions = GetPlayerPermissionsServer(playerName)

  for _, perm in ipairs(playerPermissions) do
    if perm == permission or perm == tostring(Config.GetHighestPermission()) then
      return Events.get("GetPermissionsResponse"):FireClient(player, requestId, true, "Player has permission")
    end
  end

  return Events.get("GetPermissionsResponse"):FireClient(player, requestId, false, "Player does not have permission")
end

--[[
  PopulatePermissions: Populates the permissions from storage.
]]
function PopulatePermissionsServer()
  local permissionsKey = Config.GetPermissionsStorageKey()
  local defaultPermissions = Config.GetDefaultPermissions()

  Storage.GetValue(permissionsKey, function(storedPermissions)
    if storedPermissions == nil then
      Storage.SetValue(permissionsKey, defaultPermissions)
      CachedPermissions = defaultPermissions
      return
    end

    local updated = Utils.OverwriteScriptDefinedPermissions(defaultPermissions, storedPermissions)

    if not Utils.PermissionsAreEqual(updated, storedPermissions) then
      Storage.SetValue(permissionsKey, updated)
      CachedPermissions = updated
    else
      CachedPermissions = storedPermissions
    end
  end)
end


--[[
  AddPermission: Adds a permission to a player.
  @param playerName: string
  @param permission: string
  @return Response
]]
function GrantPermissionServer(player: Player, playerName: string, permission: string, requestId: string)
  if not server then
    Logger.DeferPrint("GrantPermission: Must be called from server")
    return Events.get("GrantPermissionResponse"):FireClient(player, requestId, false, "Must be called from server")
  end

  local hasPermission = PlayerHasPermissionServer(player, playerName, "perm_update_permissions", requestId)
  if not hasPermission then
    return Events.get("GrantPermissionResponse"):FireClient(player, requestId, false, "Player does not have permission to grant permissions")
  end

  local AllPermissions = Config.GetPermissions()
  if not table.find(AllPermissions, permission) then
    Logger.DeferPrint("GrantPermission: Unknown permission '" .. permission .. "'")
    return Events.get("GrantPermissionResponse"):FireClient(player, requestId, false, "Unknown permission '" .. permission .. "'")
  end

  local playerPermissions = GetPlayerPermissionsServer(playerName)
  if playerPermissions == {} or playerPermissions == nil then
    playerPermissions = { permission }
  else
    -- check if the permission is already in the player's permissions
    if not table.find(playerPermissions, permission) then
      table.insert(playerPermissions, permission)
    else
      Logger.DeferPrint("GrantPermission: Permission already exists for " .. playerName)
      return Events.get("GrantPermissionResponse"):FireClient(player, requestId, false, "Permission already exists for " .. playerName)
    end
  end

  CachedPermissions[playerName] = playerPermissions
  Storage.SetValue(Config.GetPermissionsStorageKey(), CachedPermissions)

  return Events.get("GrantPermissionResponse"):FireClient(player, requestId, true, "Permission added successfully")
end

--[[
  RemovePermission: Removes a permission from a player.
  @param playerName: string
  @param permission: string
  @return Response
]]
function RemovePermissionServer(player: Player, playerName: string, permission: string, requestId: string)
  if not server then
    Logger.DeferPrint("RemovePermission: Must be called from server")
    return Events.get("RemovePermissionResponse"):FireClient(player, requestId, false, "Must be called from server")
  end

  local hasPermission = PlayerHasPermissionServer(player, playerName, "perm_update_permissions", requestId)
  if not hasPermission then
    return Events.get("RemovePermissionResponse"):FireClient(player, requestId, false, "Player does not have permission to remove permissions")
  end

  local AllPermissions = Config.GetPermissions()
  if not table.find(AllPermissions, permission) then
    Logger.DeferPrint("RemovePermission: Unknown permission '" .. permission .. "'")
    return Events.get("RemovePermissionResponse"):FireClient(player, requestId, false, "Unknown permission '" .. permission .. "'")
  end

  local playerPermissions = GetPlayerPermissionsServer(playerName)
  if playerPermissions == {} or playerPermissions == nil then
    Logger.DeferPrint("RemovePermission: Player does not have any permissions")
    return Events.get("RemovePermissionResponse"):FireClient(player, requestId, false, "Player does not have any permissions")
  end

  -- remove the permission from the player's permissions
  table.remove(playerPermissions, table.find(playerPermissions, permission))

  CachedPermissions[playerName] = playerPermissions
  Storage.SetValue(Config.GetPermissionsStorageKey(), CachedPermissions)

  return Events.get("RemovePermissionResponse"):FireClient(player, requestId, true, "Permission removed successfully")
end

function self:ServerAwake()
  PopulatePermissionsServer()
  Timer.Every(IntervalToRefreshPermissions, PopulatePermissionsServer)

  Events.get("GetPermissionsRequest"):Connect(PlayerHasPermissionServer)
  Events.get("GrantPermissionRequest"):Connect(GrantPermissionServer)
  Events.get("RemovePermissionRequest"):Connect(RemovePermissionServer)
end