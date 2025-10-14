# PropOutline Shader Enhancement

## Changes Made

Enhanced `PropOutline.shader` by incorporating **view-space extrusion technique** from QuickOutline (by Chris Nolet), adapted for URP and Highrise Studio compatibility.

## Technical Changes

### Before (Object-Space Extrusion)
```hlsl
// Old approach - fixed expansion in object space
float3 positionOS = input.positionOS.xyz;
float3 normalOS = normalize(input.normalOS);
positionOS += normalOS * _OutlineWidth;
output.positionCS = TransformObjectToHClip(positionOS);
```

**Problem:** Outline width appeared inconsistent at different camera distances. Close objects had thicker outlines than distant objects.

### After (View-Space Extrusion)
```hlsl
// New approach - expansion in view space scaled by distance
float3 positionVS = TransformWorldToView(TransformObjectToWorld(input.positionOS.xyz));
float3 normalVS = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, input.normalOS));
positionVS += normalVS * (-positionVS.z) * _OutlineWidth / 1000.0;
output.positionCS = TransformWViewToHClip(positionVS);
```

**Benefits:**
- ✅ Consistent outline thickness regardless of camera distance
- ✅ Outline scales naturally with perspective
- ✅ More professional appearance
- ✅ Still simple, single-pass, mobile-friendly

## Parameter Changes

| Parameter | Old Range | Old Default | New Range | New Default |
|-----------|-----------|-------------|-----------|-------------|
| _OutlineWidth | 0.0-0.05 | 0.003 | 0.0-10.0 | 2.0 |

**Note:** The scale change is intentional. The division by 1000.0 in the shader converts the new range to appropriate extrusion amounts.

## Recommended Settings

- **Subtle outline:** 0.5-1.5
- **Balanced outline:** 1.5-3.0 (recommended)
- **Bold outline:** 3.0-5.0

## What We Didn't Use from QuickOutline

QuickOutline has additional features that require C# runtime logic incompatible with Highrise Studio:

- ❌ **Stencil buffer masking** (requires two-pass rendering setup via C#)
- ❌ **Smooth normal pre-computation** (requires mesh modification in Awake())
- ❌ **Multiple outline modes** (OutlineVisible, OutlineHidden, etc.)
- ❌ **Runtime material instantiation** (C# MonoBehaviour required)

Our implementation keeps the best part (view-space extrusion) while remaining:
- ✅ Pure shader-based (no C# required)
- ✅ URP/HLSL compatible
- ✅ Lua-controllable via MeshRenderer.enabled
- ✅ Unity Editor configurable
- ✅ Single-pass rendering

## Testing Notes

After updating, you may need to adjust the _OutlineWidth value in your `PropOutline.mat` material:
1. Open `Assets/PropHunt/Materials/PropOutline.mat` in Unity Inspector
2. Adjust "Outline Width" slider (now 0-10 range)
3. Start with default value of 2.0
4. Tune to preference (1.5-3.0 recommended)

## Credits

View-space extrusion technique adapted from:
- **QuickOutline** by Chris Nolet (2018)
- License: MIT (original project)
- Adapted for URP and Highrise Studio by removing C# dependencies
