# Complete Unity Scene Setup - PropHunt V1

**This is the COMPLETE checklist. Follow every step.**

---

## Phase 1: Core Module Setup (PropHuntModules GameObject)

Your **PropHuntModules** GameObject should have ALL of these components:

### Server-Side Modules (Already attached):
- ✅ PropHuntConfig
- ✅ PropHuntGameManager
- ✅ PropHuntPlayerManager
- ✅ PropHuntScoringSystem
- ✅ PropHuntUIManager
- ✅ PropHuntVFXManager
- ✅ PropHuntTeleporter
- ✅ ZoneManager

### Client-Side Systems (ADD THESE NOW):
1. **Add Component → HunterTagSystem**
   - No configuration needed
   - Handles hunter tap-to-tag input

2. **Add Component → PropDisguiseSystem**
   - No configuration needed
   - Handles prop tap-to-select input

3. **Add Component → PropHuntRangeIndicator**
   - **REQUIRED:** Assign Range Indicator prefab in Inspector
   - Shows 4m circle around hunters during Hunt phase

---

## Phase 2: Spawn Points (Empty GameObjects)

Create two empty GameObjects for teleportation:

### 1. LobbySpawn
```
Name: LobbySpawn
Position: (0, 0, 0) or wherever your lobby area is
No components needed - just a position marker
```

### 2. ArenaSpawn
```
Name: ArenaSpawn
Position: (100, 0, 0) or wherever your arena area is (at least 50-100 units from lobby)
No components needed - just a position marker
```

### 3. Configure PropHuntTeleporter
- Select **PropHuntModules** GameObject
- Find **PropHuntTeleporter** component in Inspector
- Drag **LobbySpawn** → Lobby Spawn Position field
- Drag **ArenaSpawn** → Arena Spawn Position field

---

## Phase 3: Zone Volumes (Arena Area Only)

Create **3 zone GameObjects** in the Arena area (near ArenaSpawn position):

### Zone 1: NearSpawn (High Risk, High Reward)
```
1. Create Empty GameObject
2. Name: Zone_NearSpawn
3. Add Component → BoxCollider
   - Set "Is Trigger" = TRUE
   - Scale the collider to cover area near spawn (e.g., 20x20 units)
4. Add Component → ZoneVolume
   - Zone Name: "NearSpawn"
   - Zone Weight: 1.5
5. Position near ArenaSpawn (the risky hiding spots)
```

### Zone 2: Mid (Balanced)
```
1. Create Empty GameObject
2. Name: Zone_Mid
3. Add Component → BoxCollider
   - Set "Is Trigger" = TRUE
   - Scale the collider to cover middle area (e.g., 30x30 units)
4. Add Component → ZoneVolume
   - Zone Name: "Mid"
   - Zone Weight: 1.0
5. Position in middle of arena
```

### Zone 3: Far (Safe, Low Reward)
```
1. Create Empty GameObject
2. Name: Zone_Far
3. Add Component → BoxCollider
   - Set "Is Trigger" = TRUE
   - Scale the collider to cover far area (e.g., 40x40 units)
4. Add Component → ZoneVolume
   - Zone Name: "Far"
   - Zone Weight: 0.6
5. Position far from ArenaSpawn (the safe hiding spots)
```

**IMPORTANT:** Zones should NOT overlap. Cover different areas of the Arena.

---

## Phase 4: Possessable Props (Arena Area)

Add props that players can disguise as:

### For EACH prop in the Arena:
```
1. Select the GameObject (e.g., Chair, Barrel, Crate)
2. Add Component → Possessable
3. Done! No configuration needed (uses automatic InstanceID)
```

**Recommended:** Start with 5-10 props in the Arena area for testing.

---

## Phase 5: UI Components (Optional but Recommended)

If you have UI elements:

### Ready Button (Lobby)
- Attach **PropHuntReadyButton** script to your ready button UI element
- This handles the ready-up functionality

### HUD Display
- Attach **PropHuntHUD** script to your HUD UI element
- Shows timer, state, player counts

---

## Phase 6: Verification Checklist

Before hitting Play, verify:

### PropHuntModules GameObject has:
- [ ] All 8 server modules (Config, GameManager, PlayerManager, ScoringSystem, UIManager, VFXManager, Teleporter, ZoneManager)
- [ ] HunterTagSystem component
- [ ] PropDisguiseSystem component
- [ ] PropHuntRangeIndicator component (with Range Indicator prefab assigned)

### Scene has:
- [ ] LobbySpawn GameObject (empty, just position)
- [ ] ArenaSpawn GameObject (empty, just position)
- [ ] PropHuntTeleporter configured with both spawn positions
- [ ] 3 Zone GameObjects in Arena (NearSpawn, Mid, Far) with ZoneVolume components
- [ ] At least 5 props with Possessable component in Arena area

### Arena Layout:
- [ ] Lobby area around (0, 0, 0) or your LobbySpawn position
- [ ] Arena area around (100, 0, 0) or your ArenaSpawn position (50-100 units away from Lobby)
- [ ] Ground plane in both areas
- [ ] Props placed in Arena only (not in Lobby)

---

## Testing the Setup

Hit Play mode and check Console for:

```
[PropHuntGameManager] ServerStart
[PropHuntConfig] Initialized
[ZoneManager] Zone initialized: NearSpawn (weight: 1.5)
[ZoneManager] Zone initialized: Mid (weight: 1.0)
[ZoneManager] Zone initialized: Far (weight: 0.6)
[HunterTagSystem] ClientStart
[PropDisguiseSystem] ClientStart
[PropHuntRangeIndicator] Initialized
[PropHunt Teleporter] ...
```

If you see errors about "module not registered" or "nil value", check:
1. All modules are attached to PropHuntModules GameObject
2. All zone volumes have ZoneVolume component
3. PropHuntTeleporter has spawn positions assigned

---

## What Happens in Game Loop

1. **LOBBY** - Players spawn in Lobby area, press Ready
2. **HIDING** - Props teleport to Arena, select disguises by tapping props
3. **HUNTING** - Hunters teleport to Arena, tap to tag props (4m range shown by circle)
4. **ROUND_END** - Display winner, everyone teleports back to Lobby
5. **Loop back to LOBBY**

---

## Common Mistakes

❌ **Forgetting to add HunterTagSystem/PropDisguiseSystem** → Input won't work
❌ **Forgetting to assign Range Indicator prefab** → No visual tag range
❌ **Zones overlapping** → Scoring will be inconsistent
❌ **Props in Lobby area** → Players can't possess them (they're too far during Hide phase)
❌ **Not setting zone "Is Trigger" = true** → Zone detection won't work
❌ **Spawn positions not assigned in PropHuntTeleporter** → Teleportation fails

---

## Next Steps After Setup

Once this is working:
1. Add VFX prefabs for possession/tagging effects
2. Add UI elements (HUD, Ready Button, Recap Screen)
3. Polish arena layout with decorations
4. Add more props for variety
5. Tune zone sizes and weights for balance
