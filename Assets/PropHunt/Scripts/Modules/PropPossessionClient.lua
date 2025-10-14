--[[
    PropPossessionClient.lua

    Client-side module for handling prop possession requests.

    Uses simple Event-based networking instead of RemoteFunctions for better
    reliability in local testing.

    Usage:
        local PossessionClient = require("PropPossessionClient")
        PossessionClient.RequestPossession(propIdentifier)

        -- Listen for result:
        PossessionClient.OnPossessionResult(function(playerId, propId, success, message)
            if success then
                print("Possession successful!")
            else
                print("Possession failed:", message)
            end
        end)
]]

--!Type(Module)

-- Network Events (simpler than RemoteFunctions)
local possessionRequestEvent = Event.new("PH_PossessionRequest")
local possessionResultEvent = Event.new("PH_PossessionResult")

print("[PropPossessionClient] ===== MODULE LOADED =====")
print("[PropPossessionClient] possessionRequestEvent: " .. tostring(possessionRequestEvent))
print("[PropPossessionClient] possessionResultEvent: " .. tostring(possessionResultEvent))

--[[
    Request Possession

    Sends a possession request to the server for validation.
    Listen for result via OnPossessionResult callback.

    @param propIdentifier: string - Unique identifier for the prop (usually GameObject name)
]]
function RequestPossession(propIdentifier)
    print("[PropPossessionClient] >>> RequestPossession called with: " .. propIdentifier)
    print("[PropPossessionClient] >>> Event object: " .. tostring(possessionRequestEvent))
    print("[PropPossessionClient] >>> Calling FireServer...")

    -- Fire event to server (simpler than RemoteFunction)
    possessionRequestEvent:FireServer(propIdentifier)

    print("[PropPossessionClient] >>> FireServer completed successfully")
end

--[[
    Listen for Possession Results

    Register a callback to be notified when possession succeeds or fails.

    @param callback: function(playerId, propId, success, message)
]]
function OnPossessionResult(callback)
    print("[PropPossessionClient] Registering result callback")
    possessionResultEvent:Connect(callback)
    print("[PropPossessionClient] Result callback registered")
end

-- ========== MODULE EXPORTS ==========

return {
    RequestPossession = RequestPossession,
    OnPossessionResult = OnPossessionResult
}
