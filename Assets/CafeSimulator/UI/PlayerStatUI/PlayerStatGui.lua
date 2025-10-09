--!Type(UI)

--!Bind
-- Binding the UILabel for displaying the player's current role
local roleTitle : UILabel = nil

--!Bind
-- Binding the UIButton for changing the player's role
local roleButton : UIButton = nil

--!Bind
-- Binding the UILabel for displaying the player's current cash amount
local cashCount : UILabel = nil

--!Bind
-- Binding the UILabel for displaying the player's current experience points
local xpCount : UILabel = nil

-- Importing the PlayerManager module to handle player-related functionalities
local playerManager = require("PlayerManager")

-- Function to set the role title on the UI
function SetRoleUI(role)
    -- Updates the role title text dynamically
    roleTitle:SetPrelocalizedText(role, true)
end

-- Function to set the cash count on the UI
function SetCashUI(cash)
    -- Converts the cash amount to string and updates the UI
    cashCount:SetPrelocalizedText(tostring(cash), true)
end

-- Function to set the experience points on the UI
function SetXpUI(xp)
    -- Converts XP to a formatted string to display progression and updates the UI
    xpCount:SetPrelocalizedText(tostring((xp/100) + 1), true)
end

-- Initialize the UI with default values for role, cash, and XP
SetRoleUI(0)
SetCashUI(0)
SetXpUI(0)

-- Registers a callback for the role button press to change the player's role
roleButton:RegisterPressCallback(function()
    -- Calls the ChangeRole function from the playerManager when the button is pressed
    playerManager.ChangeRole()
end, true, true, true)
