--!Type(UI)

local MetaData = require("TipsMetaData")
local TipJarManager = require("TipJarManager")
local TipJarUtility = require("TipJarUtility")

--!Bind
local _container : VisualElement = nil

--!Bind
local _worldOwnerThumbnail : UIUserThumbnail = nil
--!Bind
local _worldOwnerName : Label = nil

--!Bind
local _amountSlider : UISlider = nil

--!Bind
local _goldAmountPreviewIcon : Image = nil
--!Bind
local _goldAmountPreviewAmount : Label = nil
--!Bind
local _sendTipButtonAmount : Label = nil

--!Bind
local _sendTipButton : VisualElement = nil
--!Bind
local _cancelButton : VisualElement = nil
--!Bind
local _closeOverlay : VisualElement = nil

--!Bind
local _messageInput : UITextField = nil
--!Bind
local _messageInputNote : VisualElement = nil

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

  _container.style.scale = StyleScale.new(Scale.new(scale))
end

function Init()
  _amountSlider.lowValue = 1
  _amountSlider.highValue = MetaData.GetGoldBarsCount()
  _amountSlider.value = 5

  _worldOwnerName.text = TipJarUtility.GetCreatorName()
  _worldOwnerThumbnail:Load(client.info.creatorId)

  local metadata = MetaData.GetGoldBarMetadataByIndex(5)

  if not metadata then return end

  _goldAmountPreviewIcon.image = metadata.Icon
  _goldAmountPreviewAmount.text = metadata.Name
  _sendTipButtonAmount.text = TipJarUtility.comma_value(metadata.Amount)

  _messageInput.textElement.text = ""
  _messageInput:SetPlaceholderText("Write a message...")

  InitializeScale()
end

function self:Start()
  Init()

  _amountSlider:RegisterCallback(IntChangeEvent, OnSliderChanged)
  _container:RegisterCallback(GeometryChangedEvent, InitializeScale)
end

function self:OnEnable()
  Init() -- Always initialize the UI when the drawer is enabled
end

function CloseUI()
  self.gameObject:SetActive(false)
end

function OnSliderChanged(event)
  local value = event.newValue
  local metadata = MetaData.GetGoldBarMetadataByIndex(value)

  if not metadata then return end

  if metadata.IsPremium then
    _messageInput:EnableInClassList("premium", true)
  else
    _messageInput:EnableInClassList("premium", false)
  end

  if metadata.CustomMessage then
    _messageInputNote:EnableInClassList("hidden", true)
    _messageInput:EnableInClassList("hidden", false)
  else
    _messageInputNote:EnableInClassList("hidden", false)
    _messageInput:EnableInClassList("hidden", true)
  end
  
  _goldAmountPreviewIcon.image = metadata.Icon
  _goldAmountPreviewAmount.text = metadata.Name
  _sendTipButtonAmount.text = TipJarUtility.comma_value(metadata.Amount)
end

_sendTipButton:RegisterPressCallback(function()
  local metadata = MetaData.GetGoldBarMetadataByIndex(_amountSlider.value)

  if metadata.CustomMessage and _messageInput.textElement.text ~= "" then
    -- Send the custom message to the server before prompting the purchase
    TipJarUtility.SendCustomMessageEvent:FireServer({
      productId = metadata.ItemId,
      message = _messageInput.textElement.text
    })
    
    -- We don't need to set the message locally as it won't be used
    -- The server will use the message we just sent
  else
    -- For non-custom messages, we use the default message
    -- The server will use the default message from TipsMetaData
  end

  TipJarManager.SendTip(metadata)
  TipJarUtility.CloseAllUI()
end)

_cancelButton:RegisterPressCallback(CloseUI)
_closeOverlay:RegisterPressCallback(CloseUI)