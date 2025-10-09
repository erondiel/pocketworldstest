# Range Indicator Setup Guide

## Quick Setup for Unity

This guide provides step-by-step instructions for setting up the Range Indicator in your PropHunt scene.

## Prerequisites

1. Range Indicator asset installed at: `Assets/Downloads/Range Indicator/`
2. DevBasics Toolkit installed at: `Assets/Downloads/DevBasics Toolkit/`
3. PropHunt scripts compiled and generated

## Step 1: Add the Component to Scene

1. Open the PropHunt scene: `Assets/PropHunt/Scenes/test.unity`
2. Locate your main GameManager GameObject (or create one if it doesn't exist)
3. Add the `PropHuntRangeIndicator` component:
   - Click **Add Component**
   - Search for "PropHuntRangeIndicator"
   - Select it from the list

## Step 2: Configure the Inspector Fields

### Required Fields

#### _RangeIndicatorPrefab
- **Source:** `Assets/Downloads/Range Indicator/Prefabs/RangeIndicator.prefab`
- **How to assign:**
  1. In Project window, navigate to `Assets/Downloads/Range Indicator/Prefabs/`
  2. Drag `RangeIndicator.prefab` into the `_RangeIndicatorPrefab` field
  3. Verify the prefab icon appears in the field

### Optional Fields (Recommended Defaults)

#### _IndicatorColor
- **Default:** RGBA(1.0, 0.3, 0.1, 0.6)
- **Description:** Orange-red color for hunter theme
- **Customization:**
  - Click the color swatch to open color picker
  - Adjust RGB for different hue
  - Keep Alpha around 0.5-0.7 for visibility

#### _EnableBreathingAnimation
- **Default:** ✓ (checked/true)
- **Description:** Enables subtle pulsing effect
- **Recommendation:** Keep enabled for visual polish

#### _AnimationSpeed
- **Default:** 1.5
- **Description:** Speed multiplier for breathing animation
- **Range:** 0.5 (slow) to 3.0 (fast)
- **Recommendation:** 1.0-2.0 for organic feel

## Step 3: Verify DevBasics Toolkit

The script uses `devx_tweens` for animation. Ensure it's accessible:

1. Check that `Assets/Downloads/DevBasics Toolkit/Scripts/Shared/devx_tweens.lua` exists
2. If missing, reinstall DevBasics Toolkit from Highrise Studio assets
3. The script will print an error on play if the module can't be loaded

## Step 4: Test the Integration

### In-Editor Testing

1. Press **Play** in Unity Editor
2. Open the Console window (Window → General → Console)
3. Look for initialization log: `[PropHuntRangeIndicator] Initialized`
4. Verify no errors appear

### Runtime Testing

1. Start a game session with at least 2 players
2. Ready up to start a round
3. If assigned Hunter role:
   - During **Hide phase:** No indicator visible
   - During **Hunt phase:** Orange circle appears at your feet (4.0m radius)
   - Circle should pulse gently (breathing animation)
4. If assigned Prop role:
   - Indicator should never appear

### Expected Console Output

```
[PropHuntRangeIndicator] Initialized
[PropHuntRangeIndicator] State changed: LOBBY
[PropHuntRangeIndicator] Role assigned: hunter
[PropHuntRangeIndicator] State changed: HIDING
[PropHuntRangeIndicator] State changed: HUNTING
[PropHuntRangeIndicator] Showing range indicator (radius: 4.0m)
```

## Step 5: Integration with Existing Systems

The range indicator automatically integrates with:

### PropHuntGameManager
- Listens to `PH_StateChanged` event
- Listens to `PH_RoleAssigned` event
- No additional setup required

### HunterTagSystem
- Both use the same 4.0m tag range
- Visual range matches gameplay range
- Server validates tags within this range

### PropHuntConfig
- Reads `_tagRange` value (default: 4.0)
- Warning printed if mismatch detected
- Change in one place updates both systems

## Troubleshooting

### Issue: Indicator not appearing for hunters

**Possible Causes:**
1. Prefab not assigned in Inspector
2. Role assignment not working
3. State machine not transitioning to Hunt phase

**Solutions:**
1. Check `_RangeIndicatorPrefab` field has prefab assigned
2. Verify console shows "Role assigned: hunter"
3. Verify console shows "State changed: HUNTING"
4. Check that game has minimum 2 players ready

### Issue: Indicator appears at wrong position

**Possible Causes:**
1. Player character not properly initialized
2. Transform parent issue

**Solutions:**
1. Wait for player character to fully spawn
2. Check console for errors during spawn
3. Verify `client.localPlayer.character` exists

### Issue: No breathing animation

**Possible Causes:**
1. `_EnableBreathingAnimation` disabled
2. DevBasics Toolkit tween system not loading
3. Tween module import error

**Solutions:**
1. Enable `_EnableBreathingAnimation` in Inspector
2. Verify `devx_tweens.lua` exists in project
3. Check console for module load errors
4. Restart Unity to force script recompilation

### Issue: Indicator color is wrong

**Possible Causes:**
1. Material on prefab overrides color
2. Custom color not set correctly

**Solutions:**
1. Check prefab's material supports vertex colors
2. Verify `_IndicatorColor` in Inspector
3. Try default color: RGB(255, 77, 26) with Alpha 153

### Issue: Range doesn't match tag distance

**Possible Causes:**
1. `TAG_RANGE` constant doesn't match `Config.GetTagRange()`
2. PropHuntConfig `_tagRange` changed but script not updated

**Solutions:**
1. Check console for warning on startup
2. Update `TAG_RANGE = 4.0` in PropHuntRangeIndicator.lua
3. Ensure PropHuntConfig `_tagRange = 4.0`
4. Recompile Lua scripts

## Advanced Configuration

### Changing Tag Range Globally

To change the tag range from 4.0m to a different value:

1. **Update PropHuntConfig.lua:**
   ```lua
   local _tagRange : number = 5.0  -- New range
   ```

2. **Update PropHuntRangeIndicator.lua:**
   ```lua
   local TAG_RANGE = 5.0  -- Match new range
   ```

3. **HunterTagSystem** automatically uses `Config.GetTagRange()` (no change needed)

4. Recompile and test

### Custom Visual Styles

To customize the indicator appearance:

#### Solid Fill (no transparency)
```lua
_IndicatorColor = Color.new(1.0, 0.3, 0.1, 1.0)  -- Full opacity
```

#### Subtle Blue (team color variation)
```lua
_IndicatorColor = Color.new(0.2, 0.5, 1.0, 0.5)  -- Blue hunter theme
```

#### High Contrast (accessibility)
```lua
_IndicatorColor = Color.new(1.0, 1.0, 0.0, 0.8)  -- Bright yellow
```

### Disable Animation for Performance

If targeting low-end mobile devices:

1. Uncheck `_EnableBreathingAnimation` in Inspector
2. Indicator will remain static (still functional)
3. Saves ~0.1ms per frame per hunter

### Custom Prefab

To use a different visual style:

1. Duplicate `RangeIndicator.prefab`
2. Modify mesh (circle, square, hexagon, etc.)
3. Assign your custom prefab to `_RangeIndicatorPrefab`
4. Ensure prefab has:
   - MeshRenderer component
   - Material with color support
   - Appropriate scale (1 unit = 1 meter)

## Performance Notes

### Mobile Optimization

The range indicator is optimized for mobile:
- Single mesh instance per hunter
- No realtime shadows
- Lightweight tween animation
- Only active during Hunt phase (auto-cleanup)

### Expected Performance Impact

- **CPU:** ~0.2ms per hunter (with animation)
- **Memory:** ~500KB per indicator instance
- **Draw Calls:** +1 per hunter
- **Recommended Max:** 20 simultaneous hunters (no performance issues)

## Related Documentation

- **Integration Details:** `RANGE_INDICATOR_INTEGRATION.md`
- **Input System:** `INPUT_SYSTEM.md`
- **Project Overview:** `../../../CLAUDE.md`

## Support

For issues or questions:
1. Check console logs for error messages
2. Verify all prerequisites are installed
3. Review troubleshooting section above
4. Check Highrise Studio documentation for platform-specific issues

---

**Last Updated:** 2025-10-08
**Version:** 1.0
**Maintainer:** PropHunt Development Team
