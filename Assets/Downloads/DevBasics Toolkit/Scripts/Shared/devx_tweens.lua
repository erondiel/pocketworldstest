--!Type(Module)

Tween = {}
Tween.__index = Tween

-- New classes for sequence and group
TweenSequence = {}
TweenSequence.__index = TweenSequence

TweenGroup = {}
TweenGroup.__index = TweenGroup

local tweens = {}
local sequences = {}
local groups = {}

-- Easing functions
Easing = {
    linear = function(t) return t end,
    easeInQuad = function(t) return t * t end,
    easeOutQuad = function(t) return t * (2 - t) end,
    easeInOutQuad = function(t)
        if t < 0.5 then
            return 2 * t * t
        else
            return -1 + (4 - 2 * t) * t
        end
    end,    
    easeInBack = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return c3 * t * t * t - c1 * t * t
    end,
    easeInBackLinear = function(t)
        local c1 = 3
        local c3 = c1 + 1
        if t < 0.5 then
            return c3 * t * t * t - c1 * t * t
        else
            local linear_t = (t - 0.5) * 2
            return (c3 * 0.5 * 0.5 * 0.5 - c1 * 0.5 * 0.5) + linear_t
        end
    end,
    easeOutBack = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        t = 1 - t
        return 1 - (c3 * t * t * t - c1 * t * t)
    end,
    bounce = function(t)
        if t < (1 / 2.75) then
            return 7.5625 * t * t
        elseif t < (2 / 2.75) then
            t = t - (1.5 / 2.75)
            return 7.5625 * t * t + 0.75
        elseif t < (2.5 / 2.75) then
            t = t - (2.25 / 2.75)
            return 7.5625 * t * t + 0.9375
        else
            t = t - (2.625 / 2.75)
            return 7.5625 * t * t + 0.984375
        end
    end,
    -- New easing functions
    easeInCubic = function(t) return t * t * t end,
    easeOutCubic = function(t) 
        t = t - 1
        return t * t * t + 1
    end,
    easeInOutCubic = function(t)
        if t < 0.5 then
            return 4 * t * t * t
        else
            t = t - 1
            return 4 * t * t * t + 1
        end
    end,
    easeInElastic = function(t)
        local c4 = (2 * math.pi) / 3
        if t == 0 then return 0 end
        if t == 1 then return 1 end
        return -math.pow(2, 10 * t - 10) * math.sin((t * 10 - 10.75) * c4)
    end,
    easeOutElastic = function(t)
        local c4 = (2 * math.pi) / 3
        if t == 0 then return 0 end
        if t == 1 then return 1 end
        return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
    end,
    easeInExpo = function(t)
        return t == 0 and 0 or math.pow(2, 10 * t - 10)
    end,
    easeOutExpo = function(t)
        return t == 1 and 1 or 1 - math.pow(2, -10 * t)
    end,
    easeInSine = function(t)
        return 1 - math.cos((t * math.pi) / 2)
    end,
    easeOutSine = function(t)
        return math.sin((t * math.pi) / 2)
    end
}

-- Vector2 and Vector3 support
local function lerpVector2(from, to, t)
    return Vector2.new(
        from.X + (to.X - from.X) * t,
        from.Y + (to.Y - from.Y) * t
    )
end

local function lerpVector3(from, to, t)
    return Vector3.new(
        from.X + (to.X - from.X) * t,
        from.Y + (to.Y - from.Y) * t,
        from.Z + (to.Z - from.Z) * t
    )
end

local function lerpColor(from, to, t)
    return Color.new(
        from.R + (to.R - from.R) * t,
        from.G + (to.G - from.G) * t,
        from.B + (to.B - from.B) * t,
        from.A + (to.A - from.A) * t
    )
end

-- Constructor for TweenSequence
function TweenSequence:new()
    local obj = {
        tweens = {},
        currentIndex = 1,
        isPlaying = false,
        onComplete = nil
    }
    setmetatable(obj, TweenSequence)
    return obj
end

-- Add a tween to the sequence
function TweenSequence:add(tween)
    table.insert(self.tweens, tween)
    return self
end

-- Start the sequence
function TweenSequence:start()
    self.isPlaying = true
    self.currentIndex = 1
    if #self.tweens > 0 then
        self.tweens[1]:start()
    end
    sequences[self] = self
end

-- Update the sequence
function TweenSequence:update(deltaTime)
    if not self.isPlaying or #self.tweens == 0 then return end

    local currentTween = self.tweens[self.currentIndex]
    if currentTween:isFinished() then
        self.currentIndex = self.currentIndex + 1
        if self.currentIndex <= #self.tweens then
            self.tweens[self.currentIndex]:start()
        else
            self.isPlaying = false
            if self.onComplete then
                self.onComplete()
            end
            sequences[self] = nil
        end
    end
end

-- Stop the sequence
function TweenSequence:stop()
    self.isPlaying = false
    if self.currentIndex <= #self.tweens then
        self.tweens[self.currentIndex]:stop()
    end
    sequences[self] = nil
end

-- Constructor for TweenGroup
function TweenGroup:new()
    local obj = {
        tweens = {},
        isPlaying = false,
        onComplete = nil
    }
    setmetatable(obj, TweenGroup)
    return obj
end

-- Add a tween to the group
function TweenGroup:add(tween)
    table.insert(self.tweens, tween)
    return self
end

-- Start all tweens in the group
function TweenGroup:start()
    self.isPlaying = true
    for _, tween in ipairs(self.tweens) do
        tween:start()
    end
    groups[self] = self
end

-- Update the group
function TweenGroup:update(deltaTime)
    if not self.isPlaying then return end

    local allFinished = true
    for _, tween in ipairs(self.tweens) do
        if not tween:isFinished() then
            allFinished = false
            break
        end
    end

    if allFinished then
        self.isPlaying = false
        if self.onComplete then
            self.onComplete()
        end
        groups[self] = nil
    end
end

-- Stop all tweens in the group
function TweenGroup:stop()
    self.isPlaying = false
    for _, tween in ipairs(self.tweens) do
        tween:stop()
    end
    groups[self] = nil
end

-- Pause all tweens in the group
function TweenGroup:pause()
    for _, tween in ipairs(self.tweens) do
        tween:pause()
    end
end

-- Resume all tweens in the group
function TweenGroup:resume()
    for _, tween in ipairs(self.tweens) do
        tween:resume()
    end
end

-- Constructor for the Tween class
-- Parameters:
--   from: starting value
--   to: ending value
--   duration: time in seconds over which to tween
--   loop: boolean, if true the tween will loop
--   pingPong: boolean, if true the tween will reverse on each loop
--   easing: easing function (optional, defaults to linear)
--   onUpdate: callback function(value) called every update
--   onComplete: callback function() called when tween finishes
function Tween:new(from, to, duration, loop, pingPong, easing, onUpdate, onComplete)
    local obj = {
        from = from,
        to = to,
        duration = duration,
        loop = loop,
        pingPong = pingPong,
        easing = easing or Easing.linear,
        onUpdate = onUpdate,
        onComplete = onComplete,
        elapsed = 0,
        finished = false,
        direction = 1,
        paused = false,  -- New: pause state
        delay = 0,       -- New: delay before starting
        delayElapsed = 0 -- New: time elapsed during delay
    }
    setmetatable(obj, Tween)
    return obj
end

-- Update the tween
-- deltaTime: time elapsed since last update (in seconds)
function Tween:update(deltaTime)
    if self.finished or self.paused then
        return
    end

    -- Handle delay
    if self.delayElapsed < self.delay then
        self.delayElapsed = self.delayElapsed + deltaTime
        return
    end

    self.elapsed = self.elapsed + deltaTime * self.direction
    local t = self.elapsed / self.duration

    if t >= 1 then
        t = 1
        if self.loop then
            if self.pingPong then
                self.direction = -self.direction
                self.elapsed = self.duration
            else
                self.elapsed = 0
            end
        else
            self.finished = true
        end
    elseif t <= 0 and self.pingPong then
        t = 0
        if self.loop then
            self.direction = -self.direction
            self.elapsed = 0
        else
            self.finished = true
        end
    end

    local easedT = self.easing(t)
    local currentValue = self.from + (self.to - self.from) * easedT

    if self.onUpdate then
        self.onUpdate(currentValue, easedT)
    end

    if self.finished and self.onComplete then
        self.onComplete()
        if not self.loop then
            tweens[self] = nil
        end
    end
end

-- Reset the tween to its initial state
function Tween:start()
    self.elapsed = 0
    self.finished = false
    self.direction = 1  -- Reset direction to forward
    tweens[self] = self
end

-- Stop the Tween in case of a loop
function Tween:stop(doCompleteCB)
    doCompleteCB = doCompleteCB or false
    self.finished = true
    if doCompleteCB and self.onComplete then
        self.onComplete()
        if not self.loop then
            tweens[self] = nil
        end
    end
end

-- Check if the tween has finished
function Tween:isFinished()
    return self.finished
end

-- Update the update function to handle sequences and groups
function self:ClientUpdate()
    -- Update individual tweens
    for _, tween in pairs(tweens) do
        if not tween.finished then
            tween:update(Time.deltaTime)
            if tween:isFinished() then
                tweens[tween] = nil
            end
        end
    end

    -- Update sequences
    for _, sequence in pairs(sequences) do
        sequence:update(Time.deltaTime)
    end

    -- Update groups
    for _, group in pairs(groups) do
        group:update(Time.deltaTime)
    end
end

-- New methods for better control
function Tween:pause()
    self.paused = true
end

function Tween:resume()
    self.paused = false
end

function Tween:setDelay(delay)
    self.delay = delay
    self.delayElapsed = 0
end

function Tween:getProgress()
    return self.elapsed / self.duration
end

function Tween:setEase(easing)
    self.easing = easing
end

function Tween:seek(progress)
    progress = math.max(0, math.min(1, progress))
    self.elapsed = progress * self.duration
    local easedT = self.easing(progress)
    local currentValue = self.from + (self.to - self.from) * easedT
    if self.onUpdate then
        self.onUpdate(currentValue, easedT)
    end
end

return {
    Tween = Tween,
    TweenSequence = TweenSequence,
    TweenGroup = TweenGroup,
    Easing = Easing
}
