--!Type(Module)

-- Event declarations for client-server communication
local GetOrdersEvent = Event.new("GetOrdersEvent")
local GetOrdersRequest = Event.new("GetOrdersRequest")
local CompleteOrderRequest = Event.new("CompleteOrderRequest")
local OrderRewardEvent = Event.new("OrderRewardEvent")
local CreateOrderRequest = Event.new("CreateOrderRequest")

-- Import player manager module
local playerManager = require("PlayerManager")

--[[
    CLIENT
]]

-- Variable to hold the Order GUI component
local OrderGui = nil

-- Function to complete an order on the client side by sending a request to the server
function CompleteOrderClient(orderName)
    CompleteOrderRequest:FireServer(orderName)
end

-- Function to create an order on the client side by sending a request to the server
function CreateOrderClient(Name, XP, Cash)
    CreateOrderRequest:FireServer(Name, XP, Cash)
end

-- Function that initializes the client-side logic
function self:ClientAwake()
    -- Get the PlayerOrderGui component from the game object
    OrderGui = self.gameObject:GetComponent(PlayerOrderGui)

    -- Request the server to send the current orders
    GetOrdersRequest:FireServer()

    -- Connect to the event that receives orders from the server
    GetOrdersEvent:Connect(function(orders)
        -- Clear the current list of orders in the GUI
        OrderGui.ClearList()
        -- Iterate through the orders and create a new quest item in the GUI for each order
        for key, value in ipairs(orders) do
            local newQuest = OrderGui.CreateQuestItem(value[1], value[2], value[3])
        end
    end)

    -- Connect to the event that handles order rewards
    OrderRewardEvent:Connect(function(order)
        -- Increment the player's WorkXP and Cash stats based on the completed order
        playerManager.IncrementStat("WorkXP", order[2])
        playerManager.IncrementStat("Cash", order[3])
    end)
end

--[[
    SERVER
]]

-- Table to hold server-side orders
local ServerOrders = {}

-- Function to create a new order on the server
function CreateServerOrder(Name, XP, Cash)
    -- Create a new order with the given name, XP, and cash rewards
    local newOrder = {Name, XP, Cash}
    -- Add the new order to the ServerOrders table
    table.insert(ServerOrders, newOrder)
    -- Notify all clients about the updated list of orders
    GetOrdersEvent:FireAllClients(ServerOrders)
    -- Print the number of current orders (for debugging)
    print(tostring(#ServerOrders))
end

-- Function to complete an order on the server
function CompleteOrderServer(player, orderName)
    -- Iterate through the list of server orders
    for i, order in ipairs(ServerOrders) do
        print(order[1])
        -- Check if the order name matches the given order name
        if order[1] == orderName then
            -- Remove the order from the ServerOrders table
            table.remove(ServerOrders, i)
            -- Notify all clients about the updated list of orders
            GetOrdersEvent:FireAllClients(ServerOrders)
            -- Send the order rewards to the client who completed the order
            OrderRewardEvent:FireClient(player, order)
            return
        end
    end
end

-- Function that initializes the server-side logic
function self:ServerAwake()
    --[[
    -- Example orders to initialize (commented out)
    CreateServerOrder("Espresso", 10, 5)
    CreateServerOrder("Espresso", 10, 5)
    CreateServerOrder("Espresso", 10, 5)
    CreateServerOrder("Cookies", 20, 25)
    CreateServerOrder("Dishes", 20, 5)
    --]]

    -- Connect to the event that handles order requests from clients
    GetOrdersRequest:Connect(function(player)
        -- Send the current list of orders to the requesting client
        GetOrdersEvent:FireClient(player, ServerOrders)
    end)

    -- Connect to the event that handles order completion requests from clients
    CompleteOrderRequest:Connect(function(player, orderName)
        CompleteOrderServer(player, orderName)
    end)

    -- Connect to the event that handles new order creation requests from clients
    CreateOrderRequest:Connect(function(player, Name, XP, Cash)
        CreateServerOrder(Name, XP, Cash)
    end)
end
