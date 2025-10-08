using Highrise.Lua.Generated;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(CinematicSequence))]
[CanEditMultipleObjects]
public class CinematicSequenceEditor : Editor
{
    private CinematicSequence _cinematicSequence;
    private SerializedProperty _defaultTransitionType;
    private SerializedProperty _defaultMaskType;
    private SerializedProperty _defaultFadeType;

    private GUIStyle customStyle1;
    private GUIStyle customStyle2;
    private GUIStyle headerStyle;
    private GUIStyle bold;
    private GUIStyle italic;

    private Font font1;
    private Font font2;

    private List<bool> foldoutStates;

    private void OnEnable()
    {
        _cinematicSequence = (CinematicSequence)target;
    }

    private bool AddEventButton(int index, string label = "+ Insert New Event")
    {
        if (EditorApplication.isPlaying) { return false; }
        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        GUI.color = Color.green;
        if (GUILayout.Button(label, GUILayout.Width(140)))
        {

            for (int i = index; i < _cinematicSequence.transform.childCount; i++)
            {
                _cinematicSequence.transform.GetChild(i).name = $"Event {i + 2:000}";
            }
            GameObject newEvent = new GameObject($"Event {index+1:000}");
            newEvent.transform.SetParent(_cinematicSequence.transform);
            newEvent.transform.SetSiblingIndex(index);
            var c = newEvent.AddComponent<CinematicEvent>();
            c._transitionType = _defaultTransitionType.objectReferenceValue;
            c._maskType = _defaultMaskType.objectReferenceValue;
            c._fadeType = _defaultFadeType.objectReferenceValue;

            foldoutStates.Insert(index, true);

            GUI.color = Color.white;
            EditorGUILayout.EndHorizontal();
            return true;
        }
        GUI.color = Color.white;
        EditorGUILayout.EndHorizontal();
        return false;
    }

    private bool DeleteButton(int index)
    {
        if (EditorApplication.isPlaying) { return false; }
        GUI.color = Color.red;
        if (GUILayout.Button("✕", GUILayout.Width(38)))
        {
            for (int i = index; i < _cinematicSequence.transform.childCount; i++)
            {
                _cinematicSequence.transform.GetChild(index).name = $"Event {i - 1:000}";
            }
            DestroyImmediate(_cinematicSequence.transform.GetChild(index).gameObject);
            foldoutStates.RemoveAt(index);
            return true;
        }
        GUI.color = Color.white;
        return false;
    }

    private void Underline()
    {
        Rect labelRect = GUILayoutUtility.GetLastRect();
        Handles.color = GUI.color;
        Handles.DrawLine(new Vector2(labelRect.xMin, labelRect.yMax), new Vector2(labelRect.xMax, labelRect.yMax));
    }

    private void InitializeGUI()
    {
        if (font1 == null)
            font1 = (Font)AssetDatabase.LoadAssetAtPath("Packages/com.pz.studio/Assets/Fonts/MuseoSansRounded-900.otf", typeof(Font));
        if (font2 == null)
            font2 = (Font)AssetDatabase.LoadAssetAtPath("Packages/com.pz.studio/Assets/Fonts/MuseoSansRounded-500.otf", typeof(Font));

        if (customStyle1 == null)
            customStyle1 = new GUIStyle(EditorStyles.label)
            {
                font = font1,
                fontSize = 18,
                alignment = TextAnchor.MiddleCenter
            };

        if (customStyle2 == null)
            customStyle2 = new GUIStyle(EditorStyles.label)
            {
                font = font2,
                fontSize = 14
            };

        headerStyle = new GUIStyle(GUI.skin.label) { alignment = TextAnchor.MiddleCenter, fontSize = 18 };
        bold = new GUIStyle(GUI.skin.label) { fontStyle = FontStyle.Bold };
        italic = new GUIStyle(GUI.skin.label) { fontStyle = FontStyle.Italic, alignment = TextAnchor.MiddleCenter };

        if (foldoutStates == null)
        {
            foldoutStates = new List<bool> { };
            for(int i = 0; i < _cinematicSequence.transform.childCount; i++)
            {
                foldoutStates.Add(false);
            }
        }
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        InitializeGUI();

        // Header
        DrawUILine(Color.black); EditorGUILayout.Space();
        EditorGUILayout.LabelField("Cutscene Editor (Cinematic Suite)", customStyle1, GUILayout.ExpandWidth(true));
        EditorGUILayout.Space(); Underline(); EditorGUILayout.Space();
        EditorGUILayout.LabelField("DM @Nintendrew on Highrise for support", italic, GUILayout.ExpandWidth(true));
        EditorGUILayout.Space(); DrawUILine(Color.black); EditorGUILayout.Space();

        SerializedProperty targetCamProperty = serializedObject.FindProperty("_targetCamera");
        CinematicCamera targetCam = EditorGUILayout.ObjectField(
            "Target Camera",
            targetCamProperty.objectReferenceValue,
            typeof(CinematicCamera),
            true
            ) as CinematicCamera;
        if (targetCam != null)
            targetCamProperty.objectReferenceValue = targetCam.gameObject;

        // Play on Enable Toggle
        SerializedProperty playOnEnable = serializedObject.FindProperty("_playOnEnable");
        EditorGUILayout.PropertyField(playOnEnable, new GUIContent("Play On Enable"));

        // Allow Player Input Toggle
        SerializedProperty allowPlayerInput = serializedObject.FindProperty("_allowPlayerInput");
        EditorGUILayout.PropertyField(allowPlayerInput, new GUIContent("Allow Player Input"));

        _defaultTransitionType = serializedObject.FindProperty("_defaultTransitionType");
        _defaultMaskType = serializedObject.FindProperty("_defaultMaskType");
        _defaultFadeType = serializedObject.FindProperty("_defaultFadeType");

        EditorGUILayout.Space();
        DrawUILine(Color.black);
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();

        GUILayout.FlexibleSpace();

        bool collapse = GUILayout.Button("Collapse All", GUILayout.Width(140));
        bool expand = GUILayout.Button("Expand All", GUILayout.Width(140));

        GUILayout.FlexibleSpace();

        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Space();
        DrawUILine(Color.black);

        for (int i = 0; i < _cinematicSequence.transform.childCount; i++)
        {
            Transform eventTransform = _cinematicSequence.transform.GetChild(i);
            eventTransform.name = $"Event {i + 1:000}";
            CinematicEvent cinematicEvent = eventTransform.GetComponent<CinematicEvent>();

            if (cinematicEvent != null)
            {

                SerializedObject eventSerializedObject = new SerializedObject(cinematicEvent);
                eventSerializedObject.Update();

                EditorGUILayout.BeginHorizontal();

                string eventString = "[Step " + (i + 1) + "]";

                bool expandFoldout = expand || (!collapse && EditorGUILayout.Foldout(foldoutStates[i], eventString, true));
                foldoutStates[i] = expandFoldout;

                GUILayout.Space(10);
                bool warning = NeedsTarget((CinematicEventType)cinematicEvent._eventType) && cinematicEvent._target == null;
                if (warning)
                    GUI.color = EditorApplication.isPlaying ? Color.red : Color.yellow;
                GUILayout.Label(FriendlyName(eventSerializedObject) + (warning ? " [warning]" : string.Empty), customStyle2); Underline();
                GUI.color = Color.white;
                GUILayout.FlexibleSpace();

                if (expandFoldout)
                {
                    if (DeleteButton(i)) { return; }
                    EditorGUILayout.EndHorizontal();
                    GUILayout.Space(10);

                    //EditorGUILayout.LabelField("Event #" + (i + 1) + " - " + FriendlyName(eventSerializedObject), EditorStyles.boldLabel);

                    // Display and edit properties of the CinematicEvent
                    EditorGUILayout.BeginVertical("box");

                    SerializedProperty eventType = eventSerializedObject.FindProperty("_eventType");
                    // Fetch the current enum value from the SerializedProperty
                    CinematicEventType selectedEventType = (CinematicEventType)eventType.floatValue;

                    // Use EnumPopup to display and select the new event type
                    selectedEventType = (CinematicEventType)EditorGUILayout.EnumPopup("Event Type", selectedEventType);

                    // Set the new value back as an integer, but before setting, explicitly cast the enum to a float
                    eventType.floatValue = (float)selectedEventType;

                    CinematicEventType currentEvent = (CinematicEventType)eventType.floatValue;

                    switch (currentEvent)
                    {
                        default:
                        case CinematicEventType.WAIT:
                            EditorGUILayout.PropertyField(eventSerializedObject.FindProperty("_duration"), new GUIContent("Wait Time (Seconds)"));
                            break;
                        case CinematicEventType.CAMERA_SNAP:
                        case CinematicEventType.CAMERA_TRANSITION:
                            // Get the SerializedProperty for the GameObject target
                            SerializedProperty targetProperty = eventSerializedObject.FindProperty("_target");

                            // Extract the current CameraAnchor if the target is set
                            CameraAnchor currentAnchor = targetProperty.objectReferenceValue != null
                                ? (targetProperty.objectReferenceValue as GameObject)?.GetComponent<CameraAnchor>()
                                : null;

                            // Track changes to the CameraAnchor field
                            EditorGUI.BeginChangeCheck();
                            CameraAnchor newAnchor = EditorGUILayout.ObjectField(
                                "New Anchor",
                                currentAnchor,
                                typeof(CameraAnchor),
                                true
                            ) as CameraAnchor;

                            if (EditorGUI.EndChangeCheck())
                            {
                                // Update the target GameObject based on the selected CameraAnchor
                                targetProperty.objectReferenceValue = newAnchor != null ? newAnchor.gameObject : null;
                            }

                            // Handle additional fields for non-CAMERA_SNAP event types
                            if (currentEvent != CinematicEventType.CAMERA_SNAP)
                            {
                                EditorGUILayout.PropertyField(eventSerializedObject.FindProperty("_transitionType"));
                                EditorGUILayout.PropertyField(eventSerializedObject.FindProperty("_duration"));
                                EditorGUILayout.PropertyField(eventSerializedObject.FindProperty("_waitForFinish"), new GUIContent("Wait For Finish?"));
                            }

                            // Check for missing anchor and warn
                            if (targetProperty.objectReferenceValue == null)
                            {
                                Warn("Event is missing a Camera Anchor!");
                            }

                            // Apply changes to the serialized object
                            eventSerializedObject.ApplyModifiedProperties();

                            break;
                        case CinematicEventType.CAMERA_TARGET:
                            EditorGUI.BeginChangeCheck();
                            Transform t = EditorGUILayout.ObjectField(
                                "Camera Target",
                                cinematicEvent._target,
                                typeof(Transform),
                                true
                            ) as Transform;
                            if (t != null)
                                cinematicEvent._target = t.gameObject;
                            else if (EditorGUI.EndChangeCheck())
                            {
                                cinematicEvent._target = null;
                            }
                            EditorGUILayout.PropertyField(eventSerializedObject.FindProperty("_duration"));
                            break;
                        case CinematicEventType.FADE_OUT:
                        case CinematicEventType.FADE_IN:
                            if(currentEvent == CinematicEventType.FADE_OUT)
                                EditorGUILayout.PropertyField(eventSerializedObject.FindProperty("_fadeType"));
                            EditorGUILayout.PropertyField(eventSerializedObject.FindProperty("_duration"));
                            EditorGUILayout.PropertyField(eventSerializedObject.FindProperty("_waitForFinish"));
                            break;
                        case CinematicEventType.LETTERBOX:
                            EditorGUILayout.PropertyField(eventSerializedObject.FindProperty("_show"), new GUIContent("Show?"));
                            EditorGUILayout.PropertyField(eventSerializedObject.FindProperty("_waitForFinish"), new GUIContent("Wait For Finish?"));
                            break;
                        case CinematicEventType.TRANSITION_MASK:
                            SerializedProperty showProperty = eventSerializedObject.FindProperty("_show");
                            EditorGUILayout.PropertyField(showProperty, new GUIContent("Show?"));
                            bool show = showProperty.boolValue;
                            if (show)
                                EditorGUILayout.PropertyField(eventSerializedObject.FindProperty("_maskType"));
                            else
                                eventSerializedObject.FindProperty("_maskType").objectReferenceValue = null;
                            EditorGUILayout.PropertyField(eventSerializedObject.FindProperty("_waitForFinish"), new GUIContent("Wait For Finish?"));
                            break;
                        case CinematicEventType.CUSTOM:
                            EditorGUILayout.PropertyField(eventSerializedObject.FindProperty("_customEvent"), new GUIContent("Custom Event String"));
                            break;
                    }

                    eventSerializedObject.ApplyModifiedProperties();
                    EditorGUILayout.EndVertical();
                    GUILayout.Space(10);

                    if (i < _cinematicSequence.transform.childCount - 1)
                    {
                        if (AddEventButton(i + 1)) { return; }
                        EditorGUILayout.Space();
                    }
                }
                else
                {
                    GUILayout.Space(42); // The ultimate answer
                    EditorGUILayout.EndHorizontal();
                    EditorGUILayout.Space();
                }

                DrawUILine(Color.black);
            }
        }

        if (AddEventButton(_cinematicSequence.transform.childCount, "+ Add New Event")) { return; };

        serializedObject.ApplyModifiedProperties();
    }

    private static void DrawUILine(Color color, int thickness = 1, int padding = 10)
    {
        Rect r = EditorGUILayout.GetControlRect(GUILayout.Height(padding + thickness));
        r.height = thickness;
        r.y += padding / 2;
        r.x -= 22;
        r.width += 16;
        EditorGUI.DrawRect(r, color);
    }

    private static void Warn(string message)
    {
        EditorGUILayout.HelpBox(message, MessageType.Warning);
    }

    private static string FriendlyName(SerializedObject eventObject)
    {
        Object targetObject = eventObject.FindProperty("_target").objectReferenceValue;
        string targetName = "Target";
        if (targetObject) { targetName = targetObject.name; }
        float duration = eventObject.FindProperty("_duration").floatValue;
        bool show = eventObject.FindProperty("_show").boolValue;
        string showString = show ? "Show" : "Hide";

        switch ((CinematicEventType)eventObject.FindProperty("_eventType").floatValue)
        {
            case CinematicEventType.WAIT:
                return "Wait for " + duration + " Second"+ (duration != 1 ? "s" : string.Empty);
            case CinematicEventType.CAMERA_SNAP:
                return "Snap Camera to "+ targetName;
            case CinematicEventType.CAMERA_TRANSITION:
                string transitionString = "Move Camera to " + targetName;
                Object transitionObject = eventObject.FindProperty("_transitionType").objectReferenceValue;
                if (transitionObject != null)
                {
                    transitionString = transitionString + " (" + transitionObject.name + ")";
                }
                return transitionString;
            case CinematicEventType.CAMERA_TARGET:
                if (targetObject)
                    return "Look at " + targetName + " (🔒Lock)";
                return "Unlock Camera from Look Target";
            case CinematicEventType.FADE_IN:
                return "Fade In";
            case CinematicEventType.FADE_OUT:
                string fadeString = "Fade Out";
                Object fadeObject = eventObject.FindProperty("_fadeType").objectReferenceValue;
                if (fadeObject != null)
                {
                    fadeString = fadeString + " (" + fadeObject.name + ")";
                }
                return fadeString;
            case CinematicEventType.LETTERBOX:
                return showString + " Letterbox";
            case CinematicEventType.TRANSITION_MASK:
                string maskString = showString + " Transition Mask";
                Object maskObject = eventObject.FindProperty("_maskType").objectReferenceValue;
                if (show && maskObject != null)
                {
                    maskString = maskString + " (" + maskObject.name + ")";
                }
                return maskString;
            case CinematicEventType.CUSTOM:
                string customString = "Custom Event";
                string functionString = eventObject.FindProperty("_customEvent").stringValue;
                if (!string.IsNullOrEmpty(functionString))
                {
                    customString = customString + " (" + functionString + ")";
                }
                return customString;
            default:
                return "Unknown Event";
        }
    }

    private static bool NeedsTarget(CinematicEventType eventType)
    {
        switch(eventType)
        {
            case CinematicEventType.CAMERA_SNAP:
            case CinematicEventType.CAMERA_TRANSITION:
            case CinematicEventType.CUSTOM:
                return true;
        }
        return false;
    }
}

public enum CinematicEventType
{
    [InspectorName("Wait")]
    WAIT = 1,
    [InspectorName("Snap To Anchor")]
    CAMERA_SNAP = 2,
    [InspectorName("Move To Anchor")]
    CAMERA_TRANSITION = 3,
    [InspectorName("Look At Target")]
    CAMERA_TARGET = 4,
    [InspectorName("Fade Out")]
    FADE_OUT = 5,
    [InspectorName("Fade In")]
    FADE_IN = 6,
    [InspectorName("Update Letterbox")]
    LETTERBOX = 7,
    [InspectorName("Update Transition Mask")]
    TRANSITION_MASK = 8,
    [InspectorName("Custom Event")]
    CUSTOM = 9
}
