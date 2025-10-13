--!Type(Client)
-- Attach this script to your Virtual Player GameObject.

-- This script will find the ThirdPersonCamera component associated with the
-- virtual player and inspect its '''_offset''' property, which is the likely
-- cause of the movement issue.

local ThirdPersonCamera = require("ThirdPersonCamera")

function self:Start()
    -- Wait a moment for all components to initialize
    Timer.After(0.2, function()
        -- Find the ThirdPersonCamera component on this object or its children
        local cameraComponent = self.gameObject:GetComponent(ThirdPersonCamera)
        if not cameraComponent then
            cameraComponent = self.gameObject:GetComponentInChildren(ThirdPersonCamera)
        end

        if cameraComponent then
            local currentOffset = cameraComponent._offset
            print("[DebugOffset] Found ThirdPersonCamera on '" .. self.gameObject.name .. "'. Current offset is: " .. tostring(currentOffset))

            -- Check if the offset is causing the problem.
            if currentOffset.magnitude > 0.1 then
                print("[DebugOffset] This non-zero offset is likely causing the movement issue.")

                -- To fix the issue, uncomment the two lines below to reset the offset at runtime.
                -- cameraComponent._offset = Vector3.new(0, 0, 0)
                -- print("[DebugOffset] WORKAROUND APPLIED: Camera offset has been reset to zero.")
            else
                print("[DebugOffset] Camera offset is already zero. The problem may be elsewhere.")
            end
        else
            print("[DebugOffset] ERROR: Could not find a ThirdPersonCamera component on '" .. self.gameObject.name .. "'.")
        end
    end)
end
