--!Type(Server)

--[[
    UnitySceneSetup.lua
    Automated scene setup helper for PropHunt

    Attach to a GameObject in your scene and enable autoSetup to automatically create:
    - Zone volumes (NearSpawn, Mid, Far)
    - Spawn points (Lobby, Arena)
    - SceneManager GameObject
    - Example possessable props

    After running once, this script will disable itself.
]]

--!SerializeField
local autoSetup : boolean = false

--!SerializeField
local createExampleProps : boolean = true

local hasRunSetup : boolean = false

-- Zone configuration
local zoneConfigs = {
    {
        name = "Zone_NearSpawn",
        position = Vector3.new(95, 0, 0),
        size = Vector3.new(15, 10, 20),
        tag = "Zone_NearSpawn",
        weight = 1.5
    },
    {
        name = "Zone_Mid",
        position = Vector3.new(110, 0, 0),
        size = Vector3.new(20, 10, 20),
        tag = "Zone_Mid",
        weight = 1.0
    },
    {
        name = "Zone_Far",
        position = Vector3.new(130, 0, 0),
        size = Vector3.new(15, 10, 20),
        tag = "Zone_Far",
        weight = 0.6
    }
}

-- Spawn point configuration
local spawnConfigs = {
    {
        name = "LobbySpawn",
        position = Vector3.new(0, 0, 0),
        rotation = Quaternion.Euler(0, 90, 0)
    },
    {
        name = "ArenaSpawn",
        position = Vector3.new(100, 0, 0),
        rotation = Quaternion.Euler(0, -90, 0)
    }
}

-- Example prop configuration (using string names for primitive types)
local propConfigs = {
    {
        name = "Prop_Cube_1",
        position = Vector3.new(95, 0.5, 5),
        scale = Vector3.new(1, 1, 1),
        primitiveType = "Cube"
    },
    {
        name = "Prop_Sphere_1",
        position = Vector3.new(100, 0.5, -3),
        scale = Vector3.new(1.2, 1.2, 1.2),
        primitiveType = "Sphere"
    },
    {
        name = "Prop_Capsule_1",
        position = Vector3.new(110, 1, 2),
        scale = Vector3.new(0.8, 0.8, 0.8),
        primitiveType = "Capsule"
    },
    {
        name = "Prop_Cube_2",
        position = Vector3.new(120, 0.5, -5),
        scale = Vector3.new(1.5, 0.5, 1.5),
        primitiveType = "Cube"
    },
    {
        name = "Prop_Cylinder_1",
        position = Vector3.new(130, 0.5, 3),
        scale = Vector3.new(1, 1.5, 1),
        primitiveType = "Cylinder"
    }
}

function CreateZoneVolume(config)
    local zoneObj = GameObject.new(config.name)
    zoneObj.transform.position = config.position
    zoneObj.tag = config.tag

    local collider = zoneObj:AddComponent(BoxCollider)
    collider.isTrigger = true
    collider.size = config.size

    -- Add ZoneVolume component (will need to be created separately)
    -- For now, we'll just create the GameObject structure

    print("[UnitySceneSetup] Created zone: " .. config.name .. " at " .. tostring(config.position))
    return zoneObj
end

function CreateSpawnPoint(config)
    local spawnObj = GameObject.new(config.name)
    spawnObj.transform.position = config.position
    spawnObj.transform.rotation = config.rotation
    spawnObj.tag = "SpawnPoint"

    -- Add a visual marker (small sphere for editor visibility)
    local marker = GameObject.CreatePrimitive(PrimitiveType.Sphere)
    marker.name = "SpawnMarker"
    marker.transform:SetParent(spawnObj.transform)
    marker.transform.localPosition = Vector3.zero
    marker.transform.localScale = Vector3.new(0.5, 0.5, 0.5)

    -- Disable collider on marker
    local markerCollider = marker:GetComponent(Collider)
    if markerCollider ~= nil then
        markerCollider.enabled = false
    end

    print("[UnitySceneSetup] Created spawn point: " .. config.name .. " at " .. tostring(config.position))
    return spawnObj
end

function CreateSceneManager()
    local managerObj = GameObject.new("PropHuntSceneManager")
    managerObj.transform.position = Vector3.zero

    -- Note: You'll need to manually add the PropHuntGameManager component in Unity
    -- This script can't add Lua-based components programmatically

    print("[UnitySceneSetup] Created SceneManager GameObject at origin")
    print("[UnitySceneSetup] IMPORTANT: Add PropHuntGameManager component manually!")

    return managerObj
end

function CreatePossessableProp(config)
    -- Map string to PrimitiveType enum
    local primitiveTypeMap = {
        Cube = PrimitiveType.Cube,
        Sphere = PrimitiveType.Sphere,
        Capsule = PrimitiveType.Capsule,
        Cylinder = PrimitiveType.Cylinder,
        Plane = PrimitiveType.Plane
    }

    local primitiveType = primitiveTypeMap[config.primitiveType] or PrimitiveType.Cube
    local propObj = GameObject.CreatePrimitive(primitiveType)
    propObj.name = config.name
    propObj.transform.position = config.position
    propObj.transform.localScale = config.scale
    propObj.tag = "Possessable"

    -- Ensure it has a collider
    local collider = propObj:GetComponent(Collider)
    if collider == nil then
        collider = propObj:AddComponent(BoxCollider)
    end

    -- Note: You'll need to manually add the Possessable component in Unity

    print("[UnitySceneSetup] Created prop: " .. config.name .. " at " .. tostring(config.position))
    return propObj
end

function CreateGroundPlane()
    -- Create a large ground plane for reference
    local ground = GameObject.CreatePrimitive(PrimitiveType.Plane)
    ground.name = "GroundPlane"
    ground.transform.position = Vector3.new(50, -0.1, 0)
    ground.transform.localScale = Vector3.new(20, 1, 10)

    print("[UnitySceneSetup] Created ground plane")
    return ground
end

function RunSetup()
    if hasRunSetup then
        print("[UnitySceneSetup] Setup already completed. Skipping.")
        return
    end

    print("[UnitySceneSetup] ========================================")
    print("[UnitySceneSetup] Starting automated scene setup...")
    print("[UnitySceneSetup] ========================================")

    -- Create parent container for organization
    local containerObj = GameObject.new("PropHunt_AutoGenerated")
    containerObj.transform.position = Vector3.zero

    -- Create zones
    print("[UnitySceneSetup] Creating zone volumes...")
    local zonesParent = GameObject.new("Zones")
    zonesParent.transform:SetParent(containerObj.transform)

    for i, config in ipairs(zoneConfigs) do
        local zone = CreateZoneVolume(config)
        zone.transform:SetParent(zonesParent.transform)
    end

    -- Create spawn points
    print("[UnitySceneSetup] Creating spawn points...")
    local spawnsParent = GameObject.new("SpawnPoints")
    spawnsParent.transform:SetParent(containerObj.transform)

    for i, config in ipairs(spawnConfigs) do
        local spawn = CreateSpawnPoint(config)
        spawn.transform:SetParent(spawnsParent.transform)
    end

    -- Create scene manager
    print("[UnitySceneSetup] Creating SceneManager...")
    local manager = CreateSceneManager()
    manager.transform:SetParent(containerObj.transform)

    -- Create example props
    if createExampleProps then
        print("[UnitySceneSetup] Creating example possessable props...")
        local propsParent = GameObject.new("Possessables")
        propsParent.transform:SetParent(containerObj.transform)

        for i, config in ipairs(propConfigs) do
            local prop = CreatePossessableProp(config)
            prop.transform:SetParent(propsParent.transform)
        end
    end

    -- Create ground plane
    print("[UnitySceneSetup] Creating ground plane...")
    local ground = CreateGroundPlane()
    ground.transform:SetParent(containerObj.transform)

    print("[UnitySceneSetup] ========================================")
    print("[UnitySceneSetup] Setup complete!")
    print("[UnitySceneSetup] ========================================")
    print("[UnitySceneSetup] Manual steps required:")
    print("[UnitySceneSetup] 1. Add PropHuntGameManager to 'PropHuntSceneManager'")
    print("[UnitySceneSetup] 2. Add Possessable component to each prop")
    print("[UnitySceneSetup] 3. Add ZoneVolume component to each zone")
    print("[UnitySceneSetup] 4. Configure references in PropHuntGameManager")
    print("[UnitySceneSetup] 5. Set up materials and lighting")
    print("[UnitySceneSetup] ========================================")

    hasRunSetup = true
    autoSetup = false
end

function self:ServerStart()
    if autoSetup and not hasRunSetup then
        -- Delay setup slightly to ensure scene is fully loaded
        Timer.After(0.5, function()
            RunSetup()
        end)
    else
        print("[UnitySceneSetup] Auto-setup disabled. Enable 'autoSetup' to run.")
    end
end
