# Emission Control Test Guide

This guide will help you test if emission control works in Highrise Studio Lua.

## Setup Steps

### 1. Prepare a Test Prop

1. Select any prop GameObject in your scene (e.g., a cube, sphere, or existing prop)
2. Make sure it has a **MeshRenderer** component
3. Note: You don't need to tag it for this test

### 2. Configure the Material for Emission

1. Select the prop's material in the Project window
2. In the Inspector, find the **"Emission"** section
3. Check the **"Emission"** checkbox to enable it
4. Set **Emission Color** to **black (R:0, G:0, B:0)** - this is the default "off" state
5. Set **Emission Intensity** to a value between 0.5-2.0 (this controls how bright it will glow)
6. Optional: Set **Global Illumination** to "Baked" or "Realtime"

**Important:** The material must have emission enabled in the shader, even if the color is black. This allows Lua to control it dynamically.

### 3. Add the Test Script

1. Create an empty GameObject in the scene (e.g., "EmissionTester")
2. Drag `PropEmissionTest.lua` onto it
3. In the Inspector, drag your test prop GameObject into the **"Test Prop"** field

### 4. Run the Test

1. Enter Play Mode
2. Check the Console for initial messages
3. **Tap anywhere** in the Game view to toggle emission on/off
4. First tap: Enable emission + outline
5. Second tap: Disable emission + outline
6. Watch the console for detailed API test results

## What to Look For

### Success Indicators

**Best Case (MaterialPropertyBlock works):**
```
[PropEmissionTest] MaterialPropertyBlock.new() ✓
[PropEmissionTest] GetPropertyBlock() ✓
[PropEmissionTest] SetColor('_EmissionColor') ✓
[PropEmissionTest] SetPropertyBlock() ✓
[PropEmissionTest] ✓✓✓ MaterialPropertyBlock API WORKS! ✓✓✓
```

**Acceptable Case (Fallback to material instance):**
```
[PropEmissionTest] ✗ MaterialPropertyBlock not available
[PropEmissionTest] Trying fallback method...
[PropEmissionTest] ✓ Fallback method (material instance) works
[PropEmissionTest] WARNING: This creates material instances!
```

### Visual Check

When you **tap** (first time), you should see:
- The prop starts glowing cyan (if emission is working)
- The outline appears around the prop (if outline child exists)

When you **tap again** (second time):
- The glow disappears
- The outline disappears

## Troubleshooting

### "No test prop assigned"
- Make sure you dragged a GameObject into the "Test Prop" field in the Inspector
- The prop should have a MeshRenderer component

### "No MeshRenderer found"
- The test prop needs a MeshRenderer component
- SkinnedMeshRenderer might also work (test will show)

### Emission not visible even though test passes
- Check material has Emission enabled in Inspector
- Try increasing Emission Intensity (2.0-5.0)
- Make sure the base Emission Color is black (0,0,0)
- Check scene lighting - emission is more visible in darker scenes

### Console shows errors about Color.new()
- Try `Color(0, 1, 1, 1)` instead of `Color.new(0, 1, 1, 1)`
- Highrise might use different Color constructor syntax

## Next Steps

Once you've confirmed which method works:

### If MaterialPropertyBlock Works ✓
- **Best option:** Use in PropOutline.lua and PropDisguiseSystem.lua
- Memory efficient, no instances created
- Can control per-object emission

### If Material Instance Works ⚠️
- **Acceptable option:** Use but be cautious
- Creates material instances (memory cost)
- Consider pooling/caching instances if needed

### If Neither Works ✗
- **Fallback:** Create two material variants per prop
  - PropMaterial (no emission)
  - PropMaterial_Emissive (with emission)
- Swap via `renderer.sharedMaterial`
- More manual setup but guaranteed to work

## Test Results Template

Share your results using this template:

```
Platform: [Windows/Mac/WebGL]
MaterialPropertyBlock: [✓ Works / ✗ Fails / ? Unknown]
Material Instance Fallback: [✓ Works / ✗ Fails / ? Unknown]
Visual Result: [Emission visible / No emission / Other issue]
Console Errors: [None / List errors here]
```

## Files

- Test Script: `Assets/PropHunt/Scripts/Testing/PropEmissionTest.lua`
- This Guide: `Assets/PropHunt/Documentation/EMISSION_TEST_GUIDE.md`
