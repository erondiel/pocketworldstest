--!Type(UI)

-- Container
--!Bind
local _announcement : VisualElement = nil

-- Content
--!Bind
local _announcementContent : VisualElement = nil
--!Bind
local _tipMessage : Label = nil
--!Bind
local _tipperThumbnail : UIUserThumbnail = nil
--!Bind
local _ThumbnailOverlayClicker : VisualElement = nil

local Messages = {
  [0] = {
    "<color=#ffd32f>{{name}}</color> tipped <color=#ffd32f>{{amount}}</color>! Thanks for your support!",
  },
  [100] = {
    "<color=#ffd32f>{{name}}</color> just tipped <color=#ffd32f>{{amount}}</color> to help keep our world amazing!",
  },
  [500] = {
    "<color=#ffd32f>{{name}}</color> just generously tipped <color=#ffd32f>{{amount}}</color> to support our community!",
  },
  [1000] = {
    "<color=#ffd32f>{{name}}</color> just added <color=#ffd32f>{{amount}}</color>! Thanks for your support!",
  },
  [5000] = {
    "<color=#ffd32f>{{name}}</color> just gave a huge <color=#ffd32f>{{amount}}</color> to boost our world!",
  },
  [10000] = {
    "<color=#ffd32f>{{name}}</color> just donated a major <color=#ffd32f>{{amount}}</color>! Huge thanks!",
  }
}

local LastPlayerId = nil

-- Function to replace {{amount}} with the actual tip amount
function ReplaceContent(content: string, playername: string, amount: number)
  if content:find("{{amount}}") then
    content = content:gsub("{{amount}}", tostring(amount))
  end

  if content:find("{{name}}") then
    content = content:gsub("{{name}}", playername)
  end

  return content
end

function GetMessageFromAmount(amount: number)
  if Messages[amount] then
    return Messages[amount][1]
  else
    return Messages[0][1]
  end
end

function PopulateContent(playername: string,  playerId: string, amount: number)
  _announcement:RemoveFromClassList("hidden")
  local message = GetMessageFromAmount(amount)
  
  _tipMessage.text = ReplaceContent(message, playername, amount)
  _tipperThumbnail:Unload()
  _tipperThumbnail:Load(playerId)

  LastPlayerId = playerId
end

_announcementContent:RegisterPressCallback(function()
  _announcement:AddToClassList("hidden")
end)

_ThumbnailOverlayClicker:RegisterPressCallback(function()
  if not LastPlayerId or LastPlayerId == nil then return end
  UI:OpenMiniProfile(LastPlayerId)
end)