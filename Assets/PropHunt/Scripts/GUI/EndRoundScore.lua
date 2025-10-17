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

--[[
    UI Initialize
]]
function self:Start()
    Logger.Log("EndRoundScore", "========================================")
    Logger.Log("EndRoundScore", "STARTED")
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

    -- Hide the score container by default (will show when ShowScores is called)
    if _scoreContainer then
        _scoreContainer:AddToClassList("hidden")
        Logger.Log("EndRoundScore", "Score container hidden by default")
    end

    -- Access the GLOBAL event object created by GameManager
    local endRoundScoresEvent = _G.PH_EndRoundScoresEvent
    if endRoundScoresEvent then
        Logger.Log("EndRoundScore", "Found global event object")

        -- Register event listener
        endRoundScoresEvent:Connect(function(scoresData, winnerId)
            Logger.Log("EndRoundScore", "========================================")
            Logger.Log("EndRoundScore", "EVENT RECEIVED")
            Logger.Log("EndRoundScore", "Scores count: " .. tostring(#scoresData))
            Logger.Log("EndRoundScore", "Winner ID: " .. tostring(winnerId))
            Logger.Log("EndRoundScore", "========================================")

            -- Determine if local player is winner
            local localPlayer = client.localPlayer
            local isWinner = (localPlayer and winnerId and localPlayer.id == winnerId)

            Logger.Log("EndRoundScore", "Local player: " .. tostring(localPlayer and localPlayer.name or "nil"))
            Logger.Log("EndRoundScore", "Is local player winner: " .. tostring(isWinner))

            -- Display scores
            ShowScores(scoresData, isWinner)
        end)

        Logger.Log("EndRoundScore", "Event listener registered")
    else
        Logger.Error("EndRoundScore", "Global event object not found!")
    end

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

    -- Show the score container
    if _scoreContainer then
        _scoreContainer:RemoveFromClassList("hidden")
        Logger.Log("EndRoundScore", "Score container shown")
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
