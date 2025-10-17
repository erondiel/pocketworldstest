--!Type(Client)
-- Attach this script to an always-active GameObject in your scene (e.g., PropHuntModules).
-- It will automatically find Virtual Players at runtime and attach the debug script to them.

local DebugScript = require("DebugVirtualPlayerOffset")

local processedPlayers = {} -- Keep track of players we've already processed

function self:FixedUpdate()
    -- Find all GameObjects. This is not super efficient, but for a debug tool it is fine.
    local allGameObjects = GameObject.FindObjectsOfType(GameObject)

    for _, obj in ipairs(allGameObjects) do
        -- Check if the object is a Virtual Player and we haven't processed it yet
        if string.match(obj.name, "VirtualPlayer") and not processedPlayers[obj] then
            print("[DebugManager] Found a new Virtual Player: " .. obj.name)

            -- Add the debug script to the virtual player object
            -- In Highrise, AddComponent can take the script name as a string.
            local addedComponent = obj:AddComponent("DebugVirtualPlayerOffset")
            if addedComponent then
                print("[DebugManager] Successfully attached DebugVirtualPlayerOffset.lua to " .. obj.name)
            else
                print("[DebugManager] FAILED to attach DebugVirtualPlayerOffset.lua to " .. obj.name)
            end

            -- Mark this player as processed to avoid adding the script every frame
            processedPlayers[obj] = true
        end
    end
end
