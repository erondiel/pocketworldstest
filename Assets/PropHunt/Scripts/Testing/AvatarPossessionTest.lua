--!Type(UI)

--[[
    AvatarPossessionTest.lua

    Test script to verify hiding and disabling player avatar control.

    SETUP:
    1. Attach this UI script to a Canvas in the scene

    BEHAVIOR:
    - Button simulates possession by hiding avatar and disabling movement
    - Tests avatar visibility and control disable/enable
    - When "possessed", player avatar disappears and cannot move

    This tests the avatar control needed for prop possession system.
]]

--!Bind
local _testButton : VisualElement = nil
--!Bind
local _label : Label = nil

local avatarVisible = true
local originalPosition = nil
local navMeshGameObject = nil  -- Store reference to NavMesh GameObject

function self:Start()
    print("[AvatarPossessionTest] Starting avatar possession test...")

    -- Register button click
    _testButton:RegisterPressCallback(OnTestButtonPressed)

    -- Set initial button state
    UpdateButtonVisuals()

    print("[AvatarPossessionTest] UI initialized. Click button to simulate possession.")
end

function OnTestButtonPressed()
    print("[AvatarPossessionTest] Test button pressed. Current avatar visible: " .. tostring(avatarVisible))

    local player = client.localPlayer
    if not player then
        print("[AvatarPossessionTest] ERROR: Local player not found!")
        return
    end

    if not player.character then
        print("[AvatarPossessionTest] ERROR: Player character not found!")
        return
    end

    if avatarVisible then
        -- SIMULATE POSSESSION: Hide avatar and disable movement
        print("[AvatarPossessionTest] Simulating possession - hiding avatar...")
        HideAvatar(player)
        avatarVisible = false
    else
        -- RESTORE: Show avatar and enable movement
        print("[AvatarPossessionTest] Restoring avatar...")
        ShowAvatar(player)
        avatarVisible = true
    end

    UpdateButtonVisuals()
end

function HideAvatar(player)
    local success, errorMsg = pcall(function()
        local character = player.character

        -- Save current position
        originalPosition = character.transform.position
        print("[AvatarPossessionTest] Saved position: " .. tostring(originalPosition))

        -- Method 1: Find and disable NavMesh GameObject to prevent tap-to-move
        if not navMeshGameObject then
            navMeshGameObject = GameObject.Find("NavMesh")
        end

        if navMeshGameObject then
            navMeshGameObject:SetActive(false)
            print("[AvatarPossessionTest] ✓ Disabled NavMesh GameObject (prevents tap-to-move)")
        else
            print("[AvatarPossessionTest] WARNING: NavMesh GameObject not found - tap-to-move may still work!")
        end

        -- Method 2: Disable character GameObject entirely (for visibility)
        local characterGameObject = character.gameObject
        if characterGameObject then
            characterGameObject:SetActive(false)
            print("[AvatarPossessionTest] ✓ Disabled character GameObject")
            print("[AvatarPossessionTest] ===== AVATAR HIDDEN =====")
            return
        end

        -- Fallback: Try component-by-component approach
        print("[AvatarPossessionTest] Trying component-based approach...")

        -- Try to disable character mesh renderers
        local rendererSuccess = pcall(function()
            local renderers = character:GetComponentsInChildren(SkinnedMeshRenderer)
            if renderers and renderers.Length then
                print("[AvatarPossessionTest] Found " .. renderers.Length .. " SkinnedMeshRenderers")
                for i = 0, renderers.Length - 1 do
                    renderers[i].enabled = false
                end
                print("[AvatarPossessionTest] ✓ Disabled SkinnedMeshRenderers")
            end
        end)

        if not rendererSuccess then
            print("[AvatarPossessionTest] Note: Could not disable SkinnedMeshRenderers")
        end

        -- Also disable regular mesh renderers
        local meshSuccess = pcall(function()
            local meshRenderers = character:GetComponentsInChildren(MeshRenderer)
            if meshRenderers and meshRenderers.Length then
                print("[AvatarPossessionTest] Found " .. meshRenderers.Length .. " MeshRenderers")
                for i = 0, meshRenderers.Length - 1 do
                    meshRenderers[i].enabled = false
                end
                print("[AvatarPossessionTest] ✓ Disabled MeshRenderers")
            end
        end)

        if not meshSuccess then
            print("[AvatarPossessionTest] Note: Could not disable MeshRenderers")
        end

        -- Try to disable character controller/movement
        local controllerSuccess = pcall(function()
            local characterController = character:GetComponent(CharacterController)
            if characterController then
                characterController.enabled = false
                print("[AvatarPossessionTest] ✓ Disabled CharacterController")
            end
        end)

        -- Try to disable player input
        local inputSuccess = pcall(function()
            player.character.movementEnabled = false
            print("[AvatarPossessionTest] ✓ Disabled movement via movementEnabled")
        end)

        if not inputSuccess then
            print("[AvatarPossessionTest] Note: movementEnabled not available")
        end

        -- Freeze rigidbody if present
        local rbSuccess = pcall(function()
            local rigidbody = character:GetComponent(Rigidbody)
            if rigidbody then
                rigidbody.isKinematic = true
                rigidbody.velocity = Vector3.zero
                print("[AvatarPossessionTest] ✓ Froze Rigidbody")
            end
        end)

        print("[AvatarPossessionTest] ===== AVATAR HIDDEN =====")
    end)

    if not success then
        print("[AvatarPossessionTest] ✗✗✗ ERROR: " .. tostring(errorMsg))
    end
end

function ShowAvatar(player)
    local success, errorMsg = pcall(function()
        local character = player.character

        -- Method 1: Re-enable character GameObject
        local characterGameObject = character.gameObject
        if characterGameObject and not characterGameObject.activeSelf then
            characterGameObject:SetActive(true)
            print("[AvatarPossessionTest] ✓ Enabled character GameObject")
        end

        -- Method 2: Re-enable NavMesh GameObject to restore tap-to-move
        if navMeshGameObject then
            navMeshGameObject:SetActive(true)
            print("[AvatarPossessionTest] ✓ Enabled NavMesh GameObject (restores tap-to-move)")
        else
            print("[AvatarPossessionTest] WARNING: NavMesh GameObject reference lost!")
        end

        print("[AvatarPossessionTest] ===== AVATAR RESTORED =====")

        if characterGameObject and characterGameObject.activeSelf then
            return
        end

        -- Fallback: Re-enable components
        print("[AvatarPossessionTest] Trying component-based restore...")

        -- Re-enable character mesh renderers
        local rendererSuccess = pcall(function()
            local renderers = character:GetComponentsInChildren(SkinnedMeshRenderer)
            if renderers and renderers.Length then
                for i = 0, renderers.Length - 1 do
                    renderers[i].enabled = true
                end
                print("[AvatarPossessionTest] ✓ Enabled SkinnedMeshRenderers")
            end
        end)

        -- Re-enable regular mesh renderers
        local meshSuccess = pcall(function()
            local meshRenderers = character:GetComponentsInChildren(MeshRenderer)
            if meshRenderers and meshRenderers.Length then
                for i = 0, meshRenderers.Length - 1 do
                    meshRenderers[i].enabled = true
                end
                print("[AvatarPossessionTest] ✓ Enabled MeshRenderers")
            end
        end)

        -- Re-enable character controller
        local controllerSuccess = pcall(function()
            local characterController = character:GetComponent(CharacterController)
            if characterController then
                characterController.enabled = true
                print("[AvatarPossessionTest] ✓ Enabled CharacterController")
            end
        end)

        -- Re-enable player input
        local inputSuccess = pcall(function()
            player.character.movementEnabled = true
            print("[AvatarPossessionTest] ✓ Enabled movement via movementEnabled")
        end)

        -- Unfreeze rigidbody if present
        local rbSuccess = pcall(function()
            local rigidbody = character:GetComponent(Rigidbody)
            if rigidbody then
                rigidbody.isKinematic = false
                print("[AvatarPossessionTest] ✓ Unfroze Rigidbody")
            end
        end)

        -- Restore position (optional, in case something moved the character)
        if originalPosition then
            character.transform.position = originalPosition
            print("[AvatarPossessionTest] ✓ Restored position")
        end

        print("[AvatarPossessionTest] ===== AVATAR RESTORED =====")
    end)

    if not success then
        print("[AvatarPossessionTest] ✗✗✗ ERROR: " .. tostring(errorMsg))
    end
end

function UpdateButtonVisuals()
    if avatarVisible then
        -- Avatar is visible - button will hide it
        _label.text = "Avatar Test: Hide"
        local cyanColor = Color.new(0, 1, 1, 1)
        _testButton.style.borderTopColor = cyanColor
        _testButton.style.borderBottomColor = cyanColor
        _testButton.style.borderLeftColor = cyanColor
        _testButton.style.borderRightColor = cyanColor
    else
        -- Avatar is hidden - button will show it
        _label.text = "Avatar Test: Show"
        local orangeColor = Color.new(1, 0.5, 0, 1)
        _testButton.style.borderTopColor = orangeColor
        _testButton.style.borderBottomColor = orangeColor
        _testButton.style.borderLeftColor = orangeColor
        _testButton.style.borderRightColor = orangeColor
    end
end

--[[
    INTEGRATION NOTES FOR PropDisguiseSystem:

    When a player possesses a prop:
    1. Hide avatar meshes (disable SkinnedMeshRenderer + MeshRenderer)
    2. Disable movement (CharacterController.enabled = false)
    3. Optionally freeze physics (Rigidbody.isKinematic = true)
    4. Move player to prop position
    5. Parent camera to prop (so player sees from prop's perspective)

    When unpossessing (if allowed) or when round ends:
    1. Restore all avatar components
    2. Move player back to safe position
    3. Unparent camera

    This ensures the player is "inside" the prop and cannot control their avatar.
]]
