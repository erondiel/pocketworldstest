# PropHunt VFX System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PropHunt VFX System                         │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      HIGH-LEVEL LAYER (Lua)                         │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │          PropHuntVFXManager.lua (Module)                     │   │
│  │                                                               │   │
│  │  ┌─────────────────┐  ┌──────────────────┐  ┌─────────────┐ │   │
│  │  │ UI Animations   │  │  GameObject VFX  │  │ Placeholders│ │   │
│  │  │                 │  │                  │  │             │ │   │
│  │  │ • FadeIn()      │  │ • ScalePulse()   │  │ • PlayerVan │ │   │
│  │  │ • FadeOut()     │  │ • PositionTween()│  │ • PropInfil │ │   │
│  │  │ • SlideIn()     │  │ • ColorTween()   │  │ • Rejection │ │   │
│  │  │                 │  │                  │  │ • TagHitVFX │ │   │
│  │  └─────────────────┘  └──────────────────┘  │ • TagMissVF │ │   │
│  │           │                     │            └─────────────┘ │   │
│  │           └─────────────────────┘                    │        │   │
│  │                       │                              │        │   │
│  │                       ▼                              │        │   │
│  │            ┌──────────────────────┐                  │        │   │
│  │            │   Helper Functions   │                  │        │   │
│  │            │                      │                  │        │   │
│  │            │ • CreateSequence()   │                  │        │   │
│  │            │ • CreateGroup()      │                  │        │   │
│  │            │ • DebugVFX()         │                  │        │   │
│  │            └──────────────────────┘                  │        │   │
│  └────────────────────────│────────────────────────────┘        │   │
│                            │                                      │   │
│                            ▼                                      │   │
│                  ┌─────────────────────┐                          │   │
│                  │   require()         │                          │   │
│                  └─────────────────────┘                          │   │
└─────────────────────────┼───────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    CORE ANIMATION LAYER                              │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │        devx_tweens.lua (DevBasics Toolkit Module)           │   │
│  │                                                               │   │
│  │  ┌──────────────┐  ┌──────────────────┐  ┌───────────────┐ │   │
│  │  │  Tween       │  │  TweenSequence   │  │  TweenGroup   │ │   │
│  │  │  Class       │  │  Class           │  │  Class        │ │   │
│  │  │              │  │                  │  │               │ │   │
│  │  │ • new()      │  │ • new()          │  │ • new()       │ │   │
│  │  │ • start()    │  │ • add()          │  │ • add()       │ │   │
│  │  │ • stop()     │  │ • start()        │  │ • start()     │ │   │
│  │  │ • pause()    │  │ • stop()         │  │ • stop()      │ │   │
│  │  │ • resume()   │  │ • update()       │  │ • pause()     │ │   │
│  │  │ • update()   │  │                  │  │ • resume()    │ │   │
│  │  └──────────────┘  └──────────────────┘  └───────────────┘ │   │
│  │                                                               │   │
│  │  ┌────────────────────────────────────────────────────────┐ │   │
│  │  │              Easing Functions (16 types)               │ │   │
│  │  │                                                         │ │   │
│  │  │  Basic:    linear, easeIn/Out/InOut Quad              │ │   │
│  │  │  Cubic:    easeIn/Out/InOut Cubic                     │ │   │
│  │  │  Expo:     easeIn/Out Expo                            │ │   │
│  │  │  Back:     easeIn/Out Back, easeInBackLinear          │ │   │
│  │  │  Elastic:  easeIn/Out Elastic                         │ │   │
│  │  │  Sine:     easeIn/Out Sine                            │ │   │
│  │  │  Bounce:   bounce                                     │ │   │
│  │  └────────────────────────────────────────────────────────┘ │   │
│  │                                                               │   │
│  │  ┌────────────────────────────────────────────────────────┐ │   │
│  │  │           Vector/Color Lerp Support                    │ │   │
│  │  │                                                         │ │   │
│  │  │  • lerpVector2()     (UI positions)                    │ │   │
│  │  │  • lerpVector3()     (3D positions/scales)             │ │   │
│  │  │  • lerpColor()       (RGBA color values)               │ │   │
│  │  └────────────────────────────────────────────────────────┘ │   │
│  │                                                               │   │
│  │  ┌────────────────────────────────────────────────────────┐ │   │
│  │  │              Update Loop (ClientUpdate)                │ │   │
│  │  │                                                         │ │   │
│  │  │  Every frame:                                          │ │   │
│  │  │    1. Update all active tweens                         │ │   │
│  │  │    2. Update all sequences                             │ │   │
│  │  │    3. Update all groups                                │ │   │
│  │  │    4. Clean up finished tweens                         │ │   │
│  │  └────────────────────────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Simple Animation Flow

```
User Script                PropHuntVFXManager           devx_tweens
    │                             │                          │
    │  VFX.FadeIn(element, 0.5)  │                          │
    │─────────────────────────────>                         │
    │                             │                          │
    │                             │  Create Tween object     │
    │                             │  from: 0, to: 1          │
    │                             │  duration: 0.5           │
    │                             │  easing: easeOutQuad     │
    │                             │  onUpdate: set opacity   │
    │                             │──────────────────────────>
    │                             │                          │
    │                             │  Tween:start()           │
    │                             │──────────────────────────>
    │                             │                          │
    │                             │  (Tween registered)      │
    │                             │<──────────────────────────
    │                             │                          │
    │  Return tween reference     │                          │
    │<─────────────────────────────                         │
    │                             │                          │
    │                                                        │
    │                        (Every frame in ClientUpdate)  │
    │                             │                          │
    │                             │  tween:update(deltaTime) │
    │                             │<──────────────────────────
    │                             │                          │
    │                             │  Call onUpdate callback  │
    │                             │  with current value      │
    │                             │──────────────────────────>
    │                             │                          │
    │  element.style.opacity = value (called by tween)      │
    │<──────────────────────────────────────────────────────────
    │                             │                          │
    │                             │  (When t >= 1.0)         │
    │                             │                          │
    │                             │  Call onComplete         │
    │                             │  callback                │
    │                             │──────────────────────────>
    │                             │                          │
    │  Callback executed          │  Cleanup tween           │
    │<─────────────────────────────<──────────────────────────
    │                             │                          │
```

---

## Integration Flow

### PropDisguiseSystem Integration

```
PropDisguiseSystem.lua (Client)
    │
    │  Player taps prop to possess
    │
    ▼
┌────────────────────────────────┐
│  OnPossessionAttempt()         │
│                                 │
│  1. Get tap position            │
│  2. Raycast to find prop        │
│  3. Send request to server      │
└────────────────────────────────┘
    │
    │  Server validates
    │
    ▼
┌────────────────────────────────┐
│  Server: ValidatePossession()  │
│                                 │
│  1. Check if prop available     │
│  2. Check player role           │
│  3. Apply possession OR reject  │
└────────────────────────────────┘
    │
    │  Fire event to clients
    │
    ▼
┌────────────────────────────────┐
│  Client: OnPossessionResult()  │
│                                 │
│  if success:                    │
│    VFX.PlayerVanishVFX(...)    │──┐
│    VFX.PropInfillVFX(...)      │──┼──> PropHuntVFXManager
│  else:                          │  │
│    VFX.RejectionVFX(...)       │──┘
└────────────────────────────────┘
```

---

### HunterTagSystem Integration

```
HunterTagSystem.lua (Client)
    │
    │  Hunter taps to tag
    │
    ▼
┌────────────────────────────────┐
│  Input.Tapped:Connect()        │
│                                 │
│  1. Get tap position            │
│  2. Raycast from player origin  │
│  3. Check if hit prop           │
└────────────────────────────────┘
    │
    ├──> Hit prop?
    │    │
    │    ├─ Yes ──> Send to server + Play VFX.TagHitVFX(...)
    │    │
    │    └─ No ───> Play VFX.TagMissVFX(...)
    │
    ▼
┌────────────────────────────────┐
│  Server: ValidateTag()         │
│                                 │
│  1. Check cooldown              │
│  2. Check distance              │
│  3. Confirm hit OR reject       │
└────────────────────────────────┘
    │
    │  If confirmed, broadcast to all clients
    │
    ▼
┌────────────────────────────────┐
│  All Clients: OnTagConfirmed() │
│                                 │
│  VFX.TagHitVFX(hitPoint, prop) │──> PropHuntVFXManager
│  Eliminate prop player          │
└────────────────────────────────┘
```

---

## Phase Transition Flow

```
PropHuntGameManager.lua
    │
    │  State machine tick
    │
    ▼
┌────────────────────────────────┐
│  TransitionToState(newState)   │
│                                 │
│  Match state:                   │
│    • LOBBY                      │
│    • HIDING                     │
│    • HUNTING                    │
│    • ROUND_END                  │
└────────────────────────────────┘
    │
    │  Fire state change event
    │
    ▼
┌────────────────────────────────┐
│  StateChangeEvent:FireAllClients│
│                                 │
│  Broadcast: (newState, timer)   │
└────────────────────────────────┘
    │
    ▼
┌────────────────────────────────┐
│  Client: OnStateChanged()      │
│                                 │
│  if HIDING:                     │
│    • Desaturate lobby           │
│    • VFX.ColorTween(light)     │──┐
│    • Enable prop outlines       │  │
│                                 │  │
│  if HUNTING:                    │  │
│    • Fade outlines              │  ├──> PropHuntVFXManager
│    • VFX animations             │  │
│                                 │  │
│  if ROUND_END:                  │  │
│    • Show winner VFX            │  │
│    • VFX.ScalePulse(confetti)  │──┘
└────────────────────────────────┘
```

---

## UI Animation Flow

```
PropHuntHUD.lua (Client)
    │
    │  Game event occurs
    │
    ▼
┌────────────────────────────────┐
│  ShowPhaseBanner(phaseName)    │
│                                 │
│  1. Get UI element              │
│  2. Set text                    │
│  3. Position off-screen         │
└────────────────────────────────┘
    │
    ▼
┌────────────────────────────────┐
│  Create TweenGroup              │
│                                 │
│  group:add(VFX.SlideIn(...))   │──┐
│  group:add(VFX.FadeIn(...))    │  ├──> PropHuntVFXManager
│  group.onComplete = HoldBanner  │  │
│  group:start()                  │──┘
└────────────────────────────────┘
    │
    │  Wait 2 seconds
    │
    ▼
┌────────────────────────────────┐
│  HidePhaseBanner(banner)       │
│                                 │
│  group:add(VFX.SlideIn(...))   │──┐
│  group:add(VFX.FadeOut(...))   │  ├──> PropHuntVFXManager
│  group.onComplete = Hide        │  │
│  group:start()                  │──┘
└────────────────────────────────┘
```

---

## Tween Lifecycle

```
┌────────────────────────────────────────────────────────────────┐
│                      Tween Lifecycle                           │
└────────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │  Created    │  Tween:new(...) called
    │  (idle)     │
    └──────┬──────┘
           │
           │  tween:start()
           │
           ▼
    ┌─────────────┐
    │   Running   │  Added to tweens table
    │             │  Updated every ClientUpdate
    └──────┬──────┘
           │
           │  Every frame: update(deltaTime)
           │
           ├─────────────────────────────┐
           │                             │
           ▼                             ▼
    ┌─────────────┐            ┌──────────────┐
    │  Paused     │            │  Delayed     │
    │             │            │  (waiting)   │
    └──────┬──────┘            └──────┬───────┘
           │                           │
           │  tween:resume()          │  delay elapsed
           │                           │
           └────────────┬──────────────┘
                        │
                        ▼
                 ┌─────────────┐
                 │  Animating  │
                 │             │
                 │  Call onUpdate(value, t)
                 │  every frame
                 └──────┬──────┘
                        │
                        │  t >= 1.0 (finished)
                        │
           ┌────────────┼────────────┐
           │                         │
           ▼                         ▼
    ┌─────────────┐          ┌─────────────┐
    │  Looping    │          │  Finished   │
    │             │          │             │
    │  Reset to   │          │  Call onComplete()
    │  start OR   │          │  Remove from table
    │  reverse    │          │  (auto cleanup)
    └──────┬──────┘          └─────────────┘
           │
           │  Continue animating
           │
           └─────────────────┐
                             │
                             ▼
                      ┌─────────────┐
                      │  Stopped    │
                      │             │
                      │  tween:stop()
                      │  Manual cleanup
                      └─────────────┘
```

---

## Sequence vs Group Execution

### TweenSequence (Sequential)

```
Timeline: ──────────────────────────────────────>

Sequence: [Tween1] ──> [Tween2] ──> [Tween3] ──> onComplete()
             0.5s         0.3s         0.2s

          |<─────────── Total: 1.0s ──────────>|

Example:
  seq:add(FadeIn)      // Runs first  (0.0 - 0.5s)
  seq:add(ScalePulse)  // Then this   (0.5 - 0.8s)
  seq:add(FadeOut)     // Finally     (0.8 - 1.0s)
```

---

### TweenGroup (Parallel)

```
Timeline: ──────────────────────────────────────>

Group:    [Tween1] ──────────────────>
          [Tween2] ──────>
          [Tween3] ──────────────────────────> onComplete()
             │        │              │
             │        │              └─ Longest determines total time
             │        └─ Shorter tweens finish early
             └─ All start simultaneously

Example:
  grp:add(FadeIn)      // All three start at t=0
  grp:add(SlideIn)     //
  grp:add(ScalePulse)  // Group completes when longest finishes
```

---

## File Relationships

```
PropHunt Project
│
├── Assets/PropHunt/Scripts/
│   │
│   ├── Modules/
│   │   │
│   │   ├── PropHuntVFXManager.lua ◄─────┐
│   │   │   (Main VFX wrapper)           │
│   │   │                                 │
│   │   ├── PropHuntPlayerManager.lua    │
│   │   ├── PropHuntUIManager.lua        │
│   │   ├── PropHuntScoringSystem.lua    │
│   │   └── ...                           │
│   │                                     │
│   ├── PropDisguiseSystem.lua ──────────┤ require()
│   ├── HunterTagSystem.lua ─────────────┤
│   ├── PropHuntGameManager.lua ─────────┤
│   ├── GUI/                              │
│   │   ├── PropHuntHUD.lua ──────────────┤
│   │   └── ...                           │
│   │                                     │
│   └── PropHuntConfig.lua ◄──────────────┘
│       (Debug logging)
│
├── Assets/Downloads/DevBasics Toolkit/Scripts/Shared/
│   │
│   ├── devx_tweens.lua ◄─── required by PropHuntVFXManager
│   │   (Core animation engine)
│   │
│   └── devx_utils.lua
│       (Helper functions)
│
└── Assets/PropHunt/Documentation/
    │
    ├── VFX_SYSTEM.md
    │   (Full API reference)
    │
    ├── VFX_INTEGRATION_EXAMPLES.md
    │   (Code examples)
    │
    ├── VFX_README.md
    │   (Quick reference)
    │
    └── VFX_ARCHITECTURE_DIAGRAM.md
        (This file)
```

---

## Future Architecture (Post-V1)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FUTURE VFX ARCHITECTURE                          │
└─────────────────────────────────────────────────────────────────────┘

PropHuntVFXManager.lua
    │
    ├─> VFX Pooling System
    │   │
    │   ├─ Particle pool (reuse GameObjects)
    │   └─ Audio pool (reuse AudioSource)
    │
    ├─> Shader Controller
    │   │
    │   ├─ Dissolve shader (_DissolveAmount)
    │   ├─ Infill shader (_InfillProgress)
    │   ├─ Outline shader (_OutlineColor, _OutlineIntensity)
    │   └─ Emissive shader (_EmissiveRim)
    │
    ├─> Particle System Manager
    │   │
    │   ├─ PlayerVanishVFX.prefab
    │   ├─ PropInfillVFX.prefab
    │   ├─ TagHitVFX.prefab
    │   ├─ TagMissVFX.prefab
    │   └─ RejectionVFX.prefab
    │
    ├─> Audio Manager Integration
    │   │
    │   ├─ VFX sound effects
    │   └─ Positional audio
    │
    └─> Network Sync
        │
        ├─ VFX events for multiplayer
        └─ Client prediction
```

---

## Performance Considerations

### Mobile Optimization Strategy

```
┌────────────────────────────────────────────────────────────┐
│                    Performance Budget                       │
└────────────────────────────────────────────────────────────┘

Per-Frame Tween Updates:
    • Target: < 10 active tweens per frame
    • Max: 20 active tweens (emergency)
    • Each tween: ~0.01ms (negligible)

Particle Systems:
    • Max particles per effect: < 50
    • Max simultaneous effects: < 5
    • Lifetime: < 1.0s

Memory:
    • Tweens auto-cleanup when finished
    • No memory leaks from abandoned tweens
    • VFX pooling (future) reduces Instantiate calls

Network:
    • VFX events: < 100 bytes per event
    • Fire only when needed (not every frame)
    • Local client prediction for responsiveness
```

---

## Error Handling

```
PropHuntVFXManager Error Handling Flow

┌────────────────────────────────────────┐
│  VFX Function Called                   │
│  (e.g., FadeIn(element, 0.5))          │
└────────────────┬───────────────────────┘
                 │
                 ▼
          ┌──────────────┐
          │  Validate    │
          │  Parameters  │
          └──────┬───────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
  ┌─────────┐      ┌─────────┐
  │  Valid  │      │ Invalid │
  │         │      │         │
  └────┬────┘      └────┬────┘
       │                │
       │                ▼
       │         ┌──────────────┐
       │         │  Log Debug   │
       │         │  Warning     │
       │         │              │
       │         │  Return nil  │
       │         └──────────────┘
       │
       ▼
┌──────────────┐
│  Create      │
│  Tween       │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Return      │
│  Tween Ref   │
└──────────────┘

Example:
  if not element then
      DebugVFX("FadeIn called with nil element")
      return nil
  end
```

---

## Summary

This architecture provides:

1. **Layered Design**: High-level wrapper over core tween engine
2. **Modular**: Each VFX type is self-contained
3. **Extensible**: Easy to add new VFX functions
4. **Debuggable**: Built-in logging and validation
5. **Performant**: Optimized for mobile, auto-cleanup
6. **Future-Proof**: Clear path to particle systems and shaders

The system is production-ready with placeholder VFX and can be progressively enhanced as art assets become available.
