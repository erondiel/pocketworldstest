# PropHunt File Organization Report

Generated: 2025-10-16

## Issues Found

### 1. Duplicate Documentation Folders

**Problem:** Two documentation folders exist with overlapping purpose
- `Assets/PropHunt/Docs/` - Contains 4 markdown files
- `Assets/PropHunt/Documentation/` - Contains 9 markdown files

**Solution:** Consolidate all documentation into `Documentation/` folder and remove `Docs/`

#### Files to Move from Docs/ to Documentation/:
1. `LOGGER_USAGE.md` - Logger system usage guide
2. `REMOTE_EXECUTION_PATTERN.md` - Remote execution pattern documentation
3. `VFX_IMPLEMENTATION_SUMMARY.md` - VFX implementation summary (likely superseded by VFX_SYSTEM.md)
4. `VFX_SYSTEM_GUIDE.md` - VFX system guide (likely superseded by VFX_SYSTEM.md)

### 2. Misplaced Scripts in Scripts/ Root

**Problem:** Several scripts are in `Scripts/` root that should be in subfolders

#### Scripts That Should Be in Modules/:
- **PropHuntConfig.lua** - Central configuration module (--!Type(Module))
- **PropHuntGameManager.lua** - Main game manager module (--!Type(Module))
- **HunterTagSystem.lua** - Client tag system module (--!Type(Module))
- **PropPossessionSystem.lua** - Possession system module (--!Type(Module))
- **PropHuntRangeIndicator.lua** - Range indicator module (--!Type(Module))

#### Scripts That Should Be in Testing/:
- **DebugCheats.lua** - Debug/cheat commands
- **DebugVirtualPlayerOffset.lua** - Virtual player debug tool
- **VirtualPlayerDebugManager.lua** - Virtual player manager
- **ValidationTest.lua** - Validation testing script
- **UnitySceneSetup.lua** - Scene setup helper (could also stay in root for visibility)

#### Scripts That Should Stay in Scripts/ Root:
- **ZoneVolume.lua** - Component script attached to GameObjects (--!Type(Server))
- **PropOutline.lua** - Component script for prop outlines

### 3. Deprecated/Redundant Documentation Files

#### Potentially Deprecated Files:

**In Docs/ folder:**
- `VFX_IMPLEMENTATION_SUMMARY.md` - Likely superseded by `Documentation/VFX_SYSTEM.md`
- `VFX_SYSTEM_GUIDE.md` - Likely superseded by `Documentation/VFX_SYSTEM.md`

**In root Assets/PropHunt/:**
- `COMPLETE_UNITY_SETUP.md` - Unity setup guide (keep but may need update)
- `SINGLE_SCENE_SETUP.md` - Single scene setup guide (keep but may need update)
- `TELEPORTER_OPTION2.md` - Alternative teleporter design (deprecated - using single-scene teleporter)

**In Documentation/:**
- `EMISSION_TEST_GUIDE.md` - Testing guide for emission (may be deprecated if testing is complete)
- `OUTLINE_ENHANCEMENT_NOTES.md` - Enhancement notes (may be deprecated)
- `INPUT_SYSTEM.md` - Input system documentation (needs review for current implementation)

### 4. Test Scenes

**In Scenes/ folder:**
- `Scenes/test/` - Test scene (check if still used)
- `Scenes/test2/` - Second test scene (check if still used)
- `Scenes/prophunt/` - Main scene (keep)

## Recommended File Structure

```
Assets/PropHunt/
├── Documentation/           # ALL documentation goes here
│   ├── README.md           # Main documentation index
│   ├── VFX_SYSTEM.md       # VFX system (current, keep)
│   ├── ZONE_SYSTEM.md      # Zone system (keep)
│   ├── SPECTATOR_SYSTEM.md # Spectator system (keep)
│   ├── SPECTATOR_UI_DESIGN.md # Spectator UI (keep)
│   ├── POSSESSION_SYSTEM_GUIDE.md # Possession guide (keep)
│   ├── IMPLEMENTATION_GUIDE.md # Implementation guide (keep)
│   ├── IMPLEMENTATION_PLAN.md # Implementation plan (keep)
│   ├── LOGGER_USAGE.md     # [MOVE FROM Docs/]
│   ├── REMOTE_EXECUTION_PATTERN.md # [MOVE FROM Docs/]
│   ├── COMPLETE_UNITY_SETUP.md # [MOVE FROM root]
│   ├── SINGLE_SCENE_SETUP.md # [MOVE FROM root]
│   └── [DEPRECATED]/       # Archive deprecated docs here
│       ├── TELEPORTER_OPTION2.md
│       ├── VFX_IMPLEMENTATION_SUMMARY.md
│       ├── VFX_SYSTEM_GUIDE.md
│       ├── EMISSION_TEST_GUIDE.md (maybe)
│       ├── OUTLINE_ENHANCEMENT_NOTES.md (maybe)
│       └── INPUT_SYSTEM.md (maybe)
│
├── Scripts/
│   ├── Modules/            # Core game modules
│   │   ├── PropHuntConfig.lua # [MOVE FROM Scripts/]
│   │   ├── PropHuntGameManager.lua # [MOVE FROM Scripts/]
│   │   ├── PropHuntLogger.lua
│   │   ├── PropHuntPlayerManager.lua
│   │   ├── PropHuntScoringSystem.lua
│   │   ├── PropHuntTeleporter.lua
│   │   ├── PropHuntUIManager.lua
│   │   ├── PropHuntVFXManager.lua
│   │   ├── PropPossessionSystem.lua # [MOVE FROM Scripts/]
│   │   ├── HunterTagSystem.lua # [MOVE FROM Scripts/]
│   │   ├── PropHuntRangeIndicator.lua # [MOVE FROM Scripts/]
│   │   └── ZoneManager.lua
│   │
│   ├── GUI/                # UI scripts
│   │   ├── EndRoundScore.lua
│   │   ├── PropHuntHUD.lua
│   │   ├── PropHuntReadyButton.lua
│   │   ├── PropHuntRecapScreen.lua
│   │   ├── PropHuntSpectatorButton.lua
│   │   └── PropHuntVFXTestButton.lua
│   │
│   ├── Testing/            # Test and debug scripts
│   │   ├── AvatarPossessionTest.lua
│   │   ├── PropEmissionTest.lua
│   │   ├── SpectatorToggleTest.lua
│   │   ├── VFXSpawnTest.lua
│   │   ├── DebugCheats.lua # [MOVE FROM Scripts/]
│   │   ├── DebugVirtualPlayerOffset.lua # [MOVE FROM Scripts/]
│   │   ├── VirtualPlayerDebugManager.lua # [MOVE FROM Scripts/]
│   │   └── ValidationTest.lua # [MOVE FROM Scripts/]
│   │
│   ├── ZoneVolume.lua      # Component script (stays in root)
│   ├── PropOutline.lua     # Component script (stays in root)
│   └── UnitySceneSetup.lua # Scene setup helper (stays for visibility)
│
└── [DELETE] Docs/          # Remove after moving all files
```

## Action Items

### Priority 1: Documentation Consolidation
1. Move 4 files from `Docs/` to `Documentation/`
2. Create `Documentation/[DEPRECATED]/` folder
3. Move deprecated documentation to archive folder
4. Delete empty `Docs/` folder
5. Move `COMPLETE_UNITY_SETUP.md` and `SINGLE_SCENE_SETUP.md` from root to `Documentation/`

### Priority 2: Script Organization
1. Move 5 module scripts to `Modules/` folder
2. Move 4 debug/test scripts to `Testing/` folder
3. Update any file references in documentation

### Priority 3: Documentation Review
1. Review `EMISSION_TEST_GUIDE.md` - determine if deprecated
2. Review `OUTLINE_ENHANCEMENT_NOTES.md` - determine if deprecated
3. Review `INPUT_SYSTEM.md` - determine if needs update or deprecation
4. Compare `VFX_SYSTEM_GUIDE.md` with `VFX_SYSTEM.md` - consolidate if needed

### Priority 4: Test Scene Cleanup
1. Review `Scenes/test/` - delete if not used
2. Review `Scenes/test2/` - delete if not used
3. Keep `Scenes/prophunt/` as main scene

## File Movement Commands

```bash
# Create deprecated folder
mkdir -p "/path/to/Assets/PropHunt/Documentation/[DEPRECATED]"

# Move Docs/ files to Documentation/
mv "/path/to/Assets/PropHunt/Docs/LOGGER_USAGE.md" "/path/to/Assets/PropHunt/Documentation/"
mv "/path/to/Assets/PropHunt/Docs/REMOTE_EXECUTION_PATTERN.md" "/path/to/Assets/PropHunt/Documentation/"
mv "/path/to/Assets/PropHunt/Docs/VFX_IMPLEMENTATION_SUMMARY.md" "/path/to/Assets/PropHunt/Documentation/[DEPRECATED]/"
mv "/path/to/Assets/PropHunt/Docs/VFX_SYSTEM_GUIDE.md" "/path/to/Assets/PropHunt/Documentation/[DEPRECATED]/"

# Move deprecated docs
mv "/path/to/Assets/PropHunt/TELEPORTER_OPTION2.md" "/path/to/Assets/PropHunt/Documentation/[DEPRECATED]/"

# Move root docs to Documentation/
mv "/path/to/Assets/PropHunt/COMPLETE_UNITY_SETUP.md" "/path/to/Assets/PropHunt/Documentation/"
mv "/path/to/Assets/PropHunt/SINGLE_SCENE_SETUP.md" "/path/to/Assets/PropHunt/Documentation/"

# Move scripts to Modules/
mv "/path/to/Assets/PropHunt/Scripts/PropHuntConfig.lua" "/path/to/Assets/PropHunt/Scripts/Modules/"
mv "/path/to/Assets/PropHunt/Scripts/PropHuntGameManager.lua" "/path/to/Assets/PropHunt/Scripts/Modules/"
mv "/path/to/Assets/PropHunt/Scripts/HunterTagSystem.lua" "/path/to/Assets/PropHunt/Scripts/Modules/"
mv "/path/to/Assets/PropHunt/Scripts/PropPossessionSystem.lua" "/path/to/Assets/PropHunt/Scripts/Modules/"
mv "/path/to/Assets/PropHunt/Scripts/PropHuntRangeIndicator.lua" "/path/to/Assets/PropHunt/Scripts/Modules/"

# Move debug scripts to Testing/
mv "/path/to/Assets/PropHunt/Scripts/DebugCheats.lua" "/path/to/Assets/PropHunt/Scripts/Testing/"
mv "/path/to/Assets/PropHunt/Scripts/DebugVirtualPlayerOffset.lua" "/path/to/Assets/PropHunt/Scripts/Testing/"
mv "/path/to/Assets/PropHunt/Scripts/VirtualPlayerDebugManager.lua" "/path/to/Assets/PropHunt/Scripts/Testing/"
mv "/path/to/Assets/PropHunt/Scripts/ValidationTest.lua" "/path/to/Assets/PropHunt/Scripts/Testing/"
```

**⚠️ IMPORTANT:** Don't forget to move the `.meta` files along with each file!

## Benefits of Reorganization

1. **Single documentation source** - No confusion about which folder to check
2. **Better script organization** - Modules, GUI, and Testing are clearly separated
3. **Deprecated file archive** - Old docs preserved but clearly marked as outdated
4. **Cleaner root directory** - Setup guides moved to Documentation/
5. **Easier navigation** - Logical folder structure matches code architecture

## Notes

- All `.meta` files must be moved along with their corresponding files to maintain Unity references
- After moving files, update CLAUDE.md to reflect new file locations
- Git should track these moves as renames, not deletions + additions
