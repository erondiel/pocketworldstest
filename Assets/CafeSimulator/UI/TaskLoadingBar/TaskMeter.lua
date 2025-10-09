--!Type(UI)

--!Bind
-- Binding the VisualElement for the task UI
local taskUi : VisualElement = nil

--!Bind
-- Binding the UILabel for displaying the first title
local titleLabel1 : UILabel = nil

--!Bind
-- Binding the UILabel for displaying the second title
local titleLabel2 : UILabel = nil

--!Bind
-- Binding the UISlider for displaying task progress
local progressSlider : UISlider = nil

-- Set the low and high values for the progress slider
progressSlider.lowValue, progressSlider.highValue = 0, 100

-- Importing the PlayerManager module to handle player-related functionalities
local playerManager = require("PlayerManager")

-- Function to update the meter value of the progress slider
function UpdateMeter(arg)
    progressSlider:SetValueWithoutNotify(arg)
end

-- Function to update the titles displayed on the UI
function UpdateTitles(Name, Xp)
    titleLabel1:SetPrelocalizedText("lvl " .. tostring((Xp/100) + 1), true)
    titleLabel2:SetPrelocalizedText(Name, true)
end

-- Function to set the visibility of the task UI
function SetVisible(hidden)
    taskUi:EnableInClassList("hiden", not hidden)
end

-- Variables for meter control
local runDuration = 10
local cooldDuration = 10
local elapsedTime = 0
local value = 0
local running = false
local cooling = false

-- Function to start the meter with specified durations
function StartMeter(duration, coolDown)
    runDuration = duration
    cooldDuration = coolDown
    elapsedTime = 0
    value = 0
    running = true
    cooling = false
    progressSlider:EnableInClassList("slider-cooldown", false)
end

-- Function to cancel the meter
function CancelMeter()
    elapsedTime = 0
    value = 0
    running = false
    cooling = false
    progressSlider:EnableInClassList("slider-cooldown", false)
    UpdateMeter(0)
end

-- Function called when the script starts
function self:Start()
    UpdateMeter(0)

    -- Listen for changes in the player's role and set the visibility of the task UI accordingly
    playerManager.players[client.localPlayer].Role.Changed:Connect(function(newVal, oldVal)
        SetVisible(newVal == 1)
    end)
end

-- Function called every frame
function self:Update()
    -- Update the meter if it's running
    if running then
        elapsedTime = elapsedTime + Time.deltaTime

        local t = Mathf.Clamp01(elapsedTime / runDuration)
        value = Mathf.Lerp(0.0, 1.0, t)

        UpdateMeter(value * 100)

        if t >= 1 then
            t = 1
            running = false
            cooling = true
            elapsedTime = 0
            progressSlider:EnableInClassList("slider-cooldown", true)
        end
    end

    -- Update the meter if it's cooling down
    if cooling then
        elapsedTime = elapsedTime + Time.deltaTime

        local t = Mathf.Clamp01(elapsedTime / cooldDuration)
        value = Mathf.Lerp(1.0, 0.0, t)

        UpdateMeter(value * 100)

        if t >= 1 then
            t = 1
            running = false
            cooling = false
            progressSlider:EnableInClassList("slider-cooldown", false)
        end
    end
end
