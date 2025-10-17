--[[
    PropHuntRangeIndicator (Client)
    Manages the visual range indicator for hunters during the Hunt phase.
    Shows a 4.0m radius circle around hunters to visualize their tag range.

    Integration:
    - Listens to role assignment events from PropHuntGameManager
    - Listens to state change events to show/hide indicator
    - Uses the RangeIndicatorManager API for visual display
    - Coordinates with HunterTagSystem for consistent tag range visualization
]]

--!Type(Client)

--!Tooltip("The range indicator prefab from the Range Indicator asset")
--!SerializeField
local _RangeIndicatorPrefab : GameObject = nil

--!Tooltip("The color of the hunter's range indicator (default: red/orange for hunter theme)")
--!SerializeField
local _IndicatorColor : Color = Color.new(1.0, 0.3, 0.1, 0.6) -- Orange-red with transparency

--!Tooltip("Enable breathing animation for the range indicator")
--!SerializeField
local _EnableBreathingAnimation : boolean = true

--!Tooltip("Speed of the breathing animation")
--!SerializeField
local _AnimationSpeed : number = 1.5

-- Import required modules
local Config = require("PropHuntConfig")
local PlayerManager = require("PropHuntPlayerManager")

-- Use DevBasics Toolkit tween system (compatible with Range Indicator asset)
local devx_tweens = require("devx_tweens")
local Tween = devx_tweens.Tween
local Easing = devx_tweens.Easing

-- Network events (match PropHuntGameManager)
local stateChangedEvent = Event.new("PH_StateChanged")
local roleAssignedEvent = Event.new("PH_RoleAssigned")

-- Network values for persistent state
local currentStateValue = nil

-- State tracking
local currentState = "LOBBY"
local localRole = "unknown"
local rangeIndicatorInstance = nil
local breathingTween = nil

-- Constants
local TAG_RANGE = 4.0 -- Should match Config.GetTagRange()

--[[
    State Normalization
    Convert numeric state values to string names
]]
local function NormalizeState(value)
    if type(value) == "number" then
        if value == 1 then return "LOBBY"
        elseif value == 2 then return "HIDING"
        elseif value == 3 then return "HUNTING"
        elseif value == 4 then return "ROUND_END"
        end
    end
    return tostring(value)
end

--[[
    Should Show Indicator
    Determines if the range indicator should be visible based on role and game state
]]
local function ShouldShowIndicator()
    return localRole == "hunter" and currentState == "HUNTING"
end

--[[
    Spawn Range Indicator
    Creates a new range indicator instance from the prefab
]]
local function SpawnRangeIndicator()
    if not _RangeIndicatorPrefab then
        print("[PropHuntRangeIndicator] ERROR: No range indicator prefab assigned!")
        return nil
    end

    local newObj = GameObject.Instantiate(_RangeIndicatorPrefab)
    newObj.transform.position = Vector3.zero
    newObj.transform.localScale = Vector3.zero

    return newObj
end

--[[
    Apply Color
    Sets the material color of the range indicator
]]
local function ApplyColor(rangeIndicator)
    if rangeIndicator then
        local renderer = rangeIndicator:GetComponent(Renderer)
        if renderer then
            renderer.material.color = _IndicatorColor
        end
    end
end

--[[
    Start Breathing Animation
    Creates a subtle pulsing/breathing effect for the range indicator
]]
local function StartBreathingAnimation(rangeIndicator)
    if not rangeIndicator or not _EnableBreathingAnimation then
        return
    end

    -- Stop existing tween if any
    if breathingTween then
        breathingTween:stop()
        breathingTween = nil
    end

    local baseScale = Vector3.new(TAG_RANGE, rangeIndicator.transform.localScale.y, TAG_RANGE)
    local expandedScale = Vector3.new(TAG_RANGE * 1.15, rangeIndicator.transform.localScale.y, TAG_RANGE * 1.15)

    breathingTween = Tween:new(
        0,
        1,
        _AnimationSpeed,
        true,  -- Loop
        true,  -- Yoyo/ping-pong mode
        Easing.easeInOutQuad,  -- Smooth sine-like easing for breathing effect
        function(value)
            if rangeIndicator and not rangeIndicator.isDestroyed then
                rangeIndicator.transform.localScale = Vector3.Lerp(baseScale, expandedScale, value)
            end
        end
    )

    breathingTween:start()
end

--[[
    Stop Breathing Animation
    Stops the breathing animation tween
]]
local function StopBreathingAnimation()
    if breathingTween then
        breathingTween:stop()
        breathingTween = nil
    end
end

--[[
    Show Range Indicator
    Displays the range indicator around the local player
]]
local function ShowRangeIndicator()
    if rangeIndicatorInstance then
        print("[PropHuntRangeIndicator] Range indicator already active")
        return
    end

    local player = client.localPlayer
    if not player or player.isDestroyed then
        print("[PropHuntRangeIndicator] No local player available")
        return
    end

    local character = player.character
    if not character then
        print("[PropHuntRangeIndicator] No character available")
        return
    end

    -- Spawn the indicator
    rangeIndicatorInstance = SpawnRangeIndicator()
    if not rangeIndicatorInstance then
        return
    end

    print("[PropHuntRangeIndicator] Showing range indicator (radius: " .. TAG_RANGE .. "m)")

    -- Attach to player character
    rangeIndicatorInstance.transform:SetParent(character.transform)
    rangeIndicatorInstance.transform.position = character.transform.position

    -- Set scale based on tag range
    rangeIndicatorInstance.transform.localScale = Vector3.new(
        TAG_RANGE,
        _RangeIndicatorPrefab.transform.localScale.y,
        TAG_RANGE
    )

    -- Apply color
    ApplyColor(rangeIndicatorInstance)

    -- Start breathing animation
    StartBreathingAnimation(rangeIndicatorInstance)
end

--[[
    Hide Range Indicator
    Removes the range indicator from view
]]
local function HideRangeIndicator()
    if not rangeIndicatorInstance then
        return
    end

    print("[PropHuntRangeIndicator] Hiding range indicator")

    -- Stop animation
    StopBreathingAnimation()

    -- Destroy the indicator
    GameObject.Destroy(rangeIndicatorInstance)
    rangeIndicatorInstance = nil
end

--[[
    Update Range Indicator Visibility
    Shows or hides the indicator based on current state and role
]]
local function UpdateIndicatorVisibility()
    if ShouldShowIndicator() then
        if not rangeIndicatorInstance then
            ShowRangeIndicator()
        end
    else
        if rangeIndicatorInstance then
            HideRangeIndicator()
        end
    end
end

--[[
    Event Handlers
]]
local function OnStateChanged(newState, timer)
    currentState = NormalizeState(newState)
    print("[PropHuntRangeIndicator] State changed: " .. currentState)
    UpdateIndicatorVisibility()
end

local function OnRoleAssigned(role)
    localRole = tostring(role)
    print("[PropHuntRangeIndicator] Role assigned: " .. localRole)
    UpdateIndicatorVisibility()
end

--[[
    Unity Lifecycle - Client Start
]]
function self:ClientStart()
    print("[PropHuntRangeIndicator] Initialized")

    -- Verify tag range matches config
    local configRange = Config.GetTagRange()
    if math.abs(TAG_RANGE - configRange) > 0.01 then
        print("[PropHuntRangeIndicator] WARNING: TAG_RANGE (" .. TAG_RANGE ..
              ") doesn't match Config.GetTagRange() (" .. configRange .. ")")
    end

    -- Setup NetworkValue tracking after a short delay
    Timer.After(0.5, function()
        -- Track game state via NetworkValue
        currentStateValue = NumberValue.new("PH_CurrentState", 1)
        if currentStateValue then
            currentState = NormalizeState(currentStateValue.value)
            print("[PropHuntRangeIndicator] Initial state from NetworkValue: " .. currentState)

            currentStateValue.Changed:Connect(function(newState, oldState)
                OnStateChanged(newState, 0)
            end)
        end

        -- Track player role via PlayerManager
        local localPlayer = client.localPlayer
        if localPlayer then
            local playerInfo = PlayerManager.GetPlayerInfo(localPlayer)
            if playerInfo and playerInfo.role then
                localRole = playerInfo.role.value
                print("[PropHuntRangeIndicator] Initial role from NetworkValue: " .. localRole)
                UpdateIndicatorVisibility()

                playerInfo.role.Changed:Connect(function(newRole, oldRole)
                    OnRoleAssigned(newRole)
                end)
            end
        end
    end)

    -- Listen for state changes (backup event system)
    stateChangedEvent:Connect(OnStateChanged)

    -- Listen for role assignment (backup event system)
    roleAssignedEvent:Connect(OnRoleAssigned)
end

--[[
    Unity Lifecycle - Client Update
    Ensure indicator follows player if they move
]]
function self:ClientUpdate()
    if rangeIndicatorInstance and not rangeIndicatorInstance.isDestroyed then
        local player = client.localPlayer
        if player and not player.isDestroyed and player.character then
            -- Keep indicator at player's feet
            local playerPos = player.character.transform.position
            rangeIndicatorInstance.transform.position = playerPos
        end
    end
end

--[[
    Unity Lifecycle - Client Destroy
    Clean up when script is destroyed
]]
function self:ClientOnDestroy()
    HideRangeIndicator()
end
