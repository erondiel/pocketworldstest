# PropHunt V1 - Implementation Guide

**Last Updated:** October 8, 2024
**Target:** V1.0 Technical Art Showcase
**Reference:** Game Design Document (GDD) in `Assets/PropHunt/Docs/`

---

## Overview

This guide provides a structured approach to implementing PropHunt using learned patterns from the Highrise Studio ecosystem. Each system references example implementations from downloaded assets when applicable.

---

## System Architecture Map

```
PropHunt V1 Systems
├── 1. Core Game Loop ✅ (COMPLETE)
│   ├── State Machine (LOBBY → HIDING → HUNTING → ROUND_END)
│   ├── Player Management (Ready, Join/Leave)
│   └── Network Synchronization (Events, RemoteFunctions)
│
├── 2. Possession System ⚠️ (IN PROGRESS)
│   ├── Possessable Component
│   ├── Server-Side Possession Logic
│   ├── No-Unpossess Enforcement
│   └── Player Teleportation
│
├── 3. Zone System ❌ (NOT STARTED)
│   ├── Zone Volumes (NearSpawn, Mid, Far)
│   ├── Zone Detection
│   └── Zone Weights
│
├── 4. Scoring System ❌ (NOT STARTED)
│   ├── Passive Prop Scoring
│   ├── Hunter Tagging Scoring
│   └── Team Bonuses
│
├── 5. Hunter Tagging ⚠️ (NEEDS ALIGNMENT)
│   ├── Player Origin Raycast (currently camera)
│   ├── Distance Validation (R_tag = 4.0m)
│   └── VFX Feedback
│
├── 6. Teleportation System ❌ (NOT STARTED)
│   ├── Lobby ↔ Arena Movement
│   └── Hunter Gating During Hide
│
├── 7. Visual Systems ❌ (NOT STARTED)
│   ├── Outline Shaders
│   ├── Possession VFX
│   ├── Tagging VFX
│   └── Phase Transition VFX
│
└── 8. UI/UX ⚠️ (BASIC COMPLETE)
    ├── HUD (complete)
    ├── Ready Button (complete)
    ├── Spectator Toggle ❌
    ├── Kill Feed ❌
    └── Recap Screen ❌
```

---

## Implementation Priority Order

### Phase 1: Core Mechanics (Current Focus)
1. **Possession System** (Your current task)
2. **Zone System** (Foundation for scoring)
3. **Hunter Tagging Fixes** (GDD alignment)
4. **Teleportation System** (Lobby/Arena separation)

### Phase 2: Game Logic
5. **Scoring System** (Logic only, no UI polish)
6. **Spectator Mode** (Basic implementation)
7. **UI Enhancements** (Kill feed, zone labels)

### Phase 3: Visual Polish (Tech Art Showcase)
8. **Shaders** (Outline, dissolve, emissive)
9. **VFX** (Possession, tagging, transitions)
10. **UI Polish** (Animations, recap screen)

---

## System 1: Possession System (IN PROGRESS)

**Status:** Basic scaffolding exists, needs full implementation
**Reference Asset:** Trigger Object (for trigger detection patterns)
**GDD Section:** §5 - Possession Rules

### Required Components

#### 1.1 Enhanced Possessable Component

**File:** `Assets/PropHunt/Scripts/Possessable.lua`

```lua
--!Type(Module)

-- Serialized fields for Unity Inspector
--!SerializeField
--!Tooltip("Unique identifier for this prop")
local _propId : string = ""

--!SerializeField
--!Tooltip("Transform where player teleports when possessing")
local _hitPoint : Transform = nil

--!SerializeField
--!Tooltip("Main collider for raycasting")
local _mainCollider : Collider = nil

--!SerializeField
--!Tooltip("Outline renderer for visual feedback (optional)")
local _outlineRenderer : Renderer = nil

-- Network-synced state (auto-sync across clients)
local _isPossessed : BoolValue = nil
local _ownerPlayerId : StringValue = nil

function self:Awake()
    -- Create network values with unique IDs
    local instanceId = tostring(self.gameObject:GetInstanceID())
    _isPossessed = BoolValue.new("PH_Possessed_" .. instanceId, false)
    _ownerPlayerId = StringValue.new("PH_Owner_" .. instanceId, "")
end

-- Public getters
function GetPropId() : string
    return _propId
end

function GetIsPossessed() : boolean
    return _isPossessed and _isPossessed.value or false
end

function GetOwnerId() : string
    return _ownerPlayerId and _ownerPlayerId.value or ""
end

function GetHitPoint() : Transform
    return _hitPoint
end

function GetMainCollider() : Collider
    return _mainCollider
end

-- Server-side only - sets ownership
function SetOwner(playerId : string)
    if _ownerPlayerId then
        _ownerPlayerId.value = playerId
        _isPossessed.value = (playerId ~= "")
    end
end

-- Server-side only - clears ownership
function ClearOwner()
    SetOwner("")
end

-- Get outline renderer for shader control (VFX system will use this)
function GetOutlineRenderer() : Renderer
    return _outlineRenderer
end
```

**Unity Setup Steps:**
1. Create prop prefabs in `Assets/PropHunt/Prefabs/Props/`
2. Add Possessable component to each prop
3. Assign unique `_propId` (e.g., "chair_01", "plant_02")
4. Create empty child GameObject named "HitPoint" and assign to `_hitPoint`
5. Assign main collider reference to `_mainCollider`
6. (Optional) Assign outline renderer for VFX support

#### 1.2 Server-Side Possession Logic

**File:** `Assets/PropHunt/Scripts/PropHuntGameManager.lua`

Add to existing GameManager:

```lua
-- At top of file with other tracking tables
local playerPossessions = {}  -- [playerId] = { propObject, possessableComponent }

-- Helper: Find prop by identifier (scene search)
local function FindPropByIdentifier(identifier)
    -- Get all Possessable components in scene
    local possessables = GameObject.FindObjectsOfType(Possessable)
    for i = 0, possessables.Length - 1 do
        local poss = possessables[i]
        if poss.GetPropId() == identifier then
            return poss.gameObject, poss
        end
    end
    return nil, nil
end

-- Helper: Check if player already possessed a prop this round
local function HasPlayerPossessedAnyProp(player)
    return playerPossessions[player.id] ~= nil
end

-- Helper: Reset all possessions (called at round start/end)
function ResetAllPossessions()
    -- Clear ownership on all props
    for playerId, possession in pairs(playerPossessions) do
        if possession.possessable then
            possession.possessable.ClearOwner()
        end
    end

    -- Clear tracking
    playerPossessions = {}

    print("[GameManager] All possessions reset")
end

-- Update disguise request handler (replace existing stub)
disguiseRequest.OnInvokeServer = function(player, propIdentifier)
    -- Validate phase
    if currentState.value ~= GameState.HIDING then
        return false, "Not hiding phase"
    end

    -- Validate player is a prop
    if not IsPlayerInTeam(player, propsTeam) then
        return false, "Not a prop"
    end

    -- Find the prop object
    local propObj, possessable = FindPropByIdentifier(propIdentifier)
    if not propObj or not possessable then
        return false, "Prop not found"
    end

    -- Check if already possessed (One-Prop Rule)
    if possessable.GetIsPossessed() then
        print("[GameManager] Prop already possessed:", propIdentifier)
        -- TODO: Trigger rejection VFX event here
        return false, "Already possessed"
    end

    -- Check No-Unpossess rule (player already possessed another prop)
    if HasPlayerPossessedAnyProp(player) then
        print("[GameManager] Player already possessing:", player.name)
        -- TODO: Trigger rejection VFX event here
        return false, "You can only possess one prop per round"
    end

    -- VALID POSSESSION - Apply changes
    possessable.SetOwner(player.id)

    -- Track possession
    playerPossessions[player.id] = {
        propObject = propObj,
        possessable = possessable
    }

    -- Teleport player character to prop's HitPoint
    local hitPoint = possessable.GetHitPoint()
    if hitPoint and player.character then
        player.character.transform.position = hitPoint.position

        -- TODO: Hide player character mesh (requires Character API research)
        -- TODO: Disable player movement (freeze during Hunt)
        -- TODO: Trigger Vanish VFX at old position
        -- TODO: Trigger Infill VFX at prop position
    end

    print("[GameManager] Possession success:", player.name, "→", propIdentifier)
    return true, "Possessed successfully"
end
```

**Add to state transitions:**

```lua
-- In TransitionToState function, update HIDING case:
elseif newState == GameState.HIDING then
    stateTimer.value = Config.GetHidePhaseTime()
    Log(string.format("HIDE %ds", Config.GetHidePhaseTime()))

    -- Reset possessions for new round
    ResetAllPossessions()
```

### Implementation Checklist

- [ ] Create prop prefabs with Possessable components
- [ ] Assign HitPoint transforms to all props
- [ ] Implement enhanced Possessable.lua
- [ ] Add server-side possession validation
- [ ] Add No-Unpossess enforcement
- [ ] Add One-Prop conflict detection
- [ ] Implement player teleportation to HitPoint
- [ ] Test possession with 2+ props
- [ ] Test rejection for double-possess attempts
- [ ] Verify network sync (possession state visible to all clients)

---

## System 2: Zone System

**Status:** Not started
**Reference Asset:** Trigger Object (trigger detection), Range Indicator (area visualization during testing)
**GDD Section:** §11 - Level Authoring (Zones)

### Implementation Plan

#### 2.1 ZoneVolume Component

**File:** `Assets/PropHunt/Scripts/ZoneVolume.lua`

```lua
--!Type(Module)

--!SerializeField
--!Tooltip("Zone weight multiplier for scoring")
local _zoneWeight : number = 1.0

--!SerializeField
--!Tooltip("Zone identifier (NearSpawn, Mid, Far)")
local _zoneTag : string = "Mid"

-- Trigger detection
local _occupants = {}  -- [gameObject] = true

function self:Start()
    -- Ensure this object has a trigger collider
    local collider = self.gameObject:GetComponent(Collider)
    if collider then
        collider.isTrigger = true
    else
        print("[ZoneVolume] WARNING: No collider found on " .. self.gameObject.name)
    end
end

function self:OnTriggerEnter(other : Collider)
    -- Track objects entering zone
    _occupants[other.gameObject] = true
end

function self:OnTriggerExit(other : Collider)
    -- Remove objects leaving zone
    _occupants[other.gameObject] = nil
end

-- Public API
function GetZoneWeight() : number
    return _zoneWeight
end

function GetZoneTag() : string
    return _zoneTag
end

function IsOccupying(gameObject : GameObject) : boolean
    return _occupants[gameObject] ~= nil
end
```

#### 2.2 Zone Query System

**File:** `Assets/PropHunt/Scripts/PropHuntGameManager.lua` (add to existing)

```lua
-- Helper: Get zone weight at position
local function GetZoneWeightAtPosition(position)
    local zones = GameObject.FindObjectsOfType(ZoneVolume)
    local highestWeight = 1.0  -- Default Mid zone
    local zoneTag = "Mid"

    for i = 0, zones.Length - 1 do
        local zone = zones[i]
        local collider = zone.gameObject:GetComponent(Collider)

        if collider and collider:bounds:Contains(position) then
            local weight = zone.GetZoneWeight()
            if weight > highestWeight then
                highestWeight = weight
                zoneTag = zone.GetZoneTag()
            end
        end
    end

    return highestWeight, zoneTag
end

-- Helper: Get zone for a prop object
local function GetZoneForProp(propObject)
    if not propObject then return 1.0, "Unknown" end
    return GetZoneWeightAtPosition(propObject.transform.position)
end
```

### Unity Setup

**Zone Creation:**
1. Create empty GameObjects in scene: "Zone_NearSpawn", "Zone_Mid", "Zone_Far"
2. Add BoxCollider (or other collider shape) to each, set `isTrigger = true`
3. Attach ZoneVolume.lua component
4. Configure weights:
   - NearSpawn: 1.5
   - Mid: 1.0
   - Far: 0.6
5. Position zones in arena based on spawn point proximity

**Visual Testing (Optional):**
- Use Range Indicator asset to visualize zone boundaries during dev
- Disable in production builds

### Implementation Checklist

- [ ] Create ZoneVolume.lua component
- [ ] Create zone GameObjects in scene (Near, Mid, Far)
- [ ] Add zone query helpers to GameManager
- [ ] Test zone detection with player movement
- [ ] Verify zone weights return correct values
- [ ] Document zone placement in scene

---

## System 3: Scoring System

**Status:** Not started
**Reference Asset:** DevBasics Toolkit (Leaderboard, Storage), Matchmaking System (score tracking)
**GDD Section:** §9 - Scoring (Static Props)

### Implementation Plan

#### 3.1 Score Tracking Structure

**File:** `Assets/PropHunt/Scripts/PropHuntGameManager.lua` (add to existing)

```lua
-- Score tracking (at module scope)
local playerScores = {}  -- [playerId] = { score, tags, misses, survivalTicks }

-- Initialize player score
local function InitializePlayerScore(player)
    playerScores[player.id] = {
        score = 0,
        tags = 0,         -- For hunters: successful tags
        misses = 0,       -- For hunters: missed shots
        survivalTicks = 0 -- For props: number of 5s ticks survived
    }
end

-- Reset all scores (called at round start)
local function ResetAllScores()
    playerScores = {}
    for _, player in pairs(activePlayers) do
        InitializePlayerScore(player)
    end
end
```

#### 3.2 Prop Scoring (Passive Survival)

```lua
-- Scoring constants from GDD
local PROP_TICK_INTERVAL = 5.0  -- Seconds
local PROP_TICK_POINTS = 10
local PROP_SURVIVE_BONUS = 100

-- Prop scoring ticker (call in ServerFixedUpdate during HUNTING state)
local lastPropScoreTick = 0

function UpdatePropScoring()
    if currentState.value ~= GameState.HUNTING then return end

    -- Tick every 5 seconds
    if Time.time < lastPropScoreTick + PROP_TICK_INTERVAL then
        return
    end

    lastPropScoreTick = Time.time

    -- Award points to all alive props
    for _, prop in ipairs(propsTeam) do
        if not IsPlayerInTable(prop, eliminatedPlayers) then
            -- Get zone weight for this prop
            local possession = playerPossessions[prop.id]
            if possession and possession.propObject then
                local zoneWeight, zoneTag = GetZoneForProp(possession.propObject)
                local points = PROP_TICK_POINTS * zoneWeight

                -- Award points
                if not playerScores[prop.id] then InitializePlayerScore(prop) end
                playerScores[prop.id].score = playerScores[prop.id].score + points
                playerScores[prop.id].survivalTicks = playerScores[prop.id].survivalTicks + 1

                print(string.format("[Scoring] %s: +%d pts (%s zone)", prop.name, points, zoneTag))
            end
        end
    end
end

-- Add to ServerFixedUpdate:
function self:ServerFixedUpdate()
    -- ... existing state updates ...

    if currentState.value == GameState.HUNTING then
        UpdateHunting()
        UpdatePropScoring()  -- Add this
    end
end
```

#### 3.3 Hunter Scoring (Tag Events)

```lua
-- Scoring constants
local HUNTER_FIND_BASE = 120
local HUNTER_MISS_PENALTY = -8

-- Update OnPlayerTagged to add scoring
function OnPlayerTagged(hunter, prop)
    -- ... existing validation ...

    -- Award hunter points based on prop's zone
    local possession = playerPossessions[prop.id]
    if possession and possession.propObject then
        local zoneWeight, zoneTag = GetZoneForProp(possession.propObject)
        local points = HUNTER_FIND_BASE * zoneWeight

        if not playerScores[hunter.id] then InitializePlayerScore(hunter) end
        playerScores[hunter.id].score = playerScores[hunter.id].score + points
        playerScores[hunter.id].tags = playerScores[hunter.id].tags + 1

        print(string.format("[Scoring] %s tagged %s: +%d pts (%s zone)",
              hunter.name, prop.name, points, zoneTag))
    end

    -- ... rest of existing code ...
end

-- Track misses (call from hunter tag validation)
function OnHunterMiss(hunter)
    if not playerScores[hunter.id] then InitializePlayerScore(hunter) end
    playerScores[hunter.id].score = playerScores[hunter.id].score + HUNTER_MISS_PENALTY
    playerScores[hunter.id].misses = playerScores[hunter.id].misses + 1
end
```

#### 3.4 End-of-Round Bonuses

```lua
-- Calculate and award bonuses at round end
function CalculateEndOfRoundBonuses()
    -- Prop survive bonus
    for _, prop in ipairs(propsTeam) do
        if not IsPlayerInTable(prop, eliminatedPlayers) then
            if playerScores[prop.id] then
                playerScores[prop.id].score = playerScores[prop.id].score + PROP_SURVIVE_BONUS
                print(string.format("[Scoring] %s survived: +%d bonus", prop.name, PROP_SURVIVE_BONUS))
            end
        end
    end

    -- Hunter accuracy bonus
    for _, hunter in ipairs(huntersTeam) do
        local scoreData = playerScores[hunter.id]
        if scoreData then
            local totalShots = scoreData.tags + scoreData.misses
            if totalShots > 0 then
                local accuracy = scoreData.tags / totalShots
                local bonus = math.floor(accuracy * 50)
                scoreData.score = scoreData.score + bonus
                print(string.format("[Scoring] %s accuracy bonus: +%d (%.0f%%)",
                      hunter.name, bonus, accuracy * 100))
            end
        end
    end

    -- Team bonuses
    if AreAllPropsEliminated() then
        -- Hunters win
        for _, hunter in ipairs(huntersTeam) do
            if playerScores[hunter.id] then
                playerScores[hunter.id].score = playerScores[hunter.id].score + 50
            end
        end
    else
        -- Props win
        for _, prop in ipairs(propsTeam) do
            local bonus = IsPlayerInTable(prop, eliminatedPlayers) and 15 or 30
            if playerScores[prop.id] then
                playerScores[prop.id].score = playerScores[prop.id].score + bonus
            end
        end
    end
end

-- Call in EndRound function before transitioning
function EndRound(winner)
    CalculateEndOfRoundBonuses()  -- Add this

    -- ... existing win announcement ...
end
```

#### 3.5 Winner Calculation

```lua
-- Determine winner with tie-breakers (GDD §10)
function DetermineWinner()
    local highestScore = -9999
    local winners = {}

    -- Find highest score
    for playerId, scoreData in pairs(playerScores) do
        if scoreData.score > highestScore then
            highestScore = scoreData.score
            winners = {playerId}
        elseif scoreData.score == highestScore then
            table.insert(winners, playerId)
        end
    end

    -- Tie-breaker logic
    if #winners > 1 then
        -- Tie-breaker 1: Most tags/survival ticks
        local bestMetric = -1
        local tiedPlayers = {}

        for _, playerId in ipairs(winners) do
            local player = GetPlayerById(playerId)
            local scoreData = playerScores[playerId]

            local metric = IsPlayerInTeam(player, huntersTeam)
                and scoreData.tags or scoreData.survivalTicks

            if metric > bestMetric then
                bestMetric = metric
                tiedPlayers = {playerId}
            elseif metric == bestMetric then
                table.insert(tiedPlayers, playerId)
            end
        end

        -- If still tied, declare draw or use timestamp (implement as needed)
        if #tiedPlayers == 1 then
            return GetPlayerById(tiedPlayers[1])
        else
            -- Still tied - declare draw
            return nil  -- Signals draw
        end
    end

    return GetPlayerById(winners[1])
end
```

### Implementation Checklist

- [ ] Add score tracking structures
- [ ] Implement prop passive scoring (5s tick)
- [ ] Implement hunter tag scoring
- [ ] Implement miss penalty
- [ ] Add end-of-round bonuses
- [ ] Implement winner determination with tie-breakers
- [ ] Test scoring with different zone weights
- [ ] Verify accuracy bonus calculation
- [ ] Test tie-breaker logic

---

## System 4: Teleportation System

**Status:** Not started
**Reference Asset:** Scene Teleporter (teleport patterns, UI triggers)
**GDD Section:** §4 - Scene Topology

### Implementation Plan

**Key Difference from Scene Teleporter:**
- Scene Teleporter moves players between scenes
- PropHunt teleports within a single scene between Lobby/Arena areas

#### 4.1 Teleport Positions Setup

**Unity Setup:**
1. Create empty GameObjects:
   - `LobbySpawnPoint` (in Lobby area)
   - `ArenaSpawnPoint_Props` (in Arena for props)
   - `ArenaSpawnPoint_Hunters` (in Arena for hunters - used after Hide)
   - `ArenaSpawnPoint_Spectators` (in Arena for spectators)

2. Position these GameObjects at desired spawn locations

#### 4.2 Teleport Logic

**File:** `Assets/PropHunt/Scripts/PropHuntGameManager.lua`

```lua
-- Teleport helper references (assign in Unity Inspector if using Module)
-- Or find by name at runtime

local function GetTeleportPoint(pointName)
    return GameObject.Find(pointName)
end

local function TeleportPlayer(player, targetPoint)
    if not player.character or not targetPoint then
        print("[Teleport] Invalid teleport:", player.name)
        return
    end

    player.character.transform.position = targetPoint.transform.position
    print("[Teleport]", player.name, "→", targetPoint.name)
end

local function TeleportTeamToArena(team, spawnPointName)
    local spawnPoint = GetTeleportPoint(spawnPointName)
    if not spawnPoint then
        print("[Teleport] ERROR: Spawn point not found:", spawnPointName)
        return
    end

    for _, player in ipairs(team) do
        TeleportPlayer(player, spawnPoint)
    end
end

local function TeleportAllToLobby()
    local lobbySpawn = GetTeleportPoint("LobbySpawnPoint")
    if not lobbySpawn then
        print("[Teleport] ERROR: Lobby spawn not found")
        return
    end

    for _, player in pairs(activePlayers) do
        TeleportPlayer(player, lobbySpawn)
    end
end
```

#### 4.3 Integrate with State Machine

```lua
-- Update TransitionToState function:

function TransitionToState(newState)
    -- ... existing state change logic ...

    if newState == GameState.LOBBY then
        -- Everyone returns to lobby
        TeleportAllToLobby()

    elseif newState == GameState.HIDING then
        -- Props and spectators to arena, hunters stay in lobby
        TeleportTeamToArena(propsTeam, "ArenaSpawnPoint_Props")
        -- TODO: Teleport spectators when implemented

    elseif newState == GameState.HUNTING then
        -- Release hunters into arena
        TeleportTeamToArena(huntersTeam, "ArenaSpawnPoint_Hunters")

    elseif newState == GameState.ROUND_END then
        -- Optional: Keep everyone in place or gather for recap
    end

    -- ... rest of existing code ...
end
```

### Implementation Checklist

- [ ] Create spawn point GameObjects in scene
- [ ] Position spawn points in Lobby and Arena areas
- [ ] Implement teleport helper functions
- [ ] Integrate teleports with state transitions
- [ ] Test Lobby → Arena transitions
- [ ] Test hunter gating during Hide phase
- [ ] Verify all players teleport correctly

---

## System 5: Hunter Tagging Fixes (GDD Alignment)

**Status:** Needs updates to match GDD spec
**Reference Asset:** Range Indicator (distance calculation reference)
**GDD Section:** §6 - Hunter Tagging

### Required Changes

#### 5.1 Raycast from Player Body (Not Camera)

**File:** `Assets/PropHunt/Scripts/HunterTagSystem.lua`

**Current (WRONG):**
```lua
local ray = cam:ScreenPointToRay(tap.position)
```

**Fixed (CORRECT per GDD):**
```lua
-- Get local player's character position
local localPlayer = client.localPlayer
if not localPlayer or not localPlayer.character then return end

local playerPos = localPlayer.character.transform.position

-- Raycast from player position toward world point clicked
local cam = Camera.main
if not cam then return end

-- Convert screen tap to world point at distance
local tapWorldRay = cam:ScreenPointToRay(tap.position)
local targetDirection = tapWorldRay.direction

-- Create ray from player body toward tap direction
local ray = Ray.new(playerPos, targetDirection)
```

#### 5.2 Add R_tag Distance Validation

**Add constant:**
```lua
local R_TAG_MAX_DISTANCE = 4.0  -- GDD spec
```

**Update validation in OnTapToShoot:**
```lua
local didHit = Physics.Raycast(ray, hit, R_TAG_MAX_DISTANCE)  -- Not 100!
```

#### 5.3 Update Cooldown to GDD Spec

**Change:**
```lua
local shootCooldown = 0.5  -- GDD spec, not 2.0
```

#### 5.4 Server-Side Distance Validation

**File:** `Assets/PropHunt/Scripts/PropHuntGameManager.lua`

Update tag request handler:
```lua
tagRequest.OnInvokeServer = function(player, targetPlayerId)
    -- ... existing phase/role checks ...

    -- Validate distance between hunter and target
    if player.character and target.character then
        local distance = Vector3.Distance(
            player.character.transform.position,
            target.character.transform.position
        )

        if distance > 4.0 then  -- R_tag
            return false, "Target too far"
        end
    end

    -- ... rest of validation ...
end
```

### Implementation Checklist

- [ ] Change raycast origin to player body
- [ ] Update R_tag distance to 4.0m (client and server)
- [ ] Update cooldown to 0.5s
- [ ] Add server-side distance validation
- [ ] Test tagging at various distances
- [ ] Verify out-of-range shots are rejected

---

## Reference Patterns from Downloaded Assets

### Pattern 1: Trigger Detection (from Trigger Object)
```lua
function self:OnTriggerEnter(other : Collider)
    -- Verify it's a character
    local character = other:GetComponent(Character)
    if not character then return end

    -- Process trigger logic
end
```
**Use in:** Zone volumes, possession detection

### Pattern 2: Network Synchronization (from Matchmaking System)
```lua
-- Server-side authority
local gameState = NumberValue.new("GameState", 1)

-- Client listens
local stateEvent = Event.new("StateChanged")
stateEvent:Connect(function(newState)
    -- Update client UI
end)
```
**Use in:** All networked game state

### Pattern 3: Player Tracking (from DevBasics Toolkit)
```lua
scene.PlayerJoined:Connect(function(sceneObj, player)
    players[player] = {
        isReady = BoolValue.new("Ready" .. player.user.id, false, player)
    }
end)
```
**Use in:** Already implemented in PlayerManager

### Pattern 4: UI Panels (from UI Panels Asset)
```lua
-- Show confirmation dialog
UIPanels.ShowConfirmation(
    "Ready to Start?",
    "Begin the round?",
    function() StartRound() end,
    function() CancelStart() end
)
```
**Use in:** Future UI enhancements (recap screen, confirmations)

### Pattern 5: Storage Persistence (from Checkpoint Spawner)
```lua
-- Save player progress
storage.SetValue(player, "checkpoint_id", checkpointId, function(success)
    if success then
        print("Progress saved")
    end
end)
```
**Use in:** Future persistent stats (optional post-V1)

---

## Testing Checklist (Per System)

### Possession System Testing
- [ ] Place 5+ props in scene with Possessable components
- [ ] Test selecting different props during Hide
- [ ] Verify One-Prop rule (can't possess multiple)
- [ ] Verify No-Unpossess (can't change prop after possession)
- [ ] Test double-possess rejection
- [ ] Verify player teleports to HitPoint
- [ ] Test with 2+ players simultaneously possessing
- [ ] Verify network sync (other clients see possession state)

### Zone System Testing
- [ ] Walk through all three zones (Near, Mid, Far)
- [ ] Verify zone weight returns correctly
- [ ] Test overlapping zones (highest priority wins)
- [ ] Verify zone detection persists across frames

### Scoring System Testing
- [ ] Props gain points every 5s during Hunt
- [ ] Verify zone weights affect scoring correctly
- [ ] Hunter gains points for tagging
- [ ] Hunter loses points for missing
- [ ] Verify survive bonus applied
- [ ] Verify accuracy bonus calculated
- [ ] Test tie-breaker logic
- [ ] Verify team bonuses applied

### Hunter Tagging Testing
- [ ] Tag from <4m distance (should succeed)
- [ ] Tag from >4m distance (should fail)
- [ ] Verify cooldown prevents spam
- [ ] Test raycast from player body (not camera)
- [ ] Verify server validates distance

---

## Common Pitfalls & Solutions

### Pitfall 1: Forgetting Server-Side Validation
**Problem:** Client sends data, server accepts without checks
**Solution:** Always validate on server: phase, role, distance, cooldown

### Pitfall 2: Not Resetting State Between Rounds
**Problem:** Possessions/scores persist across rounds
**Solution:** Call reset functions in TransitionToState(LOBBY)

### Pitfall 3: Using Wrong Raycast Origin
**Problem:** Using camera for gameplay raycasts
**Solution:** Use player.character.transform.position for gameplay (GDD spec)

### Pitfall 4: Missing Network Sync
**Problem:** State changes not visible to other clients
**Solution:** Use BoolValue/NumberValue/Events for all shared state

### Pitfall 5: Hardcoded Values
**Problem:** Magic numbers scattered in code
**Solution:** Define constants at top of file, reference GDD values

---

## Next Steps (Immediate)

1. **Complete Possession System** (Current focus)
   - Enhance Possessable.lua with all properties
   - Implement full server-side validation
   - Add teleportation logic
   - Test with multiple props

2. **Implement Zone System** (Foundation for scoring)
   - Create ZoneVolume.lua
   - Set up zone GameObjects
   - Add query functions

3. **Fix Hunter Tagging** (GDD alignment)
   - Change raycast origin
   - Update distances and cooldowns
   - Add server validation

4. **Add Teleportation** (Lobby/Arena separation)
   - Create spawn points
   - Implement teleport logic
   - Test with state transitions

---

## Documentation Maintenance

**When to Update:**
- System implementation changes
- GDD spec changes
- New patterns discovered
- Testing reveals issues

**Update Sections:**
- System status (✅ ⚠️ ❌)
- Implementation checklists
- Code examples
- Testing procedures

---

**Document Version:** 1.0
**Author:** Claude Code
**Last Review:** October 8, 2024
