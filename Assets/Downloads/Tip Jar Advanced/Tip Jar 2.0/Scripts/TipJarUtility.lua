--!Type(Module)

--!SerializeField
local _creatorName : string = "iHsein"

--!Tooltip("The limit of top tippers to show")
--!Range(1, 100)
--!SerializeField
local _TopTippersLimit : number = 30

--!Tooltip("The limit of tipping messages to show")
--!Range(1, 100)
--!SerializeField
local _TippingMessagesLimit : number = 30

--!SerializeField
local _tipJarDrawer : GameObject = nil
--!SerializeField
local _tipJarBasic : GameObject = nil

-- Combined events for fetching both datasets at once
GetTipJarDataRequest = Event.new("GetTipJarDataRequest")
GetTipJarDataResponse = Event.new("GetTipJarDataResponse")

SuccessfullPurchase = Event.new("SuccessfullPurchase")
SendCustomMessageEvent = Event.new("SendCustomMessageEvent")

type Message = {
  Amount: number,
  Message: string,
  Time: number,
  PlayerId: string,
  PlayerName: string
}

type Messages = { [number]: Message }

--[[
  -- Function to add commas to numbers
  -- @param amount: number
  -- @return formatted: string
]]
function comma_value(amount: number)
  local formatted = amount
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if k == 0 then
      break
    end
  end
  return formatted
end

--[[
  -- Function to get the creator name
  -- @return creatorName: string
]]
function GetCreatorName(): string
  return _creatorName
end

--[[
  -- Function to generate fake data for the top tippers (For testing purposes only)
  -- @param players: number
  -- @return topTippers: table
]]
function GenerateFakeTopTippers(players: number)
  local topTippers = {}
  for i = 1, players do
    table.insert(topTippers, {
      Amount = math.random(100, 10000),
      Name = "Player " .. i,
      Id = "player" .. i
    })
  end
  return topTippers
end

--[[
  -- Function to generate fake messages (For testing purposes only)
  -- @param messages: number
  -- @return messagesTable: table
]]
function GenerateFakeMessages(messages: number): Messages
  local messagesTable: Messages = {}

  -- Generate random messages with random times
  for i = 1, messages do
    table.insert(messagesTable, {
      Amount = math.random(100, 10000),
      Message = "Message " .. i,
      Time = os.time(),
      PlayerId = client.localPlayer.user.id,
      PlayerName = "Player " .. i
    })
  end

  return messagesTable
end

--[[
  -- Function to sort messages by time
  -- @param messages: table
]]
function SortMessagesByTime(messages: Messages)
  table.sort(messages, function(a, b)
    return a.Time > b.Time
  end)
end

--[[
  -- Function to convert a timestamp to a local time
  -- @param time: number
  -- @return localTime: string
]]
function ConvertToLocalTime(time: number)
  local localTime = os.time()
  local timeDifference = localTime - time
  
  -- If less than 30 seconds, return "just now"
  if timeDifference < 30 then
    return "just now"
  end
  
  local days = math.floor(timeDifference / 86400)
  local hours = math.floor((timeDifference % 86400) / 3600)
  local minutes = math.floor((timeDifference % 3600) / 60)
  local seconds = timeDifference % 60

  -- If more than 30 days, return date format
  if days > 30 then
    local dateTable = os.date("*t", time)
    return string.format("%d %s", dateTable.day, os.date("%B", time))
  end

  if days > 0 then
    return string.format("%dd ago", days)
  elseif hours > 0 then
    return string.format("%dh ago", hours)
  elseif minutes > 0 then
    return string.format("%dm ago", minutes)
  else
    return string.format("%ds ago", seconds)
  end
end

--[[
  -- Function to open the tip jar drawer
]]
function OpenTipJarDrawer()
  if not _tipJarDrawer then
    print("Please assign the tip jar drawer in the inspector")
    return
  end

  _tipJarDrawer:SetActive(true)
end

--[[
  -- Function to open the tip jar basic
]]
function OpenTipJarBasic()
  if not _tipJarBasic then
    print("Please assign the tip jar basic in the inspector")
    return
  end

  _tipJarBasic:SetActive(true)
end

--[[
  -- Function to close the tip jar basic
]]
function CloseTipJarBasic()
  if not _tipJarDrawer then
    print("Please assign the tip jar drawer in the inspector")
    return
  end

  _tipJarDrawer:SetActive(false)
end 

--[[
  -- Function to close the tip jar drawer
]]
function CloseTipJarDrawer()
  if not _tipJarDrawer then
    print("Please assign the tip jar drawer in the inspector")
    return
  end
  
  _tipJarBasic:SetActive(false)
end

--[[
  -- Function to close all UI
]]
function CloseAllUI()
  CloseTipJarDrawer()
  CloseTipJarBasic()
end

--[[
  GenerateRandomRequestId: Generates a random request ID.
  @return string
]]
function GenerateRandomRequestId(): string
  local requestId = tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
  return requestId
end

function GetTopTippersLimit(): number
  return _TopTippersLimit
end

function GetTippingMessagesLimit(): number
  return _TippingMessagesLimit
end