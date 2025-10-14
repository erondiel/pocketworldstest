--!Type(UI)

--[[
    PropEmissionTest.lua

    Test script to verify emission control for prop possession effect.

    SETUP:
    1. Create a test prop with a URP Lit material that has Emission enabled
    2. Set emission color and strength to desired values in Unity material (e.g., strength 2.0)
    3. Attach this UI script to a Canvas in the scene
    4. Drag the prop to the "Test Prop" field in the Inspector

    BEHAVIOR:
    - Emission starts ON (prop is visible with glow)
    - Click "Simulate Possession": Turns emission OFF (strength = 0) to simulate player possessing prop
    - Click "Restore Emission": Turns emission back ON (restores saved strength)
    - Outline toggles with emission state

    This tests the emission control that will be used in PropDisguiseSystem.
]]

--!SerializeField
--!Tooltip("Drag a prop GameObject here to test emission control")
local testProp : GameObject = nil

--!Bind
local _toggleButton : VisualElement = nil
--!Bind
local _label : Label = nil

local emissionActive = true  -- Start with emission ON (prop is visible)
local savedEmissionStrength = 2.0  -- Will be read from material on start

function self:Start()
    print("[PropEmissionTest] Starting emission test UI...")

    if testProp == nil then
        print("[PropEmissionTest] ERROR: No test prop assigned!")
        print("[PropEmissionTest] Please drag a prop GameObject to the 'Test Prop' field in the Inspector")
        return
    end

    print("[PropEmissionTest] Test prop: " .. testProp.name)

    -- Read initial emission strength from material
    ReadInitialEmissionStrength()

    -- Register button click
    _toggleButton:RegisterPressCallback(OnToggleButtonPressed)

    -- Set initial button state
    UpdateButtonVisuals()

    print("[PropEmissionTest] UI initialized. Emission is ON. Click button to simulate possession.")
end

function ReadInitialEmissionStrength()
    local success, errorMsg = pcall(function()
        local renderer = testProp:GetComponent(MeshRenderer)
        if not renderer then
            print("[PropEmissionTest] WARNING: No MeshRenderer found, using default strength 2.0")
            return
        end

        local material = renderer.sharedMaterial
        if material then
            -- Try to read current emission strength
            local readSuccess = pcall(function()
                savedEmissionStrength = material:GetFloat("_EmissionStrength")
                print("[PropEmissionTest] Read emission strength from material: " .. savedEmissionStrength)
            end)

            if not readSuccess then
                print("[PropEmissionTest] Could not read _EmissionStrength, using default 2.0")
                savedEmissionStrength = 2.0
            end
        end
    end)

    if not success then
        print("[PropEmissionTest] Error reading material: " .. tostring(errorMsg))
    end
end

function OnToggleButtonPressed()
    if testProp == nil then return end

    if emissionActive then
        -- Turn OFF (simulate possession)
        print("[PropEmissionTest] Simulating possession - turning OFF emission...")
        SetEmissionStrength(0)
        emissionActive = false
    else
        -- Turn ON (restore)
        print("[PropEmissionTest] Restoring emission (strength: " .. savedEmissionStrength .. ")...")
        SetEmissionStrength(savedEmissionStrength)
        emissionActive = true
    end

    UpdateButtonVisuals()
end

function SetEmissionStrength(strength)
    local success, errorMsg = pcall(function()
        local renderer = testProp:GetComponent(MeshRenderer)
        if not renderer then
            print("[PropEmissionTest] ERROR: No MeshRenderer found on prop")
            return
        end

        -- Try MaterialPropertyBlock first (preferred method - no material instances)
        local mpbSuccess = pcall(function()
            local propertyBlock = MaterialPropertyBlock.new()
            renderer:GetPropertyBlock(propertyBlock)
            propertyBlock:SetFloat("_EmissionStrength", strength)
            renderer:SetPropertyBlock(propertyBlock)
            print("[PropEmissionTest] ✓ Set emission strength to " .. strength .. " via MaterialPropertyBlock")
        end)

        if not mpbSuccess then
            -- Fallback to material instance
            local material = renderer.material
            material:SetFloat("_EmissionStrength", strength)
            print("[PropEmissionTest] ✓ Set emission strength to " .. strength .. " via material instance (creates instance)")
        end

        -- Toggle outline visibility
        local outlineChild = testProp.transform:Find(testProp.name .. "_Outline")
        if outlineChild then
            local outlineRenderer = outlineChild:GetComponent(MeshRenderer)
            if outlineRenderer then
                outlineRenderer.enabled = (strength > 0)
                print("[PropEmissionTest] Outline: " .. (strength > 0 and "ON" or "OFF"))
            end
        end
    end)

    if not success then
        print("[PropEmissionTest] ✗✗✗ ERROR: " .. tostring(errorMsg))
    end
end

function UpdateButtonVisuals()
    if emissionActive then
        -- Emission is ON - button will turn it OFF
        _label.text = "Simulate Possession"
        local cyanColor = Color.new(0, 1, 1, 1)
        _toggleButton.style.borderTopColor = cyanColor
        _toggleButton.style.borderBottomColor = cyanColor
        _toggleButton.style.borderLeftColor = cyanColor
        _toggleButton.style.borderRightColor = cyanColor
    else
        -- Emission is OFF - button will turn it ON
        _label.text = "Restore Emission"
        local orangeColor = Color.new(1, 0.5, 0, 1)
        _toggleButton.style.borderTopColor = orangeColor
        _toggleButton.style.borderBottomColor = orangeColor
        _toggleButton.style.borderLeftColor = orangeColor
        _toggleButton.style.borderRightColor = orangeColor
    end
end

--[[
    INTEGRATION NOTES FOR PropDisguiseSystem:

    When a player possesses a prop, call:
        SetEmissionStrength(0)  -- Turn off emission
        outlineRenderer.enabled = false  -- Hide outline

    This makes the prop look "normal" and indistinguishable from other props.

    The MaterialPropertyBlock method is preferred as it doesn't create material instances,
    which is important for performance when many props can be possessed.
]]
