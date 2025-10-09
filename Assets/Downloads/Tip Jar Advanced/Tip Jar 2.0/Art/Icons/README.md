# Tip Jar Basics

This is a simple tip jar that allows people to tip you with their gold currency in the game.

## Installation

### In Unity
1. Drag and drop all the prefabs into your Hierarchy.
2. Drag and drop the `TipJarObject` and place it where you want it to be.
3. Locate TipJarManager and assign the `TipJarNotify` object to the `Tip Jar Announcement` field.
4. Locate TipJarIndicator inside the TipJarObject and assign `TipJarUI` to the `Tip Jar UI` field.
5. Done!

### In Creator Portal

To be able to use the tip jar, you need to create In-World Purchases in the Creator Portal. Here is how you do it:

1. Go to the [Creator Portal](https://create.highrise.game/dashboard/creations).
2. Find the world you want to add the tip jar to and click on it.
3. Navigate to In-World Purchases.
4. Start by creating a new In-World Purchase.

If you want to have the same gold amount that Highrise uses, you can use the following values:

### In-World Purchase IDs
1. 1 gold: `nugget`
2. 5 gold: `5_bar`
3. 10 gold: `10_bar`
4. 50 gold: `50_bar`
5. 100 gold: `100_bar`
6. 500 gold: `500_bar`
7. 1000 gold: `1000_bar`
8. 5000 gold: `5000_bar`
9. 10000 gold: `10000_bar`

If you assign the same IDs to your In-World Purchases, the tip jar will automatically use them.

If you assign different IDs, you can change the IDs in the `TipJarMetaData` script located in the `Scripts` folder.

For the gold icon, it can be found in `Icons` > `bars`. Feel free to use your own icons if you prefer.

## Usage

When you create the IWP, make sure each one has "List For Sale" enabled with the relative price.

If preferred, "Send payouts to world" can be enabled to send the gold directly to the world wallet instead of the creator's wallet.

## Support

If you need help, you can join our [Discord server](https://discord.gg/highrise) and ask in the #studio-help channel.