--!Type(Module)

-- Add more player info here
type PlayerInfo = {
    player: Player,
    currency: IntValue,
    score: IntValue,
    inventory: TableValue
}

local playerCount : number = 0
local players : { [Player]: PlayerInfo } = {}

--[[
  track: Tracks the players and their info.
  @param game: The game to track the players in.
  @param characterCallback: A callback that is called when the character of a player changes.
]]
function track(game, characterCallback: (playerInfo: PlayerInfo) -> () | nil)
    game.PlayerConnected:Connect(function(player: Player)
        playerCount = playerCount + 1

        players[player] = {
            player = player,
            currency = IntValue.new("Currency" .. player.user.id, 0, player),
            score = IntValue.new("Score" .. player.user.id, 0, player),
            inventory = TableValue.new("Inventory" .. player.user.id, {}, player)
        }

        player.CharacterChanged:Connect(function(_, character)
            local playerInfo = players[player]
            if not character then return end

            if characterCallback then
                characterCallback(playerInfo)
            end
        end)
    end)

    game.PlayerDisconnected:Connect(function(player: Player)
        playerCount = playerCount - 1
        players[player] = nil
    end)
end

--[[
  getPlayerInfo: Returns the info of a player.
  @param player: The player to get the info of.
  @return { PlayerInfo }
]]
function getPlayerInfo(player): PlayerInfo
    return players[player]
end

--[[
  getPlayerCount: Returns the number of players.
  @return { number }
]]
function getPlayerCount(): number
    return playerCount
end

--[[
  getPlayers: Returns all players.
  @return { { [Player]: PlayerInfo } }
]]
function getPlayers(): { [Player]: PlayerInfo }
    return players
end

--[[
  getPlayerInventory: Returns the inventory of a player.
  @param player: The player to get the inventory of.
  @return { TableValue }
]]
function getPlayerInventory(player: Player): TableValue
    return players[player].inventory
end

--[[
  getPlayerScore: Returns the score of a player.
  @param player: The player to get the score of.
  @return { IntValue }
]]
function getPlayerScore(player: Player): IntValue
    return players[player].score
end

--[[
  getPlayerCurrency: Returns the currency of a player.
  @param player: The player to get the currency of.
  @return { IntValue }
]]
function getPlayerCurrency(player: Player): IntValue
    return players[player].currency
end