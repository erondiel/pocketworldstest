--!Type(UI)

--!Tooltip("Message to display when a new check point is unlocked")
--!SerializeField
local _NewCheckPointMessage : string = "New Check Point Unlocked"

--!Tooltip("Duration of the flash")
--!SerializeField
local _FlashDuration : number = 0.8

--!Bind
local _TextLabel : Label = nil

function Init()
  _TextLabel.text = _NewCheckPointMessage
end

function Flash()
  view:RemoveFromClassList("hidden")
  Timer.After(_FlashDuration, function()
    view:AddToClassList("hidden")
  end)
end