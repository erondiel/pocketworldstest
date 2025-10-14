# PropHunt Outline System

Simple outline rendering using inverted hull technique. Creates a slightly larger duplicate mesh rendered behind the original.

## Quick Setup

**Unity Editor:**
1. `PropHunt → Outline Setup`
2. Tag props with "Possessable"
3. Click "Add Outlines to All Props"

Creates child GameObject `PropName_Outline` with outline mesh (disabled by default).

## How It Works

**Inverted Hull Technique (Enhanced with View-Space Extrusion):**
- Duplicate mesh rendered with backface culling (Cull Front)
- Vertices expanded along normals in **view-space** (camera space)
- Extrusion scales with camera distance for consistent outline thickness
- Renders behind original mesh creating outline effect
- Simple, lightweight, mobile-friendly

**Technique based on QuickOutline by Chris Nolet, adapted for URP/Highrise Studio.**

**Limitation:** Outline may be partially hidden when object is very close to walls (backfaces occluded). Use moderate width (1.5-3.0) to minimize this.

## Control from Lua

```lua
-- Show all prop outlines
local allProps = scene:FindGameObjectsWithTag("Possessable")
for i = 1, #allProps do
    local prop = allProps[i]
    local outlineChild = prop.transform:Find(prop.name .. "_Outline")
    if outlineChild then
        local renderer = outlineChild:GetComponent(MeshRenderer)
        renderer.enabled = true
    end
end

-- Hide outline (when prop possessed)
local outlineChild = propObject.transform:Find(propObject.name .. "_Outline")
if outlineChild then
    local renderer = outlineChild:GetComponent(MeshRenderer)
    renderer.enabled = false
end
```

**Or use PropOutline.lua component:**
```lua
local propScript = prop:GetComponent("PropOutline")
propScript:ShowOutline()
propScript:HideOutline()
```

## Material Settings

Edit `PropOutline.mat`:
- **Outline Color:** Cyan (default)
- **Outline Width:** 2.0 (range: 0.0-10.0)
  - Recommended: 1.5-3.0 for balanced visibility
  - Smaller (0.5-1.5) = subtle outline
  - Larger (3.0-5.0) = bold outline, may look thicker on distant objects

**Note:** Width now uses view-space scaling, so values are larger than the old object-space version. The outline thickness remains consistent as you move closer/farther from objects.

## Troubleshooting

**Outline not visible:** Check MeshRenderer.enabled = true on child
**Outline disappears near walls:** Use smaller width (1.0-2.0)
**Outline too thin:** Increase width in material (try 2.5-4.0)
**Outline too thick:** Decrease width (try 1.0-1.5)
**Outline inconsistent at different distances:** This should now be fixed with view-space extrusion!

## Files

```
Assets/PropHunt/
├── Shaders/PropOutline.shader          (Inverted hull shader)
├── Materials/PropOutline.mat           (Cyan outline material)
├── Scripts/PropOutline.lua             (Optional Lua component)
└── Editor/PropOutlineSetupUtility.cs   (Setup tool)
```
