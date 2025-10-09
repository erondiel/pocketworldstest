--!Type(UI)

local Utils = require("devx_utils")
local Tweens = require("devx_tweens")

local LeaderboardManager = require("devx_leaderboard_manager")

local Tween = Tweens.Tween
local Easing = Tweens.Easing

-- Animation constants
local POP_SCALE = 1.05
local POP_DURATION = 0.2
local ITEM_DELAY = 0.1
local FADE_DURATION = 0.3

--!Bind
local _CloseButton : VisualElement = nil
--!Bind
local _LeaderboardContent : UIScrollView = nil
--!Bind
local _LeaderboardEmptyState : VisualElement = nil

type LeaderboardEntry = {
  id: string,
  name: string,
  score: number,
  rank: number
}

--[[
  ClearLeaderboardContent: Clears the leaderboard content.
]]
local function ClearLeaderboardContent()
  _LeaderboardContent:Clear()
end

--[[
  CloseLeaderboard: Closes the leaderboard.
]]
function CloseLeaderboard()
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
      ClearLeaderboardContent()
      self.gameObject:SetActive(false)
    end
  )

  fadeOutTween:start()
  scaleDownTween:start()
end

--[[
  CreateLeaderboardEntry: Creates a leaderboard entry.
  @param entry: LeaderboardEntry
  @return VisualElement
]]
function CreateLeaderboardEntry(entry: LeaderboardEntry): VisualElement
  local _LeaderboardEntry = VisualElement.new()
  _LeaderboardEntry:AddToClassList("leaderboard-entry")
  _LeaderboardEntry.pickingMode = PickingMode.Ignore
  _LeaderboardEntry.style.scale = StyleScale.new(Scale.new(Vector2.new(0.5, 0.5)))
  _LeaderboardEntry.style.opacity = StyleFloat.new(0)

  local _LeaderboardEntryRank = Label.new()
  _LeaderboardEntryRank:AddToClassList("leaderboard-entry-rank")

  local _LeaderboardEntryName = Label.new()
  _LeaderboardEntryName:AddToClassList("leaderboard-entry-name")

  local _LeaderboardEntryScore = Label.new()
  _LeaderboardEntryScore:AddToClassList("leaderboard-entry-score")

  _LeaderboardEntry:Add(_LeaderboardEntryRank)
  _LeaderboardEntry:Add(_LeaderboardEntryName)
  _LeaderboardEntry:Add(_LeaderboardEntryScore)

  _LeaderboardEntryRank.text = Utils.RankSuffix(entry.rank)
  _LeaderboardEntryName.text = entry.name
  _LeaderboardEntryScore.text = Utils.AddCommas(entry.score)

  return _LeaderboardEntry
end

--[[
  AnimateLeaderboardEntry: Animates a leaderboard entry.
  @param entry: VisualElement
  @param delay: number
]]
local function AnimateLeaderboardEntry(entry: VisualElement, delay: number)
  local fadeInTween = Tween:new(
    0,
    1,
    FADE_DURATION,
    false,
    false,
    Easing.OutQuad,
    function(value)
      entry.style.opacity = StyleFloat.new(value)
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
      entry.style.scale = StyleScale.new(Scale.new(Vector2.new(value, value)))
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
          entry.style.scale = StyleScale.new(Scale.new(Vector2.new(value, value)))
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
  PopulateLeaderboard: Populates the leaderboard.
]]
function PopulateLeaderboard()
  ClearLeaderboardContent()

  LeaderboardManager.GetTopPlayers(10, function(topPlayers)
    if not topPlayers or #topPlayers == 0 then
      _LeaderboardEmptyState:RemoveFromClassList("hidden")
      return
    else
      if not _LeaderboardEmptyState:ClassListContains("hidden") then
        _LeaderboardEmptyState:AddToClassList("hidden")
      end
    end
    
    local index = 0
    local firstElement = nil
    for _, entry in ipairs(topPlayers) do
      local element = CreateLeaderboardEntry(entry)
      _LeaderboardContent:Add(element)

      if index == 0 then
        firstElement = element
      end

      AnimateLeaderboardEntry(element, index * ITEM_DELAY)
      index = index + 1
    end

    if firstElement then
      _LeaderboardContent:ScrollTo(firstElement)
    end

    SetContentHeight(index, topPlayers, nil)
  end)
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
          PopulateLeaderboard()
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
  ClearLeaderboardContent()
end

--[[
  SetContentHeight: Sets the content height.
  @param index: number
  @param entries: {LeaderboardEntry}
  @param height: number | nil
]]
function SetContentHeight(index: number, entries: {LeaderboardEntry}, height: number | nil)
  local scrollView = _LeaderboardContent:Q("unity-content-container")
  Timer.After(index * ITEM_DELAY + FADE_DURATION, function()
    if height then
      scrollView.style.height = StyleLength.new(Length.new(height))
    else
      scrollView.style.height = StyleLength.new(Length.new((#entries) * 50))
    end
  end)
end

_CloseButton:RegisterPressCallback(CloseLeaderboard)