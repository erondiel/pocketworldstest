# PropHunt Scene Setup Wizard

Automated scene setup tool for PropHunt V1. **No menu items required** - works via ScriptableObject.

## How to Use

### 1. Create the Wizard Asset
```
Project Window → Right-click → Create → PropHunt → Scene Setup Wizard
```

### 2. Configure in Inspector
- Select the created wizard asset
- Set Lobby Position (default: 0, 0, 0)
- Set Arena Position (default: 100, 0, 0)
- Configure prop count, zone sizes, colors

### 3. Click "🚀 SETUP SCENE" Button
The wizard will create:
- ✅ LobbySpawn and ArenaSpawn GameObjects
- ✅ Lobby area with ground plane
- ✅ Arena area with ground plane
- ✅ 3 Zone volumes (NearSpawn, Mid, Far) with debug visualization
- ✅ Random props scattered in arena

### 4. Manual Steps (Required)
Unity cannot add Lua components via C#, so you must manually:

**Add ZoneVolume to zones:**
- `Zone_NearSpawn` → Add Component → ZoneVolume (zoneName="NearSpawn", weight=1.5)
- `Zone_Mid` → Add Component → ZoneVolume (zoneName="Mid", weight=1.0)
- `Zone_Far` → Add Component → ZoneVolume (zoneName="Far", weight=0.6)

**Add Possessable to props:**
- Select all GameObjects in `Props` folder
- Add Component → Possessable (batch add)

**Add client systems to PropHuntModules:**
- Select PropHuntModules GameObject
- Add Component → HunterTagSystem
- Add Component → PropDisguiseSystem
- Add Component → PropHuntRangeIndicator (assign Range Indicator prefab)

**Configure PropHuntTeleporter:**
- Select PropHuntModules GameObject
- Drag `LobbySpawn` → Lobby Spawn Position field
- Drag `ArenaSpawn` → Arena Spawn Position field

## Clear Scene
Click **"Clear All PropHunt Objects"** button to delete everything and start over.

## Why ScriptableObject Instead of Menu Item?
Some Unity installations block adding custom menu items. ScriptableObject wizard works around this restriction by using the Create Asset Menu system, which is rarely blocked.
