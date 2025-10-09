--!Type(UI)

local Utils = require("devx_utils")
local Tweens = require("devx_tweens")
local UIManager = require("devx_ui_manager")
local PlayerTracker = require("devx_player_tracker")

local Tween = Tweens.Tween
local Easing = Tweens.Easing

--!Bind
local _CurrencyContainer : VisualElement = nil
--!Bind
local _CurrencyLabel : Label = nil
--!Bind
local _CurrencyPlaceholder : Label = nil
--!Bind
local _LeftContainer : VisualElement = nil
--!Bind
local _RightContainer : VisualElement = nil

type Sides = "left" | "right"

-- Button Tween
local POP_SCALE : number = 1.2
local POP_DURATION : number = 0.2
local BUTTON_DELAY : number = 0.1
local FADE_DURATION : number = 0.3
local STATE_CHANGE_DURATION : number = 0.2

-- Currency Floating Number
local FLOAT_DISTANCE : number = 50
local FLOAT_DURATION : number = 1.0


local buttons = { 
  ranks = nil,
  shop = nil
}

--[[
  CreateHudButton: Creates a HUD button.
  @param text: string
  @param iconId: string
  @param side: Sides
  @param callback: () -> ()
  @return VisualElement
]]
function CreateHudButton(text: string, iconClass: string, side: Sides, callback: () -> ()): VisualElement
  local iconClass = iconClass or "devx_icon_default"

  local _ButtonContainer = VisualElement.new()
  _ButtonContainer:AddToClassList("button-container")

  _ButtonContainer.style.scale = StyleScale.new(Scale.new(Vector2.new(0.5, 0.5)))
  _ButtonContainer.style.opacity = StyleFloat.new(0)

  local _ButtonIcon = VisualElement.new()
  _ButtonIcon:AddToClassList("button-icon")
  _ButtonIcon:AddToClassList(iconClass)

  local _ButtonLabel = Label.new()
  _ButtonLabel:AddToClassList("button-label")
  _ButtonLabel.text = text

  _ButtonContainer:Add(_ButtonIcon)
  _ButtonContainer:Add(_ButtonLabel)

  if side == "left" then
    _LeftContainer:Add(_ButtonContainer)
  else
    _RightContainer:Add(_ButtonContainer)
  end

  _ButtonContainer:AddToClassList(side .. "-side")
  _ButtonContainer:RegisterPressCallback(callback)

  local fadeInTween = Tween:new(
    0,
    1,
    FADE_DURATION,
    false,
    false,
    Easing.OutQuad,
    function(value)
      _ButtonContainer.style.opacity = StyleFloat.new(value)
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
      _ButtonContainer.style.scale = StyleScale.new(Scale.new(Vector2.new(value, value)))
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
          _ButtonContainer.style.scale = StyleScale.new(Scale.new(Vector2.new(value, value)))
        end
    )
    scaleBackTween:start()
  end)

  local delay = side == "left" and 0 or BUTTON_DELAY
  Timer.After(delay, function()
    fadeInTween:start()
    scaleUpTween:start()
  end)

  return _ButtonContainer
end

--[[
  CreateFloatingNumber: Creates a floating number.
  @param amount: number
  @param parentElement: VisualElement
  @return VisualElement
]]
function CreateFloatingNumber(amount: number, addition: boolean, parentElement: VisualElement): VisualElement
  local floatingNumber = Label.new()
  floatingNumber:AddToClassList("floating-number")
  floatingNumber.text = addition and "+" .. tostring(amount) or "-" .. tostring(amount)
  
  -- Position relative to the parent element
  floatingNumber.style.left = Length.new(0)
  floatingNumber.style.top = Length.new(0)

  if addition then
    floatingNumber.style.color = Color.new(0, 1, 0, 1) -- Green color
  else
    floatingNumber.style.color = Color.new(1, 0, 0, 1) -- Red color
  end

  -- Add to parent element instead of hud
  parentElement:Add(floatingNumber)
  
  -- Animate floating up and fading out
  local startY = 0
  local endY = -FLOAT_DISTANCE
  
  local floatTween = Tween:new(
    startY,
    endY,
    FLOAT_DURATION,
    false,
    true,
    Easing.OutQuad,
    function(value)
      floatingNumber.style.top = Length.new(value)
    end
  )
  
  local fadeTween = Tween:new(
    1,
    0,
    FLOAT_DURATION,
    false,
    true,
    Easing.Linear,
    function(value)
      floatingNumber.style.opacity = StyleFloat.new(value)
    end,
    function()
      parentElement:Remove(floatingNumber)
    end
  )
  
  floatTween:start()
  fadeTween:start()

  return floatingNumber
end

function UpdateCurrency(newValue: number, oldValue: number)
  local earnedAmount = newValue - oldValue

  local floatingNumber = CreateFloatingNumber(earnedAmount, earnedAmount > 0, _CurrencyContainer)

  local popTween = Tween:new(
    1,
    POP_SCALE,
    POP_DURATION,
    false,
    true,
    Easing.OutQuad,
    function(value)
      _CurrencyContainer.style.scale = StyleScale.new(Scale.new(Vector2.new(value, value)))
    end,
    function()
      -- Pop back
      local popBackTween = Tween:new(
        POP_SCALE,
        1,
        POP_DURATION,
        false,
        true,
        Easing.InQuad,
        function(value)
          _CurrencyContainer.style.scale = StyleScale.new(Scale.new(Vector2.new(value, value)))
        end
      )
      popBackTween:start()
    end
  )

  local originalColor = _CurrencyContainer.style.unityBackgroundImageTintColor
  local flashColor = earnedAmount > 0 and StyleColor.new(Color.new(1, 1, 0, 1)) or StyleColor.new(Color.new(1, 0, 0, 1)) -- Yellow for positive, Red for negative

  local colorTween = Tween:new(
    0,
    1,
    POP_DURATION * 2,
    false,
    true,
    Easing.InOutQuad,
    function(value)
      _CurrencyContainer.style.unityBackgroundImageTintColor = StyleColor.new(Color.Lerp(originalColor.value, flashColor.value, value))
    end,
    function()
      -- Return to original color
      local colorBackTween = Tween:new(
        1,
        0,
        POP_DURATION * 2,
        false,
        true,
        Easing.InOutQuad,
        function(value)
          _CurrencyContainer.style.unityBackgroundImageTintColor = StyleColor.new(Color.Lerp(originalColor.value, flashColor.value, value))
        end
      )
      colorBackTween:start()
    end
  )

  local currencyTween = Tween:new(
    oldValue,
    newValue,
    POP_DURATION,
    false,
    true,
    Easing.OutQuad,
    function(value)
      _CurrencyLabel.text = Utils.FormatNumber(math.floor(value))
    end,
    function()
      _CurrencyLabel.text = Utils.FormatNumber(newValue)
    end
  )

  popTween:start()
  colorTween:start()
  currencyTween:start()
end

function self:Start()
  Timer.After(0, function()
    buttons.ranks = CreateHudButton("Ranks", "ranks-icon", "right", function()
      UIManager.OpenLeaderboard()
    end)
  end)

  Timer.After(0.5, function()
    buttons.shop = CreateHudButton("Shop", "shop-icon", "right", function()
      UIManager.OpenShop()
    end)
  end)

  PlayerTracker.getPlayerInfo(client.localPlayer).currency.Changed:Connect(UpdateCurrency)
end