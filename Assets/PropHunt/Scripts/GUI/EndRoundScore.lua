--!Type(UI)

--[[
    EndRoundScore.lua

    Displays the End Round scoring screen showing all players ranked by score.
    Shows a special "WINNER!" overlay only to the winning player.

    FEATURES:
    - Displays all players sorted by score (highest to lowest)
    - Highlights top 3 players (Gold/Silver/Bronze)
    - Shows player rank, name, score, and role
    - Winner-only overlay with celebration message
    - Networked via broadcast event from server

    SETUP:
    1. Attach EndRoundScore.uxml to scene as UIDocument
    2. This script should be attached to the same GameObject
    3. Server broadcasts scores via PH_EndRoundScores event
]]

--!Bind
local _scoreContainer : VisualElement = nil
--!Bind
local _playerList : VisualElement = nil
--!Bind
local _winnerOverlay : VisualElement = nil
--!Bind
local _footerText : Label = nil

local Logger = require("PropHuntLogger")

-- Reference to the actual list container where we add entries
local playerListContainer = nil

-- Network Event
local endRoundScoresEvent = Event.new("PH_EndRoundScores")

-- Register event listener at module load time (not in lifecycle)
Logger.Log("EndRoundScore", "========================================")
Logger.Log("EndRoundScore", "MODULE LOADING")
Logger.Log("EndRoundScore", "========================================")

endRoundScoresEvent:Connect(function(playersData, localPlayerIsWinner)
    Logger.Log("EndRoundScore", "*** EVENT RECEIVED ***")
    Logger.Log("EndRoundScore", "playersData type: " .. type(playersData))
    Logger.Log("EndRoundScore", "localPlayerIsWinner: " .. tostring(localPlayerIsWinner))
    ShowScores(playersData, localPlayerIsWinner)
end)

Logger.Log("EndRoundScore", "Event listener registered for PH_EndRoundScores")

--[[
    UI Initialize
]]
function self:ClientAwake()
    Logger.Log("EndRoundScore", "========================================")
    Logger.Log("EndRoundScore", "CLIENT AWAKE")
    Logger.Log("EndRoundScore", "========================================")

    if not _scoreContainer or not _playerList or not _winnerOverlay then
        Logger.Error("EndRoundScore", "Missing UI elements!")
        Logger.Error("EndRoundScore", "_scoreContainer: " .. tostring(_scoreContainer ~= nil))
        Logger.Error("EndRoundScore", "_playerList: " .. tostring(_playerList ~= nil))
        Logger.Error("EndRoundScore", "_winnerOverlay: " .. tostring(_winnerOverlay ~= nil))
        return
    end

    Logger.Log("EndRoundScore", "All UI elements found successfully")

    -- _playerList is a ScrollView (bound as VisualElement)
    -- We need to access its contentContainer to add entries
    -- Try to get contentContainer if it exists (ScrollView property)
    if _playerList.contentContainer then
        playerListContainer = _playerList.contentContainer
        Logger.Log("EndRoundScore", "Using ScrollView.contentContainer")
    else
        -- Fallback: use _playerList directly if contentContainer doesn't exist
        playerListContainer = _playerList
        Logger.Log("EndRoundScore", "Using _playerList directly (no contentContainer)")
    end

    Logger.Log("EndRoundScore", "playerListContainer: " .. tostring(playerListContainer ~= nil))

    Logger.Log("EndRoundScore", "UI initialized and ready for scores")
end

--[[
    ShowScores: Display the End Round scores
    @param playersData: table - Array of {name, score, role, rank}
    @param localPlayerIsWinner: boolean - Is the local player the winner?
]]
function ShowScores(playersData, localPlayerIsWinner)
    Logger.Log("EndRoundScore", "========================================")
    Logger.Log("EndRoundScore", "SHOWING SCORES")
    Logger.Log("EndRoundScore", "Players: " .. tostring(#playersData))
    Logger.Log("EndRoundScore", "Is Winner: " .. tostring(localPlayerIsWinner))
    Logger.Log("EndRoundScore", "========================================")

    if not playerListContainer then
        Logger.Error("EndRoundScore", "playerListContainer is nil! Cannot display scores.")
        return
    end

    -- Clear existing player entries
    playerListContainer:Clear()
    Logger.Log("EndRoundScore", "Cleared existing entries")

    -- Add each player entry
    for i, playerData in ipairs(playersData) do
        CreatePlayerEntry(playerData)
        Logger.Log("EndRoundScore", string.format("Added entry: Rank %d - %s (%d pts)", playerData.rank, playerData.name, playerData.score))
    end

    -- Show/hide winner overlay
    if localPlayerIsWinner then
        _winnerOverlay:RemoveFromClassList("hidden")
        Logger.Log("EndRoundScore", "Showing WINNER overlay")
    else
        _winnerOverlay:AddToClassList("hidden")
        Logger.Log("EndRoundScore", "Hiding WINNER overlay")
    end

    Logger.Log("EndRoundScore", "Score display complete (visibility handled by UIManager)")
end

--[[
    CreatePlayerEntry: Create a UI entry for a player
    @param playerData: table - {name, score, role, rank}
]]
function CreatePlayerEntry(playerData)
    -- Create container
    local entry = VisualElement.new()
    entry:AddToClassList("player-entry")

    -- Add rank-specific class for top 3
    if playerData.rank == 1 then
        entry:AddToClassList("rank-1")
    elseif playerData.rank == 2 then
        entry:AddToClassList("rank-2")
    elseif playerData.rank == 3 then
        entry:AddToClassList("rank-3")
    end

    -- Rank label
    local rankLabel = Label.new()
    rankLabel:AddToClassList("player-rank")
    rankLabel.text = tostring(playerData.rank)
    entry:Add(rankLabel)

    -- Player name
    local nameLabel = Label.new()
    nameLabel:AddToClassList("player-name")
    nameLabel.text = playerData.name
    entry:Add(nameLabel)

    -- Score
    local scoreLabel = Label.new()
    scoreLabel:AddToClassList("player-score")
    scoreLabel.text = tostring(playerData.score)
    entry:Add(scoreLabel)

    -- Role
    local roleLabel = Label.new()
    roleLabel:AddToClassList("player-role")
    -- Capitalize first letter
    local role = playerData.role
    if role then
        role = role:sub(1,1):upper() .. role:sub(2)
    else
        role = "Unknown"
    end
    roleLabel.text = role
    entry:Add(roleLabel)

    -- Add to list
    playerListContainer:Add(entry)
end
