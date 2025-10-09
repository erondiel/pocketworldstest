# GEMINI.md

This file provides guidance to Gemini when working with code in this repository.

## Project Overview

**PropHunt V1** is a round-based, hide-and-seek multiplayer game for the Highrise Studio platform. In this game, players are divided into two teams: "Props," who hide by disguising themselves as objects in the game world, and "Hunters," who search for the Props. The game is built with Unity 2022.3+ and the Highrise Studio SDK, utilizing the Universal Render Pipeline (URP).

**Tech Stack**:
*   **Game Logic**: Lua
*   **Editor Tools**: C#
*   **UI**: UXML/USS
*   **Version Control**: Git with Conventional Commits (`commitizen`)

## Architecture

The game's architecture is centered around a server-authoritative state machine that manages the game flow. This ensures that all critical gameplay actions are validated on the server to prevent cheating.

### State Machine

The core of the game is a finite state machine implemented in `PropHuntGameManager.lua`. The game progresses through the following states:

*   **LOBBY**: Players join and ready up. A minimum of two players is required to start.
*   **HIDING**: Props are teleported to the arena to choose their disguises.
*   **HUNTING**: Hunters are teleported to the arena to find and tag the Props.
*   **ROUND_END**: The round concludes, and the results and scores are displayed.

### Module System

The game's functionality is organized into a modular system, with different modules responsible for specific aspects of the game. These modules are located in `Assets/PropHunt/Scripts/Modules/` and are attached to a **PropHuntModules** GameObject in the Unity scene.

**Key Server Modules**:
*   `PropHuntConfig.lua`: Central configuration for all game parameters.
*   `PropHuntGameManager.lua`: The main state machine controller.
*   `PropHuntPlayerManager.lua`: Manages player connections and ready states.
*   `PropHuntScoringSystem.lua`: Handles the zone-weighted scoring and tie-breaker logic.
*   `PropHuntTeleporter.lua`: Manages single-scene, position-based teleportation between the lobby and the arena.

**Key Client Systems**:
*   `HunterTagSystem.lua`: Manages the tap-to-tag input for Hunters.
*   `PropDisguiseSystem.lua`: Handles the tap-to-select prop possession for Props.

## Building and Running

This is a Unity project, so all development, building, and running is done through the Unity Editor.

1.  **Open the project in Unity Hub**, ensuring you have Unity version 2022.3 or later installed.
2.  **Open the main scene**, which is likely located in `Assets/PropHunt/Scenes/`.
3.  **Press the Play button** in the Unity Editor to run the game in a simulated environment.

There are no specific build scripts in the `package.json` file, as all building and running is handled by the Unity Editor.

## Development Conventions

The project follows a set of development conventions to maintain code quality and consistency.

### Code Style

*   **Lua**:
    *   `PascalCase` for functions (e.g., `GetPlayerScore`).
    *   `camelCase` for local functions (e.g., `onPlayerTagged`).
    *   `PH_` prefix for network events (e.g., `PH_StateChanged`).
*   **C#**: Follows standard C# and Unity conventions.


### Testing and Debugging

*   **Debug Mode**: Can be enabled via the `_enableDebug` SerializeField in `PropHuntConfig.lua`.
*   **Console Output**: The game provides detailed console logs with prefixes to identify the source of the log message (e.g., `[PropHunt]`, `[ScoringSystem]`).
