--!Type(UI)

-- Modules
local TipsMetaData = require("TipsMetaData")
local TipJarManager = require("TipJarManager")
local TipJarUtility = require("TipJarUtility")
local TweenModule = require("TweenModule")

--!Bind
local _contentHeader : VisualElement = nil

-- Buttons
--!Bind
local _closeButton : VisualElement = nil
--!Bind
local _MessagesButton : VisualElement = nil
--!Bind
local _TopTippersButton : VisualElement = nil

-- Containers
--!Bind
local _content : UIScrollView = nil
--!Bind
local _messagesList : VisualElement = nil
--!Bind
local _TopTippers : VisualElement = nil
--!Bind
local _loadingContainer : VisualElement = nil
--!Bind
local _loadingSpinner : VisualElement = nil

--!Bind
local _emptyState : VisualElement = nil 

--!Bind
local _sendTipButton : VisualElement = nil
--!Bind
local _closeOverlay : VisualElement = nil

local _HeightOffset : number = 50
local _MessageItemHeight : number = 100

local _CurrentView : string = "Messages" -- Messages, TopTippers

local CachedTopTippers = {}
local CachedTippingMessages = {}

-- Tween variables
local Tween = TweenModule.Tween
local Easing = TweenModule.Easing
local spinnerTween = nil

local function InitializeScale()
  if not view.parent then 
      return
  end

  local width = view.worldBound.width

  if width == 0 or width ~= width then 
      return
  end

  -- Scale between 0.8 and 1.0 based on screen width
  -- 300px or less = 0.8 scale
  -- 700px = 0.9 scale
  -- 1200px or more = 1.0 scale (capped to avoid oversized UI)
  local t = math.clamp((width - 300) / (1200 - 300), 0, 1)
  local scaleValue = 0.8 + t * (1.0 - 0.8)
  local scale = Vector2.new(scaleValue, scaleValue)

  view.style.scale = StyleScale.new(Scale.new(scale))
end

--[[
  -- Function to start the spinner animation
]]
local function StartSpinnerAnimation()
  -- Stop existing tween if any
  if spinnerTween then
    spinnerTween:stop()
  end

  -- Create a continuous rotation tween from 0 to 360 degrees
  spinnerTween = Tween:new(
    0,           -- from: 0 degrees
    360,         -- to: 360 degrees
    1,           -- duration: 1 second per rotation
    true,        -- loop: continuous
    false,       -- pingPong: false (we want continuous rotation)
    Easing.linear, -- easing: linear for smooth rotation
    function(value)
      -- Update the spinner's rotation
      _loadingSpinner.style.rotate = StyleRotate.new(Rotate.new(Angle.new(value)))
    end
  )

  spinnerTween:start()
end

--[[
  -- Function to stop the spinner animation
]]
local function StopSpinnerAnimation()
  if spinnerTween then
    spinnerTween:stop()
    spinnerTween = nil
  end
end

--[[
  -- Function to clear the elements in the grid
]]
local function ClearElements()
  _messagesList:Clear()
  _TopTippers:Clear()
end

--[[
  -- Function to create a message item
  -- @param data: table
  -- @return _message_item: VisualElement
]]
local function CreateMessageItem(data)
  local _message_item = VisualElement.new()
  _message_item:AddToClassList("message-item")

  local _player_avatar_container = VisualElement.new()
  _player_avatar_container:AddToClassList("player-avatar-container")

  local _player_avatar_container_thumbnail = UIUserThumbnail.new()
  _player_avatar_container_thumbnail:AddToClassList("player-avatar-container__thumbnail")
  _player_avatar_container:Add(_player_avatar_container_thumbnail)
  _player_avatar_container_thumbnail:Load(data.PlayerId)

  local _player_avatar_container_thumbnail_overlay = VisualElement.new()
  _player_avatar_container_thumbnail_overlay:AddToClassList("player-avatar-container__thumbnail__overlay")
  _player_avatar_container:Add(_player_avatar_container_thumbnail_overlay)
  _player_avatar_container_thumbnail_overlay:RegisterPressCallback(function()
    UI:OpenMiniProfile(data.PlayerId)
  end)

  _message_item:Add(_player_avatar_container)

  local _message_content_container = VisualElement.new()
  _message_content_container:AddToClassList("message-content-container")

  local _message_content_container_header = VisualElement.new()
  _message_content_container_header:AddToClassList("message-content-container-header")

  local _player_name = Label.new()
  _player_name:AddToClassList("player-name")
  _player_name.text = data.PlayerName
  _message_content_container_header:Add(_player_name)

  local _message_time = Label.new()
  _message_time:AddToClassList("message-time")
  _message_time.text = TipJarUtility.ConvertToLocalTime(data.Time)
  _message_content_container_header:Add(_message_time)
  _message_content_container:Add(_message_content_container_header)

  local _message_content_container_body = VisualElement.new()
  _message_content_container_body:AddToClassList("message-content-container-body")

  local _message_content = UILabel.new()
  _message_content:AddToClassList("message-content")
  _message_content:SetEmojiPrelocalizedText(data.Message)
  _message_content_container_body:Add(_message_content)

  local _message_tip_amount = VisualElement.new()
  _message_tip_amount:AddToClassList("message-tip-amount")

  local _message_tip_amount_icon = UILabel.new()
  _message_tip_amount_icon:AddToClassList("message-tip-amount__icon")
  _message_tip_amount_icon:SetEmojiPrelocalizedText("💰")
  _message_tip_amount:Add(_message_tip_amount_icon)

  local _message_tip_amount_label = Label.new()
  _message_tip_amount_label:AddToClassList("message-tip-amount__label")
  _message_tip_amount_label.text = TipJarUtility.comma_value(data.Amount) .. " Gold"
  _message_tip_amount:Add(_message_tip_amount_label)

  _message_content_container_body:Add(_message_tip_amount)
  _message_content_container:Add(_message_content_container_body)

  _message_item:Add(_message_content_container)

  if data.IsPremium then
    _message_item:EnableInClassList("premium", true)
  end

  return _message_item
end

--[[
  -- Function to create a top tipper item
  -- @param data: table
  -- @return _top_tippers_item: VisualElement
]]
local function CreateTopTipperItem(data)
  local _top_tippers_item = VisualElement.new()
  _top_tippers_item:AddToClassList("top-tippers-item")
  local _top_tippers_item_position = Label.new()

  _top_tippers_item_position:AddToClassList("top-tippers-item__position")
  _top_tippers_item_position.text = data.Position .. " ."
  _top_tippers_item:Add(_top_tippers_item_position)

  local _top_tippers_item_player = VisualElement.new()
  _top_tippers_item_player:AddToClassList("top-tippers-item__player")

  local _top_tippers_item_player_thumbnail = UIUserThumbnail.new()
  _top_tippers_item_player_thumbnail:AddToClassList("top-tippers-item__player__thumbnail")
  _top_tippers_item_player:Add(_top_tippers_item_player_thumbnail)

  local _top_tippers_item_player_thumbnail_overlay = VisualElement.new()
  _top_tippers_item_player_thumbnail_overlay:AddToClassList("top-tippers-item__player__thumbnail__overlay")
  _top_tippers_item_player:Add(_top_tippers_item_player_thumbnail_overlay)
  _top_tippers_item_player_thumbnail_overlay:RegisterPressCallback(function()
    UI:OpenMiniProfile(data.PlayerId)
  end)

  local _top_tippers_item_player_name = Label.new()
  _top_tippers_item_player_name:AddToClassList("top-tippers-item__player__name")
  _top_tippers_item_player_name.pickingMode = PickingMode.Ignore

  _top_tippers_item_player_name.text = data.PlayerName
  _top_tippers_item_player:Add(_top_tippers_item_player_name)
  _top_tippers_item:Add(_top_tippers_item_player)

  local _top_tippers_item_content = VisualElement.new()
  _top_tippers_item_content:AddToClassList("top-tippers-item__content")

  local _top_tippers_item_content_icon = Image.new()
  _top_tippers_item_content_icon:AddToClassList("top-tippers-item__content__icon")
  _top_tippers_item_content:Add(_top_tippers_item_content_icon)

  local _top_tippers_item_content_label = Label.new()
  _top_tippers_item_content_label:AddToClassList("top-tippers-item__content__label")
  _top_tippers_item_content_label.text = TipJarUtility.comma_value(data.Amount) or data.Amount
  _top_tippers_item_content:Add(_top_tippers_item_content_label)
  _top_tippers_item:Add(_top_tippers_item_content)

  return {TopTippersItem = _top_tippers_item, PlayerThumbnail = _top_tippers_item_player_thumbnail}
end

--[[
  -- Function to populate the top tippers
]]
local function PopulateTopTippers()
  ClearElements()

  _messagesList:AddToClassList("hidden")
  _TopTippers:RemoveFromClassList("hidden")

  if CachedTopTippers == nil or #CachedTopTippers == 0 then return end

  -- Sort the top tippers by amount in descending order
  table.sort(CachedTopTippers, function(a, b)
    return a.Amount > b.Amount
  end)

  -- Add the sorted top tippers to the grid
  for key, value in ipairs(CachedTopTippers) do
    if key > TipJarUtility.GetTopTippersLimit() then break end  -- Limit to top 50 tippers
    value.Position = key
    value.PlayerId = value.Id
    value.PlayerName = value.Name

    local _top_tippers_item = CreateTopTipperItem(value)
    _TopTippers:Add(_top_tippers_item.TopTippersItem)
    _top_tippers_item.PlayerThumbnail:Load(value.Id)

  end
end

--[[
  -- Function to check if we should show empty state
]]
local function CheckEmptyState()
  local hasTopTippers = CachedTopTippers and #CachedTopTippers > 0
  local hasTippingMessages = CachedTippingMessages and #CachedTippingMessages > 0
  
  if not hasTopTippers and not hasTippingMessages then
    -- Show empty state
    _emptyState:RemoveFromClassList("hidden")
    _messagesList:AddToClassList("hidden")
    _TopTippers:AddToClassList("hidden")
    _contentHeader:AddToClassList("hidden")
    return true
  else
    -- Hide empty state
    _emptyState:AddToClassList("hidden")
    _contentHeader:RemoveFromClassList("hidden")
    return false
  end
end

--[[
  -- Function to populate the messages
]]
local function PopulateMessages()
  -- Clear the grid
  ClearElements()

  if CachedTippingMessages == nil or #CachedTippingMessages == 0 then return end

  local messagesCount = 0

  -- Add the sorted messages to the grid
  for _, value in ipairs(CachedTippingMessages) do
    if messagesCount > TipJarUtility.GetTippingMessagesLimit() then break end
    
    value.IsPremium = value.Amount and value.Amount >= 5000
    local _message_item = CreateMessageItem(value)
    _messagesList:Add(_message_item)

    messagesCount = messagesCount + 1
  end

  local calculatedHeight = messagesCount * _MessageItemHeight + _HeightOffset
  _messagesList.style.height = StyleLength.new(Length.new(calculatedHeight))
  _content:ScrollToBeginning()

  _TopTippers:AddToClassList("hidden")
  _messagesList:RemoveFromClassList("hidden")
end

--------------------- BUTTONS ---------------------
-- Close button
_closeButton:RegisterPressCallback(function()
  self.gameObject:SetActive(false)
end)

-- Close overlay
_closeOverlay:RegisterPressCallback(function()
  self.gameObject:SetActive(false)
end)

-- Tip button
_MessagesButton:RegisterPressCallback(function()
  if _CurrentView == "Messages" then
    return
  end

  _CurrentView = "Messages"

  if _messagesList:ClassListContains("hidden") then
    -- Check if we should show empty state
    local isEmpty = CheckEmptyState()
    
    if not isEmpty then
      PopulateMessages()

      _TopTippersButton:RemoveFromClassList("active")
      _MessagesButton:AddToClassList("active")
      _contentHeader:EnableInClassList("hidden", false)
    end
  end
end)

-- Top tippers button
_TopTippersButton:RegisterPressCallback(function()
  if _CurrentView == "TopTippers" then
    return
  end

  _CurrentView = "TopTippers"

  if _TopTippers:ClassListContains("hidden") then
    -- Check if we should show empty state
    local isEmpty = CheckEmptyState()
    
    if not isEmpty then
      PopulateTopTippers()

      _MessagesButton:RemoveFromClassList("active")
      _TopTippersButton:AddToClassList("active")
      _contentHeader:EnableInClassList("hidden", true)
    end
  end
end)

function self:Start()
  InitializeScale()
  view:RegisterCallback(GeometryChangedEvent, InitializeScale)
end

function self:OnEnable()
  -- Always show loading state for 1 second
  _loadingContainer:RemoveFromClassList("hidden")
  _messagesList:AddToClassList("hidden")
  _TopTippers:AddToClassList("hidden")
  _emptyState:AddToClassList("hidden") -- Hide empty state during loading
  
  -- Disable navigation buttons during loading
  _MessagesButton:SetEnabled(false)
  _TopTippersButton:SetEnabled(false)
  
  -- Start the spinner animation
  StartSpinnerAnimation()
  
  -- Cache the data using the combined function
  TipJarManager.ClientGetTipJarData(function(topTippers, tippingMessages)
    CachedTopTippers = topTippers
    CachedTippingMessages = tippingMessages
    
    -- Wait 1 second before hiding loading state
    Timer.After(1, function()
      -- Stop the spinner animation
      StopSpinnerAnimation()
      
      -- Hide loading state
      _loadingContainer:AddToClassList("hidden")
      
      -- Re-enable navigation buttons
      _MessagesButton:SetEnabled(true)
      _TopTippersButton:SetEnabled(true)
      
      -- Check if we should show empty state
      local isEmpty = CheckEmptyState()
      
      if not isEmpty then
        -- Default to messages view
        _CurrentView = "Messages"
        
        -- Set button states
        _MessagesButton:AddToClassList("active")
        _TopTippersButton:RemoveFromClassList("active")
        _contentHeader:EnableInClassList("hidden", false)

        PopulateMessages()
      end
    end)
  end)
end

_sendTipButton:RegisterPressCallback(function()
  TipJarUtility.OpenTipJarDrawer()
end)

function self:OnDestroy()
  -- Clean up the spinner tween
  StopSpinnerAnimation()
end