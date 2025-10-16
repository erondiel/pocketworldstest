# PropHunt Technical Write-up
## Highrise Studio Take-Home Assessment

---

## Page 1: Game Design Document & Code Implementation

**Core Game Loop & State Machine**
PropHunt implements a server-authoritative finite state machine: `LOBBY → HIDING → HUNTING → ROUND_END → LOBBY`

- **LOBBY**: Players ready up (minimum 2 players)
- **HIDING**: Props teleport to arena and select disguises (35s)
- **HUNTING**: Hunters teleport to arena and tag props (240s)
- **ROUND_END**: Display results and scores (15s)

**Multiplayer Architecture & Anti-Cheat**
Built on Highrise Studio SDK using Unity 6 with URP:
- **Network Sync**: `NumberValue`, `BoolValue`, `TableValue`, `Event`, `RemoteFunction`
- **Server Validation**: Tag distance (≤4.0m), cooldown (≥0.5s), phase/role validation
- **Edge Cases**: Desync prevention, reconnection handling, dynamic role assignment (2-20 players)
- **Performance**: Single-scene teleportation, efficient zone detection, mobile-first design

**Scoring System**
Zone-based multipliers: NearSpawn (1.5x), Mid (1.0x), Far (0.6x). Props: +10×ZoneWeight/5s + 100 survival. Hunters: +120×ZoneWeight/tag, -8/miss, accuracy bonus.

**Code Architecture Highlights**
- Server-authoritative validation prevents cheating
- One-Prop Rule with static props during hunt phase
- Raycast origin from player body (not camera)
- Efficient network event patterns with minimal bandwidth

---

## Page 2: Technical Art & Implementation

**Custom Shader Pipeline**
**GodrayUnlit Shader**: Multi-beam volumetric lighting with procedural generation, UV offset controls, dual fade system (Tip/Base), additive blending for atmospheric depth. Features configurable beam count (1-10), spacing, width, and softness with real-time parameter adjustment.

**Advanced Shader Features:**
- WidthMask function with unrolled loops for performance
- LengthMask with dual attenuation (tip/base fade)
- UV offset controls for dynamic positioning
- Additive blending pipeline for atmospheric effects
- Mobile-optimized with LOD considerations

**VFX System Architecture**
Integrated `PropHuntVFXManager.lua` with DevBasics Tweens library:
- **Phase Transitions**: Smooth camera movements, UI fade effects, state change animations
- **Possession Effects**: Player vanish, prop with emissive glow
- **Tag Effects**: Hit/miss particle systems, screen shake (TBD)
- **Rejection Effects**: Visual feedback for invalid actions, cooldown indicators (TBD)

**Technical Art Features:**
- Dynamic lighting system with godray effects for atmospheric immersion
- Custom prop shaders with emissive states for possession
- Smooth UI transitions with tween-based animations

**Assets Implementation Workflow**
- **Unity Pipeline**: Structured asset hierarchy in `Assets/PropHunt/`
- **Prefab Creation**: 30+ prop prefabs with standardized collision meshes and "Possessable" tags, zone volumes with BoxCollider triggers and ZoneVolume.lua scripts, spawn point markers for teleportation system
- **Scene Assembly**: URP lighting setup with directional/ambient lighting

**Future Enhancements (1 Week Extension):**
- **Performance & Optimization**: Shader LOD system for different quality settings, efficient particle pooling for VFX reuse, mobile-optimized rendering pipeline with texture streaming, memory-conscious asset streaming, optimized lightmap resolution for mobile devices, efficient collision mesh generation for props
- **Profiling & Analysis**: Performance profiling for mobile device
- **Advanced VFX**: Advanced particle effects for possession/tagging, cinematic transitions.
