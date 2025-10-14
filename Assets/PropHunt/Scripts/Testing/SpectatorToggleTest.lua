--!Type(UI)

--[[
    SpectatorToggleTest.lua

    Test script to verify hiding/showing the spectator toggle UI element.

    SETUP:
    1. Attach this UI script to a Canvas in the scene
    2. Create a GameObject named "SpectatorToggle" with the PropHuntSpectatorButton UI script
    3. Drag the SpectatorToggle GameObject to the "Spectator UI GameObject" field

    BEHAVIOR:
    - Button hides or shows the spectator toggle UI GameObject
    - Tests if we can remove the spectator UI from screen programmatically
    - Useful for hiding spectator toggle during gameplay phases

    This tests UI visibility control needed for game flow.
]]

--!SerializeField
--!Tooltip("Drag the SpectatorToggle GameObject here")
local spectatorUIGameObject : GameObject = nil

--!Bind
local _testButton : VisualElement = nil
--!Bind
local _label : Label = nil

local spectatorUIVisible = true

function self:Start()
    print("[SpectatorToggleTest] Starting spectator UI visibility test...")

    -- Check if GameObject is assigned
    if spectatorUIGameObject == nil then
        print("[SpectatorToggleTest] ERROR: No Spectator UI GameObject assigned!")
        print("[SpectatorToggleTest] Please drag the 'SpectatorToggle' GameObject to the field in Inspector")
        return
    end

    print("[SpectatorToggleTest] Spectator UI GameObject: " .. spectatorUIGameObject.name)

    -- Register button click
    _testButton:RegisterPressCallback(OnTestButtonPressed)

    -- Set initial button state
    UpdateButtonVisuals()

    print("[SpectatorToggleTest] UI initialized")
end

function OnTestButtonPressed()
    print("[SpectatorToggleTest] Test button pressed. Current visibility: " .. tostring(spectatorUIVisible))

    if spectatorUIGameObject == nil then
        print("[SpectatorToggleTest] ERROR: Spectator UI GameObject not assigned!")
        return
    end

    -- Toggle GameObject active state
    if spectatorUIVisible then
        -- Hide the spectator UI
        spectatorUIGameObject:SetActive(false)
        print("[SpectatorToggleTest] ✓ Hid spectator UI (SetActive false)")
        spectatorUIVisible = false
    else
        -- Show the spectator UI
        spectatorUIGameObject:SetActive(true)
        print("[SpectatorToggleTest] ✓ Showed spectator UI (SetActive true)")
        spectatorUIVisible = true
    end

    UpdateButtonVisuals()
end

function UpdateButtonVisuals()
    if spectatorUIVisible then
        -- UI is visible - button will hide it
        _label.text = "Hide Spectator UI"
        local redColor = Color.new(1, 0, 0, 1)
        _testButton.style.borderTopColor = redColor
        _testButton.style.borderBottomColor = redColor
        _testButton.style.borderLeftColor = redColor
        _testButton.style.borderRightColor = redColor
    else
        -- UI is hidden - button will show it
        _label.text = "Show Spectator UI"
        local greenColor = Color.new(0, 1, 0, 1)
        _testButton.style.borderTopColor = greenColor
        _testButton.style.borderBottomColor = greenColor
        _testButton.style.borderLeftColor = greenColor
        _testButton.style.borderRightColor = greenColor
    end
end

--[[
    INTEGRATION NOTES:

    To hide the spectator toggle UI during gameplay:

    1. Get reference to the UI element by name or class
    2. Set display style: element.style.display = DisplayStyle.None
    3. To show again: element.style.display = DisplayStyle.Flex

    This is useful for:
    - Hiding spectator toggle during HIDING/HUNTING phases
    - Only showing it in LOBBY phase
    - Preventing spectator changes mid-game
]]
