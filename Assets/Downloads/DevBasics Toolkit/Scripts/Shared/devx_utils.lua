--!Type(Module)

--[[
  IsProductWithPrefix: Checks if a product ID has a specific prefix.
  @param product_id: string
  @param prefix: string
]]
function IsProductWithPrefix(product_id: string, prefix: string): boolean
  if type(product_id) ~= "string" or type(prefix) ~= "string" then
    return false
  end
  return string.sub(product_id, 1, #prefix) == prefix
end

--[[
  GenerateRandomRequestId: Generates a random request ID.
  @return string
]]
function GenerateRandomRequestId(): string
  local requestId = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
  return requestId
end

--[[
  RankSuffix: Returns the suffix for a rank.
  @param rank: number
  @return string
]]
function RankSuffix(rank: number): string
  if rank == 1 then
    return "1st"
  elseif rank == 2 then
    return "2nd"
  elseif rank == 3 then
    return "3rd"
  else
    return tostring(rank) .. "th"
  end
end

type Permission = {
  [string]: { string }
}

--[[
  PermissionsAreEqual: Checks if two permissions are equal.
  @param a: Permission
  @param b: Permission
  @return boolean
]]
function PermissionsAreEqual(a: Permission, b: Permission): boolean
  for player, permsA in pairs(a) do
    local permsB = b[player]
    if not permsB or #permsA ~= #permsB then
      return false
    end
    table.sort(permsA)
    table.sort(permsB)
    for i = 1, #permsA do
      if permsA[i] ~= permsB[i] then
        return false
      end
    end
  end

  for player in pairs(b) do
    if not a[player] then return false end
  end

  return true
end

--[[
  MergeDefaultIntoStored: Merges default permissions into stored permissions.
  @param defaults: Permission
  @param stored: Permission
  @return Permission
]]
function MergeDefaultIntoStored(defaults: Permission, stored: Permission): Permission
  local merged = {}

  -- Start with stored permissions
  for player, perms in pairs(stored) do
    merged[player] = { table.unpack(perms) }
  end

  -- Add missing users or permissions from defaults
  for player, defaultPerms in pairs(defaults) do
    if not merged[player] then
      merged[player] = { table.unpack(defaultPerms) }
    else
      -- Merge permissions, avoiding duplicates
      local existing = {}
      for _, perm in ipairs(merged[player]) do
        existing[perm] = true
      end
      for _, perm in ipairs(defaultPerms) do
        if not existing[perm] then
          table.insert(merged[player], perm)
        end
      end
    end
  end

  return merged
end

--[[
  OverwriteScriptDefinedPermissions: Overwrites the script-defined permissions.
  @param defaults: Permission
  @param stored: Permission
  @return Permission
]]
function OverwriteScriptDefinedPermissions(defaults: Permission, stored: Permission): Permission
  local updated = {}

  -- Copy stored values for non-script-defined users
  for player, perms in pairs(stored) do
    if not defaults[player] then
      updated[player] = { table.unpack(perms) }
    end
  end

  -- Overwrite (or add) users from script-defined defaults
  for player, defaultPerms in pairs(defaults) do
    updated[player] = { table.unpack(defaultPerms) }
  end

  return updated
end

--[[
  Prompt: Prompts the user to purchase a product.
  @param id: string
  @param callback: (paid: boolean) -> ()
]]
function Prompt(id: string, callback: (paid: boolean) -> ())
  Payments:PromptPurchase(id, callback)
end

--[[
  FormatNumber: Formats a number to a string.
  @param number: number
  @return string
]]
function FormatNumber(number: number): string
  -- Ensure number is positive
  number = math.max(0, number)
  
  if number >= 1000000000000 then
    return string.format("%.2fT", number / 1000000000000)
  elseif number >= 1000000000 then
    return string.format("%.2fB", number / 1000000000)
  elseif number >= 1000000 then
    return string.format("%.2fM", number / 1000000)
  elseif number >= 1000 then
    return string.format("%.2fK", number / 1000)
  end

  return tostring(math.floor(number))
end

--[[
  AddCommas: Adds commas to a number.
  @param number: number
  @return string
]]
function AddCommas(number: number): string
  -- Ensure number is positive
  number = math.max(0, number)
  
  -- Format to 0 decimal places for integers
  local formatted = tostring(math.floor(number))
  
  -- Add commas for thousands
  local k
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if k == 0 then break end
  end
  
  return formatted
end

-- TABLE UTILITIES --

--[[
  DeepCopy: Creates a deep copy of a table.
  @param original: table
  @return table
]]
function DeepCopy(original: { [any]: any }): { [any]: any }
  if type(original) ~= "table" then return original end
  
  local copy = {}
  for key, value in pairs(original) do
    if type(value) == "table" then
      copy[key] = DeepCopy(value)
    else
      copy[key] = value
    end
  end
  
  return copy
end

--[[
  ShallowCopy: Creates a shallow copy of a table.
  @param original: table
  @return table
]]
function ShallowCopy(original: { [any]: any }): { [any]: any }
  if type(original) ~= "table" then return original end
  
  local copy = {}
  for key, value in pairs(original) do
    copy[key] = value
  end
  
  return copy
end

--[[
  TableContains: Checks if a table contains a value.
  @param tbl: table
  @param value: any
  @return boolean
]]
function TableContains(tbl: { [any]: any }, value: any): boolean
  for _, v in pairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end

--[[
  FindInTable: Finds an element in a table by a custom predicate function.
  @param tbl: table
  @param predicate: function(value: any, key: any) -> boolean
  @return any, any - The value and key if found, nil otherwise
]]
function FindInTable(tbl: { [any]: any }, predicate: (value: any, key: any) -> boolean): (any, any)
  for k, v in pairs(tbl) do
    if predicate(v, k) then
      return v, k
    end
  end
  return nil, nil
end

--[[
  CountTable: Counts the number of elements in a table.
  @param tbl: table
  @return number
]]
function CountTable(tbl: { [any]: any }): number
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

--[[
  MergeTables: Merges two tables.
  @param t1: table
  @param t2: table
  @return table
]]
function MergeTables(t1: { [any]: any }, t2: { [any]: any }): { [any]: any }
  local result = ShallowCopy(t1)
  
  for k, v in pairs(t2) do
    result[k] = v
  end
  
  return result
end

-- MATH UTILITIES --

--[[
  Lerp: Linear interpolation between two values.
  @param a: number
  @param b: number
  @param t: number (0-1)
  @return number
]]
function Lerp(a: number, b: number, t: number): number
  return a + (b - a) * math.max(0, math.min(1, t))
end

--[[
  Clamp: Clamps a value between min and max.
  @param value: number
  @param min: number
  @param max: number
  @return number
]]
function Clamp(value: number, min: number, max: number): number
  return math.max(min, math.min(max, value))
end

--[[
  RandomRange: Returns a random number between min and max.
  @param min: number
  @param max: number
  @param isInteger: boolean (optional)
  @return number
]]
function RandomRange(min: number, max: number, isInteger: boolean): number
  local value = min + math.random() * (max - min)
  if isInteger then
    return math.floor(value + 0.5)
  end
  return value
end

--[[
  DistanceSquared: Returns the squared distance between two Vector3 points.
  @param a: Vector3
  @param b: Vector3
  @return number
]]
function DistanceSquared(a: Vector3, b: Vector3): number
  local dx = b.x - a.x
  local dy = b.y - a.y
  local dz = b.z - a.z
  return dx * dx + dy * dy + dz * dz
end

--[[
  Distance: Returns the distance between two Vector3 points.
  @param a: Vector3
  @param b: Vector3
  @return number
]]
function Distance(a: Vector3, b: Vector3): number
  return math.sqrt(DistanceSquared(a, b))
end

-- STRING UTILITIES --

--[[
  TrimString: Trims whitespace from both ends of a string.
  @param str: string
  @return string
]]
function TrimString(str: string): string
  return str:match("^%s*(.-)%s*$") or ""
end

--[[
  SplitString: Splits a string by a delimiter.
  @param str: string
  @param delimiter: string
  @return table
]]
function SplitString(str: string, delimiter: string): { string }
  local result = {}
  local pattern = "(.-)" .. delimiter .. "()"
  local lastPos = 1
  
  for part, pos in string.gmatch(str, pattern) do
    table.insert(result, part)
    lastPos = pos
  end
  
  table.insert(result, string.sub(str, lastPos))
  return result
end

--[[
  FormatTime: Formats seconds into a time string (MM:SS or HH:MM:SS).
  @param seconds: number
  @param includeHours: boolean (optional)
  @return string
]]
function FormatTime(seconds: number, includeHours: boolean): string
  seconds = math.max(0, math.floor(seconds))
  local minutes = math.floor(seconds / 60)
  local hours = math.floor(minutes / 60)
  
  seconds = seconds % 60
  minutes = minutes % 60
  
  if includeHours or hours > 0 then
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
  else
    return string.format("%02d:%02d", minutes, seconds)
  end
end

-- GAME UTILITIES --

--[[
  GetRandomPosition: Gets a random position within a radius.
  @param center: Vector3
  @param minRadius: number
  @param maxRadius: number
  @return Vector3
]]
function GetRandomPosition(center: Vector3, minRadius: number, maxRadius: number): Vector3
  local radius = RandomRange(minRadius, maxRadius, true)
  local angle = math.random() * math.pi * 2
  
  local x = center.x + radius * math.cos(angle)
  local z = center.z + radius * math.sin(angle)
  
  return Vector3.new(x, center.y, z)
end

--[[
  IsPlayerInRange: Checks if a player is within a range of a position.
  @param player: Player
  @param position: Vector3
  @param range: number
  @return boolean
]]
function IsPlayerInRange(player: Player, position: Vector3, range: number): boolean
  if not player or not player.character then
    return false
  end
  
  local playerPos = player.character.transform.position
  return DistanceSquared(playerPos, position) <= (range * range)
end

--[[
  SafeDestroy: Safely destroys a GameObject if it exists.
  @param gameObject: GameObject
]]
function SafeDestroy(gameObject: GameObject)
  if gameObject then
    Object.Destroy(gameObject)
  end
end

--[[
  ScheduleCallback: Schedules a callback after a delay.
  @param delay: number
  @param callback: function
  @return Timer
]]
function ScheduleCallback(delay: number, callback: () -> ()): Timer
  return Timer.After(delay, callback)
end

--[[
  ScheduleRepeating: Schedules a repeating callback.
  @param interval: number
  @param callback: function
  @return Timer
]]
function ScheduleRepeating(interval: number, callback: () -> ()): Timer
  return Timer.Every(interval, callback)
end

--[[
  LogDebug: Logs a debug message with context.
  @param context: string
  @param message: string
  @param ...
]]
function LogDebug(context: string, message: string, ...)
  local formatted = string.format(message, ...)
  print("[" .. context .. "] " .. formatted)
end

type LeaderboardEntry = {
  id: string,
  name: string,
  score: number,
  rank: number
}

function GenerateFakeLeaderboardEntries(count: number): { LeaderboardEntry }
  local entries = {}
  for i = 1, count do
    table.insert(entries, {
      id = tostring(i),
      name = "Player " .. i,
      score = math.random(1000, 1000000),
      rank = i
    })
  end 

  return entries
end