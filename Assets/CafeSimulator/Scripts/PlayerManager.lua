--!Type(Module) -- Module type declaration, typically used in specific game engines or frameworks.

-- Create events for different types of requests, these will be used for communication between client and server.
local getStatsRequest = Event.new("GetStatsRequest")
local saveStatsRequest = Event.new("SaveStatsRequest")
local incrementStatRequest = Event.new("IncrementStatRequest")
local setRoleRequest = Event.new("SetRoleRequest")

-- Variable to hold the player's statistics GUI component
local playerStatGui = nil

-- Table to keep track of players and their associated stats
players = {}

-- Function to track players joining and leaving the game
local function TrackPlayers(game, characterCallback)
    -- Connect to the event when a player joins the game
    scene.PlayerJoined:Connect(function(scene, player)
        -- Initialize player's stats and store them in the players table
        players[player] = {
            player = player,
            Role = IntValue.new("Role" .. tostring(player.id), -1), -- Role: 1 = Employee, 0 = Customer, -1 = Undefined
            Cash = IntValue.new("Cash" .. tostring(player.id), 0), -- Initial cash value
            WorkXP = IntValue.new("WorkXP" .. tostring(player.id), 0), -- Initial work experience
            CustXP = IntValue.new("CustXp" .. tostring(player.id), 0) -- Initial customer experience
        }

        -- Connect to the event when the player's character changes (e.g., respawn)
        player.CharacterChanged:Connect(function(player, character)
            local playerinfo = players[player]
            -- If character is nil, do nothing
            if (character == nil) then
                return
            end 

            -- If a character callback function is provided, call it with the player information
            if characterCallback then
                characterCallback(playerinfo)
            end
        end)
    end)

    -- Connect to the event when a player leaves the game
    scene.PlayerLeft:Connect(function(player)
        -- Remove the player from the players table
        players[player] = nil
    end)
end

-- Function to find the key with the maximum value in a table
local function findMaxKey(tbl)
    local maxKey = nil
    local maxValue = -math.huge -- Start with negative infinity as initial maximum value

    -- Iterate through the table to find the key with the maximum value
    for key, value in pairs(tbl) do
        if value > maxValue then
            maxValue = value
            maxKey = key
        elseif value == maxValue then
            maxValue = value
            maxKey = nil -- If there is a tie, set maxKey to nil
        end
    end

    return maxKey
end

--[[

    Client-side functionality

--]]

-- Function to change the player's role by sending a request to the server
function ChangeRole()
    setRoleRequest:FireServer()
end

-- Function to get the local player's cash
function GetPlayerCash()
    return players[client.localPlayer].Cash.value
end

-- Function to initialize the client-side logic
function self:ClientAwake()
    -- Get the PlayerStatGui component from the game object to interact with the player's stat UI
    playerStatGui = self.gameObject:GetComponent(PlayerStatGui)

    -- Function to handle character instantiation for a player
    function OnCharacterInstantiate(playerinfo)
        local player = playerinfo.player
        local character = player.character

        -- Handle changes in the player's role
        playerinfo.Role.Changed:Connect(function(currentRole, oldVal)
            if player == client.localPlayer then
                local roleText = ""
                if currentRole == 0 then 
                    roleText = "Customer"
                    playerStatGui.SetXpUI(playerinfo.CustXP.value)
                elseif currentRole == 1 then 
                    roleText = "Employee" 
                    playerStatGui.SetXpUI(playerinfo.WorkXP.value)
                end
                -- Update the local UI to reflect the new role
                playerStatGui.SetRoleUI(roleText)
                -- Request the server to save the updated stats
                saveStatsRequest:FireServer()
            end
        end)

        -- Handle changes in the player's cash
        playerinfo.Cash.Changed:Connect(function(currentCash, oldVal)
            if player == client.localPlayer then
                -- Update the local UI to reflect the new cash value
                playerStatGui.SetCashUI(currentCash)
            end
        end)

        -- Handle changes in the player's work experience
        playerinfo.WorkXP.Changed:Connect(function(currentXP, oldVal)
            if player == client.localPlayer and playerinfo.Role.value == 1 then
                -- Update the local UI to reflect the new work experience value
                playerStatGui.SetXpUI(currentXP)
            end
        end)

        -- Handle changes in the player's customer experience
        playerinfo.CustXP.Changed:Connect(function(currentXP, oldVal)
            if player == client.localPlayer and playerinfo.Role.value == 0 then
                -- Update the local UI to reflect the new customer experience value
                playerStatGui.SetXpUI(currentXP)
            end
        end)
    end

    -- Function to increment a specific stat by a given value
    function IncrementStat(stat, value)
        incrementStatRequest:FireServer(stat, value)
    end

    -- Request the server to send the player's stats
    getStatsRequest:FireServer()

    -- Track players joining and leaving, and handle character instantiation
    TrackPlayers(client, OnCharacterInstantiate)
end

--[[

    Server-side functionality

--]]

-- Function to save a player's stats to persistent storage
local function SaveStats(player)
    -- Create a table to store the player's current stats
    local stats = {Role = 0, Cash = 0, WorkXP = 0, CustXP = 0}
    stats.Role = players[player].Role.value
    stats.Cash = players[player].Cash.value
    stats.WorkXP = players[player].WorkXP.value
    stats.CustXP = players[player].CustXP.value

    -- Save the stats to storage and handle any errors
    Storage.SetPlayerValue(player, "PlayerStats", stats, function(errorCode)
        print(player.name .. " Stats Saved")
    end)
end

-- Function to initialize the server-side logic
function self:ServerAwake()
    -- Track players joining and leaving the game
    TrackPlayers(server) 

    -- Fetch a player's stats from storage when they join
    getStatsRequest:Connect(function(player)
        Storage.GetPlayerValue(player, "PlayerStats", function(stats)
            -- If no existing stats are found, create default stats
            if stats == nil then 
                stats = {Role = 1, Cash = 0, WorkXP = 0, CustXP = 0}
                Storage.SetPlayerValue(player, "PlayerStats", stats) 
            end

            -- Update the player's current networked stats from storage
            players[player].Role.value = stats.Role
            players[player].Cash.value = stats.Cash
            players[player].WorkXP.value = stats.WorkXP
            players[player].CustXP.value = stats.CustXP

            --[[
            -- Uncomment the following lines to print the player's stats to the console for debugging
            for stat, value in pairs(stats) do
                print(player.name .. "'s " .. stat .. ": " .. tostring(value))
            end
            --]]
        end)
    end)

    -- Save the player's stats when requested by the client
    saveStatsRequest:Connect(function(player)
        SaveStats(player)
    end)

    -- Increment a player's stat when requested by the client
    incrementStatRequest:Connect(function(player, stat, value)
        --Override the Role Stat of the player to 'value' with =
        if stat == "Role" then players[player].Role.value = value end

        --Increment the  Cash / WorkXP / CustXp Stat of the player by 'value' with +=
        if stat == "Cash" then players[player].Cash.value += value end
        if stat == "WorkXP" then players[player].WorkXP.value += value end
        if stat == "CustXP" then players[player].CustXP.value += value end
        -- Save the updated stats to storage
        SaveStats(player)
    end)

    -- Change a player's role when requested by the client
    setRoleRequest:Connect(function(player)
        -- Retrieve the current role of the player from the players table.
        local currentRole = players[player].Role.value

        if currentRole == 0 then -- Check if the current role is Customer (0).
            currentRole = 1  -- Change role to Employee (1).

        elseif currentRole == 1 then -- Check if the current role is Employee (1).
            currentRole = 0  -- Change role to Customer (0).

        else -- If the current role is neither Customer (0) nor Employee (1), print an error message.
            print("ERROR: player outside Role bounds")
            return  -- Exit the function to prevent further execution.
        end
        -- Update the player's role
        players[player].Role.value = currentRole
    end)
end
