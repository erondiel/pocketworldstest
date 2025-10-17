# PropHunt V1 - Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- **EndRoundScore System** - Complete end-of-round scoring UI with player rankings (commit 0d570ae, 67757aa)
  - Displays all players ranked by score (highest to lowest)
  - Highlights top 3 players (Gold/Silver/Bronze styling)
  - Shows player rank, name, score, and original role
  - Winner-only overlay with celebration message (transparent background)
  - Automatically hides when returning to LOBBY
  - Uses Global Event Pattern for Module-to-UI communication

- **Global Event Pattern** - Cross-script communication solution (commit 67757aa, 3b25e00)
  - `_G.PH_EndRoundScoresEvent` - Broadcasts end-round scores from GameManager to UI
  - `_G.PH_StateChangedEvent` - Broadcasts state changes for UI visibility control
  - Enables Module scripts to communicate with UI scripts via shared Event instances

- **Original Role Tracking** - Preserves player roles for accurate score display (commit 3b25e00)
  - Tracks roles assigned at round start in `originalRoles` table
  - Eliminated props display as "Prop" instead of "Spectator" in score screen
  - Spectators display as "Spectator" throughout the game

- **Phase Transition VFX** - Visual effects for game state changes (commit f1efe17)
  - Lobby transition VFX with configurable parameters
  - Hide phase start VFX for props team
  - Hunt phase start VFX
  - End round VFX with winning team celebration
  - All VFX use DevBasics Tweens library for animations

### Fixed
- **Duplicate Tag Prevention** - Props can only be tagged once per round (current session)
  - Removed possessed props from tracking table immediately after successful tag
  - Prevents VFX/animation from triggering multiple times on the same prop
  - Subsequent taps on already-tagged props now correctly trigger miss penalty

- **Winner Overlay Background** - Removed black background for better visibility (commit 3b25e00)
  - Changed from `rgba(0, 0, 0, 0.85)` to transparent
  - Players can now see the score leaderboard behind the winner celebration

- **EndRoundScore UI Persistence** - Score screen now hides when returning to lobby (commit 3b25e00)
  - Listens to `PH_StateChangedEvent` for LOBBY transition
  - Automatically hides score container and winner overlay via CSS classes
  - UI GameObject remains active for event listener registration

- **EndRoundScore Event Communication** - Fixed Module-to-UI Event isolation issue (commit 67757aa)
  - Root cause: Module scripts and UI scripts created separate Event instances
  - Solution: Global Event Pattern using `_G.` namespace for shared Event objects
  - Event data now successfully broadcasts from server to all clients

- **Space Attribute Syntax** - Fixed Unity build warnings (commit f1efe17)
  - Changed `--!Space(10)` to `--!Space` (no parameters)
  - Fixed 16 occurrences across PropHuntConfig, PropHuntVFXManager, and PropHuntLogger

- **VFX Scale Synchronization** - Enhanced player appear VFX with prop scaling (commit 4457c6c)
  - Player appear animation now scales based on possessed prop size
  - Smoother visual transition when props are revealed

- **Avatar Restoration and VFX Timing** - Improved synchronization (commit 8a5ea85)
  - Fixed race conditions between avatar restoration and VFX animations
  - Better coordination between teleportation and visual effects

### Changed
- **Score Broadcast Method** - Changed from `FireClient` loop to `FireAllClients` (commit 67757aa)
  - More efficient single broadcast instead of per-player loop
  - Improves network performance during ROUND_END phase

- **EndRoundScore Lifecycle** - Changed from `ClientAwake()` to `Start()` (commit 67757aa)
  - Ensures UI elements are fully initialized before event registration
  - Follows best practices for UI Toolkit script initialization

- **EndRoundScore Visibility Control** - Changed from `SetActive()` to CSS classes (commit 67757aa)
  - GameObject stays active entire game for event listener registration
  - Visibility managed via `hidden` CSS class (display: none)
  - Prevents timing issues with GameObject activation/deactivation

### Technical Details

#### Highrise SDK Event System Limitation
Module scripts (`--!Type(Module)`) and UI scripts (`--!Type(UI)`) create **separate Event instances** even when using the same event name. This prevents cross-type communication without the Global Event Pattern.

**Example - Broken Communication:**
```lua
-- GameManager.lua (Module)
local myEvent = Event.new("MyEvent")  -- Creates instance A

-- MyUI.lua (UI)
local myEvent = Event.new("MyEvent")  -- Creates instance B (different!)
```

**Solution - Global Event Pattern:**
```lua
-- GameManager.lua (Module)
_G.MyEvent = Event.new("MyEvent")  -- Create in global namespace
local myEvent = _G.MyEvent

-- MyUI.lua (UI)
local myEvent = _G.MyEvent  -- Access same instance
```

#### VFX System Architecture
- **VFXManager Module** - Central coordinator for all visual effects
- **DevBasics Tweens** - Animation library for scale, fade, and position tweens
- **Network Events** - VFX triggers broadcast from server to all clients for synchronization
- **Particle Systems** - Prefabs for possession, tagging, and phase transitions (stored in `Assets/PropHunt/VFX/`)

---

## [0.1.0] - 2025-01-XX

### Initial Implementation
- Core game loop with state machine (LOBBY → HIDING → HUNTING → ROUND_END)
- Player role assignment (Props vs Hunters)
- Prop possession system with One-Prop Rule
- Hunter tagging system with distance validation (4.0m range)
- Zone-based scoring system (NearSpawn/Mid/Far multipliers)
- Ready-up system with lobby countdown
- Spectator mode with mid-game join support
- Single-scene teleportation (Lobby ↔ Arena)
- Network synchronization using Highrise SDK primitives
- Server-authoritative validation for all gameplay actions

---

## Version History

**Current Version:** V1 (Pre-release)
**Target Platform:** Highrise Studio (Unity 2022.3+)
**SDK Version:** com.pz.studio@0.23.0
**Render Pipeline:** Universal Render Pipeline (URP 14.0.9)
