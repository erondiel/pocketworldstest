# Spectator Toggle UI Design

## Visual Layout

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│                         LOBBY AREA                            │
│                                                               │
│                                                               │
│                                                               │
│                                                               │
│                                                               │
│                                                               │
│                                                               │
│                    ┌─────────┐                                │
│                    │  Ready  │  ← Ready Button (center)       │
│                    └─────────┘                                │
│                                         ┌──────────────────┐  │
│                                         │ Spectator  [⚫—] │  │
│                                         └──────────────────┘  │
│                                         ↑ Spectator Toggle    │
│                                         (bottom-right)        │
└─────────────────────────────────────────────────────────────┘
```

## Toggle States

### OFF State (Gray)
```
┌──────────────────┐
│ Spectator  [—⚫] │  ← Toggle is OFF (gray background)
└──────────────────┘
```

### ON State (Green)
```
┌──────────────────┐
│ Spectator  [⚫—] │  ← Toggle is ON (green background)
└──────────────────┘
```

## Specifications

### Container
- **Position**: Absolute, bottom-right corner
- **Bottom**: 10px
- **Right**: 10px
- **Size**: 120px × 40px
- **Background**: Black with 50% opacity
- **Border**: 2px white with 30% opacity
- **Border Radius**: 8px
- **Layout**: Horizontal row (label + toggle)

### Label
- **Text**: "Spectator"
- **Font**: var(--font-bold)
- **Size**: 14px
- **Color**: White
- **Alignment**: Left

### Toggle Switch
- **Size**: 40px × 20px
- **Border Radius**: 10px (pill shape)
- **OFF Background**: #666666 (gray)
- **ON Background**: #4CAF50 (green)
- **Transition**: 0.3s smooth

### Toggle Thumb
- **Size**: 16px × 16px (circle)
- **Color**: White
- **Position (OFF)**: 2px from left
- **Position (ON)**: 22px from left
- **Transition**: 0.2s smooth

## Color Palette

```css
--toggle-off-color: #666666;  /* Gray - Not spectating */
--toggle-on-color: #4CAF50;   /* Green - Spectating */
--white-color: #ffffff;        /* Text and thumb */
```

## Comparison with Ready Button

### Ready Button
- **Position**: Bottom-center
- **Size**: 100px × 40px
- **Type**: Button with label
- **Border**: Green (2px)

### Spectator Toggle
- **Position**: Bottom-right
- **Size**: 120px × 40px
- **Type**: Toggle switch with label
- **Border**: White/transparent (2px)

## Interaction Behavior

### User Actions
1. **Click/Tap Toggle**: Flips switch ON/OFF
2. **Visual Feedback**:
   - Thumb slides left→right (ON) or right→left (OFF)
   - Background color changes gray→green or green→gray
   - Smooth 0.2-0.3s animation

### State Synchronization
- Toggle state syncs with server-side `isSpectator` value
- If server changes spectator state, toggle updates automatically
- No desync between visual state and actual state

## CSS Properties Reference

### Positioning
```css
position: absolute;
bottom: 10px;
right: 10px;
```

### Flexbox Layout
```css
flex-direction: row;
align-items: center;
justify-content: space-between;
```

### Toggle Animation
```css
transition-property: background-color;
transition-duration: 0.3s;
```

### Thumb Animation
```css
transition-property: left;
transition-duration: 0.2s;
```

## Accessibility Notes

1. **Size**: Toggle is 40px × 20px (easily tappable on mobile)
2. **Contrast**: White text on dark background (high contrast)
3. **Feedback**: Visual state change (color) + position change (thumb)
4. **Label**: Clear "Spectator" text explains purpose

## Mobile Optimization

- **Touch Target**: 40px height meets minimum tap target size
- **Corner Position**: Easy thumb reach on mobile devices
- **Clear Label**: No ambiguity about function
- **Immediate Feedback**: Toggle flips instantly, teleport happens server-side

## Files

### UXML (Layout)
**File**: `PropHuntSpectatorButton.uxml`
```xml
<hr:UILuaView class="prophuntspectatorbutton">
  <VisualElement class="spectator-container">
    <Label class="spectator-label" text="Spectator" />
    <hr:UISwitchToggle class="spectator-toggle" name="_toggle" />
  </VisualElement>
</hr:UILuaView>
```

### USS (Styling)
**File**: `PropHuntSpectatorButton.uss`
- Defines all visual properties
- Handles OFF/ON states via `:checked` pseudo-class
- Animates toggle and thumb transitions

### Lua (Behavior)
**File**: `PropHuntSpectatorButton.lua`
- Binds to `_toggle : UISwitchToggle`
- Listens to `BoolChangeEvent`
- Fires `SpectatorToggleRequest:FireServer()`
- Syncs toggle state with server

## Unity Inspector Setup

1. **Create UI GameObject** in Lobby scene
2. **Attach Script**: `PropHuntSpectatorButton.lua`
3. **Link UXML**: Drag `PropHuntSpectatorButton.uxml` to UXML field
4. **Link USS**: Drag `PropHuntSpectatorButton.uss` to USS field
5. **Test**: Toggle should appear in bottom-right corner

## Visual Hierarchy

```
Lobby UI Layer
├── Background Elements
├── Center Elements
│   └── Ready Button (bottom-center)
├── Right Elements
│   └── Spectator Toggle (bottom-right) ← NEW
└── Other UI Elements
```

## Design Rationale

### Why Toggle Instead of Button?
1. **State Clarity**: Toggle clearly shows ON/OFF state at a glance
2. **Space Efficiency**: Smaller footprint (120px vs 250px button)
3. **Modern UX**: Toggle switches are standard for binary states
4. **No Text Change**: "Spectator" label stays constant (simpler)

### Why Bottom-Right?
1. **Non-Intrusive**: Doesn't overlap with center Ready button
2. **Thumb-Friendly**: Easy to reach on mobile devices
3. **Logical Grouping**: Both action buttons at bottom of screen
4. **Visual Balance**: Ready (center) + Spectator (right)

### Why Compact Design?
1. **120px width**: Just enough for label + toggle
2. **40px height**: Matches Ready button height
3. **Minimal footprint**: Doesn't block lobby view
4. **Professional**: Clean, uncluttered interface
