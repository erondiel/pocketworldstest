--!Type(UI)

--!Bind
-- Bind the Orders_Root variable to a UIScrollView UI element
local Orders_Root : UIScrollView = nil

-- Table to keep track of created quest items
local QuestItems = {}

-- Function to create a new quest item UI element
function CreateQuestItem(Name, XP, Cash)
    -- Create a new VisualElement for the quest item and add a CSS class
    local questItem = VisualElement.new()
    questItem:AddToClassList("quest-item")

    -- Create and set up the title label with the quest name
    local _titleLabel = UILabel.new()
    _titleLabel:AddToClassList("title")
    _titleLabel:SetPrelocalizedText(Name)
    questItem:Add(_titleLabel)

    -- Create and set up the XP label with the quest XP
    local _xpLabel = UILabel.new()
    _xpLabel:AddToClassList("title")
    _xpLabel:SetPrelocalizedText(tostring(XP).."xp")
    questItem:Add(_xpLabel)

    -- Create and set up the cash label with the quest cash reward
    local _cashLabel = UILabel.new()
    _cashLabel:AddToClassList("title")
    _cashLabel:SetPrelocalizedText("$"..tostring(Cash))
    questItem:Add(_cashLabel)

    -- Add the quest item to the Orders_Root scroll view
    Orders_Root:Add(questItem)
    -- Store the quest item in the QuestItems table
    table.insert(QuestItems, questItem)
    return questItem
end

-- Function to clear the list of quest items
function ClearList()
    -- Iterate through all quest items and remove them from the UI hierarchy
    for i, item in ipairs(QuestItems) do
        item:RemoveFromHierarchy()
    end
    -- Clear the QuestItems table
    QuestItems = {}
end
