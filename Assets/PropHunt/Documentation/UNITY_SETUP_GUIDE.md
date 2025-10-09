# PropHunt Unity Scene Setup Guide

**Comprehensive step-by-step guide for setting up a PropHunt scene from scratch**

**Total Estimated Time:** 45-60 minutes
**Difficulty:** Intermediate
**Unity Version:** 2022.3+
**Required:** Highrise Studio SDK installed

---

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] Unity 2022.3 or later installed
- [ ] Highrise Studio package (com.pz.studio@0.23.0) installed
- [ ] Project opened in Unity
- [ ] Universal Render Pipeline (URP) configured
- [ ] Basic understanding of Unity hierarchy and inspector
- [ ] All PropHunt Lua scripts compiled (check Packages/com.pz.studio.generated)

---

## Part 1: Zone Volumes (3 zones, ~15 min)

Zone volumes define scoring multipliers for props based on location. We need three zones: NearSpawn (1.5x), Mid (1.0x), and Far (0.6x).

### Zone 1: NearSpawn (5 min)

**Step 1.1: Create GameObject**
- [ ] Right-click in Hierarchy → Create Empty
- [ ] Name it exactly: `Zone_NearSpawn`
- [ ] Set Transform Position: `X: 95, Y: 0, Z: 0`

**Step 1.2: Add Box Collider**
- [ ] Select `Zone_NearSpawn` in Hierarchy
- [ ] Inspector → Add Component → Box Collider
- [ ] Set Box Collider properties:
  - [ ] **Is Trigger:** ✓ (checked)
  - [ ] **Center:** X: 0, Y: 5, Z: 0
  - [ ] **Size:** X: 15, Y: 10, Z: 20

**Step 1.3: Configure Tags**
- [ ] Inspector → Tag dropdown → Add Tag...
- [ ] Click + to add new tag
- [ ] Type: `Zone_NearSpawn`
- [ ] Save
- [ ] Select `Zone_NearSpawn` GameObject again
- [ ] Set Tag to: `Zone_NearSpawn`

**Step 1.4: Add ZoneVolume Component (if available)**
- [ ] Inspector → Add Component → Search "ZoneVolume"
- [ ] If ZoneVolume script exists, add it
- [ ] Set ZoneWeight field to: `1.5`
- [ ] **Note:** If ZoneVolume doesn't exist, you'll create it later

**Step 1.5: Visual Marker (Optional)**
- [ ] Right-click `Zone_NearSpawn` → 3D Object → Cube
- [ ] Name it: `ZoneMarker`
- [ ] Set Transform:
  - [ ] Position: X: 0, Y: 5, Z: 0
  - [ ] Scale: X: 15, Y: 10, Z: 20
- [ ] Remove Box Collider component (we only need parent's trigger)
- [ ] Set Material to semi-transparent green (for editor visibility)
- [ ] Disable MeshRenderer in build (or delete after setup)

### Zone 2: Mid (5 min)

**Step 2.1: Create GameObject**
- [ ] Hierarchy → Create Empty
- [ ] Name: `Zone_Mid`
- [ ] Transform Position: `X: 110, Y: 0, Z: 0`

**Step 2.2: Add Box Collider**
- [ ] Add Component → Box Collider
- [ ] **Is Trigger:** ✓
- [ ] **Center:** X: 0, Y: 5, Z: 0
- [ ] **Size:** X: 20, Y: 10, Z: 20

**Step 2.3: Configure Tags**
- [ ] Add new tag: `Zone_Mid` (same process as Step 1.3)
- [ ] Set GameObject Tag to: `Zone_Mid`

**Step 2.4: Add ZoneVolume Component**
- [ ] Add Component → ZoneVolume (if available)
- [ ] Set ZoneWeight: `1.0`

**Step 2.5: Visual Marker (Optional)**
- [ ] Create child Cube named `ZoneMarker`
- [ ] Position: X: 0, Y: 5, Z: 0
- [ ] Scale: X: 20, Y: 10, Z: 20
- [ ] Semi-transparent yellow material

### Zone 3: Far (5 min)

**Step 3.1: Create GameObject**
- [ ] Hierarchy → Create Empty
- [ ] Name: `Zone_Far`
- [ ] Transform Position: `X: 130, Y: 0, Z: 0`

**Step 3.2: Add Box Collider**
- [ ] Add Component → Box Collider
- [ ] **Is Trigger:** ✓
- [ ] **Center:** X: 0, Y: 5, Z: 0
- [ ] **Size:** X: 15, Y: 10, Z: 20

**Step 3.3: Configure Tags**
- [ ] Add new tag: `Zone_Far`
- [ ] Set GameObject Tag to: `Zone_Far`

**Step 3.4: Add ZoneVolume Component**
- [ ] Add Component → ZoneVolume (if available)
- [ ] Set ZoneWeight: `0.6`

**Step 3.5: Visual Marker (Optional)**
- [ ] Create child Cube named `ZoneMarker`
- [ ] Position: X: 0, Y: 5, Z: 0
- [ ] Scale: X: 15, Y: 10, Z: 20
- [ ] Semi-transparent red material

### Organization

**Step 3.6: Create Zones Parent**
- [ ] Hierarchy → Create Empty
- [ ] Name: `Zones`
- [ ] Position: X: 0, Y: 0, Z: 0
- [ ] Drag all three zone GameObjects into Zones parent

---

## Part 2: Spawn Points (2 points, ~8 min)

Spawn points determine where players teleport during phase transitions.

### Spawn 1: Lobby Spawn (4 min)

**Step 4.1: Create GameObject**
- [ ] Hierarchy → Create Empty
- [ ] Name: `LobbySpawn`
- [ ] Transform Position: `X: 0, Y: 0, Z: 0`
- [ ] Transform Rotation: `X: 0, Y: 90, Z: 0`

**Step 4.2: Configure Tags**
- [ ] Add new tag: `SpawnPoint`
- [ ] Set Tag to: `SpawnPoint`

**Step 4.3: Add Visual Marker**
- [ ] Right-click `LobbySpawn` → 3D Object → Sphere
- [ ] Name: `SpawnMarker`
- [ ] Transform:
  - [ ] Position: X: 0, Y: 0, Z: 0
  - [ ] Scale: X: 0.5, Y: 0.5, Z: 0.5
- [ ] Remove Sphere Collider (or disable it)
- [ ] Set Material to bright blue (for editor visibility)

**Step 4.4: Add Identifier Component (Optional)**
- [ ] Add a text component or custom script to identify: "LOBBY"
- [ ] This helps distinguish spawn points in code

### Spawn 2: Arena Spawn (4 min)

**Step 5.1: Create GameObject**
- [ ] Hierarchy → Create Empty
- [ ] Name: `ArenaSpawn`
- [ ] Transform Position: `X: 100, Y: 0, Z: 0`
- [ ] Transform Rotation: `X: 0, Y: -90, Z: 0`

**Step 5.2: Configure Tags**
- [ ] Set Tag to: `SpawnPoint`

**Step 5.3: Add Visual Marker**
- [ ] Create child Sphere: `SpawnMarker`
- [ ] Position: X: 0, Y: 0, Z: 0
- [ ] Scale: X: 0.5, Y: 0.5, Z: 0.5
- [ ] Remove/disable collider
- [ ] Material: Bright green

**Step 5.4: Organization**
- [ ] Create parent GameObject: `SpawnPoints`
- [ ] Drag `LobbySpawn` and `ArenaSpawn` into parent

---

## Part 3: Scene Manager (1 object, ~5 min)

The Scene Manager is the brain of the game, controlling state transitions and game logic.

### Step 6: Create Scene Manager GameObject (5 min)

**Step 6.1: Create GameObject**
- [ ] Hierarchy → Create Empty
- [ ] Name: `PropHuntSceneManager`
- [ ] Position: `X: 0, Y: 0, Z: 0`

**Step 6.2: Add PropHuntGameManager Component**
- [ ] Select `PropHuntSceneManager`
- [ ] Inspector → Add Component
- [ ] Search: `PropHuntGameManager` (auto-generated from Lua)
- [ ] Add component
- [ ] **Note:** If component doesn't appear, ensure Lua scripts have compiled

**Step 6.3: Configure PropHuntGameManager Fields**

**Serialized Fields to Configure:**

*Config References:*
- [ ] **Config:** Drag `PropHuntConfig` ScriptableObject (or create one)

*Scene References:*
- [ ] **Lobby Spawn:** Drag `LobbySpawn` GameObject
- [ ] **Arena Spawn:** Drag `ArenaSpawn` GameObject
- [ ] **Possessables Container:** Create empty GameObject named `Possessables`, drag here

*UI References:*
- [ ] **HUD:** Drag PropHuntHUD UI GameObject (create in Part 4)
- [ ] **Ready Button:** Drag ReadyButton UI GameObject

*Module References:*
- [ ] **Player Manager:** Reference to PropHuntPlayerManager module
- [ ] **UI Manager:** Reference to PropHuntUIManager module

**Step 6.4: Verify Component Added**
- [ ] Check Inspector shows all serialized fields from PropHuntGameManager.lua
- [ ] Fields should include: `_config`, `_lobbySpawn`, `_arenaSpawn`, etc.

---

## Part 4: Possessable Props (5+ props, ~15 min)

Possessable props are objects that Props can disguise as during the Hide phase.

### Creating a Possessable Prop (3 min per prop)

**Step 7: First Prop - Cube**

**Step 7.1: Create Primitive**
- [ ] Hierarchy → 3D Object → Cube
- [ ] Name: `Prop_Cube_1`
- [ ] Transform Position: `X: 95, Y: 0.5, Z: 5`
- [ ] Transform Scale: `X: 1, Y: 1, Z: 1`

**Step 7.2: Configure Collider**
- [ ] Verify Box Collider exists (added automatically)
- [ ] **Is Trigger:** ✗ (unchecked - should be solid collider)

**Step 7.3: Add Possessable Component**
- [ ] Inspector → Add Component
- [ ] Search: `Possessable` (auto-generated from Lua)
- [ ] Add component

**Step 7.4: Configure Possessable Fields**

*Component References:*
- [ ] **Outline:** Leave empty for now (add outline shader later)
- [ ] **HitPoint:** Create child Empty GameObject:
  - [ ] Name: `HitPoint`
  - [ ] Position: X: 0, Y: 0, Z: 0 (center of prop)
  - [ ] Drag into Possessable → HitPoint field
- [ ] **MainCollider:** Drag the Box Collider component into this field

**Step 7.5: Configure Tags/Layers**
- [ ] Tag: Create and assign `Possessable`
- [ ] Layer: Create and assign `Possessable` (for raycasting)

**Step 7.6: Add Material**
- [ ] Create new Material: `Mat_Prop_Cube`
- [ ] Set to URP/Lit shader
- [ ] Assign to MeshRenderer
- [ ] Configure PBR properties (Albedo, Metallic, Smoothness)

### Additional Props (12 min total)

Repeat Step 7 for each of these props:

**Step 8: Prop 2 - Sphere**
- [ ] Name: `Prop_Sphere_1`
- [ ] Position: `X: 100, Y: 0.5, Z: -3`
- [ ] Scale: `X: 1.2, Y: 1.2, Z: 1.2`
- [ ] Primitive: Sphere
- [ ] Add Possessable component with HitPoint child

**Step 9: Prop 3 - Capsule**
- [ ] Name: `Prop_Capsule_1`
- [ ] Position: `X: 110, Y: 1, Z: 2`
- [ ] Scale: `X: 0.8, Y: 0.8, Z: 0.8`
- [ ] Primitive: Capsule
- [ ] Add Possessable component with HitPoint child

**Step 10: Prop 4 - Flat Cube**
- [ ] Name: `Prop_Cube_2`
- [ ] Position: `X: 120, Y: 0.5, Z: -5`
- [ ] Scale: `X: 1.5, Y: 0.5, Z: 1.5`
- [ ] Primitive: Cube
- [ ] Add Possessable component with HitPoint child

**Step 11: Prop 5 - Cylinder**
- [ ] Name: `Prop_Cylinder_1`
- [ ] Position: `X: 130, Y: 0.5, Z: 3`
- [ ] Scale: `X: 1, Y: 1.5, Z: 1`
- [ ] Primitive: Cylinder
- [ ] Add Possessable component with HitPoint child

**Step 12: Organize Props**
- [ ] Create parent GameObject: `Possessables`
- [ ] Position: X: 0, Y: 0, Z: 0
- [ ] Drag all 5 props into Possessables parent
- [ ] Reference this parent in PropHuntGameManager

---

## Part 5: Environment & Lighting (~10 min)

### Step 13: Ground Plane (2 min)

**Step 13.1: Create Ground**
- [ ] Hierarchy → 3D Object → Plane
- [ ] Name: `GroundPlane`
- [ ] Position: `X: 50, Y: -0.1, Z: 0`
- [ ] Scale: `X: 20, Y: 1, Z: 10` (200x100 world units)

**Step 13.2: Add Material**
- [ ] Create Material: `Mat_Ground`
- [ ] Shader: URP/Lit
- [ ] Set Albedo to neutral gray
- [ ] Add tiling if desired

### Step 14: Lighting (3 min)

**Step 14.1: Directional Light**
- [ ] Hierarchy should have default Directional Light
- [ ] Name: `MainLight`
- [ ] Rotation: `X: 50, Y: -30, Z: 0`
- [ ] Intensity: `1.0`
- [ ] Color: Slightly warm white

**Step 14.2: Environment Lighting**
- [ ] Window → Rendering → Lighting
- [ ] Environment tab:
  - [ ] Skybox Material: Default (or custom)
  - [ ] Sun Source: MainLight
  - [ ] Environment Reflections: Skybox
- [ ] Generate Lighting (if using baked lighting)

### Step 15: Camera Setup (3 min)

**Step 15.1: Main Camera**
- [ ] Verify Main Camera exists
- [ ] Tag: `MainCamera`
- [ ] Clear Flags: Skybox
- [ ] Culling Mask: Everything

**Step 15.2: URP Settings**
- [ ] Add URP Camera component (if not already added)
- [ ] Rendering → Anti-aliasing: FXAA or SMAA
- [ ] Post Processing: Enable if using effects

### Step 16: Create Camera Boundaries (2 min)

**Optional: Confine camera to playable area**
- [ ] Create invisible colliders around play area edges
- [ ] Use Box Colliders on Layer: `CameraBounds`
- [ ] Configure camera controller to respect boundaries

---

## Part 6: UI Setup (~8 min)

### Step 17: HUD Canvas (4 min)

**Step 17.1: Create UI Document**
- [ ] Hierarchy → UI Toolkit → UI Document
- [ ] Name: `PropHuntHUD`
- [ ] Inspector → UI Document component:
  - [ ] Source Asset: Create/assign `PropHuntHUD.uxml`
  - [ ] Panel Settings: Create/assign PanelSettings asset

**Step 17.2: Add PropHuntHUD Component**
- [ ] Add Component → PropHuntHUD (Lua-generated)
- [ ] This script will handle HUD updates

**Step 17.3: Configure UXML**
- [ ] Create `Assets/PropHunt/Scripts/GUI/PropHuntHUD.uxml`
- [ ] Add basic elements:
  - [ ] Timer label
  - [ ] State label
  - [ ] Player count label
- [ ] Style with USS file

### Step 18: Ready Button (4 min)

**Step 18.1: Create UI Document**
- [ ] Hierarchy → UI Toolkit → UI Document
- [ ] Name: `ReadyButton`
- [ ] Source Asset: Create `ReadyButton.uxml`

**Step 18.2: Add PropHuntReadyButton Component**
- [ ] Add Component → PropHuntReadyButton
- [ ] Wire up to scene manager

**Step 18.3: Reference in SceneManager**
- [ ] Select `PropHuntSceneManager`
- [ ] Drag `ReadyButton` GameObject into `_readyButton` field

---

## Part 7: Validation & Testing (~10 min)

### Step 19: Scene Validation Checklist

**GameObject Hierarchy Check:**
- [ ] Zones folder contains: Zone_NearSpawn, Zone_Mid, Zone_Far
- [ ] SpawnPoints folder contains: LobbySpawn, ArenaSpawn
- [ ] Possessables folder contains: 5+ props with Possessable component
- [ ] PropHuntSceneManager exists with PropHuntGameManager component

**Component Configuration Check:**
- [ ] All zones have Box Collider with Is Trigger enabled
- [ ] All zones have correct tags (Zone_NearSpawn, etc.)
- [ ] All props have Possessable component
- [ ] All props have HitPoint child GameObject
- [ ] All props have proper colliders

**Reference Check:**
- [ ] PropHuntGameManager → Lobby Spawn: Assigned
- [ ] PropHuntGameManager → Arena Spawn: Assigned
- [ ] PropHuntGameManager → Possessables: Assigned
- [ ] PropHuntGameManager → HUD: Assigned
- [ ] PropHuntGameManager → Config: Assigned
- [ ] All Possessable → MainCollider: Assigned
- [ ] All Possessable → HitPoint: Assigned

**Tags & Layers Check:**
- [ ] Tags created: Zone_NearSpawn, Zone_Mid, Zone_Far, SpawnPoint, Possessable
- [ ] Layers created: Possessable (for raycasting)
- [ ] All GameObjects have correct tags assigned

### Step 20: Play Mode Test (5 min)

**Step 20.1: Enter Play Mode**
- [ ] Click Play button
- [ ] Check Console for errors

**Step 20.2: Verify Startup**
- [ ] Console shows: "[PropHunt] Game initialized"
- [ ] Console shows: "[PropHunt] State: LOBBY"
- [ ] No red errors in Console

**Step 20.3: Check HUD**
- [ ] HUD displays current state
- [ ] Timer shows lobby countdown
- [ ] Ready button visible

**Step 20.4: Test Multiplayer Simulation**
- [ ] If Highrise multiplayer simulation available, test with 2+ simulated players
- [ ] Verify ready-up system works
- [ ] Verify state transitions to HIDING

**Step 20.5: Exit Play Mode**
- [ ] Stop Play mode
- [ ] Save scene: `Ctrl+S` / `Cmd+S`

---

## Troubleshooting Common Issues

### Issue: Lua Components Don't Appear in Add Component

**Solution:**
1. Check `Packages/com.pz.studio.generated/Runtime/Highrise.Lua.Generated/`
2. Verify C# wrappers exist for your Lua scripts
3. If missing, trigger recompilation:
   - Edit any .lua file (add/remove whitespace)
   - Save file
   - Return to Unity (auto-recompiles)
4. Check Console for compilation errors

### Issue: "Missing Reference" Warnings

**Solution:**
1. Select PropHuntSceneManager
2. Inspector → Find field with "Missing" or "None"
3. Drag correct GameObject/component from Hierarchy
4. Common missing references:
   - Spawn points (drag GameObjects)
   - Possessables (drag parent GameObject)
   - UI elements (drag UI Documents)

### Issue: Zones Not Detecting Players

**Solution:**
1. Verify Box Collider → Is Trigger is checked
2. Verify zone GameObject has correct tag
3. Verify player has Rigidbody component
4. Check Physics collision matrix (Edit → Project Settings → Physics)

### Issue: Props Not Selectable

**Solution:**
1. Verify Possessable component is attached
2. Verify MainCollider field is assigned
3. Verify prop is on Possessable layer
4. Check that collider is enabled (not disabled in Inspector)

### Issue: State Transitions Not Working

**Solution:**
1. Check Console for Lua errors
2. Verify PropHuntGameManager → Config is assigned
3. Check network synchronization (NumberValue, BoolValue)
4. Enable debug logging in PropHuntConfig

### Issue: UI Not Displaying

**Solution:**
1. Verify UI Document → Source Asset is assigned
2. Check PanelSettings is created and assigned
3. Verify UXML file has correct structure
4. Check USS styles are applied
5. Ensure Canvas Scaler settings are correct

### Issue: Players Spawn at Origin (0,0,0)

**Solution:**
1. Verify spawn point GameObjects are tagged `SpawnPoint`
2. Check PropHuntGameManager has spawn references assigned
3. Verify spawn point positions are correct (not at 0,0,0 if unintended)

### Issue: Performance Issues / Low FPS

**Solution:**
1. Reduce prop count (start with 5-10)
2. Optimize materials (reduce texture sizes)
3. Disable visual markers (or reduce count)
4. Check URP settings (reduce shadow quality/distance)
5. Profile with Unity Profiler (Window → Analysis → Profiler)

---

## Next Steps After Setup

Once your scene is set up and validated:

1. **Configure PropHuntConfig**
   - [ ] Create ScriptableObject: PropHuntConfig
   - [ ] Set phase timers (Lobby: 30s, Hide: 35s, Hunt: 240s)
   - [ ] Set scoring parameters
   - [ ] Assign to PropHuntGameManager

2. **Add VFX**
   - [ ] Create possession VFX (dissolve, sparks)
   - [ ] Create tagging VFX (hit/miss feedback)
   - [ ] Create phase transition VFX
   - [ ] Reference VFX in appropriate scripts

3. **Add Custom Shaders**
   - [ ] Create outline shader for props
   - [ ] Create dissolve shader for transformations
   - [ ] Apply to materials

4. **Expand Prop Variety**
   - [ ] Import custom 3D models
   - [ ] Create themed prop sets (kitchen, office, etc.)
   - [ ] Add 15-30 total props for variety

5. **Polish Lighting**
   - [ ] Add area lights for mood
   - [ ] Configure post-processing (bloom, color grading)
   - [ ] Bake lightmaps for static objects

6. **Test Multiplayer**
   - [ ] Publish to Highrise test environment
   - [ ] Test with real players (2-10)
   - [ ] Gather feedback on balance

7. **Iterate Based on Testing**
   - [ ] Adjust zone sizes/positions
   - [ ] Tweak scoring parameters
   - [ ] Balance hunter/prop distribution

---

## Additional Resources

- **PropHunt Documentation:** `Assets/PropHunt/Documentation/README.md`
- **Input System Guide:** `Assets/PropHunt/Documentation/INPUT_SYSTEM.md`
- **Highrise Studio Docs:** https://create.highrise.game/learn/studio
- **Quick Setup Guide:** `/QUICK_UNITY_SETUP.md` (10-minute version)
- **Automated Setup Script:** `Assets/PropHunt/Scripts/UnitySceneSetup.lua`

---

## Checklist Summary

**Scene Structure:**
- [ ] 3 zone volumes created and configured
- [ ] 2 spawn points created and configured
- [ ] Scene Manager created with PropHuntGameManager
- [ ] 5+ possessable props created
- [ ] Ground plane and lighting configured

**Components:**
- [ ] All zones have Box Collider (Is Trigger)
- [ ] All props have Possessable component
- [ ] All props have HitPoint child
- [ ] Scene Manager has all references assigned

**UI:**
- [ ] HUD created with UI Toolkit
- [ ] Ready button created and wired

**Testing:**
- [ ] Scene loads without errors
- [ ] Play mode test successful
- [ ] Scene saved

**Time Spent:** _____ minutes

---

**Setup Complete!** You now have a functional PropHunt scene ready for testing and iteration. Proceed to the Quick Unity Setup guide for faster iteration on new scenes, or dive into VFX/shader work to polish the experience.
