
---

## Overview

The `SceneTeleporter` asset consists of the following components:

- **SceneSwitcher**: Handles the user interface for teleporting to a new scene.
- **SceneManager**: Handles the loading and storing of all the necessary scenes on the server as well as handling the event to move a player to a new scene.

---

## Steps for Setup

1. In the top navigation bar, navigate to **Highrise > World Settings** and make sure that all your scenes are added to the scene list
2. In your project files create a new `World Variant` Prefab to use in place of your standard `World` Prefab by right clicking and going to **Create > Highrise > World Variant**
3. In the inspector of the new World Variant Prefab, find the `World Prefab (Script)` Component attached to the Prefab and click the **Use This Prefab** button. This will set this World Variant Prefab as the current World Prefab in your Highrise Settings.
4. Again in the inspector, click **Add Component**, and add the `SceneManager` lua script to the Prefab.
5. On this newly added component, add the names of all your scenes into the `Scene Names` dropdown.
6. You are now done setting up the `SceneManager`. Next, we will setup our `SceneTeleporters`
7. In the prefabs folder of this asset, find the `SceneTeleporter` prefab, and drag it into your scene.
8. The `SceneTeleporter` Prefab has 2 components. A `Box Collider` which acts as the trigger to display the teleport button when your player enters into the trigger area, and the `SceneSwitcher UI` UI lua script.
9. Position your `SceneTeleporter` Prefab anywhere in your scene you want the trigger to be placed. You can also resize the Prefab or Box Collider to adjust the size of your trigger as needed for your scene.
10. In the inspector for your newly placed `SceneTeleporter` Prefab, find the `SceneSwitcher (UI)` Component and update the two properties: `Button Icon` which will be the image displayed on the button, and `Scene Name` which will be the name of the scene you want your player to teleport to when they click the button.
11. You are now done setting up a one-way teleporter to a new Scene.
12. Repeat steps 7-11 to create additonal teleporters throughout your scenes.

---

## Support and Contact Information

If you encounter issues or need assistance customising the scripts, feel free to reach out:

- **Highrise**: drewsifer
- **Discord**: drewio