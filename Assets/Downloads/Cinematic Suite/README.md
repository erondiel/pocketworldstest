# 🎥 Cinematic Suite for Highrise Studio 🎬
by Drew - DM @Nintendrew on Highrise or Discord for support

---

This developer module is a set of components designed to help you make Cinematic Sequences (a.k.a. cutscenes).

## Example Scene

Check out the Cinematic Suite in action by searching for the "Cinematic Suite Demo World" in the Highrise client, or by following this URL: https://high.rs/world?id=6797d7ee862dff3ada5a40f0

## Overview

The Cinematic Suite consists of 5 distinct and uniquely useful components:
 - CinematicCamera: At the core of the toolset, this script includes behavior for any action you might want to perform during a cutscene (snap camera, move camera, target an object, etc.).
 - CinematicAnchor: Similar to a normal anchor, but for the cinematic camera. Defines a world orientation & field of view to set the camera to.
 - CinematicSequence: A cutscene, or in other words, a collection of cinematic events. Custom inspector allows for intuitive writing and editing of complex cinematic routines.
 - CinematicElements: A modular prefab which can be added to any camera to give it cinematic overlays (i.e. letterboxing, fading in/out, and transition masks/'swipes').
 - CinematicSuiteEvents.lua: An events factory module which allows users to connect their own arbitrary functions to cinematic events.

## Component Descriptions

### CinematicCamera (prefab, drag 1 into scene)
This is the main driving component for cinematic events. The CinematicCamera can be manipulated from code (i.e., ```cineCam.TransitionToAnchor(anchor)```) or it can be driven by a CinematicSequence (recommended).

### CinematicAnchor (prefab, drag multiple into scene)
CinematicAnchors act like cameras in the scene view, and you can move them around just like you would position a camera object. Once in place, an anchor represents a target orientation and field of view that the CinematicCamera can match itself to.

### CinematicSequence (prefab, drag 1 or more into scene & customize)
CinematicSequence is where the magic happens. When a CinematicSequence is selected in the hierarchy, a custom editor will be shown in the inspector panel. Variables are dynamically populated based on the chosen type of each cinematic event, and events can be inserted into and deleted from any index at will. Ambitious builders may choose to delve further into the CinematicEvents themselves, as they are present in the scene hierarchy as child GameObjects positioned underneath the CinematicSequence.

### CinematicElements (nested underneath CinematicCamera by default)
This component includes methods for letterboxing, fading the scene in/out, and swipe transitions/masks. The latter two can be further customized with the "FadeType" and "TransitionMaskType" scriptable objects in the project window (```Create > Highrise > ScriptableObjects > FadeType```, for example). You can fade to any arbitrary color, define a custom animation curve, and even bring in custom graphics for branded transitions.

### CinematicSuiteEvents.lua (attached to CinematicCamera by default)
Finally, the CinematicSuiteEvents component allows builders to link their own custom behaviors to a cinematic event. Simply choose the "Custom" event type, specify a target string (e.g., ```'PlayNiceSound'```), then subscribe to the ```CustomEvents``` event and compare its data against your target string in a custom script:

```
--!Type(Client)
--!SerializeField
--!Tooltip("Custom event string to match the CinematicSequence Custom Event")
local _myCustomEventString : string = "PlayNiceSound"
local events = require("CinematicSuiteEvents")
events.CustomEvents:Connect(function(customString:string)
    if customString == _myCustomEventString then
        PlayNiceSound() -- Do your custom behavior here
    end
end)
```

## Final Thoughts

I hope this asset package is useful to you, and that you're able to build some amazing cutscenes with the toolset! Feel free to reach out on Highrise or Discord if you have any issues. Have fun with it - try to make your own custom transitions, camera movements, and more! Happy building!! 😃🏗️🛠️🚧