--!Type(UI)

local Utils = require("devx_utils")
local Tweens = require("devx_tweens")

local Products = require("devx_product_manager")

local Tween = Tweens.Tween
local Easing = Tweens.Easing

-- Animation constants
local POP_SCALE = 1.05
local POP_DURATION = 0.2
local ITEM_DELAY = 0.1
local FADE_DURATION = 0.3

type Deal = {
  id: string,
  name: string,
  description: string,
  price: number,
  icon: Texture,
  value: number,
}

--!Bind
local _ShopContent : UIScrollView = nil
--!Bind
local _ShopEmptyState : VisualElement = nil
--!Bind
local _CloseButton : VisualElement = nil


--[[
  ClearShopContent: Clears the shop content.
]]
local function ClearShopContent()
  _ShopContent:Clear()
end

--[[
  CloseShop: Closes the shop.
]]
function CloseShop()
  local fadeOutTween = Tween:new(
    1,
    0,
    FADE_DURATION,
    false,
    false,
    Easing.InQuad,
    function(value)
      view.style.opacity = StyleFloat.new(value)
    end
  )

  local scaleDownTween = Tween:new(
    1,
    0.8,
    POP_DURATION,
    false,
    false,
    Easing.InQuad,
    function(value)
      view.style.scale = StyleScale.new(Scale.new(Vector2.new(value, value)))
    end,
    function()
      -- Reset view state before hiding
      view.style.scale = StyleScale.new(Scale.new(Vector2.new(0.8, 0.8)))
      view.style.opacity = StyleFloat.new(0)
      
      SetContentHeight(0, {}, 0)
      ClearShopContent()
      self.gameObject:SetActive(false)
    end
  )

  fadeOutTween:start()
  scaleDownTween:start()
end

--[[
  CreateShopItem: Creates a shop item.
  @param deal: Deal
  @return VisualElement
]]
local function CreateShopItem(deal: Deal): VisualElement
  local _ShopItem = VisualElement.new()
  _ShopItem:AddToClassList("shop-item")

  _ShopItem.style.scale = StyleScale.new(Scale.new(Vector2.new(0.5, 0.5)))
  _ShopItem.style.opacity = StyleFloat.new(0)

  local _ItemContent = VisualElement.new()
  _ItemContent:AddToClassList("item-content")

  local _ItemName = Label.new()
  _ItemName:AddToClassList("item-name")
  _ItemName.text = deal.name

  local _ItemAmountLabel = Label.new()
  _ItemAmountLabel:AddToClassList("item-amount-label")
  _ItemAmountLabel.text = "x" .. Utils.FormatNumber(deal.value)

  _ItemContent:Add(_ItemName)
  _ItemContent:Add(_ItemAmountLabel)

  local _ItemImage = Image.new()
  _ItemImage:AddToClassList("shop-image")
  _ItemImage.image = deal.icon

  local _PriceContainer = VisualElement.new()
  _PriceContainer:AddToClassList("price-container")

  local _PriceImage = Image.new()
  _PriceImage:AddToClassList("gold-icon")

  local _PriceLabel = Label.new()
  _PriceLabel:AddToClassList("price-label")
  _PriceLabel.text = tostring(deal.price)

  _PriceContainer:Add(_PriceImage)
  _PriceContainer:Add(_PriceLabel)

  _ShopItem:RegisterPressCallback(function()
    Utils.Prompt(deal.id, function(paid: boolean)
      if paid then
        CloseShop()
      end
    end)
  end)

  _ShopItem:Add(_ItemContent)
  _ShopItem:Add(_ItemImage)
  _ShopItem:Add(_PriceContainer)

  return _ShopItem
end

--[[
  AnimateShopItem: Animates a shop item.
  @param item: VisualElement
  @param delay: number
]]
local function AnimateShopItem(item: VisualElement, delay: number)
  local fadeInTween = Tween:new(
    0,
    1,
    FADE_DURATION,
    false,
    false,
    Easing.OutQuad,
    function(value)
      item.style.opacity = StyleFloat.new(value)
    end
  )

  local scaleUpTween = Tween:new(
    0.5,
    POP_SCALE,
    POP_DURATION,
    false,
    false,
    Easing.OutBack,
    function(value)
      item.style.scale = StyleScale.new(Scale.new(Vector2.new(value, value)))
    end,
    function()
      -- Scale back to normal
      local scaleBackTween = Tween:new(
        POP_SCALE,
        1,
        POP_DURATION,
        false,
        false,
        Easing.InQuad,
        function(value)
          item.style.scale = StyleScale.new(Scale.new(Vector2.new(value, value)))
        end
      )
      scaleBackTween:start()
    end
  )
  function StartAnimation()
    fadeInTween:start()
    scaleUpTween:start()
  end

  Timer.After(delay, StartAnimation)
end

--[[
  PopulateShop: Populates the shop.
]]
function PopulateShop()
  ClearShopContent()

  local deals = Products.GetDeals()
  local dealsArray = {}
  for _, deal in pairs(deals) do
    table.insert(dealsArray, deal)
  end

  if not dealsArray or #dealsArray == 0 then
    _ShopEmptyState:RemoveFromClassList("hidden")
    return
  else
    if not _ShopEmptyState:ClassListContains("hidden") then
      _ShopEmptyState:AddToClassList("hidden")
    end
  end

  local index = 0
  local firstElement = nil

  table.sort(dealsArray, function(a, b)
    return a.price < b.price
  end)

  for _, deal in ipairs(dealsArray) do
    local element = CreateShopItem(deal)
    _ShopContent:Add(element)

    if index == 0 then
      firstElement = element
    end

    AnimateShopItem(element, index * ITEM_DELAY)
    index = index + 1
  end

  if firstElement then
    _ShopContent:ScrollTo(firstElement)
  end

  SetContentHeight(index, dealsArray, nil)
end

function self:Awake()
  -- Reset view state
  view.style.scale = StyleScale.new(Scale.new(Vector2.new(0.8, 0.8)))
  view.style.opacity = StyleFloat.new(0)
end

function InitializeView()
  view.style.scale = StyleScale.new(Scale.new(Vector2.new(0.8, 0.8)))
  view.style.opacity = StyleFloat.new(0)
 
  local fadeInTween = Tween:new(
    0,
    1,
    FADE_DURATION,
    false,
    false,
    Easing.OutQuad,
    function(value)
      view.style.opacity = StyleFloat.new(value)
    end
  )

  local scaleUpTween = Tween:new(
    0.8,
    POP_SCALE,
    POP_DURATION,
    false,
    false,
    Easing.OutBack,
    function(value)
      view.style.scale = StyleScale.new(Scale.new(Vector2.new(value, value)))
    end,
    function()
      -- Scale back to normal
      local scaleBackTween = Tween:new(
        POP_SCALE,
        1,
        POP_DURATION,
        false,
        false,
        Easing.InQuad,
        function(value)
          view.style.scale = StyleScale.new(Scale.new(Vector2.new(value, value)))
        end,
        function()
          -- Only populate content after the view animation is complete
          PopulateShop()
        end
      )
      scaleBackTween:start()
    end
  )

  -- Start animations
  fadeInTween:start()
  scaleUpTween:start()
end

function self:OnEnable()
  InitializeView()
end

function self:OnDisable()
  ClearShopContent()
end

--[[
  SetContentHeight: Sets the content height.
  @param index: number
  @param deals: {Deal}
  @param height: number | nil
]]
function SetContentHeight(index: number, deals: {Deal}, height: number | nil)
  local scrollView = _ShopContent:Q("unity-content-container")
  Timer.After(index * ITEM_DELAY + FADE_DURATION, function()
    if height then
      scrollView.style.height = StyleLength.new(Length.new(height))
    else
      scrollView.style.height = StyleLength.new(Length.new((#deals / 2) * 180))
    end
  end)
end

_CloseButton:RegisterPressCallback(CloseShop)