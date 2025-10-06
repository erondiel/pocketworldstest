#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

/// <summary>
/// Workaround to force SpaceNavigator window to open in Highrise environment
/// </summary>
public class ForceSpaceNavigator : EditorWindow
{
    [MenuItem("Tools/Force Open SpaceNavigator")]
    public static void ForceOpenSpaceNavigatorWindow()
    {
        // Try to get the SpaceNavigator window type
        var spaceNavType = System.Type.GetType("SpaceNavigatorDriver.SpaceNavigatorWindow, PatHightree.SpaceNavigatorDriver.Editor");
        
        if (spaceNavType != null)
        {
            var window = EditorWindow.GetWindow(spaceNavType);
            window.Show();
            Debug.Log("SpaceNavigator window opened successfully!");
        }
        else
        {
            Debug.LogError("SpaceNavigatorWindow type not found. Package may not be properly loaded.");
        }
    }
}
#endif

