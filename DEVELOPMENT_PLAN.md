# PropHunt Technical Art Assignment - Development Plan

**Assignment Period:** October 6-14, 2024 (8 days)  
**Deadline:** October 14, 2024  
**Role Focus:** Technical Artist  
**Repository:** https://github.com/erondiel/pocketworldstest

---

## 📋 PROJECT OVERVIEW

### Assignment Requirements (Original)
- Real-time multiplayer Prop Hunt game
- Round-based game loop: Lobby → Hide Phase → Hunt Phase → Round End → Repeat
- State machine for phase transitions
- Persistent player state (optional)
- UI/UX cues for gameplay

### Assignment Focus (Recruiter Clarification)
> "We are more interested in your artistic prowess! Please feel free to use your own assets as well to showcase your technical art skills."

### Deliverables
1. ✅ GitHub repository with all code
2. ✅ Playable Highrise game link
3. ✅ 5-minute Loom video (gameplay demo + architecture walkthrough)
4. ✅ Technical write-up (max 2 pages)

---

## 🎯 SCOPE DEFINITION

### MUST HAVE - Core Gameplay
- [x] Functional game loop (Lobby → Hide → Hunt → End → Repeat)
- [ ] Simple Lua-based state machine
- [ ] Two roles: Props (disguise) and Hunters (tag)
- [ ] Timer system driving phase transitions
- [ ] Win conditions (all props tagged = Hunters win, timer expires = Props win)
- [ ] Basic player spawning and role assignment

### MUST HAVE - Technical Art Focus ⭐
- [ ] **Prop disguise visual system** - Shader/VFX for transformation
- [ ] **Custom shaders** (2-3 showcase pieces)
  - [ ] Dissolve shader for prop transformation
  - [ ] Outline/highlight shader for hunter vision
- [ ] **VFX library**
  - [ ] Player spawn effect
  - [ ] Prop transformation effect
  - [ ] Tag hit effect
  - [ ] Round win/lose effects
- [ ] **Material system** - PBR materials for props and environment
- [ ] **Lighting setup** - Baked lightmaps, mood lighting, atmosphere
- [ ] **UI/UX visual design** - Styled elements (timers, role indicators, scores)

### NICE TO HAVE
- [ ] Persistent player stats (wins/losses) - if Highrise API makes it trivial
- [ ] Spectator mode for eliminated players
- [ ] Object-specific visual variations (speed trails, size effects)
- [ ] Sound effects integration

### OUT OF SCOPE ❌
- ❌ Anti-cheat systems
- ❌ Complex networking/edge case handling
- ❌ Reconnection/desync mitigation
- ❌ Server-authoritative validation beyond basics

---

## 📅 8-DAY SCHEDULE

### **Day 1: Monday, Oct 6 - Foundation** ✅ IN PROGRESS
**Status:** Setting up, learning framework

**Tasks:**
- [x] GitHub repository setup
- [x] Project analysis and planning
- [x] SpaceNavigator integration (partial - workaround created)
- [ ] Study Highrise Lua API documentation
- [ ] Test basic Lua scripting (Hello World test)
- [ ] Scene preparation (import modular assets)
- [ ] Art direction decisions

**Deliverables:**
- Development plan document
- Working Lua script test
- Scene layout started

---

### **Day 2: Tuesday, Oct 7 - Scene Setup & Core Architecture**
**Status:** Not started

**Code Tasks:**
- [ ] Create `PropHuntGameManager.lua` - Main state machine skeleton
- [ ] Create `RoleManager.lua` - Player role assignment system
- [ ] Test multiplayer player detection
- [ ] Basic spawn system

**Art Tasks:**
- [ ] Complete scene layout with spawn points
- [ ] Place hiding spots and prop locations
- [ ] Import all prop models (5-10 props)
- [ ] Basic material setup on props

**Deliverables:**
- Functional scene with spawns
- State machine foundation
- Player role assignment working

---

### **Day 3: Wednesday, Oct 8 - Core Gameplay Mechanics**
**Status:** Not started

**Code Tasks:**
- [ ] Implement state transitions (Lobby → Hide → Hunt → End)
- [ ] Timer system for each phase
- [ ] Prop disguise mechanic (mesh/material swapping)
- [ ] Hunter tagging system (raycast detection)
- [ ] Win condition logic

**Art Tasks:**
- [ ] Test gameplay mechanics as they're built
- [ ] Refine prop placement
- [ ] Start PBR material creation
- [ ] Plan shader requirements

**Deliverables:**
- Full game loop working (even if basic)
- Props can hide, hunters can tag
- Round resets properly

---

### **Day 4: Thursday, Oct 9 - Gameplay Polish & Bug Fixes**
**Status:** Not started

**Code Tasks:**
- [ ] Bug fixes from Day 3 testing
- [ ] Round reset and cleanup logic
- [ ] Basic UI implementation (timer display, role indicator)
- [ ] Player feedback systems (tagged notification, etc.)

**Art Tasks:**
- [ ] Playtest extensively and document bugs
- [ ] Continue material development
- [ ] Shader planning and mockups
- [ ] VFX planning document

**Deliverables:**
- Stable, playable game loop
- Bug list resolved
- Ready for visual enhancement phase

**MILESTONE:** Core gameplay must be 100% functional by end of Day 4

---

### **Day 5: Friday, Oct 10 - Technical Art Begins (BGS Day)**
**Status:** Not started

**Code Tasks:**
- [ ] Shader integration hooks in Lua
- [ ] VFX spawn/despawn system
- [ ] Particle effect trigger points
- [ ] UI animation framework

**Art Tasks:**
- [ ] Morning: Shader development start (dissolve effect)
- [ ] BGS attendance (limited work time)
- [ ] Evening: VFX planning and first effects

**Deliverables:**
- Shader foundation created
- Code ready for visual integration

---

### **Day 6: Saturday, Oct 11 - Visual Systems Implementation** ⭐
**Status:** Not started

**Code Tasks:**
- [ ] Integrate shaders into gameplay events
- [ ] VFX timing and synchronization
- [ ] Camera effects setup
- [ ] Performance optimization pass

**Art Tasks:**
- [ ] **SHADER CREATION DAY**
- [ ] Dissolve shader for prop transformation (complete)
- [ ] Outline/highlight shader for hunter detection (complete)
- [ ] Material polish on all props
- [ ] Start VFX creation (spawn, tag effects)

**Deliverables:**
- Working shaders integrated into game
- First VFX pass complete
- Materials polished

**MILESTONE:** All technical art systems functional by end of Day 6

---

### **Day 7: Sunday, Oct 12 - Polish & Integration** ⭐⭐
**Status:** Not started

**Code Tasks:**
- [ ] Connect all visual systems to game events
- [ ] Sound effect integration (if assets available)
- [ ] Final bug fixes
- [ ] Code cleanup and documentation
- [ ] Performance check (mobile optimization)

**Art Tasks:**
- [ ] Lighting pass (baked lightmaps, mood creation)
- [ ] Final VFX polish (win/lose effects, particles)
- [ ] UI visual design complete
- [ ] Final material tweaks
- [ ] Screenshot/video capture for documentation

**Deliverables:**
- Visually complete game
- All systems integrated and polished
- Performance optimized

---

### **Day 8: Monday, Oct 13 - Documentation Day**
**Status:** Not started

**Tasks:**
- [ ] Record Loom video (5 minutes)
  - [ ] Gameplay demonstration (2 min)
  - [ ] Architecture walkthrough (2 min)
  - [ ] Technical art showcase (1 min)
- [ ] Write technical document (2 pages)
  - [ ] Page 1: Visual systems & technical art
  - [ ] Page 2: Game architecture & implementation
- [ ] Create README.md for GitHub
- [ ] Final code comments and cleanup
- [ ] Create screenshots/GIFs for presentation
- [ ] Final Git commit and push

**Deliverables:**
- Complete documentation package
- Submission-ready materials

---

### **Day 9: Tuesday, Oct 14 - SUBMISSION DAY**
**Status:** Not started

**Tasks:**
- [ ] Final review of all materials
- [ ] Test Highrise game link
- [ ] Verify GitHub repository is public and complete
- [ ] Submit all deliverables
- [ ] 🎉 Celebrate!

---

## 🛠️ TECHNICAL ARCHITECTURE

### Highrise Lua Structure
```lua
--!Type(Server)  -- Server-side script
--!Type(Client)  -- Client-side script
--!Type(Module)  -- Shared code

--!SerializeField  -- Exposed to Unity Inspector
local variable: type = value

function self:ServerStart()  -- Server initialization
function self:ClientStart()  -- Client initialization
function self:Start()         -- Unity Start
function self:Update()        -- Unity Update
```

### Planned Lua Scripts

#### 1. **PropHuntGameManager.lua** (Server)
- State machine (4 states: Lobby, Hiding, Hunting, RoundEnd)
- Timer management
- Phase transitions
- Win condition detection
- Round reset logic

#### 2. **RoleManager.lua** (Server)
- Player role assignment (Props vs Hunters)
- Team balancing
- Role data synchronization

#### 3. **PropDisguiseSystem.lua** (Module)
- Prop selection interface
- Mesh/material swapping
- Visual transformation triggers (shader/VFX)

#### 4. **HunterTagSystem.lua** (Client + Server)
- Raycast detection (client)
- Tag validation (server)
- Hit feedback (VFX trigger)

#### 5. **TimerUI.lua** (Client)
- Countdown display
- Phase indicator
- Score display

#### 6. **VisualEffectsManager.lua** (Client)
- Spawn effects
- Transformation effects
- Tag hit effects
- Win/lose effects

---

## 🎨 ART ASSET PLAN

### Scene Assets
- [x] Modular scene system (existing, needs adaptation)
- [ ] Modified for PropHunt layout (smaller, optimized)
- [ ] Spawn points placed
- [ ] Hiding spots identified

### Props (5-10 items)
- [ ] List props to be used: ________________
- [ ] Import/create prop models
- [ ] UV mapping check
- [ ] Collision setup

### Materials
- [ ] PBR material setup
- [ ] Texture optimization (mobile-friendly)
- [ ] Material variations for props

### Shaders
1. **Dissolve Shader** - Prop transformation effect
   - [ ] Dissolve pattern texture
   - [ ] Emission during transition
   - [ ] Timing curve

2. **Outline Shader** - Hunter detection highlight
   - [ ] Configurable outline color
   - [ ] Pulsing effect
   - [ ] Distance-based intensity

3. **(Optional) Hologram Shader** - Lobby/spectator mode
   - [ ] Scanline effect
   - [ ] Transparency
   - [ ] Color tint

### VFX List
- [ ] Player spawn effect
- [ ] Prop transformation effect (particles + shader)
- [ ] Tag hit effect (impact particles)
- [ ] Hunter vision pulse effect
- [ ] Round win celebration effect
- [ ] Round loss effect

### Lighting
- [ ] Baked lightmaps for static geometry
- [ ] Realtime lights for dramatic accents
- [ ] Light probes for dynamic objects
- [ ] Reflection probes
- [ ] Atmospheric fog/particles

### UI Visual Design
- [ ] Timer display (stylized countdown)
- [ ] Role indicator (Prop/Hunter badge)
- [ ] Score display
- [ ] Round result screen
- [ ] Phase transition graphics

---

## 📊 SUCCESS METRICS

### Functional Requirements
- ✅ Game loop completes without errors
- ✅ 2+ players can join and play
- ✅ Props can successfully hide
- ✅ Hunters can successfully tag props
- ✅ Win conditions trigger correctly
- ✅ Round resets and repeats

### Technical Art Requirements
- ✅ Custom shaders visible and functional
- ✅ VFX integrated with gameplay events
- ✅ Materials demonstrate PBR workflow
- ✅ Lighting creates mood and atmosphere
- ✅ UI is visually polished
- ✅ Performance: 30+ FPS on mobile

### Documentation Requirements
- ✅ 5-minute video covers all key points
- ✅ 2-page write-up explains systems clearly
- ✅ GitHub repo is organized and documented
- ✅ Code is commented and readable

---

## 🚨 RISK MANAGEMENT

### Identified Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Highrise Lua API limitations | High | Early testing, simple fallbacks |
| Shader compatibility issues | Medium | Test early on mobile, standard URP shaders |
| Multiplayer sync complexity | High | Use Highrise built-in systems, avoid custom networking |
| Time constraints (interviews, BGS) | Medium | Front-load core gameplay, buffer on Day 8 |
| VFX performance on mobile | Medium | Optimize particle counts, use GPU particles sparingly |

### Contingency Plans

**If core gameplay takes longer than Day 4:**
- Simplify state machine (remove lobby, go straight to Hide phase)
- Remove spectator mode
- Basic UI only (text, no graphics)

**If shaders don't work as planned:**
- Use standard URP shaders with creative material setup
- Focus on VFX and lighting instead
- Document shader attempt in write-up

**If multiplayer is too complex:**
- Create single-player prototype with AI hunters
- Document multiplayer architecture theoretically
- Show that systems are "multiplayer-ready"

---

## 📝 DAILY LOG

### Day 1 (Oct 6) - Log
**Completed:**
- ✅ GitHub repository initialized and pushed
- ✅ Project analysis complete
- ✅ Development plan created (530-line comprehensive roadmap)
- ✅ SpaceNavigator partial integration (workaround script using reflection)
- ✅ Explored Highrise Lua structure from package cache examples
- ✅ Found Highrise Studio documentation portal (create.highrise.game)
- ✅ Reviewed best practices for optimization, UI, security

**Blockers:**
- Need to explore full API reference for multiplayer/server features
- Need to test basic Lua script creation workflow in Unity

**Next Session:**
- Navigate to https://create.highrise.game/learn/studio/scripting to find API details
- Test basic Lua script creation (Hello World)
- Import scene assets and begin layout
- List specific props for the game

**Notes:**
- SpaceNavigator has limited functionality (pan/zoom only, no rotation) due to Highrise editor restrictions
- Created `ForceSpaceNavigator.cs` workaround using reflection to bypass UI restrictions
- Framework uses Lua with `--!Type(Server)` and `--!Type(Client)` annotations
- Highrise emphasizes: optimize assets, reduce polygons, test on mobile devices
- Documentation available at create.highrise.game/learn/studio

---

## 📚 RESOURCES

### Documentation Links
- [x] Highrise Studio Best Practices: https://create.highrise.game/learn/studio/basics/best-practices
- [ ] Highrise Studio API Reference: https://create.highrise.game/learn/studio (explore further)
- [ ] Lua Scripting Guide: https://create.highrise.game/learn/studio/scripting
- [ ] Example projects: Check Highrise Studio dashboard/community

### Reference Files
- `Library/PackageCache/com.pz.studio@be2e4f637d27/Runtime/Lua/GeneralChat.lua` - Example module
- `Library/PackageCache/com.pz.studio@be2e4f637d27/Runtime/Lua/Camera/FirstPersonCamera.lua` - Example client script

### Key Code Patterns Discovered
```lua
-- Server player connection
server.PlayerConnected:Connect(function(player)
    -- Handle new player
end)

-- Access local player
client.localPlayer.character

-- Unity component access
self.gameObject:GetComponent(Camera)

-- Event connections
player.CharacterChanged:Connect(function(player, character)
    -- Handle character change
end)
```

---

## ✅ COMPLETION CHECKLIST

### Pre-Submission
- [ ] All code committed to GitHub
- [ ] Highrise game published and link tested
- [ ] Loom video recorded and uploaded
- [ ] Technical write-up completed (PDF)
- [ ] README.md complete with screenshots
- [ ] All assets properly attributed
- [ ] Repository is public
- [ ] Code is commented

### Submission Materials
- [ ] GitHub repository URL
- [ ] Highrise game link
- [ ] Loom video URL
- [ ] Technical write-up (PDF/Google Doc)
- [ ] Cover email/message prepared

---

## 🎯 PROJECT GOALS REMINDER

**Primary Goal:** Showcase technical artist skills through:
- Beautiful, polished visuals
- Custom shader development
- VFX integration
- Material artistry
- Lighting expertise

**Secondary Goal:** Demonstrate technical competence through:
- Functional game implementation
- Clean, readable code
- Problem-solving within framework constraints
- Professional documentation

**This is a portfolio piece, not production code.**

---

*Last Updated: October 6, 2024*

