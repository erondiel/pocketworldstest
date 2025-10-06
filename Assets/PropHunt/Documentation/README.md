# PropHunt - Technical Art Showcase

This folder contains all assets and scripts for the PropHunt multiplayer game.

## Folder Structure

```
PropHunt/
├── Scenes/              - Game scenes
├── Scripts/             - Lua game logic scripts
├── Prefabs/
│   ├── Props/          - Disguisable prop prefabs
│   └── UI/             - UI element prefabs
├── Materials/
│   ├── Props/          - PBR materials for props
│   └── Environment/    - Environment materials
├── Shaders/            - Custom shaders (dissolve, outline, etc.)
├── VFX/                - Particle effects and visual effects
├── Audio/
│   ├── Music/          - Background music
│   └── SFX/            - Sound effects
└── Environment/
    └── Modular/        - Modular environment pieces
```

## Core Scripts

- **PropHuntGameManager.lua** - Main game loop and state machine
- **PropDisguiseSystem.lua** - Prop transformation mechanics (TODO)
- **HunterTagSystem.lua** - Tagging and elimination system (TODO)
- **PropHuntUI.lua** - User interface controller (TODO)

## Technical Art Features

### Shaders
- Dissolve shader for prop transformations
- Outline shader for hunter vision mode

### VFX
- Player spawn effects
- Prop transformation effects
- Tag hit effects
- Round win/lose effects

### Materials
- PBR workflow for all props
- Optimized for mobile performance

## Development Timeline

**Target Deadline:** October 14, 2024

See `DEVELOPMENT_PLAN.md` in project root for detailed schedule.

