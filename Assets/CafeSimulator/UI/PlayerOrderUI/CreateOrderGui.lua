--!Type(UI)
-- Specifies that this script manages UI elements.

--!Bind
local Orders_Root : UIScrollView = nil -- Reference to the root UI element for orders.
--!Bind
local closeButton : UIButton = nil -- Reference to the button for closing the UI.
--!Bind
local closeLabel : UILabel = nil -- Reference to the label for the close button.

local orderManager = require("OrderManager") -- Accesses order management functions.
local playerManager = require("PlayerManager") -- Accesses player management functions.

-- Creates a new quest item in the UI.
function CreateQuestItem(Name, XP, Cash)
    -- Create a new button for the quest item.
    local questItem = UIButton.new()
    questItem:AddToClassList("order-item") -- Add a class to style the quest item.

    -- Create a label for the quest item's title and add it to the quest item.
    local _titleLabel = UILabel.new()
    _titleLabel:AddToClassList("title")
    _titleLabel:SetPrelocalizedText("Buy: " .. Name) -- Set the text to display the quest item's name.
    questItem:Add(_titleLabel)

    -- Create a label for the quest item's XP reward and add it to the quest item.
    local _xpLabel = UILabel.new()
    _xpLabel:AddToClassList("title")
    _xpLabel:SetPrelocalizedText(tostring(XP).."xp") -- Set the text to display the XP reward.
    questItem:Add(_xpLabel)

    -- Create a label for the quest item's cash cost and add it to the quest item.
    local _cashLabel = UILabel.new()
    _cashLabel:AddToClassList("title")
    _cashLabel:SetPrelocalizedText("$"..tostring(Cash)) -- Set the text to display the cash cost.
    questItem:Add(_cashLabel)

    -- Add a press callback to the quest item button.
    questItem:RegisterPressCallback(function()
        -- Check if the player is a customer and has enough cash to buy the item.
        if playerManager.players[client.localPlayer].Role.value == 0 and playerManager.GetPlayerCash() >= Cash then
            -- Create the order and deduct the cash from the player's balance.
            orderManager.CreateOrderClient(Name, XP, Cash)
            playerManager.IncrementStat("CustXP", XP) -- Increment customer XP.
            playerManager.IncrementStat("Cash", -Cash) -- Deduct cash from the player.
        end
    end, true, true, true)

    -- Add the quest item to the UI.
    Orders_Root:Add(questItem)

    return questItem
end

-- Sets the visibility of the UI.
function SetVisible(visible)
    Orders_Root:EnableInClassList("hidden", not visible)
end

-- Called when the UI object this script is attached to is initialized.
function self:Awake()
    SetVisible(false) -- Hide the UI initially.
    closeLabel:SetPrelocalizedText("Close", true) -- Set the text of the close button.
    
    -- Add a callback to the close button to hide the UI when pressed.
    closeButton:RegisterPressCallback(function()
        SetVisible(false)
    end, true, true, true)
end

-- Create quest items for the UI.
local EspressoMenuButton = CreateQuestItem("Espresso", 10, 5)
local CookiesMenuButton = CreateQuestItem("Cookies", 20, 25)
