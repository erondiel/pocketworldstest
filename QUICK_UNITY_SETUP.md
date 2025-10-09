# PropHunt - 10 Minute Scene Setup

No explanations. Follow exactly. Copy-paste values.

**Total Time:** 10 minutes
**Result:** Playable PropHunt scene

---

## Step 1: Zones (3 min)

### Zone 1
1. Hierarchy → Create Empty → Name: `Zone_NearSpawn`
2. Transform: `X: 95, Y: 0, Z: 0`
3. Add Component → Box Collider
4. Is Trigger: ✓
5. Center: `X: 0, Y: 5, Z: 0`
6. Size: `X: 15, Y: 10, Z: 20`
7. Tag → Add Tag → Type: `Zone_NearSpawn` → Save
8. Set Tag: `Zone_NearSpawn`

### Zone 2
1. Create Empty → Name: `Zone_Mid`
2. Transform: `X: 110, Y: 0, Z: 0`
3. Add Component → Box Collider
4. Is Trigger: ✓
5. Center: `X: 0, Y: 5, Z: 0`
6. Size: `X: 20, Y: 10, Z: 20`
7. Tag → Add Tag → Type: `Zone_Mid`
8. Set Tag: `Zone_Mid`

### Zone 3
1. Create Empty → Name: `Zone_Far`
2. Transform: `X: 130, Y: 0, Z: 0`
3. Add Component → Box Collider
4. Is Trigger: ✓
5. Center: `X: 0, Y: 5, Z: 0`
6. Size: `X: 15, Y: 10, Z: 20`
7. Tag → Add Tag → Type: `Zone_Far`
8. Set Tag: `Zone_Far`

### Organize
1. Create Empty → Name: `Zones`
2. Drag all 3 zones into Zones parent

---

## Step 2: Spawns (2 min)

### Lobby Spawn
1. Create Empty → Name: `LobbySpawn`
2. Transform Position: `X: 0, Y: 0, Z: 0`
3. Transform Rotation: `X: 0, Y: 90, Z: 0`
4. Tag → Add Tag → Type: `SpawnPoint`
5. Set Tag: `SpawnPoint`

### Arena Spawn
1. Create Empty → Name: `ArenaSpawn`
2. Transform Position: `X: 100, Y: 0, Z: 0`
3. Transform Rotation: `X: 0, Y: -90, Z: 0`
4. Set Tag: `SpawnPoint`

### Organize
1. Create Empty → Name: `SpawnPoints`
2. Drag both spawns into parent

---

## Step 3: Scene Manager (1 min)

1. Create Empty → Name: `PropHuntSceneManager`
2. Transform: `X: 0, Y: 0, Z: 0`
3. Add Component → `PropHuntGameManager`
4. Leave fields empty for now (assign after Step 4)

---

## Step 4: Props (3 min)

### Prop 1
1. 3D Object → Cube → Name: `Prop_Cube_1`
2. Position: `X: 95, Y: 0.5, Z: 5`
3. Scale: `X: 1, Y: 1, Z: 1`
4. Add Component → `Possessable`
5. Create child Empty → Name: `HitPoint`
6. Drag HitPoint into Possessable → HitPoint field
7. Drag Box Collider into Possessable → MainCollider field
8. Tag → Add Tag → Type: `Possessable`
9. Set Tag: `Possessable`

### Prop 2
1. 3D Object → Sphere → Name: `Prop_Sphere_1`
2. Position: `X: 100, Y: 0.5, Z: -3`
3. Scale: `X: 1.2, Y: 1.2, Z: 1.2`
4. Add Component → Possessable
5. Create child Empty → Name: `HitPoint`
6. Drag HitPoint → Possessable → HitPoint
7. Drag Sphere Collider → Possessable → MainCollider
8. Set Tag: `Possessable`

### Prop 3
1. 3D Object → Capsule → Name: `Prop_Capsule_1`
2. Position: `X: 110, Y: 1, Z: 2`
3. Scale: `X: 0.8, Y: 0.8, Z: 0.8`
4. Add Component → Possessable
5. Create child Empty → Name: `HitPoint`
6. Drag HitPoint → Possessable → HitPoint
7. Drag Capsule Collider → Possessable → MainCollider
8. Set Tag: `Possessable`

### Prop 4
1. 3D Object → Cube → Name: `Prop_Cube_2`
2. Position: `X: 120, Y: 0.5, Z: -5`
3. Scale: `X: 1.5, Y: 0.5, Z: 1.5`
4. Add Component → Possessable
5. Create child Empty → Name: `HitPoint`
6. Drag HitPoint → Possessable → HitPoint
7. Drag Box Collider → Possessable → MainCollider
8. Set Tag: `Possessable`

### Prop 5
1. 3D Object → Cylinder → Name: `Prop_Cylinder_1`
2. Position: `X: 130, Y: 0.5, Z: 3`
3. Scale: `X: 1, Y: 1.5, Z: 1`
4. Add Component → Possessable
5. Create child Empty → Name: `HitPoint`
6. Drag HitPoint → Possessable → HitPoint
7. Drag Capsule Collider → Possessable → MainCollider
8. Set Tag: `Possessable`

### Organize
1. Create Empty → Name: `Possessables`
2. Drag all 5 props into parent

---

## Step 5: Ground (30 sec)

1. 3D Object → Plane → Name: `GroundPlane`
2. Position: `X: 50, Y: -0.1, Z: 0`
3. Scale: `X: 20, Y: 1, Z: 10`

---

## Step 6: Wire References (30 sec)

1. Select `PropHuntSceneManager`
2. Drag `LobbySpawn` → Lobby Spawn field
3. Drag `ArenaSpawn` → Arena Spawn field
4. Drag `Possessables` → Possessables field

---

## Step 7: Test (1 min)

1. Press Play
2. Check Console for "[PropHunt] Game initialized"
3. No red errors
4. Stop Play
5. Save Scene: `Ctrl+S` / `Cmd+S`

---

## Done ✓

**Scene is playable.** Now add:
- UI (HUD, Ready Button)
- Config (PropHuntConfig ScriptableObject)
- VFX
- Custom materials
- More props

See `Assets/PropHunt/Documentation/UNITY_SETUP_GUIDE.md` for full details.

---

## Fast Copy-Paste Values

**Zone Positions:**
```
Zone_NearSpawn: 95, 0, 0
Zone_Mid: 110, 0, 0
Zone_Far: 130, 0, 0
```

**Zone Sizes:**
```
NearSpawn: 15, 10, 20
Mid: 20, 10, 20
Far: 15, 10, 20
```

**Spawns:**
```
LobbySpawn: 0, 0, 0 | Rot: 0, 90, 0
ArenaSpawn: 100, 0, 0 | Rot: 0, -90, 0
```

**Props:**
```
Cube_1: 95, 0.5, 5 | Scale: 1, 1, 1
Sphere_1: 100, 0.5, -3 | Scale: 1.2, 1.2, 1.2
Capsule_1: 110, 1, 2 | Scale: 0.8, 0.8, 0.8
Cube_2: 120, 0.5, -5 | Scale: 1.5, 0.5, 1.5
Cylinder_1: 130, 0.5, 3 | Scale: 1, 1.5, 1
```

**Ground:**
```
Position: 50, -0.1, 0
Scale: 20, 1, 10
```

---

## Troubleshooting

**Lua components missing?**
- Edit any .lua file → Save → Return to Unity

**Missing references?**
- Drag GameObjects into Inspector fields

**Play mode errors?**
- Check all tags created
- Check all Possessable components have HitPoint + MainCollider

---

**Time:** _____ min | **Errors:** _____ | **Status:** ☐ Complete
