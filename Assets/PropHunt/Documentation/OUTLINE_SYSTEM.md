# PropHunt Outline System

Simple outline rendering using inverted hull technique. Creates a slightly larger duplicate mesh rendered behind the original.

## Quick Setup

**Unity Editor:**
1. `PropHunt → Outline Setup`
2. Tag props with "Possessable"
3. Click "Add Outlines to All Props"

Creates child GameObject `PropName_Outline` with outline mesh (disabled by default).

## How It Works

**Inverted Hull Technique:**
- Duplicate mesh rendered with backface culling (Cull Front)
- Vertices expanded slightly along normals in object-space
- Renders behind original mesh creating outline effect
- Simple, lightweight, mobile-friendly

**Limitation:** Outline may be partially hidden when object is very close to walls (backfaces occluded). Use small width (0.002-0.005) to minimize this.

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
- **Outline Width:** 0.003 (range: 0.001-0.01)
  - Smaller = tighter outline, less occlusion issues
  - Larger = more visible but may clip through nearby objects

## Troubleshooting

**Outline not visible:** Check MeshRenderer.enabled = true on child
**Outline disappears near walls:** Use smaller width (0.002-0.004)
**Outline too thin:** Increase width in material
**Outline clips through objects:** Decrease width

## Files

```
Assets/PropHunt/
├── Shaders/PropOutline.shader          (Inverted hull shader)
├── Materials/PropOutline.mat           (Cyan outline material)
├── Scripts/PropOutline.lua             (Optional Lua component)
└── Editor/PropOutlineSetupUtility.cs   (Setup tool)
```
