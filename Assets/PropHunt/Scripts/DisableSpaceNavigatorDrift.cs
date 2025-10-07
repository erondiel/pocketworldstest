#if UNITY_EDITOR
using UnityEngine;
using UnityEngine.InputSystem;

/// <summary>
/// Disables the 3DConnexion SpaceNavigator device (BEEF-46D) from gameplay input
/// while keeping other joysticks/gamepads functional
/// </summary>
[DefaultExecutionOrder(-5000)]
public class DisableSpaceNavigatorDrift : MonoBehaviour
{
    private void Awake()
    {
        // Only disable if component is enabled
        if (enabled)
        {
            // Disable the SpaceNavigator device as early as possible
            DisableSpaceNavigatorDevices();
        }
    }

    private void OnEnable()
    {
        // Also hook into device addition events in case it gets re-added
        InputSystem.onDeviceChange += OnDeviceChange;
    }

    private void OnDisable()
    {
        InputSystem.onDeviceChange -= OnDeviceChange;
        
        // Re-enable SpaceNavigator devices when exiting Play mode
        ReEnableSpaceNavigatorDevices();
    }
    
    private void OnDestroy()
    {
        // Also re-enable on destroy to ensure cleanup
        ReEnableSpaceNavigatorDevices();
    }
    
    private void ReEnableSpaceNavigatorDevices()
    {
        foreach (var device in InputSystem.devices)
        {
            if (IsSpaceNavigatorDevice(device) && !device.enabled)
            {
                InputSystem.EnableDevice(device);
                //Debug.Log($"[SpaceNav Fix] Re-enabled device: {device.name} for editor use");
            }
        }
    }

    private void DisableSpaceNavigatorDevices()
    {
        foreach (var device in InputSystem.devices)
        {
            if (IsSpaceNavigatorDevice(device))
            {
                InputSystem.DisableDevice(device);
                //Debug.Log($"[SpaceNav Fix] Disabled device: {device.name} (Product: {device.description.product})");
            }
        }
    }

    private void OnDeviceChange(InputDevice device, InputDeviceChange change)
    {
        // If a new device is added, check if it's the SpaceNavigator and disable it
        if (change == InputDeviceChange.Added && IsSpaceNavigatorDevice(device))
        {
            InputSystem.DisableDevice(device);
            //Debug.Log($"[SpaceNav Fix] Disabled newly added device: {device.name}");
        }
    }

    private bool IsSpaceNavigatorDevice(InputDevice device)
    {
        // Check multiple identifiers for the SpaceNavigator
        string deviceName = device.name?.ToLower() ?? "";
        string productName = device.description.product?.ToLower() ?? "";
        string manufacturer = device.description.manufacturer?.ToLower() ?? "";

        return deviceName.Contains("beef") ||  // BEEF-46D identifier
               deviceName.Contains("46d") ||
               productName.Contains("3dconnexion") ||
               productName.Contains("spacemouse") ||
               productName.Contains("spacenavigator") ||
               manufacturer.Contains("3dconnexion");
    }
}
#endif

