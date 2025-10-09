--!Type(UI)

--!SerializeField
local checkpointCount : number = 0

--!Bind
local titleLabel : UILabel = nil
--!Bind
local progressSlider : UISlider = nil

progressSlider.highValue = checkpointCount

function UpdateMeter(arg)
    progressSlider:SetValueWithoutNotify(arg)
    titleLabel:SetPrelocalizedText(tostring(arg) .. " / " .. tostring(checkpointCount), true)
end

UpdateMeter(0)