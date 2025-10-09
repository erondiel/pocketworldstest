# Tip Jar 2.0

A modular, production-grade tip jar system for Highrise Studio, allowing users to tip world creators with gold using secure, server-authoritative In-World Purchases (IWP). Includes advanced UI, top tippers, custom messages, and robust event-driven architecture.

## Features

- **Multiple UI Modes:** Drawer and Basic views for tipping and history.
- **Top Tippers Leaderboard:** Tracks and displays the top 50 tippers.
- **Tipping History:** Shows recent tip messages with timestamps.
- **Custom Messages:** High-value tippers can attach a message.
- **Premium Tiers:** Special styling and messaging for large tips.
- **Audio/Visual Feedback:** Optional sound and announcement UI.

## Installation

### 1. Unity Setup

1. **Prefabs:**  
   Drag the prefabs from `Assets/Tip Jar 2.0/Prefabs/` into your scene:
   - `Tip Jar 2.0`

2. **References:**  
   - In the `TipJarManager` inspector, assign:
     - `Tip Jar Announcement` → `TipJarNotify`
     - `Tip Recieved Sound` (optional) → `Art/Sounds/Shaders/TipRecieved.asset`
   - In `TipJarObject`, assign `TipJarUI` to the `Tip Jar UI` field.

4. **Icons:**  
   - Gold bar icons are in `Art/Icons/bars/`.  
   - You can use your own icons by updating the `_GoldBarIcons` array in `TipsMetaData.lua`.

### 2. Creator Portal Setup

1. Go to the [Creator Portal](https://create.highrise.game/dashboard/creations).
2. Select your world and navigate to **In-World Purchases**.
3. Create IWP entries for each gold tier you want to support.

#### Recommended IWP IDs (match these for auto-detection):

| Gold Amount | IWP ID      |
|-------------|-------------|
| 1           | `nugget`    |
| 5           | `5_bar`     |
| 10          | `10_bar`    |
| 50          | `50_bar`    |
| 100         | `100_bar`   |
| 500         | `500_bar`   |
| 1000        | `1000_bar`  |
| 5000        | `5000_bar`  |
| 10000       | `10000_bar` |

- If you use different IDs, update them in `TipsMetaData.lua`.

4. **Enable "List For Sale"** for each IWP.
5. (Optional) Enable "Send payouts to world" to send gold to the world wallet.

## Usage

- **Tipping:**  
  Players tap the tip jar to open the UI, select an amount, and (for premium tiers) can add a custom message.
- **Leaderboard:**  
  The UI displays the top 50 tippers and recent tip messages.
- **Announcements:**  
  Large tips trigger an announcement UI and optional sound.
- **All gold transactions are handled securely on the server.**

## Customization

- **Minimum Announcement Amount:**  
  Set in `TipJarManager` (`MinimumAnnouncementAmount`).
- **Audio Feedback:**  
  Enable/disable and set volume in `TipJarManager`.
- **Custom Messages:**  
  Only enabled for certain gold tiers (see `CustomMessage` in `TipsMetaData.lua`).
- **Premium Styling:**  
  Tiers with `IsPremium = true` get special UI treatment.

## Security & Architecture

- **Client/Server Separation:**  
  - UI and input: Client
  - All gold, leaderboard, and message logic: Server
  - Communication: Events only (see `TipJarUtility.lua`)
- **No client-authoritative logic.**  
- **All purchases are acknowledged and validated server-side.**

## File Structure

- **Prefabs:** `Assets/Tip Jar 2.0/Prefabs/`
- **Scripts:** `Assets/Tip Jar 2.0/Scripts/`
  - `TipJarManager.lua` (core logic, server authority)
  - `TipJarTapper.lua` (tap-to-open UI)
  - `TipJarUtility.lua` (shared events/utilities)
  - `TipsMetaData.lua` (IWP and icon config)
  - `GUI/TipJarBasic/` (basic UI)
  - `GUI/TipJarDrawer/` (drawer UI)
  - `GUI/TipJarNotify/` (announcement UI)
- **Icons:** `Assets/Tip Jar 2.0/Art/Icons/bars/`
- **Sounds:** `Assets/Tip Jar 2.0/Art/Sounds/`

## Extending

- **Add new gold tiers:**  
  Update `TipsMetaData.lua` and add new icons as needed.
- **Change UI:**  
  Edit UXML/USS in `Scripts/GUI/TipJarBasic/` and `Scripts/GUI/TipJarDrawer/`.

## Troubleshooting

- **Tips not showing?**  
  - Check IWP IDs match in both Creator Portal and `TipsMetaData.lua`.
  - Ensure all prefab references are assigned in the Inspector.
- **Leaderboard not updating?**  
  - Only the top 50 tippers are shown.
  - All data is synced via server events.

## Support

- Join the [Highrise Discord](https://discord.gg/highrise) and ask in `#studio-help`.
- See the [official Highrise Studio API docs](https://create.highrise.game/learn/studio-api/globals) for more details.