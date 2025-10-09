# PropHunt Documentation Audit

**Date:** 2025-10-09
**Purpose:** Identify deprecated, redundant, and outdated documentation

---

## Summary

The PropHunt documentation has **significant redundancy** with multiple overlapping setup guides. Many documents were created iteratively during development and reference **outdated systems** (Scene Teleporter vs. single-scene teleportation).

---

## Recommendations

### ✅ KEEP (Primary Documentation)

**Root Directory:**
- `CLAUDE.md` - Main architecture reference for AI assistants (UPDATE to current state)
- `IMPLEMENTATION_PLAN.md` - Project timeline/milestones

**Assets/PropHunt/**
- `COMPLETE_UNITY_SETUP.md` - **PRIMARY SETUP GUIDE** (comprehensive checklist)
- `SINGLE_SCENE_SETUP.md` - **QUICK REFERENCE** for single-scene teleportation

**Assets/PropHunt/Documentation/**
- `README.md` - Project overview and folder structure
- `IMPLEMENTATION_GUIDE.md` - System-by-system implementation details
- `INPUT_SYSTEM.md` - Input handling patterns
- `Prop_Hunt__V1_Game_Design_Document_(Tech_ArtFocused).pdf` - Original GDD

---

### ⚠️ CONSOLIDATE OR DELETE (Redundant)

#### Unity Setup Guides (4+ overlapping documents)

**Problem:** Multiple setup guides with overlapping content at different detail levels

**Redundant Documents:**
1. `Assets/PropHunt/Documentation/QUICK_UNITY_SETUP.md` - 10-minute version
2. `Assets/PropHunt/Documentation/UNITY_SETUP_GUIDE.md` - Comprehensive 45-60 min version
3. `Assets/PropHunt/Documentation/UNITY_SCENE_FROM_SCRATCH.md` - 15-20 min version with module focus
4. `Assets/PropHunt/Documentation/UNITY_MODULE_SETUP_CHECKLIST.md` - Checklist only
5. `Assets/PropHunt/Documentation/VALIDATION_GUIDE.md` - Testing checklist

**Recommendation:**
- **KEEP:** `Assets/PropHunt/COMPLETE_UNITY_SETUP.md` (most comprehensive, in main folder)
- **KEEP:** `Assets/PropHunt/SINGLE_SCENE_SETUP.md` (concise teleporter reference)
- **DELETE:** All 5 docs listed above (redundant with COMPLETE_UNITY_SETUP.md)

---

#### Teleporter Documentation (6+ overlapping documents)

**Problem:** Teleporter system changed from Scene Teleporter asset (multi-scene) to single-scene position-based. Multiple outdated guides exist.

**Deprecated Documents (Reference SceneManager/Multi-Scene):**
1. `Assets/PropHunt/Documentation/TELEPORTER_INTEGRATION.md` - **OUTDATED** (uses SceneManager asset)
2. `Assets/PropHunt/Documentation/TELEPORTER_ARCHITECTURE.md` - **OUTDATED** (SceneManager architecture)
3. `Assets/PropHunt/Documentation/TELEPORTER_CODE_SNIPPETS.md` - **OUTDATED** (old API)
4. `Assets/PropHunt/Documentation/TELEPORTER_UNITY_SETUP.md` - **OUTDATED** (multi-scene setup)
5. `Assets/PropHunt/TELEPORTER_SETUP_GUIDE.md` - **OUTDATED** (choose Option 1 vs 2)
6. `Assets/PropHunt/TELEPORTER_QUICK_START.md` - **OUTDATED** (SceneManager setup)
7. `Assets/PropHunt/TELEPORTER_OPTION2.md` - **OUTDATED** (referenced but doesn't exist)
8. `Assets/PropHunt/Documentation/TELEPORTER_INTEGRATION_SUMMARY.md` - **OUTDATED**

**Current System (per CLAUDE.md):**
- Uses **single-scene position-based teleportation**
- Spawn points configured via SerializeFields in PropHuntConfig.lua
- No SceneManager asset needed

**Recommendation:**
- **DELETE:** All 8 teleporter docs listed above
- **UPDATE:** `SINGLE_SCENE_SETUP.md` to be the single source of truth for teleportation

---

#### Zone System Documentation (4 overlapping documents)

**Problem:** Multiple guides for same system

**Redundant Documents:**
1. `Assets/PropHunt/Documentation/ZONE_SYSTEM.md` - Detailed system explanation
2. `Assets/PropHunt/Documentation/ZONE_INTEGRATION_QUICK_START.md` - Quick start
3. `Assets/PropHunt/Documentation/ZONE_SYSTEM_DIAGRAM.md` - Architecture diagram
4. `Assets/PropHunt/Documentation/ZONE_SYSTEM_IMPLEMENTATION.md` - Implementation steps
5. `Assets/PropHunt/Documentation/ZONE_CODE_EXAMPLES.lua` - Code snippets
6. `Assets/PropHunt/Documentation/ZONE_QUICK_REFERENCE.txt` - Quick reference

**Recommendation:**
- **CONSOLIDATE:** Merge into single `ZONE_SYSTEM.md` with sections:
  - Overview + diagram
  - Unity setup (from ZONE_INTEGRATION_QUICK_START.md)
  - Code examples (from ZONE_CODE_EXAMPLES.lua)
  - Quick reference table
- **DELETE:** Other 5 zone docs

---

#### VFX Documentation (3 overlapping documents)

**Problem:** VFX system is placeholder-only in V1, but has extensive documentation

**Documents:**
1. `Assets/PropHunt/Documentation/VFX_SYSTEM.md` - System overview
2. `Assets/PropHunt/Documentation/VFX_ARCHITECTURE_DIAGRAM.md` - Architecture
3. `Assets/PropHunt/Documentation/VFX_INTEGRATION_EXAMPLES.md` - Examples
4. `Assets/PropHunt/Scripts/Modules/VFX_README.md` - Module-level README

**Current Status (per CLAUDE.md):**
- VFX framework integrated via PropHuntVFXManager.lua
- Uses **placeholder functions only**
- Particle systems and custom shaders **deferred to post-V1**

**Recommendation:**
- **CONSOLIDATE:** Merge into single `VFX_SYSTEM.md`
- **DELETE:** VFX_ARCHITECTURE_DIAGRAM.md, VFX_INTEGRATION_EXAMPLES.md
- **UPDATE:** Mark as "V2 Feature" with placeholder status

---

#### Range Indicator Documentation (3 documents)

**Documents:**
1. `Assets/PropHunt/Documentation/HUNTER_TAG_RANGE_SYSTEM.md` - Hunter tagging with range indicator
2. `Assets/PropHunt/Documentation/RANGE_INDICATOR_INTEGRATION.md` - Integration guide
3. `Assets/PropHunt/Documentation/RANGE_INDICATOR_SETUP.md` - Setup steps

**Recommendation:**
- **CONSOLIDATE:** Merge into single `HUNTER_TAG_SYSTEM.md` (covers tagging + range indicator)
- **DELETE:** Other 2 docs

---

#### Recap Screen Documentation (5 documents)

**Documents:**
1. `Assets/PropHunt/Documentation/RECAP_SCREEN_INTEGRATION.md`
2. `Assets/PropHunt/Documentation/RECAP_SCREEN_QUICKSTART.md`
3. `Assets/PropHunt/Documentation/RECAP_SCREEN_README.md`
4. `Assets/PropHunt/Documentation/RECAP_SCREEN_SUMMARY.md`
5. `Assets/PropHunt/Documentation/RECAP_SCREEN_CHECKLIST.md`
6. `Assets/PropHunt/Documentation/RECAP_SCREEN_EXAMPLE.lua`

**Recommendation:**
- **CONSOLIDATE:** Merge into single `RECAP_SCREEN.md` with sections:
  - Overview
  - Integration steps
  - Example code (from .lua file)
  - Checklist
- **DELETE:** Other 5 docs

---

#### Module Setup/Registration Documents (3 documents)

**Documents:**
1. `Assets/PropHunt/Documentation/COMPLETE_MODULE_CHECKLIST.md`
2. `Assets/PropHunt/Documentation/FINAL_MODULE_SETUP.md`
3. `Assets/PropHunt/Documentation/MODULE_REGISTRATION_FIX.md`
4. `Assets/PropHunt/Documentation/DEVBASICS_TWEENS_SETUP_SUMMARY.md`

**Recommendation:**
- **DELETE:** All 4 (content now covered in COMPLETE_UNITY_SETUP.md)
- Module registration is straightforward (attach to GameObject), doesn't need standalone docs

---

#### Outdated Status Documents

**Documents:**
1. `Assets/PropHunt/CRITICAL_FIXES_APPLIED.md` - Historical fixes log
2. `Assets/PropHunt/FINAL_VERIFICATION.md` - Old verification checklist
3. `Assets/PropHunt/UNITY_VALIDATION_CHECKLIST.md` - Redundant with VALIDATION_GUIDE.md

**Recommendation:**
- **DELETE:** All 3 (superseded by current documentation)

---

## Proposed New Documentation Structure

```
PropHunt/
├── CLAUDE.md (AI assistant reference - UPDATED)
├── IMPLEMENTATION_PLAN.md (Timeline)
└── Assets/PropHunt/
    ├── COMPLETE_UNITY_SETUP.md (PRIMARY SETUP GUIDE)
    ├── SINGLE_SCENE_SETUP.md (Teleporter quick reference)
    ├── Documentation/
    │   ├── README.md (Project overview)
    │   ├── IMPLEMENTATION_GUIDE.md (System details)
    │   ├── INPUT_SYSTEM.md (Input patterns)
    │   ├── ZONE_SYSTEM.md (CONSOLIDATED)
    │   ├── VFX_SYSTEM.md (CONSOLIDATED, marked V2)
    │   ├── HUNTER_TAG_SYSTEM.md (CONSOLIDATED)
    │   ├── RECAP_SCREEN.md (CONSOLIDATED)
    │   └── Prop_Hunt__V1_Game_Design_Document_(Tech_ArtFocused).pdf
    └── Editor/
        └── README.md (Editor tools reference)
```

**Total Reduction:** ~35 documents → ~12 documents (-65% redundancy)

---

## Update Priorities

### High Priority (Do First)
1. **DELETE outdated Teleporter docs** (8 files) - References wrong system
2. **UPDATE CLAUDE.md** - Remove auto-commit instruction, reflect current state
3. **UPDATE SINGLE_SCENE_SETUP.md** - Clarify as single source of truth for teleportation

### Medium Priority
4. **CONSOLIDATE Zone docs** (6 → 1 file)
5. **CONSOLIDATE VFX docs** (4 → 1 file)
6. **DELETE redundant Unity setup guides** (5 files)

### Low Priority
7. **CONSOLIDATE Recap Screen docs** (6 → 1 file)
8. **CONSOLIDATE Hunter Tag/Range docs** (3 → 1 file)
9. **DELETE module setup docs** (4 files)
10. **DELETE outdated status docs** (3 files)

---

## Notes

- The **Documentation/README.md** references several deleted docs - needs update after consolidation
- Many docs reference "Day 2", "October 8, 2024" timestamps - consider removing temporal references
- **IMPLEMENTATION_PLAN.md** likely outdated (references Oct 14, 2024 deadline) - review separately
- Git status shows many .md files modified but not committed - suggests ongoing documentation churn

---

## Specific Issues Found

### CLAUDE.md Issues
1. Contains Git commit workflow instructions that should be removed per user request
2. References `/DEVELOPMENT_PLAN.md` which may not exist (couldn't find in project)
3. References `Assets/PropHunt/Docs/` folder for GDD, but it's actually in `Documentation/`

### Teleporter Documentation Issues
1. **TELEPORTER_OPTION2.md** is referenced but doesn't exist in the filesystem
2. Multiple docs reference SceneManager GameObject setup, but current implementation uses SerializeFields
3. Conflicting information between "separate scenes" vs "single scene" approach

### README.md Issues
1. Lists many files/folders that may not exist (Shaders/, VFX/, Audio/, etc.)
2. Implementation status outdated (lists possession as "In Progress", actually complete)
2. References deleted/consolidated documentation files

---

## Action Items

**For User:**
- [ ] Review and approve consolidation plan
- [ ] Decide whether to keep historical docs (CRITICAL_FIXES_APPLIED.md) for reference

**For Claude:**
- [ ] Edit CLAUDE.md to remove auto-commit instructions
- [ ] Create consolidated documents where approved
- [ ] Delete redundant documents where approved
- [ ] Update cross-references in remaining docs
