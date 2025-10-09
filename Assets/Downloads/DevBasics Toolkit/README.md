# DevBasics for Highrise Studio

A comprehensive toolkit designed to accelerate Highrise Studio development with ready-to-use modules for common game systems.

## Installation

1. Import the DevBasics asset into your project
2. Drag the `DevBasics` prefab into your scene Hierarchy
3. Configure any serialized fields through the Inspector panel

## Core Modules

DevBasics includes several modules to handle common game development tasks:

### Player Tracking

Automatically tracks players joining and leaving your world, with support for:

- Player currency tracking
- Score/leaderboard integration
- Inventory management

```lua
-- Import the module
local PlayerTracker = require("devx_player_tracker")

-- Access player information
local playerInfo = PlayerTracker.getPlayerInfo(player)
local currency = playerInfo.currency.value
local inventory = playerInfo.inventory.value
```

### Storage Management

Handles persistent data storage for player currency and other values:

```lua
-- Import the module
local StorageManager = require("devx_storage_manager")

-- Increment player currency (client-side)
StorageManager.IncrementPlayerCurrency(50, function(response)
  if response.success then
    print("Currency added successfully")
  end
end)

-- Decrement player currency (client-side)
StorageManager.DecrementPlayerCurrency(25, function(response)
  if response.success then
    print("Currency removed successfully")
  end
end)
```

### Inventory Management

Manages player inventory items with automatic synchronization:

```lua
-- Import the module
local InventoryManager = require("devx_inventory_manager")

-- Give an item to a player (client-side)
InventoryManager.GivePlayerItem(player, {
  id = "item_sword",
  amount = 1
}, nil)

-- Take an item from a player (client-side)
InventoryManager.TakePlayerItem(player, {
  id = "item_sword",
  amount = 1
})
```

### Leaderboard Management

Simplifies working with Highrise leaderboards:

```lua
-- Import the module
local LeaderboardManager = require("devx_leaderboard_manager")

-- Server-side: Increment player score
LeaderboardManager.IncrementPlayerScore(player, 100)

-- Server-side: Update player score
LeaderboardManager.UpdatePlayerScore(player, 500)

-- Client-side: Get top players
LeaderboardManager.GetTopPlayers(10, function(topPlayers)
  for _, player in ipairs(topPlayers) do
    print(player.name .. ": " .. player.score)
  end
end)
```

### Permissions System

Provides a role-based permission system:

```lua
-- Import the module
local PermissionsManager = require("devx_permissions_manager")

-- Check if player has permission (client-side)
PermissionsManager.GetPermission(playerName, "perm_give_currency", function(success, message)
  if success then
    -- Player has permission
  else
    -- Player doesn't have permission
  end
end)

-- Grant permission to player (client-side)
PermissionsManager.GrantPermission(playerName, "perm_give_currency", function(success, message)
  if success then
    print("Permission granted")
  end
end)

-- Remove permission from player (client-side)
PermissionsManager.RemovePermission(playerName, "perm_give_currency", function(success, message)
  if success then
    print("Permission removed")
  end
end)
```

### Payment Processing

Simplifies in-app purchases with Highrise Gold:

```lua
-- Import the module
local Utils = require("devx_utils")

-- Prompt a purchase
Utils.Prompt("devx_currency_100", function(paid)
  if paid then
    print("Purchase successful")
  else
    print("Purchase cancelled or failed")
  end
end)
```

### Wallet Management

Handles Gold transfers securely (server-side only):

```lua
-- Import the module
local WalletManager = require("devx_wallet_manager")

-- Transfer Gold to a player
WalletManager.TransferGold(player, 50, function(success, message)
  if success then
    print("Gold transferred successfully")
  else
    print("Transfer failed: " .. message)
  end
end)

-- Get wallet balance
local wallet = WalletManager.GetWallet()
print("Current Gold: " .. wallet.gold)
```

### UI System

Includes pre-built UI components for common game interfaces:

- Currency display
- Shop interface
- Leaderboard display

```lua
-- Import the module
local UIManager = require("devx_ui_manager")

-- Open the shop UI
UIManager.OpenShop()

-- Open the leaderboard UI
UIManager.OpenLeaderboard()

-- Check if UI is active
local isActive = UIManager.isUIActive("DevX_Shop")
```

### Events System

Centralized event management for client-server communication:

```lua
-- Import the module
local Events = require("devx_events_factory")

-- Get an event
local event = Events.get("PlayerJoined")

-- Fire an event from client to server
event:FireServer(data)

-- Connect to an event
event:Connect(function(player, data)
  -- Handle event
end)
```

### Utility Functions

Provides common utility functions:

```lua
-- Import the module
local Utils = require("devx_utils")

-- Format a number with K/M/B suffixes
local formatted = Utils.FormatNumber(1500000) -- "1.50M"

-- Add commas to a number
local withCommas = Utils.AddCommas(1500000) -- "1,500,000"

-- Format time (seconds to MM:SS or HH:MM:SS)
local timeString = Utils.FormatTime(125) -- "02:05"
```

### Animation System

Includes a powerful tweening system for UI animations:

```lua
-- Import the module
local Tweens = require("devx_tweens")
local Tween = Tweens.Tween
local Easing = Tweens.Easing

-- Create a simple tween
local myTween = Tween:new(
  0,  -- start value
  1,  -- end value
  0.5, -- duration (seconds)
  false, -- loop
  false, -- ping-pong
  Easing.OutQuad, -- easing function
  function(value)
    -- Update something with the value
    element.style.opacity = StyleFloat.new(value)
  end,
  function()
    -- Optional completion callback
    print("Tween complete")
  end
)

-- Start the tween
myTween:start()
```

## Configuration

Most configuration options are available in `devx_config.lua`:

- Currency prefix for products
- Storage keys
- Default permissions
- Event names
- Static inventory items

Additional configuration is available through serialized fields in the Inspector:

- Audio settings
- Currency icons
- Debug options

## Best Practices

1. **Client-Server Separation**: Always respect Highrise's client-server architecture:
   - Client scripts handle UI and input
   - Server scripts handle game logic, rewards, and validation

2. **Event Communication**: Use the Events system for all client-server communication

3. **Permissions**: Use the permissions system to control access to administrative functions

4. **Storage**: Use the Storage Manager for all persistent data

5. **UI Integration**: Use the provided UI components and extend them as needed

## Troubleshooting

- Check the console for error messages
- Verify that the DevBasics prefab is in your scene
- Ensure all required modules are properly imported
- Review the Highrise Studio documentation for API limitations

## Support

If you need help or have questions about using **Dev Basics**, join [Highrise's Official Discord Server](https://discord.gg/Highrise). You can ask for support in the `#studio-chat` or `#studio-help` channels by mentioning **@iHsein**.

Please include as much detail as possible about your issue, including:

- A description of the problem
- Any error messages
- Steps to reproduce the issue
- Screenshots or code snippets (if applicable)

The community and developers are active and happy to assist!


## License

This asset is provided for use in Highrise Studio projects. All rights reserved.
