# Repository Guidelines

## Project Structure & Module Organization
PropHunt-specific content lives under `Assets/PropHunt`, with gameplay Lua modules inside `Scripts` and reusable managers under `Scripts/Modules` (for example `PropHuntPlayerManager.lua`). Keep scene-facing prefabs in `Prefabs`, art and shaders in their named sibling folders, and reference documentation in `Docs` / `Documentation`. Ship scenes from `Assets/PropHunt/Scenes/test.unity`; duplicate this scene for new variants instead of overwriting it. Exported builds belong in `Build/Studio`, while shared packages and configuration stay in `Packages` and `ProjectSettings`. Leave generated Unity folders (`Library`, `Logs`, `UserSettings`) untouched to avoid merge noise.

## Build, Test, and Development Commands
Open the project with Unity 6000.0.55f1 via the Hub or `Unity -projectPath "$(pwd)"`. Produce unattended builds with `Unity -batchmode -quit -projectPath "$(pwd)" -buildTarget StandaloneWindows64 -executeMethod BuildPipeline.BuildPlayer`, updating the target as needed. During playtesting, load `test.unity` and enter Play Mode; `ValidationTest.lua` will surface required setup checks in the Console. Run the optional commit workflow with `npm install` once and `npm run commit` to launch the Commitizen wizard that enforces our Conventional Commit format.

## Coding Style & Naming Conventions
Lua gameplay files use 4-space indentation, PascalCase module names, and start with the `--!Type(Module)` directive when they are One Commander modules. Prefer descriptive NetworkValue and Event identifiers (e.g. `PH_StateTimer`). Keep client-only helpers in the same folder as their consumer and suffix experimental scripts with `Debug`. C# utilities (such as `DisableSpaceNavigatorDrift.cs`) follow standard Unity C# conventions: PascalCase classes, camelCase fields, and `[SerializeField]` for exposed members. Avoid adding Unity Gizmo code to production modules—place editor tooling under `Assets/PropHunt/Editor`.

## Testing Guidelines
Smoke-test every change in `test.unity` with at least two networked players to exercise `PropHuntGameManager.lua` transitions (Lobby → Hiding → Hunting → RoundEnd). Watch the Console for `PH_` prefixed logs from the manager, teleporter, and scoring modules; resolve warnings before merging. Update or clone `ValidationTest.lua` when adding new required components so automated checks stay current. Capture short gameplay clips or screenshots for feature branches touching VFX or UI to document expected behaviours.

## Commit & Pull Request Guidelines
Follow the repo’s Conventional Commit history (`feat`, `fix`, `docs`, scoped like `fix(Teleporter): …`). Use `npm run commit` or ensure manual messages adhere to `type(scope): summary`. Each PR should include: a concise problem statement, testing notes (e.g. “Play Mode with 2 players, Windows build”), and screenshots or videos for visual changes. Link to tracking tickets or Notion docs where available, and request review from the systems owner for affected modules before merging. Never create git commits automatically; leave commit creation to repository contributors.
