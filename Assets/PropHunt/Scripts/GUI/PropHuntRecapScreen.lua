--[[
    PropHunt Recap Screen
    Displays round-end results using UI Panels notification system
    Shows winner, scores, team bonuses, and hunter accuracy stats
]]

--!Type(Module)

local Config = require("PropHuntConfig")
local panels = require("panels")

-- Network Events to listen for recap data
local recapEvent = Event.new("PH_RecapScreen")

-- Recap data structure
local currentRecapData = nil
local recapTimer = nil

--[[
    Initialize the recap screen system
]]
function self:ClientAwake()
    print("[PropHuntRecapScreen] Initialized")

    -- Listen for recap screen events from server
    recapEvent:Connect(function(recapData)
        OnRecapDataReceived(recapData)
    end)
end

--[[
    Handle recap data received from server

    Expected recapData structure:
    {
        winner = { name = "PlayerName", id = "userId", score = 150 },
        tieBreaker = "Most tags" or nil,
        winningTeam = "props" or "hunters",
        playerScores = {
            { name = "Player1", score = 150, role = "hunter", stats = {...} },
            { name = "Player2", score = 120, role = "prop", stats = {...} }
        },
        teamBonuses = {
            hunters = 50,
            props = 30
        },
        hunterStats = {
            { name = "Hunter1", hits = 3, misses = 1, accuracy = 0.75 }
        }
    }
]]
function OnRecapDataReceived(recapData)
    currentRecapData = recapData
    ShowRecapScreen(recapData)
end

--[[
    Display the recap screen with all round-end information
]]
function ShowRecapScreen(recapData)
    if not recapData then
        print("[PropHuntRecapScreen] No recap data provided")
        return
    end

    -- Build recap message
    local message = BuildRecapMessage(recapData)

    -- Determine notification type based on winning team
    local notificationType = panels.GetNotificationTypes().SUCCESS
    if recapData.winningTeam == "hunters" then
        notificationType = panels.GetNotificationTypes().INFO
    end

    -- Show notification with auto-dismiss after 10 seconds
    panels.ShowNotification(
        notificationType,
        BuildTitleText(recapData),
        message,
        10 -- Auto-dismiss after 10 seconds
    )

    -- Start manual timer for additional tracking
    if recapTimer then
        recapTimer:Stop()
    end

    recapTimer = Timer.After(10, function()
        print("[PropHuntRecapScreen] Recap screen auto-dismissed")
        currentRecapData = nil
    end)
end

--[[
    Build the title text for the recap screen
]]
function BuildTitleText(recapData)
    local title = "ROUND COMPLETE"

    if recapData.winner then
        title = recapData.winner.name .. " WINS!"
    elseif recapData.winningTeam then
        if recapData.winningTeam == "props" then
            title = "PROPS WIN!"
        else
            title = "HUNTERS WIN!"
        end
    end

    return title
end

--[[
    Build the detailed recap message
]]
function BuildRecapMessage(recapData)
    local lines = {}

    -- Winner announcement with score
    if recapData.winner then
        local winnerLine = string.format("%s - %d points", recapData.winner.name, recapData.winner.score)
        table.insert(lines, winnerLine)

        -- Tie-breaker info if applicable
        if recapData.tieBreaker then
            table.insert(lines, string.format("(Won by: %s)", recapData.tieBreaker))
        end
        table.insert(lines, "")
    end

    -- Team bonuses
    if recapData.teamBonuses then
        table.insert(lines, "=== TEAM BONUSES ===")
        if recapData.winningTeam == "hunters" and recapData.teamBonuses.hunters then
            table.insert(lines, string.format("Hunters: +%d points each", recapData.teamBonuses.hunters))
        elseif recapData.winningTeam == "props" then
            if recapData.teamBonuses.propsSurvived then
                table.insert(lines, string.format("Surviving Props: +%d points", recapData.teamBonuses.propsSurvived))
            end
            if recapData.teamBonuses.propsFound then
                table.insert(lines, string.format("Found Props: +%d points", recapData.teamBonuses.propsFound))
            end
        end
        table.insert(lines, "")
    end

    -- Player scores (sorted highest to lowest)
    if recapData.playerScores and #recapData.playerScores > 0 then
        table.insert(lines, "=== FINAL SCORES ===")
        for i, playerScore in ipairs(recapData.playerScores) do
            local roleIcon = playerScore.role == "hunter" and "🔫" or "📦"
            local scoreLine = string.format("%d. %s %s - %d pts",
                i,
                roleIcon,
                playerScore.name,
                playerScore.score
            )
            table.insert(lines, scoreLine)
        end
        table.insert(lines, "")
    end

    -- Hunter accuracy stats
    if recapData.hunterStats and #recapData.hunterStats > 0 then
        table.insert(lines, "=== HUNTER ACCURACY ===")
        for _, stat in ipairs(recapData.hunterStats) do
            local accuracyPercent = math.floor(stat.accuracy * 100)
            local statsLine = string.format("%s: %d/%d (%d%%)",
                stat.name,
                stat.hits,
                stat.hits + stat.misses,
                accuracyPercent
            )
            table.insert(lines, statsLine)

            -- Show accuracy bonus if applicable
            if stat.accuracyBonus and stat.accuracyBonus > 0 then
                table.insert(lines, string.format("  Bonus: +%d pts", stat.accuracyBonus))
            end
        end
    end

    -- Join all lines with newlines
    return table.concat(lines, "\n")
end

--[[
    Public API: Show recap screen manually
    Can be called from other scripts with custom data
]]
function ShowRecap(winnerData)
    ShowRecapScreen(winnerData)
end

--[[
    Public API: Hide recap screen manually
]]
function HideRecap()
    if recapTimer then
        recapTimer:Stop()
        recapTimer = nil
    end
    currentRecapData = nil
    print("[PropHuntRecapScreen] Recap screen manually hidden")
end

--[[
    Get the current recap data (for debugging or external queries)
]]
function GetCurrentRecapData()
    return currentRecapData
end

--[[
    Cleanup
]]
function self:OnDestroy()
    if recapTimer then
        recapTimer:Stop()
        recapTimer = nil
    end
    currentRecapData = nil
    print("[PropHuntRecapScreen] Cleaned up")
end
