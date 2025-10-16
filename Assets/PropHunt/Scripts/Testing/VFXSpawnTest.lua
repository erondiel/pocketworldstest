--!Type(UI)

--[[
    VFXSpawnTest.lua

    Test UI script to verify VFX spawning system with SerializeField pattern.

    SETUP:
    1. Create an empty GameObject in the scene (e.g., "VFXTestUI")
    2. Attach this UI script to the empty GameObject
    3. Drag the "ArenaSpawn" GameObject to the "Arena Spawn" field in Inspector
    4. Ensure all VFX prefabs are assigned in PropHuntModules > PropHuntVFXManager
    5. Ensure VFXPrefabs parent GameObject exists with VFX children (disabled)

    BEHAVIOR:
    - Each button spawns a specific VFX type at ArenaSpawn position
    - Comprehensive logging for debugging
]]

local VFXManager = require("PropHuntVFXManager")

--!SerializeField
--!Tooltip("Drag the ArenaSpawn GameObject here")
local arenaSpawnGameObject : GameObject = nil

--!Bind
local _playerVanishButton : VisualElement = nil
--!Bind
local _propInfillButton : VisualElement = nil
--!Bind
local _rejectionButton : VisualElement = nil
--!Bind
local _tagHitButton : VisualElement = nil
--!Bind
local _tagMissButton : VisualElement = nil

function self:Start()
    print("[VFXSpawnTest] ===== VFX Test UI Initializing =====")

    -- Validate Arena Spawn reference
    if arenaSpawnGameObject == nil then
        print("[VFXSpawnTest] ERROR: No Arena Spawn GameObject assigned!")
        print("[VFXSpawnTest] Please drag the 'ArenaSpawn' GameObject to the field in Inspector")
        return
    end

    print("[VFXSpawnTest] Arena Spawn GameObject: " .. arenaSpawnGameObject.name)
    print("[VFXSpawnTest] Arena Spawn Position: " .. tostring(arenaSpawnGameObject.transform.position))

    -- Register button callbacks
    _playerVanishButton:RegisterPressCallback(OnPlayerVanishPressed)
    _propInfillButton:RegisterPressCallback(OnPropInfillPressed)
    _rejectionButton:RegisterPressCallback(OnRejectionPressed)
    _tagHitButton:RegisterPressCallback(OnTagHitPressed)
    _tagMissButton:RegisterPressCallback(OnTagMissPressed)

    print("[VFXSpawnTest] ===== VFX Test UI Initialized Successfully =====")
    print("[VFXSpawnTest] Click buttons to spawn VFX at Arena position")
end

function OnPlayerVanishPressed()
    print("[VFXSpawnTest] ========================================")
    print("[VFXSpawnTest] PlayerVanish Button Pressed")

    local pos = arenaSpawnGameObject.transform.position
    print(string.format("[VFXSpawnTest] Spawning at: (%.2f, %.2f, %.2f)", pos.x, pos.y, pos.z))

    VFXManager.PlayerVanishVFX(pos, nil)
    print("[VFXSpawnTest] ✓ PlayerVanishVFX called")
    print("[VFXSpawnTest] ========================================")
end

function OnPropInfillPressed()
    print("[VFXSpawnTest] ========================================")
    print("[VFXSpawnTest] PropInfill Button Pressed")

    local pos = arenaSpawnGameObject.transform.position
    print(string.format("[VFXSpawnTest] Spawning at: (%.2f, %.2f, %.2f)", pos.x, pos.y, pos.z))

    VFXManager.PropInfillVFX(pos, nil)
    print("[VFXSpawnTest] ✓ PropInfillVFX called")
    print("[VFXSpawnTest] ========================================")
end

function OnRejectionPressed()
    print("[VFXSpawnTest] ========================================")
    print("[VFXSpawnTest] Rejection Button Pressed")

    local pos = arenaSpawnGameObject.transform.position
    print(string.format("[VFXSpawnTest] Spawning at: (%.2f, %.2f, %.2f)", pos.x, pos.y, pos.z))

    VFXManager.RejectionVFX(pos, nil)
    print("[VFXSpawnTest] ✓ RejectionVFX called")
    print("[VFXSpawnTest] ========================================")
end

function OnTagHitPressed()
    print("[VFXSpawnTest] ========================================")
    print("[VFXSpawnTest] TagHit Button Pressed")

    local pos = arenaSpawnGameObject.transform.position
    print(string.format("[VFXSpawnTest] Spawning at: (%.2f, %.2f, %.2f)", pos.x, pos.y, pos.z))

    VFXManager.TagHitVFX(pos, nil)
    print("[VFXSpawnTest] ✓ TagHitVFX called")
    print("[VFXSpawnTest] ========================================")
end

function OnTagMissPressed()
    print("[VFXSpawnTest] ========================================")
    print("[VFXSpawnTest] TagMiss Button Pressed")

    local pos = arenaSpawnGameObject.transform.position
    print(string.format("[VFXSpawnTest] Spawning at: (%.2f, %.2f, %.2f)", pos.x, pos.y, pos.z))

    VFXManager.TagMissVFX(pos, nil)
    print("[VFXSpawnTest] ✓ TagMissVFX called")
    print("[VFXSpawnTest] ========================================")
end
