#if UNITY_EDITOR
using UnityEngine;
using UnityEngine.InputSystem;

/// <summary>
/// Debug script to list all detected input devices and their current state
/// This will help identify what's causing the drift
/// </summary>
public class DebugInputDevices : MonoBehaviour
{
    private void Start()
    {
        Debug.Log("=== LISTING ALL INPUT DEVICES ===");
        
        foreach (var device in InputSystem.devices)
        {
            Debug.Log($"Device: {device.name} | Layout: {device.layout} | Product: {device.description.product} | Enabled: {device.enabled}");
            
            // If it's a joystick or gamepad, show its current state
            if (device is UnityEngine.InputSystem.Joystick joystick)
            {
                Debug.Log($"  → Joystick Stick: {joystick.stick.ReadValue()}");
            }
            else if (device is UnityEngine.InputSystem.Gamepad gamepad)
            {
                Debug.Log($"  → Gamepad LeftStick: {gamepad.leftStick.ReadValue()}");
            }
        }
        
        Debug.Log("=== END OF DEVICE LIST ===");
    }

    private void Update()
    {
        // Check for any active joystick input every frame
        foreach (var device in InputSystem.devices)
        {
            if (device is UnityEngine.InputSystem.Joystick joystick && joystick.enabled)
            {
                var stickValue = joystick.stick.ReadValue();
                if (stickValue.magnitude > 0.01f)
                {
                    Debug.LogWarning($"[DRIFT DETECTED] Device: {device.name} | Stick Value: {stickValue} | Magnitude: {stickValue.magnitude}");
                }
            }
            else if (device is UnityEngine.InputSystem.Gamepad gamepad && gamepad.enabled)
            {
                var leftStick = gamepad.leftStick.ReadValue();
                if (leftStick.magnitude > 0.01f)
                {
                    Debug.LogWarning($"[DRIFT DETECTED] Device: {device.name} | LeftStick: {leftStick} | Magnitude: {leftStick.magnitude}");
                }
            }
        }
    }
}
#endif

