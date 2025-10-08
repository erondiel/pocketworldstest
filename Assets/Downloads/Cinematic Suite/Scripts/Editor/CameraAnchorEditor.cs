using Highrise.Lua.Generated;
using Highrise.Studio;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(CameraAnchor))]
[CanEditMultipleObjects]
public class CameraAnchorEditor : LuaThunkEditor
{
    private const float FrustumLength = 5.0f; // Length of the frustum
    private const float Padding = 15f; // Padding for the preview
    private const float BorderThickness = 4f; // Border size around the preview
    private const float PreviewSize = 250f; // Set the size of the camera preview in px (height)
    private const string IconPath = "Packages/com.pz.studio/Assets/Sprites/Icons/icon_camera.png"; // Icon path
    private static readonly Color FrustumColor = Color.green; // Green frustum
    private static readonly Color NonSelectedColor = new Color(1f, 1f, 1f, .15f);
    private static readonly Color BorderColor = Color.black; // Black border for preview

    [DrawGizmo(GizmoType.Pickable | GizmoType.NonSelected | GizmoType.Selected)]
    private static void DrawCameraAnchorGizmo(CameraAnchor cameraAnchor, GizmoType gizmoType)
    {
        Transform transform = cameraAnchor.transform;
        float fov = (float)cameraAnchor._fieldOfView;
        Gizmos.color = (gizmoType & GizmoType.Selected) != 0 ? FrustumColor : NonSelectedColor;
        DrawFrustum(transform.position, transform.rotation, fov, FrustumLength);
    }

    private static void DrawFrustum(Vector3 position, Quaternion rotation, float fov, float length)
    {
        float halfFovRad = Mathf.Deg2Rad * fov * 0.5f;
        float height = Mathf.Tan(halfFovRad) * length;
        float width = height * Camera.main.aspect;

        // Define frustum corners
        Vector3 forward = rotation * Vector3.forward * length;
        Vector3 up = rotation * Vector3.up * height;
        Vector3 right = rotation * Vector3.right * width;

        Vector3 topLeft = position + forward - right + up;
        Vector3 topRight = position + forward + right + up;
        Vector3 bottomLeft = position + forward - right - up;
        Vector3 bottomRight = position + forward + right - up;

        // Draw frustum lines
        Gizmos.DrawLine(position, topLeft);
        Gizmos.DrawLine(position, topRight);
        Gizmos.DrawLine(position, bottomLeft);
        Gizmos.DrawLine(position, bottomRight);
        Gizmos.DrawLine(topLeft, topRight);
        Gizmos.DrawLine(topRight, bottomRight);
        Gizmos.DrawLine(bottomRight, bottomLeft);
        Gizmos.DrawLine(bottomLeft, topLeft);
    }

    private void OnSceneGUI()
    {
        CameraAnchor cameraAnchor = (CameraAnchor)target;
        Transform anchorTransform = cameraAnchor.transform;

        float fov = (float)cameraAnchor._fieldOfView;

        // Render the PIP overlay
        Handles.BeginGUI();

        // Get the main camera's aspect ratio
        Camera mainCamera = Camera.main;
        if (mainCamera == null)
        {
            Debug.LogWarning("MainCamera is missing. Please tag a camera as 'MainCamera'.");
            return;
        }

        // Save the current main camera's position and rotation
        Vector3 originalPosition = mainCamera.transform.position;
        Quaternion originalRotation = mainCamera.transform.rotation;
        float originalFOV = mainCamera.fieldOfView;

        try
        {
            // Temporarily adjust the main camera position for preview rendering
            mainCamera.transform.position = anchorTransform.position + anchorTransform.forward * 0.01f; // Move slightly to avoid frustum rendering
            mainCamera.transform.rotation = anchorTransform.rotation;
            mainCamera.fieldOfView = fov;

            // Get aspect ratio for preview calculation
            float aspectRatio = mainCamera.aspect;
            float previewHeight = PreviewSize;
            float previewWidth = previewHeight * aspectRatio; // Adjust width based on scaled height

            // Calculate border size
            float borderWidth = previewWidth + BorderThickness * 2;
            float borderHeight = previewHeight + BorderThickness * 2;

            // Position the PIP overlay at the bottom-left corner with padding
            float xPos = Padding;
            float yPos = SceneView.lastActiveSceneView.position.height - borderHeight - Padding - 20f; // Magic number because the scene view's height is too low for some reason

            // Draw black border
            GUILayout.BeginArea(new Rect(xPos - BorderThickness, yPos - BorderThickness, borderWidth, borderHeight));
            GUI.color = BorderColor;
            GUI.Box(new Rect(0, 0, borderWidth, borderHeight), GUIContent.none);
            GUILayout.EndArea();

            // Draw the fake camera preview
            GUILayout.BeginArea(new Rect(xPos, yPos, previewWidth, previewHeight));
            GUI.color = Color.white;
            RenderFakeCameraPreview(anchorTransform, fov, previewWidth, previewHeight);
            GUILayout.EndArea();
        }
        finally
        {
            // Restore the original main camera's position and rotation after rendering the preview
            mainCamera.transform.position = originalPosition;
            mainCamera.transform.rotation = originalRotation;
            mainCamera.fieldOfView = originalFOV;
        }

        Handles.EndGUI();
    }

    private void RenderFakeCameraPreview(Transform anchorTransform, float fov, float width, float height)
    {
        // Set up a temporary camera for rendering
        Camera tempCamera = Camera.main;
        if (tempCamera == null) return;

        tempCamera.transform.position = anchorTransform.position + anchorTransform.forward * 0.01f; // Move forward slightly to avoid frustum rendering
        tempCamera.transform.rotation = anchorTransform.rotation;
        tempCamera.fieldOfView = fov;

        // Save current RenderTexture
        RenderTexture currentRT = RenderTexture.active;

        // Create a temporary RenderTexture
        RenderTexture tempRT = RenderTexture.GetTemporary((int)width, (int)height, 16);
        tempCamera.targetTexture = tempRT;

        // Render the camera's view
        tempCamera.Render();

        // Draw the RenderTexture on the GUI
        GUI.DrawTexture(new Rect(0, 0, width, height), tempRT, ScaleMode.StretchToFill);

        // Cleanup
        tempCamera.targetTexture = null;
        RenderTexture.active = currentRT;
        RenderTexture.ReleaseTemporary(tempRT);
    }
}
