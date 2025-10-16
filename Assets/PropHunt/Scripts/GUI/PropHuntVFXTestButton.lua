--!Type(Client)

--[[
    PropHunt VFX Test Button
    Simple UI button to test VFX spawning at Arena spawn position

    Usage:
    1. Attach this script to a Button GameObject in the scene
    2. Button will spawn VFX at ArenaSpawn position when clicked
    3. Cycles through all 5 VFX types for testing
]]

local VFXManager = require("PropHuntVFXManager")

-- VFX types to cycle through
local vfxTypes = {
    "PlayerVanish",
    "PropInfill",
    "Rejection",
    "TagHit",
    "TagMiss"
}
local currentVFXIndex = 1

-- Arena spawn reference
local arenaSpawn = nil

--[[
    Find Arena Spawn GameObject
]]
local function GetArenaSpawn()
    if not arenaSpawn then
        local arenaGO = GameObject.Find("ArenaSpawn")
        if arenaGO then
            arenaSpawn = arenaGO.transform
            print("[VFX Test Button] Found ArenaSpawn GameObject")
        else
            print("[VFX Test Button] ERROR: ArenaSpawn GameObject not found in scene!")
        end
    end
    return arenaSpawn
end

--[[
    Spawn VFX at Arena spawn position
]]
local function SpawnTestVFX()
    local spawn = GetArenaSpawn()
    if not spawn then
        print("[VFX Test Button] ERROR: Cannot spawn VFX - ArenaSpawn not found!")
        return
    end

    local position = spawn.position
    local vfxType = vfxTypes[currentVFXIndex]

    print(string.format("[VFX Test Button] ===== SPAWNING %s VFX at Arena =====", vfxType))
    print(string.format("[VFX Test Button] Position: (%.2f, %.2f, %.2f)", position.x, position.y, position.z))

    -- Spawn the appropriate VFX
    if vfxType == "PlayerVanish" then
        VFXManager.PlayerVanishVFX(position, nil)
        print("[VFX Test Button] Called: VFXManager.PlayerVanishVFX()")
    elseif vfxType == "PropInfill" then
        VFXManager.PropInfillVFX(position, nil)
        print("[VFX Test Button] Called: VFXManager.PropInfillVFX()")
    elseif vfxType == "Rejection" then
        VFXManager.RejectionVFX(position, nil)
        print("[VFX Test Button] Called: VFXManager.RejectionVFX()")
    elseif vfxType == "TagHit" then
        VFXManager.TagHitVFX(position, nil)
        print("[VFX Test Button] Called: VFXManager.TagHitVFX()")
    elseif vfxType == "TagMiss" then
        VFXManager.TagMissVFX(position, nil)
        print("[VFX Test Button] Called: VFXManager.TagMissVFX()")
    end

    print(string.format("[VFX Test Button] ===== %s VFX SPAWNED =====", vfxType))

    -- Cycle to next VFX type
    currentVFXIndex = currentVFXIndex + 1
    if currentVFXIndex > #vfxTypes then
        currentVFXIndex = 1
    end

    print(string.format("[VFX Test Button] Next VFX will be: %s", vfxTypes[currentVFXIndex]))
end

--[[
    Client Start - Setup button click handler
]]
function self:ClientStart()
    -- Find the button component on this GameObject
    local button = self.gameObject:GetComponent(Button)
    if not button then
        print("[VFX Test Button] ERROR: No Button component found on GameObject!")
        return
    end

    -- Setup click handler
    button.onClick:AddListener(function()
        SpawnTestVFX()
    end)

    print("[VFX Test Button] Initialized - Button click handler registered")
    print("[VFX Test Button] Click button to test VFX spawning at ArenaSpawn")
end
