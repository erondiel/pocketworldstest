--[[
    ValidationTest.lua
    Quick validation script to test that all PropHunt modules load correctly
    Attach to a GameObject in the scene to run validation on start
]]

--!Type(Server)

-- Import all modules to test they load without errors
local Config = require("PropHuntConfig")
local PlayerManager = require("PropHuntPlayerManager")
local ScoringSystem = require("PropHuntScoringSystem")
local Teleporter = require("PropHuntTeleporter")
local ZoneManager = require("ZoneManager")
local VFXManager = require("PropHuntVFXManager")
local GameManager = require("PropHuntGameManager")

local function Log(msg)
    print("[ValidationTest] " .. tostring(msg))
end

function self:ServerStart()
    Log("=================================================")
    Log("PropHunt V1 Integration Validation Test")
    Log("=================================================")

    local allPassed = true

    -- Test 1: Config Module
    Log("\n[TEST 1] PropHuntConfig Module")
    local success1, result1 = pcall(function()
        local hideTime = Config.GetHidePhaseTime()
        local huntTime = Config.GetHuntPhaseTime()
        local tagRange = Config.GetTagRange()
        local tagCooldown = Config.GetTagCooldown()

        assert(hideTime == 35, "Hide time should be 35s")
        assert(huntTime == 240, "Hunt time should be 240s")
        assert(tagRange == 4.0, "Tag range should be 4.0m")
        assert(tagCooldown == 0.5, "Tag cooldown should be 0.5s")

        Log("✓ Config values: Hide=" .. hideTime .. "s, Hunt=" .. huntTime .. "s, TagRange=" .. tagRange .. "m, Cooldown=" .. tagCooldown .. "s")
    end)

    if not success1 then
        Log("✗ Config test failed: " .. tostring(result1))
        allPassed = false
    end

    -- Test 2: Scoring System
    Log("\n[TEST 2] Scoring System Module")
    local success2, result2 = pcall(function()
        -- Note: Using player IDs as strings since we don't have real Player objects in this test
        ScoringSystem.InitializePlayer("test_player_1")
        ScoringSystem.InitializePlayer("test_player_2")

        -- Test zone-based scoring
        ScoringSystem.AwardPropTick("test_player_1", 1.5) -- NearSpawn
        ScoringSystem.AwardPropTick("test_player_2", 0.6) -- Far

        -- Test hunter scoring
        ScoringSystem.AwardHunterTag("test_player_1", 1.0) -- Mid zone
        ScoringSystem.TrackHunterHit("test_player_1")

        ScoringSystem.ApplyMissPenalty("test_player_1")
        ScoringSystem.TrackHunterMiss("test_player_1")

        -- GetPlayerScore expects a Player object, which we don't have in tests
        -- Just verify the functions exist and can be called
        Log("✓ Scoring functions called successfully")

        -- Cleanup
        ScoringSystem.ResetAllScores()
    end)

    if not success2 then
        Log("✗ Scoring test failed: " .. tostring(result2))
        allPassed = false
    end

    -- Test 3: Zone Manager
    Log("\n[TEST 3] Zone Manager Module")
    local success3, result3 = pcall(function()
        -- Test zone weight by name (doesn't require player object)
        local nearSpawnWeight = ZoneManager.GetZoneWeightByName("NearSpawn")
        local midWeight = ZoneManager.GetZoneWeightByName("Mid")
        local farWeight = ZoneManager.GetZoneWeightByName("Far")

        assert(nearSpawnWeight == 1.5, "NearSpawn weight should be 1.5")
        assert(midWeight == 1.0, "Mid weight should be 1.0")
        assert(farWeight == 0.6, "Far weight should be 0.6")

        Log("✓ ZoneManager loaded. Weights: Near=1.5, Mid=1.0, Far=0.6")

        ZoneManager.ClearAllPlayerZones()
    end)

    if not success3 then
        Log("✗ ZoneManager test failed: " .. tostring(result3))
        allPassed = false
    end

    -- Test 4: Teleporter
    Log("\n[TEST 4] Teleporter Module")
    local success4, result4 = pcall(function()
        local lobbyScene = Teleporter.GetLobbySceneName()
        local arenaScene = Teleporter.GetArenaSceneName()

        Log("✓ Teleporter loaded. Lobby=" .. lobbyScene .. ", Arena=" .. arenaScene)
    end)

    if not success4 then
        Log("✗ Teleporter test failed: " .. tostring(result4))
        allPassed = false
    end

    -- Test 5: VFX Manager
    Log("\n[TEST 5] VFX Manager Module")
    local success5, result5 = pcall(function()
        -- Test that VFX functions exist (won't execute without game objects)
        assert(VFXManager.PlayerVanishVFX ~= nil, "PlayerVanishVFX should exist")
        assert(VFXManager.PropInfillVFX ~= nil, "PropInfillVFX should exist")
        assert(VFXManager.TagHitVFX ~= nil, "TagHitVFX should exist")
        assert(VFXManager.TagMissVFX ~= nil, "TagMissVFX should exist")
        assert(VFXManager.RejectionVFX ~= nil, "RejectionVFX should exist")

        Log("✓ VFXManager loaded. All placeholder VFX functions present")
    end)

    if not success5 then
        Log("✗ VFXManager test failed: " .. tostring(result5))
        allPassed = false
    end

    -- Test 6: Game Manager
    Log("\n[TEST 6] Game Manager Module")
    local success6, result6 = pcall(function()
        local currentState = GameManager.GetCurrentState()
        local stateTimer = GameManager.GetStateTimer()

        Log("✓ GameManager loaded. Current state=" .. currentState .. ", Timer=" .. stateTimer)
    end)

    if not success6 then
        Log("✗ GameManager test failed: " .. tostring(result6))
        allPassed = false
    end

    -- Final Results
    Log("\n=================================================")
    if allPassed then
        Log("✓✓✓ ALL TESTS PASSED! ✓✓✓")
        Log("PropHunt V1 integration is working correctly!")
        Log("Ready for Unity scene setup and gameplay testing")
    else
        Log("✗✗✗ SOME TESTS FAILED ✗✗✗")
        Log("Check the console output above for details")
    end
    Log("=================================================\n")
end
