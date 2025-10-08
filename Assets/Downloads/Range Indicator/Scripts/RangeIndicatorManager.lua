--!Type(Client)

--!Tooltip("The range indicator prefab")
--!SerializeField
local _RangeIndicatorPrefab : GameObject = nil

--!Tooltip("The radius of the range indicator")
--!SerializeField
--!Range(0, 100)
local _Radius: number = 4

--!Tooltip("The time to hide the range indicator after it is spawned")
--!SerializeField
local _HideAfterTime: number = 10

--!Tooltip("Whether to enable the breathing animation")
--!SerializeField
local _EnableBreathingAnimation : boolean = true

--!Tooltip("The speed of the breathing animation")
--!SerializeField
local _AnimationSpeed : number = 1

--!Tooltip("Whether to deploy the range indicator to the assigned object")
--!SerializeField
local _DeployToAssignedObject : boolean = false

--!Tooltip("Whether to test the range indicator")
--!SerializeField
local _TestDemo : boolean = true

--!Tooltip("The time to spawn the range indicator after the game starts")
--!SerializeField
local _TestDemoSpawnAfterTime: number = 5

--!Tooltip("The color of the range indicator")
--!SerializeField
local _Color : Color = Color.white

local TweenModule = require("TweenModule")
local Tween = TweenModule.Tween
local Easing = TweenModule.Easing

local _RangeIndicatorInstance = nil
local breathingTween = nil

function BreathingAnimation(rangeIndicator: GameObject)
  if rangeIndicator then
    -- Stop existing tween if any
    if breathingTween then
      breathingTween:stop()
    end

    local baseScale = Vector3.new(_Radius, rangeIndicator.transform.localScale.y, _Radius)
    local expandedScale = Vector3.new(_Radius * 1.2, rangeIndicator.transform.localScale.y, _Radius * 1.2)

    breathingTween = Tween:new(
      0,
      1,
      _AnimationSpeed, -- Duration
      true, -- Loop
      true, -- Yoyo/ping-pong mode
      Easing.easeInOutSine,
      function(value)
        rangeIndicator.transform.localScale = Vector3.Lerp(baseScale, expandedScale, value)
      end
    )

    breathingTween:start()
  end
end

function SpawnRangeIndicator(): GameObject | nil
  if _RangeIndicatorPrefab then
    local newObj = GameObject.Instantiate(_RangeIndicatorPrefab)
    newObj.transform.position = Vector3.zero
    newObj.transform.localScale = Vector3.zero

    return newObj
  end

  return nil
end

function DestroyRangeIndicator(rangeIndicator: GameObject)
  if rangeIndicator then
    if breathingTween then
      breathingTween:stop()
      breathingTween = nil
    end
    GameObject.Destroy(rangeIndicator)
  end
end

-- Helper function to calculate the distance to the target
function CalculateDistanceToTarget(targetPosition: Vector3)
  local player = client.localPlayer
  if player and not player.isDestroyed then
    local character = player.character
    local playerPosition = character.transform.position

    return Vector3.Distance(playerPosition, targetPosition)
  end

  return 0
end

function ApplyColor(rangeIndicator: GameObject)
  if rangeIndicator then
    local renderer = rangeIndicator:GetComponent(Renderer)
    if renderer then
      renderer.material.color = _Color
    end
  end
end

function DeployRangeIndicator(deployToAssignedObject: boolean)
  local targetObject = nil

  -- If no target is specified, use the local player
  if not deployToAssignedObject then
    local player = client.localPlayer
    if player and not player.isDestroyed then
      targetObject = player.character
    end
  else
    targetObject = self.gameObject
  end

  -- Only proceed if we have a valid target
  if targetObject then
    local targetPosition = targetObject.transform.position

    -- Activate the range indicator
    local rangeIndicator = SpawnRangeIndicator()
    if rangeIndicator then
      -- Set the range indicator instance
      _RangeIndicatorInstance = rangeIndicator

      -- Attach the range indicator to the target object
      rangeIndicator.transform:SetParent(targetObject.transform)

      -- Update the position of the range indicator to show under the target
      rangeIndicator.transform.position = targetPosition

      -- Update the range based on the radius and height
      rangeIndicator.transform.localScale = Vector3.new(_Radius, _RangeIndicatorPrefab.transform.localScale.y, _Radius)

      -- Apply the color to the range indicator
      ApplyColor(rangeIndicator)

      -- Start the breathing animation with the spawned indicator
      if _EnableBreathingAnimation then
        BreathingAnimation(rangeIndicator)
      end
    end
  end

  -- Destroy the range indicator after the hide time
  Timer.After(_HideAfterTime, function()
    if _RangeIndicatorInstance then
      DestroyRangeIndicator(_RangeIndicatorInstance)
      _RangeIndicatorInstance = nil
    end
  end)
end

-- This will be later replaced with a trigger event
if _TestDemo then
  Timer.After(_TestDemoSpawnAfterTime, function()
    DeployRangeIndicator(_DeployToAssignedObject)
  end)
end