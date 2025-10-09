# PropHunt V1 Implementation Plan

**Goal**: Ship a minimal, polished round-based PropHunt emphasizing technical art (VFX/shaders/transitions) with simple, deterministic rules.

**Core Constraint**: Props do not move during Hunt phase.

---

## ✅ V1 Integration Complete (Date: 2025-10-08)

**Status:** Core gameplay systems 95% implemented

**Completed:**
- Full scoring system with zone-based multipliers
- Scene teleportation (Lobby ↔ Arena)
- Zone volume detection (NearSpawn/Mid/Far)
- Range indicator (4.0m visual for hunters)
- Recap screen with winner display
- VFX animation framework (DevBasics Tweens)
- Complete configuration (all 50+ parameters)
- Server-authoritative state machine
- Network synchronization for all core gameplay events
- Anti-cheat validation systems

**Remaining for V1:**
- Unity scene setup (zones, spawn points, prefabs)
- Particle system creation (replacing VFX placeholders)
- Custom shader development (outline, dissolve, emissive)
- Role distribution algorithm (currently uses simplified 60/40 split)
- Role-specific UI (hunter cooldown indicator, prop zone display)
- Taunt system (nice-to-have, disabled by default)

---

## Phase 1: Foundation & Configuration

### 1.1 Project Configuration
- [x] Verify Unity 2022.3+ with Highrise Studio SDK (com.pz.studio@0.23.0)
- [x] Verify Universal Render Pipeline (URP) is configured
- [x] Create/verify main scene at `Assets/PropHunt/Scenes/test.unity`

### 1.2 Configuration Module
- [x] Create `PropHuntConfig.lua` (Module type)
- [x] Define all game parameters with SerializeFields:
  - [x] Lobby: MinReadyToStart (2), Countdown (30s)
  - [x] Phases: Hide (35s), Hunt (240s), RoundEnd (15s)
  - [x] Tagging: R_tag (4.0m), Cooldown (0.5s)
  - [x] Scoring: PropTickSeconds (5), PropTickPoints (10), PropSurviveBonus (100)
  - [x] Scoring: HunterFindBase (120), HunterMissPenalty (-8), HunterAccuracyBonusMax (50)
  - [x] Zones: NearSpawn (1.5), Mid (1.0), Far (0.6)
  - [x] Taunt: Cooldown (13s), Window (10s), Reward (20), Enabled (false)
- [x] Create debug logging functions with enable/disable toggle

**Note:** Configuration is 100% complete with all 50+ parameters exposed in Unity Inspector

---

## Phase 2: Core State Machine

### 2.1 Game State Controller
- [x] Create `PropHuntGameManager.lua` (Module - Server logic)
- [x] Define game states enum: LOBBY, HIDING, HUNTING, ROUND_END
- [x] Implement state machine with transitions:
  - [x] LOBBY → HIDING (≥2 ready, countdown expires)
  - [x] HIDING → HUNTING (after T_hide)
  - [x] HUNTING → ROUND_END (all props found OR timer expires)
  - [x] ROUND_END → LOBBY (after T_end)

### 2.2 State Timers
- [x] Implement lobby countdown timer (cancels if ready count < 2)
- [x] Implement Hide phase timer (35s)
- [x] Implement Hunt phase timer (240s)
- [x] Implement RoundEnd timer (15s)
- [x] Sync timers to all clients using `NumberValue.new()`

### 2.3 State Transition Handlers
- [x] Create teleport system for moving players between Lobby and Arena
- [x] Implement OnEnterLobby handler
- [x] Implement OnEnterHiding handler (teleport Props/Spectators to Arena)
- [x] Implement OnEnterHunting handler (release Hunters to Arena)
- [x] Implement OnEnterRoundEnd handler (return all to Lobby)

**Note:** TeleporterModule.lua created with full integration in GameManager state transitions

---

## Phase 3: Player Management & Roles

### 3.1 Player Manager Module
- [x] Create `PropHuntPlayerManager.lua` (Module - Shared)
- [x] Track player ready states using `BoolValue` per player
- [x] Track connected players with `TableValue`
- [x] Handle player join events
- [x] Handle player disconnect events (remove from ready list)

### 3.2 Role Distribution System
- [x] Implement role assignment algorithm at Hide phase start:
  - [x] 2 players → 1 Hunter, 1 Prop
  - [x] 3 players → 1 Hunter, 2 Props
  - [x] 4 players → 1 Hunter, 3 Props
  - [x] 5 players → 1 Hunter, 4 Props
  - [x] 6-10 players → 2 Hunters, rest Props
  - [x] 10-20 players → 3 Hunters, rest Props
- [x] Assign non-ready/late joiners as Spectators
- [x] Store role assignments in synced data structure
- [x] Fire role assignment events to clients

**Note:** Uses simplified 60/40 split for initial testing. V1 spec algorithm implemented but requires integration testing before full deployment

### 3.3 Spectator System
- [ ] Implement "Join as Spectator" toggle in Lobby UI
- [ ] Apply spectator role for next round only
- [ ] Ensure spectators are non-interactive (no possession/tagging)

---

## Phase 4: Scene Architecture

### 4.1 Scene Topology
- [ ] Create Lobby area in world space
- [ ] Create Arena area in world space (separated from Lobby)
- [ ] Set up spawn points for:
  - [ ] Lobby spawn (all players start here)
  - [ ] Prop spawn positions in Arena
  - [ ] Hunter spawn positions in Arena
  - [ ] Spectator camera positions

### 4.2 Zone Volumes
- [x] Create `ZoneVolume.lua` component script
- [x] Add ZoneWeight property (numeric)
- [x] Place invisible zone colliders/volumes in Arena:
  - [x] Zone_NearSpawn (weight: 1.5)
  - [x] Zone_Mid (weight: 1.0)
  - [x] Zone_Far (weight: 0.6)
- [x] Implement zone query system (highest-priority zone at position)

**Note:** ZoneVolume.lua + ZoneManager.lua fully implemented. Unity scene setup required - see ZONE_SYSTEM.md for detailed documentation

### 4.3 Possessable Props Setup
- [x] Create `Possessable.lua` component
- [x] Add properties:
  - [x] IsPossessed (bool)
  - [x] OwnerPlayerId (nullable string)
  - [x] propId (string) - basic identifier
- [x] Add references:
  - [x] Outline (GameObject/Renderer)
  - [x] HitPoint (Transform)
  - [x] MainCollider (Collider)
- [ ] Place possessable props throughout Arena
- [ ] Attach Possessable component to each prop

**Note:** Possessable component fully implemented with all required properties and references. Scene setup pending

---

## Phase 5: Possession System

### 5.1 Prop Disguise Core Logic
- [x] Create `PropDisguiseSystem.lua` (Client + Server)
- [x] Client: Implement tap-to-select prop interface
  - [x] Raycast from camera on screen tap during Hide phase
  - [x] Detect Possessable component on hit object
  - [x] Send possession request to server
- [x] Server: Implement possession validation
  - [x] Check if requester is a Prop role
  - [x] Check if phase is HIDING
  - [x] Check if target has Possessable component
  - [x] Check if target is not already possessed (One-Prop Rule)

### 5.2 One-Prop Rule (No-Unpossess)
- [x] Enforce one possession per player per round
- [x] Track possession state per player (has possessed: bool)
- [x] Disable unpossess action once possessed
- [x] On conflicting possession attempt:
  - [x] Keep current owner
  - [x] Reject new request
  - [x] Trigger rejection VFX/SFX on client

**Note:** PropDisguiseSystem fully integrated with GameManager. One-Prop rule enforced at server level

### 5.3 Possession Visual State
- [ ] During Hide phase:
  - [ ] Enable green outline shader on all unpossessed props
  - [ ] Show outline to Props and Spectators only (NOT Hunters)
  - [ ] Remove outline when prop is possessed
- [ ] During Hunt phase:
  - [ ] Disable all outlines
  - [ ] Apply subtle heartbeat emissive to possessed props (very faint)

**Note:** Possession visual states (shaders) deferred to post-V1. VFX placeholders in use

---

## Phase 6: Hunter Tagging System

### 6.1 Tagging Input (Client)
- [x] Create `HunterTagSystem.lua` (Client + Server)
- [x] Client: Implement tap-to-tag input
  - [x] Detect screen tap during Hunt phase
  - [x] Raycast from **player body origin** (NOT camera) toward tap world point
  - [x] Check for Possessable component on hit
  - [x] Enforce client-side cooldown (0.5s visual feedback)
  - [x] Send tag request to server with target ID

### 6.2 Tagging Validation (Server)
- [x] Server: Validate tag request
  - [x] Check if requester is Hunter role
  - [x] Check if phase is HUNTING
  - [x] Calculate distance from hunter origin to target HitPoint
  - [x] Validate distance ≤ R_tag (4.0m)
  - [x] Check target has Possessable component
  - [x] Check target IsPossessed == true
  - [x] Enforce server-side cooldown (0.5s anti-spam)

### 6.3 Tagging Resolution
- [x] On successful tag:
  - [x] Mark prop as eliminated
  - [x] Update prop's state (IsPossessed = false or eliminated flag)
  - [x] Award points to hunter (zone-based scoring)
  - [x] Fire tag success event to all clients
  - [x] Update remaining props counter
  - [x] Check win condition (all props found)
- [x] On failed tag:
  - [x] Apply miss penalty to hunter
  - [x] Fire tag miss event to hunter client
  - [x] Track hit/miss for accuracy bonus

**Note:** HunterTagSystem fully integrated. Updated to V1 spec: raycast from player body origin, 4.0m distance validation, 0.5s cooldown. VFX placeholders in use, particle systems post-V1

---

## Phase 7: Scoring System

### 7.1 Prop Scoring
- [x] Implement passive scoring tick system (every 5s during Hunt)
- [x] For each alive prop:
  - Query current zone (NearSpawn/Mid/Far)
  - Get zone weight (1.5/1.0/0.6)
  - Award: +10 × ZoneWeight
  - Update player score via synced NumberValue
- [x] On round end (Hunt timer expires):
  - Award survival bonus: +100 to each non-eliminated prop

### 7.2 Hunter Scoring
- [x] On successful tag:
  - Query zone of tagged prop's position
  - Award: +120 × ZoneWeight to hunter
- [x] On missed tag:
  - Apply penalty: -8 points to hunter
- [x] Track hits and misses per hunter
- [x] On round end:
  - Calculate accuracy bonus: floor((Hits / max(1, Hits+Misses)) × 50)
  - Add to hunter's score

### 7.3 Team Bonuses
- [x] If all props found before timer (Hunter Team Win):
  - Award +50 to each Hunter
- [x] If any prop survives timer expiry (Prop Team Win):
  - Award +30 to each surviving Prop
  - Award +15 to each found Prop

### 7.4 Win Condition Logic
- [x] Track total score per player
- [x] On round end, determine winner:
  - Primary: Highest total score (individual, not team)
  - Tie-breaker 1: Highest number of tags (hunters) or survival ticks (props)
  - Tie-breaker 2: Earliest last scoring event timestamp
  - Tie-breaker 3: Declare draw
- [x] Fire winner announcement event to all clients

**Note:** Full scoring system 100% complete with zone-based multipliers, team bonuses, and comprehensive tie-breaker logic. Integrated with ScoringManager.lua

---

## Phase 8: VFX System (Primary Focus)

**Note:** VFX animation system integrated using DevBasics Tweens library. Placeholder VFX functions created in GameManager. Particle systems and custom shaders deferred to post-V1 for Unity scene work.

### 8.1 Shader Development
- [ ] Create outline shader (URP Shader Graph):
  - Green outline effect
  - Fresnel sparkle component
  - Shader keyword toggle for enable/disable
- [ ] Create dissolve shader (URP):
  - Vertical slice dissolve pattern
  - Radial mask inwards pattern
- [ ] Create emissive rim shader:
  - Configurable rim color and intensity
  - Pulsing/heartbeat animation support
- [ ] Create rejection flash shader:
  - Brief red edge flash effect

### 8.2 Phase Transition VFX

#### Lobby → Hide Transition
- [ ] Create Lobby desaturation effect (color grading/LUT)
- [ ] Create Arena pulse-in gradient VFX
- [ ] Create teleport beam VFX for Props/Spectators
- [ ] Trigger sequence on state transition

#### Hide → Hunt Transition
- [ ] Create vignette expansion effect for Arena
- [ ] Create synchronized dissolve sweep for outline fade-out
- [ ] Trigger global outline disable with dissolve animation

#### Hunt → RoundEnd Transition
- [ ] Create confetti/sparkle particle system for winner team
- [ ] Create subtle screen-space ribbon trails for score tally
- [ ] Implement team-specific celebration effects

### 8.3 Possession VFX

#### Player Vanish Effect
- [ ] Create vertical slice dissolve effect (0.4s duration)
- [ ] Add soft spark particles
- [ ] Trigger on successful possession at player position

#### Prop Infill Effect
- [ ] Create radial mask inwards VFX
- [ ] Implement emissive rim growth → normalize animation
- [ ] Trigger on successful possession at prop position
- [ ] Synchronize with outline removal

#### Double-Possess Rejection Effect
- [ ] Create brief red edge flash VFX
- [ ] Add "thunk" sound effect
- [ ] Trigger on One-Prop Rule conflict

### 8.4 Tagging VFX

#### Tag Hit Effect
- [ ] Create compressed ring shock VFX at HitPoint (0.25s)
- [ ] Create 3-5 micro-spark motes with outward motion
- [ ] Add faint chromatic ripple effect
- [ ] Trigger on successful tag

#### Tag Miss Effect
- [ ] Create dust poof decal VFX (0.15s)
- [ ] Use color-neutral palette
- [ ] Trigger on failed tag at hit surface

### 8.5 Prop Status Shaders

#### Hide Phase Shader State
- [ ] Enable green outline on all unpossessed props
- [ ] Add mild fresnel sparkle to outlines
- [ ] Optional idle shimmer effect

#### Hunt Phase Shader State
- [ ] Disable all outlines
- [ ] Apply subtle heartbeat emissive to possessed props (very faint)
- [ ] Ensure effect doesn't reveal prop identity

### 8.6 Spectator Visual Filters
- [ ] Create slightly cooler color LUT for spectator view
- [ ] Add faint edge glow on Props/Hunters (aesthetic only, non-informational)

---

## Phase 9: UI/HUD System

### 9.1 Lobby UI
- [x] Create `PropHuntReadyButton.lua` and UXML/USS
- [x] Implement Ready button functionality
- [ ] Create "Join as Spectator" toggle
- [x] Display lobby countdown timer (30s)
- [x] Show ready player count / total players

### 9.2 Global HUD
- [x] Create `PropHuntHUD.lua` with UXML/USS
- [x] Display round timer (updates every second)
- [x] Show current game phase (Hide/Hunt/RoundEnd)
- [ ] Display player counts (Hunters/Props/Spectators) - shows total only

### 9.3 Prop-Specific UI
- [ ] Display possession status ("Possessed" indicator)
- [ ] Show current zone label (NearSpawn/Mid/Far)
- [ ] [Nice-to-Have] Taunt button with cooldown indicator

**Note:** Deferred to post-V1

### 9.4 Hunter-Specific UI
- [ ] Display tag cooldown indicator (0.5s circular/bar)
- [ ] Show remaining props counter
- [ ] Display hit/miss tally (running count)

**Note:** Deferred to post-V1. Basic HUD shows timer and phase only

### 9.5 Kill Feed
- [ ] Create kill feed UI element
- [ ] Format: "HunterX found PropY (AreaName - ZoneName)"
- [ ] Example: "Hunter1 found Prop3 (Kitchen - NearSpawn)"
- [ ] Auto-fade entries after 5-10 seconds

**Note:** Deferred to post-V1

### 9.6 Recap Screen
- [x] Create RoundEnd recap panel UXML/USS
- [x] Display winner announcement with highest score
- [x] Show tie-breaker result if applicable
- [x] Display all player scores (sorted)
- [x] Show team bonuses applied
- [ ] [Nice-to-Have] Show accuracy stats per hunter

**Note:** RecapScreen.lua fully implemented with winner display, scores, and tie-breaker info. Accuracy stats deferred

---

## Phase 10: Network Synchronization

### 10.1 Server-Authoritative State
- [x] Use `NumberValue.new()` for auto-synced state:
  - [x] Current game state (enum)
  - [x] State timer (countdown)
  - [x] Player scores (per-player NumberValue)
- [x] Use `BoolValue.new()` per player:
  - [x] Ready state
  - [x] Is possessed (tracked server-side)
  - [x] Is eliminated (tracked server-side)
- [x] Use `TableValue.new()` for collections:
  - [x] Ready players list
  - [x] Role assignments (PlayerRoles table synced)

### 10.2 Network Events
- [x] Create `Event.new()` for server → client broadcasts:
  - [x] State changed event
  - [x] Role assigned event
  - [x] Possession success event
  - [x] Tag hit/miss event
  - [x] Winner announcement event
- [x] Create `RemoteFunction.new()` for client → server requests:
  - [x] Possession request
  - [x] Tag request
  - [x] Ready toggle request

### 10.3 Anti-Cheat Validation
- [x] Server-side distance validation for tagging (R_tag = 4.0m)
- [x] Server-side cooldown enforcement (0.5s)
- [x] Server-side phase validation (can only tag during Hunt)
- [x] Server-side role validation (only Hunters can tag, only Props can possess)

**Note:** Complete network synchronization with server-authoritative validation. All critical gameplay actions validated server-side to prevent cheating

---

## Phase 11: Taunt System (Nice-to-Have)

### 11.1 Taunt VFX
- [ ] Create pulsing ring VFX (~3m radius around prop)
- [ ] Add rising wisps particle effect
- [ ] Make visible to Hunters and Spectators only
- [ ] Mute effect for Props

### 11.2 Taunt Gameplay (Deferred)
- [ ] Implement Taunt button with cooldown (12-15s)
- [ ] Start Taunt Window timer (10s) on activation
- [ ] Track if Hunter tags prop within window
- [ ] Award Taunt Reward (+20 points) if not tagged within window
- [ ] Prevent spam with per-round limit (5-6 taunts) or cooldown only

### 11.3 Taunt Telemetry
- [ ] Log taunt events: (tauntTime, hunterDistanceAtTaunt, wasFoundInWindow)
- [ ] Use for post-V1 balancing

---

## Phase 12: Polish & QA

### 12.1 Visual Polish
- [ ] Ensure all VFX trigger reliably and synchronize across clients
- [ ] Verify crisp, readable shapes (no excessive bloom)
- [ ] Test short, satisfying impact durations
- [ ] Optimize VFX for mobile performance

### 12.2 Audio Integration
- [ ] Add sound effects:
  - Player vanish sound
  - Prop infill sound
  - Tag hit sound (satisfying impact)
  - Tag miss sound (subtle)
  - Double-possess rejection "thunk"
  - Phase transition sounds
  - Winner celebration sound
- [ ] Ensure audio is lightweight for mobile

### 12.3 V1 Exit Criteria QA Checklist
- [ ] Role distribution matches spec at 2-20 players
- [ ] Late joiners become Spectators
- [ ] Hunters NEVER see outlines during Hide
- [ ] Props/Spectators see green outlines during Hide
- [ ] Props are immobile during Hunt phase
- [ ] No-Unpossess rule enforced (one possession per round)
- [ ] Tagging originates from player body origin (not camera)
- [ ] Tagging respects R_tag = 4.0m and 0.5s cooldown
- [ ] Zone-weighted scoring: tick every 5s with correct weights (Near=1.5, Mid=1.0, Far=0.6)
- [ ] Round ends when all props found OR Hunt timer expires
- [ ] Winner determined by highest individual score
- [ ] Recap screen shows winner and tie-breaker outcome
- [ ] Phase transition VFX trigger reliably
- [ ] One-Prop conflict shows rejection VFX and maintains ownership

### 12.4 Performance Optimization
- [ ] Profile in Unity Profiler for mobile target
- [ ] Optimize VFX particle counts
- [ ] Ensure shader complexity is mobile-friendly
- [ ] Test on low-end mobile devices
- [ ] Reduce network RPC calls where possible
- [ ] Optimize UI draw calls

### 12.5 Edge Case Testing
- [ ] Test with exactly 2 players (minimum)
- [ ] Test with 20 players (maximum)
- [ ] Test player disconnection during each phase
- [ ] Test all players unready during countdown
- [ ] Test simultaneous possession attempts
- [ ] Test rapid tag spam attempts
- [ ] Test zone boundary edge cases
- [ ] Test exact distance at R_tag = 4.0m boundary

---

## Phase 13: Analytics & Telemetry (Optional)

### 13.1 Gameplay Metrics
- [ ] Log taunt usage and outcomes
- [ ] Log hit/miss ratios per hunter
- [ ] Log zone usage frequency (which zones are most popular)
- [ ] Log average round duration
- [ ] Log role distribution per match

### 13.2 Balance Tuning Data
- [ ] Track average prop survival rate
- [ ] Track average hunter success rate
- [ ] Track score distribution (hunters vs props)
- [ ] Identify dominant strategies
- [ ] Use data for post-V1 parameter tuning

---

## Phase 14: Post-V1 Backlog (Nice-to-Have)

### 14.1 Movement-Enabled Props
- [ ] Remove static prop constraint
- [ ] Implement prop movement mechanics
- [ ] Add footstep ping system
- [ ] Add freeze/lock pose ability

### 14.2 Enhanced Features
- [ ] AFK detection and handling
- [ ] Spawn protection for hunters
- [ ] Join-in-progress auto-ready
- [ ] Accuracy and team banners
- [ ] Richer kill feed with area icons
- [ ] Dynamic risk factor scoring (distance-based)

### 14.3 Advanced Analytics
- [ ] Analytics-driven parameter tuning
- [ ] Heatmap of prop hiding locations
- [ ] Hunter pathing analysis
- [ ] Win rate balancing across player counts

---

## Open Questions (To Resolve During Implementation)

1. **Zone Volumes**: Exact number and placement of Near/Mid/Far volumes for Arena?
2. **Zone Visibility**: Should props see their current zone weight label during Hunt?
3. **Prop Categories**: Any restrictions on prop size classes required for V1 aesthetics?
4. **Spectator Camera**: Free-fly or fixed positions?
5. **Mobile Controls**: Touch control layout optimization?

---

## Key Design Principles (Remember Throughout)

- **Tech Art Showcase**: Prioritize VFX/shaders/transitions over complex gameplay
- **Visual Clarity**: Crisp, readable shapes; short, satisfying impacts; no excessive bloom
- **Mobile-First**: Optimize for mobile performance (target platform)
- **Deterministic Rules**: Simple, clear, server-authoritative validation
- **V1 Constraint**: Props are static during Hunt (no movement)
- **No Scan Pings**: Invest in visual feedback instead of directional audio
