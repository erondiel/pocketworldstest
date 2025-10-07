--[[
    DebugMenu (Client)
    Visual overlay showing current phase/timer/role and quick force-state buttons.
    Long-press cheats remain available, but this menu gives immediate feedback.
]]

--!Type(Module)

-- Network events (must match server names)
local stateChangedEvent = Event.new("PH_StateChanged")
local roleAssignedEvent = Event.new("PH_RoleAssigned")
local debugEvent = Event.new("PH_Debug")
local forceStateRequest = RemoteFunction.new("PH_ForceState")

local root = nil
local stateLabel = nil
local timerLabel = nil
local roleLabel = nil
local stateTimer = 0
local currentState = "LOBBY"
local localRole = "unknown"

local function FormatState(value)
    if type(value) == "number" then
        if value == 1 then return "LOBBY"
        elseif value == 2 then return "HIDING"
        elseif value == 3 then return "HUNTING"
        elseif value == 4 then return "ROUND_END"
        end
        return tostring(value)
    end
    return tostring(value)
end

local function UpdateLabels()
    if stateLabel then
        stateLabel.text = string.format("State: %s", currentState)
    end
    if timerLabel then
        timerLabel.text = string.format("Timer: %.0fs", math.max(0, stateTimer))
    end
    if roleLabel then
        roleLabel.text = string.format("Role: %s", localRole)
    end
end

local function ForceState(name)
    forceStateRequest:InvokeServer(name, function(ok, msg)
        print("[DebugMenu] ForceState", name, ok, msg)
    end)
end

local function CreateButton(text, callback)
    local btn = VisualElement.new()
    btn.style.flexDirection = FlexDirection.Column
    btn.style.justifyContent = Justify.Center
    btn.style.alignItems = Align.Center
    btn.style.marginRight = 4
    btn.style.marginTop = 4
    btn.style.paddingLeft = 8
    btn.style.paddingRight = 8
    btn.style.paddingTop = 6
    btn.style.paddingBottom = 6
    btn.style.backgroundColor = Color.new(0.2, 0.2, 0.2, 0.8)
    btn.style.borderBottomLeftRadius = 4
    btn.style.borderBottomRightRadius = 4
    btn.style.borderTopLeftRadius = 4
    btn.style.borderTopRightRadius = 4
    btn.style.flexGrow = 1

    local label = UILabel.new()
    label.text = text
    label.style.unityFontStyleAndWeight = FontStyle.Bold
    btn:Add(label)

    btn:RegisterPressCallback(function()
        callback()
    end)

    return btn
end

local function BuildUI()
    root = VisualElement.new()
    local style = root.style
    style.flexDirection = FlexDirection.Column
    style.paddingLeft = 10
    style.paddingRight = 10
    style.paddingTop = 8
    style.paddingBottom = 8
    style.backgroundColor = Color.new(0, 0, 0, 0.55)
    style.borderBottomLeftRadius = 6
    style.borderBottomRightRadius = 6
    style.borderTopLeftRadius = 6
    style.borderTopRightRadius = 6
    style.position = Position.Absolute
    style.left = 12
    style.bottom = 12
    style.minWidth = 220
    style.maxWidth = 320

    stateLabel = UILabel.new()
    stateLabel.style.unityFontStyleAndWeight = FontStyle.Bold
    timerLabel = UILabel.new()
    roleLabel = UILabel.new()

    root:Add(stateLabel)
    root:Add(timerLabel)
    root:Add(roleLabel)

    local buttonRow1 = VisualElement.new()
    buttonRow1.style.flexDirection = FlexDirection.Row
    buttonRow1.style.marginTop = 6

    local buttonRow2 = VisualElement.new()
    buttonRow2.style.flexDirection = FlexDirection.Row

    buttonRow1:Add(CreateButton("Lobby", function() ForceState("LOBBY") end))
    buttonRow1:Add(CreateButton("Hide", function() ForceState("HIDING") end))
    buttonRow2:Add(CreateButton("Hunt", function() ForceState("HUNTING") end))
    buttonRow2:Add(CreateButton("End", function() ForceState("ROUND_END") end))

    root:Add(buttonRow1)
    root:Add(buttonRow2)

    UI.hud:Add(root)
    UpdateLabels()
end

function self:ClientStart()
    print("[DebugMenu] ClientStart")
    BuildUI()

    stateChangedEvent:Connect(function(newState, timer)
Seri        print("[DebugMenu] State changed:", newState, timer)
        currentState = FormatState(newState)
        stateTimer = tonumber(timer) or 0
        print("[DebugMenu] Formatted state:", currentState, stateTimer)
        UpdateLabels()
    end)

    roleAssignedEvent:Connect(function(role)
        localRole = tostring(role)
        UpdateLabels()
    end)

    debugEvent:Connect(function(kind, a, b, c)
        print("[Debug]", tostring(kind), tostring(a), tostring(b), tostring(c))
    end)
end

function self:Update()
    if stateTimer > 0 then
        stateTimer = math.max(0, stateTimer - Time.deltaTime)
        UpdateLabels()
    end
end
