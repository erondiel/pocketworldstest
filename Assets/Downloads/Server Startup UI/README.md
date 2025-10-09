# Server Startup UI

A dynamic server startup message system for Highrise Studio that displays customizable welcome messages to players when they join your world. The system loads message content from Storage, allowing you to update messages directly from the Creator Portal without redeploying your world.

## 🚀 Quick Start

1. **Drag the `ServerStartup.prefab`** into your scene
2. **Assign the UI reference** in the Inspector (ServerStartupModule component)
3. **Configure your message** in the Creator Portal Storage
4. **Set `live = true`** to activate the message

That's it! Players will see your custom welcome message when they join.

## 🎯 Features

- **Dynamic Content**: Update messages without redeploying your world
- **Storage Integration**: Loads message data from Highrise Storage API
- **Live Toggle**: Enable/disable messages instantly via Creator Portal
- **Modern UI**: Clean, professional interface with smooth animations
- **Customizable**: Edit header, title, and message content
- **Automatic Display**: Shows to all players when they join (if live)

## 🔧 Installation & Configuration

### 1. Unity Setup

1. **Drag the prefab** from `Assets/ServerStartupUI/Prefab/ServerStartup.prefab` into your scene
2. **Assign UI Reference**: In the Inspector, set the `startupUIOBJ` field to the ServerStartupUI GameObject

### 2. Creator Portal Configuration

1. Go to the [Creator Portal](https://create.highrise.game/dashboard/creations)
2. Select your world and navigate to **Storage**

```json
{
    "title": "Welcome to My World!",
    "message": "This is a custom welcome message that players will see when they join. You can update this anytime from the Creator Portal!",
    "header": "Welcome",
    "live": true
}
```

### 3. Message Configuration

| Field | Description | Example |
|-------|-------------|---------|
| `title` | Main title text | "Welcome to My World!" |
| `message` | Detailed message content | "Enjoy your stay and have fun!" |
| `header` | Header text in the UI | "Welcome" |
| `live` | Enable/disable the message | `true` or `false` |

## 🎮 Usage

### For Players
- **Automatic Display**: Message appears automatically when players join (if live)
- **Dismiss**: Click the "OK!" button or close button to dismiss
- **Smooth Animations**: Professional fade-in/out effects

### For Creators
- **Update Messages**: Change content anytime via Creator Portal Storage
- **Toggle On/Off**: Set `live: false` to disable without deleting
- **Real-time Updates**: Changes take effect immediately for new players

## 📋 File Structure

```
Assets/ServerStartupUI/
├── Prefab/
│   └── ServerStartup.prefab (Main prefab)
├── Scripts/
│   ├── ServerStartupModule.lua (Core logic)
│   └── GUI/
│       ├── ServerStartupUI.lua (UI controller)
│       ├── ServerStartupUI.uxml (UI structure)
│       └── ServerStartupUI.uss (UI styling)
└── README.md
```

## 🎨 Customization

### UI Styling
Edit `ServerStartupUI.uss` to customize:
- Colors and typography
- Spacing and layout
- Button styling
- Background effects

### Message Content
Update via Creator Portal Storage:
- Header text
- Title text
- Message content
- Live status

### Timing
Modify the display delay in `ServerStartupModule.lua`:
```lua
Timer.After(0.5, function() -- Change 0.5 to your preferred delay
```

## 🔒 Security & Architecture

- **Server Authority**: All message loading and validation happens server-side
- **Storage Security**: Messages are loaded from secure Highrise Storage
- **Client/Server Separation**: 
  - Server: Loads and validates message data
  - Client: Displays UI and handles user interaction
  - Communication: Events only

## 🚨 Troubleshooting

### Message Not Showing
- Check that `live: true` in Storage
- Verify the `startupUIOBJ` reference is assigned in Inspector
- Ensure the prefab is active in the scene

### Storage Issues
- Verify the storage key is exactly `start_message`
- Check JSON format is valid
- Ensure you have proper permissions in Creator Portal

### UI Not Working
- Check that all UI elements are properly bound in the Lua script
- Verify the prefab hierarchy matches the expected structure
- Ensure the UI GameObject is assigned to the module

## 📝 Example Storage Values

### Welcome Message
```json
{
    "title": "Welcome to Adventure World!",
    "message": "Explore our amazing world filled with quests, friends, and fun activities. Check out the map to get started!",
    "header": "Welcome",
    "live": true
}
```

### Event Announcement
```json
{
    "title": "Special Event This Weekend!",
    "message": "Join us for our weekend celebration with special rewards, exclusive items, and fun mini-games. Don't miss out!",
    "header": "Event",
    "live": true
}
```

### Maintenance Notice
```json
{
    "title": "Scheduled Maintenance",
    "message": "We'll be performing maintenance on Tuesday from 2-4 PM. Please save your progress and check back later.",
    "header": "Notice",
    "live": true
}
```