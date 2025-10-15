using UnityEngine;
using UnityEditor;

public class ReplaceWithMultiplePrefabs : EditorWindow
{
    bool parentNew = false;
    bool deleteOld = true;
    bool rotateX = false;
    bool rotateY = false;
    bool rotateZ = false;
    bool followRotationX = false;
    bool followRotationY = true;
    bool followRotationZ = false;
    bool randomScale = false;
    bool translateScale = false;
    float minRandomScale = 0.9f;
    float maxRandomScale = 1.1f;
    float rx;
    float ry;
    float rz;
    float rs;
    Vector2 scrollPosition;

    [SerializeField] private GameObject[] theNewPrefabList;
    private int randomPrefab = 0;

    // UI Styles
    private GUIStyle headerStyle;
    private GUIStyle sectionStyle;
    private GUIStyle buttonStyle;
    private GUIStyle warningStyle;
    private bool stylesInitialized = false;

    [MenuItem("Window/Level Design/Replace Prefabs")]
    static void CreateReplaceWithPrefab()
    {
        var window = EditorWindow.GetWindow<ReplaceWithMultiplePrefabs>();
        window.titleContent = new GUIContent("Replace Prefabs");
        window.minSize = new Vector2(400, 600);
    }

    private void InitializeStyles()
    {
        if (stylesInitialized) return;

        headerStyle = new GUIStyle(EditorStyles.boldLabel)
        {
            fontSize = 14,
            normal = { textColor = EditorGUIUtility.isProSkin ? Color.white : Color.black }
        };

        sectionStyle = new GUIStyle(GUI.skin.box)
        {
            padding = new RectOffset(10, 10, 10, 10),
            margin = new RectOffset(5, 5, 5, 5)
        };

        buttonStyle = new GUIStyle(GUI.skin.button)
        {
            fontSize = 12,
            fontStyle = FontStyle.Bold
        };

        warningStyle = new GUIStyle(EditorStyles.helpBox)
        {
            normal = { textColor = Color.yellow }
        };

        stylesInitialized = true;
    }

    private void OnGUI()
    {
        InitializeStyles();
        
        ScriptableObject scriptableObj = this;
        SerializedObject serialObj = new SerializedObject(scriptableObj);
        SerializedProperty serialProp = serialObj.FindProperty("theNewPrefabList");

        // Header
        EditorGUILayout.Space(10);
        EditorGUILayout.LabelField("Replace Prefabs Tool", headerStyle, GUILayout.Height(20));
        EditorGUILayout.LabelField("Replace selected objects with random prefabs from your list", EditorStyles.miniLabel);
        
        EditorGUILayout.Space(5);
        DrawSeparator();
        EditorGUILayout.Space(10);

        scrollPosition = EditorGUILayout.BeginScrollView(scrollPosition);

        // Section 1: Prefab Setup
        DrawPrefabSetupSection(serialProp, serialObj);
        EditorGUILayout.Space(10);

        // Section 2: Selection Info
        DrawSelectionSection();
        EditorGUILayout.Space(10);

        // Section 3: Options
        DrawOptionsSection();
        EditorGUILayout.Space(10);

        // Section 4: Execute
        DrawExecuteSection();

        EditorGUILayout.EndScrollView();
    }

    private void DrawSeparator()
    {
        EditorGUILayout.Space(2);
        Rect rect = EditorGUILayout.GetControlRect(false, 1);
        EditorGUI.DrawRect(rect, EditorGUIUtility.isProSkin ? new Color(0.3f, 0.3f, 0.3f) : new Color(0.6f, 0.6f, 0.6f));
        EditorGUILayout.Space(2);
    }

    private void DrawPrefabSetupSection(SerializedProperty serialProp, SerializedObject serialObj)
    {
        EditorGUILayout.BeginVertical(sectionStyle);
        
        // Section header with icon
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("🎯", GUILayout.Width(20));
        EditorGUILayout.LabelField("Prefab Configuration", EditorStyles.boldLabel);
        EditorGUILayout.EndHorizontal();
        
        EditorGUILayout.Space(5);
        
        // Important note
        EditorGUILayout.HelpBox("⚠️ IMPORTANT: Drag prefabs from the Project window (blue cube icon), NOT from the Hierarchy!", MessageType.Info);
        
        EditorGUILayout.Space(5);
        
        // Prefab list
        EditorGUILayout.LabelField("Replacement Prefabs:", EditorStyles.label);
        EditorGUILayout.PropertyField(serialProp, GUIContent.none, true);
        serialObj.ApplyModifiedProperties();
        
        EditorGUILayout.Space(8);
        
        // Drag and drop area with better styling
        EditorGUILayout.LabelField("Quick Add from Project:", EditorStyles.boldLabel);
        Rect dropArea = GUILayoutUtility.GetRect(0, 60, GUILayout.ExpandWidth(true));
        
        // Custom styled drop area with border
        Color originalColor = GUI.backgroundColor;
        GUI.backgroundColor = new Color(0.3f, 0.5f, 0.8f, 0.3f);
        GUI.Box(dropArea, "", EditorStyles.helpBox);
        GUI.backgroundColor = originalColor;
        
        GUIStyle dropStyle = new GUIStyle(EditorStyles.centeredGreyMiniLabel)
        {
            fontSize = 12,
            fontStyle = FontStyle.Bold,
            wordWrap = true
        };
        
        GUI.Label(dropArea, "📦 Drag Prefab Assets Here\n(From Project Window)", dropStyle);
        HandlePrefabDragAndDrop(dropArea);
        
        // Show prefab count
        if (theNewPrefabList != null && theNewPrefabList.Length > 0)
        {
            EditorGUILayout.Space(5);
            EditorGUILayout.LabelField($"✓ {theNewPrefabList.Length} prefab(s) configured", EditorStyles.miniLabel);
        }
        
        EditorGUILayout.EndVertical();
    }

    private void DrawSelectionSection()
    {
        EditorGUILayout.BeginVertical(sectionStyle);
        
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("🎯", GUILayout.Width(20));
        EditorGUILayout.LabelField("Target Selection", EditorStyles.boldLabel);
        EditorGUILayout.EndHorizontal();
        
        EditorGUILayout.Space(5);
        
        EditorGUILayout.LabelField("Select objects in the Hierarchy to replace", EditorStyles.label);
        
        EditorGUILayout.Space(5);
        
        // Selection count with better styling
        int selectionCount = Selection.objects.Length;
        Color originalColor = GUI.color;
        
        if (selectionCount == 0)
        {
            GUI.color = Color.yellow;
            EditorGUILayout.LabelField("⚠️ No objects selected", EditorStyles.boldLabel);
        }
        else
        {
            GUI.color = Color.green;
            EditorGUILayout.LabelField($"✓ {selectionCount} object(s) selected for replacement", EditorStyles.boldLabel);
        }
        
        GUI.color = originalColor;
        
        EditorGUILayout.EndVertical();
    }

    private void DrawOptionsSection()
    {
        EditorGUILayout.BeginVertical(sectionStyle);
        
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("⚙️", GUILayout.Width(20));
        EditorGUILayout.LabelField("Replacement Options", EditorStyles.boldLabel);
        EditorGUILayout.EndHorizontal();
        
        EditorGUILayout.Space(8);
        
        // General Options
        EditorGUILayout.LabelField("General", EditorStyles.boldLabel);
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        parentNew = EditorGUILayout.ToggleLeft("Create parent object for new prefabs", parentNew);
        deleteOld = EditorGUILayout.ToggleLeft("Delete original objects", deleteOld);
        EditorGUILayout.EndVertical();
        
        EditorGUILayout.Space(8);
        
        // Scale Options
        EditorGUILayout.LabelField("Scale", EditorStyles.boldLabel);
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        translateScale = EditorGUILayout.ToggleLeft("Copy scale from original objects", translateScale);
        randomScale = EditorGUILayout.ToggleLeft("Apply random scaling", randomScale);
        
        if (randomScale)
        {
            EditorGUILayout.Space(5);
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("Range:", GUILayout.Width(50));
            minRandomScale = EditorGUILayout.FloatField(minRandomScale, GUILayout.Width(60));
            EditorGUILayout.LabelField("to", GUILayout.Width(20));
            maxRandomScale = EditorGUILayout.FloatField(maxRandomScale, GUILayout.Width(60));
            EditorGUILayout.EndHorizontal();
            
            if (minRandomScale > maxRandomScale)
            {
                EditorGUILayout.HelpBox("⚠️ Min scale should be ≤ max scale", MessageType.Warning);
            }
        }
        EditorGUILayout.EndVertical();
        
        EditorGUILayout.Space(8);
        
        // Rotation Options
        EditorGUILayout.LabelField("Rotation", EditorStyles.boldLabel);
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
        
        EditorGUILayout.LabelField("Copy rotation from original:", EditorStyles.miniLabel);
        EditorGUILayout.BeginHorizontal();
        followRotationX = EditorGUILayout.ToggleLeft("X", followRotationX, GUILayout.Width(40));
        followRotationY = EditorGUILayout.ToggleLeft("Y", followRotationY, GUILayout.Width(40));
        followRotationZ = EditorGUILayout.ToggleLeft("Z", followRotationZ, GUILayout.Width(40));
        EditorGUILayout.EndHorizontal();
        
        EditorGUILayout.Space(5);
        
        EditorGUILayout.LabelField("Apply random rotation:", EditorStyles.miniLabel);
        EditorGUILayout.BeginHorizontal();
        rotateX = EditorGUILayout.ToggleLeft("X", rotateX, GUILayout.Width(40));
        rotateY = EditorGUILayout.ToggleLeft("Y", rotateY, GUILayout.Width(40));
        rotateZ = EditorGUILayout.ToggleLeft("Z", rotateZ, GUILayout.Width(40));
        EditorGUILayout.EndHorizontal();
        
        // Warning for conflicting rotation settings
        if ((rotateX && followRotationX) || (rotateY && followRotationY) || (rotateZ && followRotationZ))
        {
            EditorGUILayout.Space(5);
            EditorGUILayout.HelpBox("⚠️ Random rotation overrides copy rotation on the same axis", MessageType.Warning);
        }
        
        EditorGUILayout.EndVertical();
        
        EditorGUILayout.EndVertical();
    }

    private void DrawExecuteSection()
    {
        EditorGUILayout.BeginVertical(sectionStyle);
        
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("🚀", GUILayout.Width(20));
        EditorGUILayout.LabelField("Execute Replacement", EditorStyles.boldLabel);
        EditorGUILayout.EndHorizontal();
        
        EditorGUILayout.Space(8);
        
        // Validation
        bool canExecute = true;
        string validationMessage = "";
        
        if (theNewPrefabList == null || theNewPrefabList.Length == 0)
        {
            canExecute = false;
            validationMessage = "⚠️ No prefabs configured";
        }
        else if (Selection.objects.Length == 0)
        {
            canExecute = false;
            validationMessage = "⚠️ No objects selected for replacement";
        }
        else
        {
            validationMessage = $"✓ Ready to replace {Selection.objects.Length} object(s) with {theNewPrefabList.Length} prefab variant(s)";
        }
        
        EditorGUILayout.LabelField(validationMessage, EditorStyles.wordWrappedLabel);
        EditorGUILayout.Space(8);
        
        // Execute button
        GUI.enabled = canExecute;
        
        Color originalColor = GUI.backgroundColor;
        GUI.backgroundColor = canExecute ? Color.green : Color.gray;
        
        if (GUILayout.Button("🔄 Replace Objects", buttonStyle, GUILayout.Height(35)))
        {
            ExecuteReplacement();
        }
        
        GUI.backgroundColor = originalColor;
        GUI.enabled = true;
        
        EditorGUILayout.EndVertical();
    }

    private void ExecuteReplacement()
    {
        // Validate all prefabs before starting
        for (int j = 0; j < theNewPrefabList.Length; j++)
        {
            if (theNewPrefabList[j] == null)
            {
                Debug.LogError($"⚠️ Prefab at index {j} in the list is null. Please remove empty slots.");
                EditorUtility.DisplayDialog("Error", $"Prefab at index {j} is null. Remove empty slots from the list.", "OK");
                return;
            }

            PrefabAssetType prefabType = PrefabUtility.GetPrefabAssetType(theNewPrefabList[j]);
            if (prefabType == PrefabAssetType.NotAPrefab)
            {
                Debug.LogError($"⚠️ GameObject '{theNewPrefabList[j].name}' at index {j} is not a prefab. Please add only prefab assets from the Project window.");
                EditorUtility.DisplayDialog("Error", $"'{theNewPrefabList[j].name}' is not a prefab.\n\nPlease drag prefabs from the Project window, not from the Hierarchy.", "OK");
                return;
            }

            // Check if it's a prefab asset (has asset path)
            string assetPath = AssetDatabase.GetAssetPath(theNewPrefabList[j]);
            if (string.IsNullOrEmpty(assetPath))
            {
                Debug.LogError($"⚠️ GameObject '{theNewPrefabList[j].name}' at index {j} is not a prefab asset (no asset path).");
                EditorUtility.DisplayDialog("Error", 
                    $"'{theNewPrefabList[j].name}' is a scene object, not a prefab asset.\n\n" +
                    "You must drag the prefab from the Project window, not from the Hierarchy.\n\n" +
                    "Look for the blue cube icon in the Project window.", 
                    "OK");
                return;
            }

            // Check if it's actually part of a prefab asset
            if (!PrefabUtility.IsPartOfPrefabAsset(theNewPrefabList[j]))
            {
                Debug.LogWarning($"⚠️ GameObject '{theNewPrefabList[j].name}' at index {j} may not be a proper prefab asset. This might cause issues.");
            }
        }

        GameObject prefabParent = null;

        if (parentNew)
        {
            prefabParent = new GameObject("NewPrefabHolder");
            prefabParent.transform.position = Vector3.zero;
            Undo.RegisterCreatedObjectUndo(prefabParent, "Parent Replace With Prefabs");
        }

        var selection = Selection.gameObjects;
        int successCount = 0;

        for (var i = selection.Length - 1; i >= 0; --i)
        {
            var selected = selection[i];

            randomPrefab = Random.Range(0, theNewPrefabList.Length);
            GameObject prefabToInstantiate = theNewPrefabList[randomPrefab];

            // Additional validation (should not happen due to pre-checks, but just in case)
            if (prefabToInstantiate == null)
            {
                Debug.LogError($"Selected prefab at index {randomPrefab} is null");
                continue;
            }

            GameObject newObject = (GameObject)PrefabUtility.InstantiatePrefab(prefabToInstantiate, selected.scene);

            if (newObject == null)
            {
                Debug.LogError($"Failed to instantiate prefab '{prefabToInstantiate.name}'. This should not happen after validation.");
                continue;
            }

            successCount++;

            if (!parentNew)
            {
                Undo.RegisterCreatedObjectUndo(newObject, "Replace With Multiple Prefabs");
            }

            newObject.name = newObject.name + " (" + i + ")";

            // Set parent
            newObject.transform.parent = parentNew ? prefabParent.transform : selected.transform.parent;

            // Set position
            newObject.transform.position = selected.transform.position;

            // Enhanced rotation logic
            rx = rotateX ? Random.Range(0f, 360f) : 
                 followRotationX ? selected.transform.eulerAngles.x : 
                 newObject.transform.eulerAngles.x;
                 
            ry = rotateY ? Random.Range(0f, 360f) : 
                 followRotationY ? selected.transform.eulerAngles.y : 
                 newObject.transform.eulerAngles.y;
                 
            rz = rotateZ ? Random.Range(0f, 360f) : 
                 followRotationZ ? selected.transform.eulerAngles.z : 
                 newObject.transform.eulerAngles.z;
                 
            rs = randomScale ? Random.Range(minRandomScale, maxRandomScale) : 1f;

            newObject.transform.eulerAngles = new Vector3(rx, ry, rz);

            // Scale logic
            if (translateScale)
            {
                if (randomScale)
                {
                    newObject.transform.localScale = new Vector3(
                        selected.transform.localScale.x * rs,
                        selected.transform.localScale.y * rs,
                        selected.transform.localScale.z * rs
                    );
                }
                else
                {
                    newObject.transform.localScale = selected.transform.localScale;
                }
            }
            else
            {
                newObject.transform.localScale = new Vector3(rs, rs, rs);
            }
            
            newObject.transform.SetSiblingIndex(selected.transform.GetSiblingIndex());

            if (deleteOld)
            {
                Undo.DestroyObjectImmediate(selected);
            }
        }

        if (successCount > 0)
        {
            Debug.Log($"✓ Successfully replaced {successCount}/{selection.Length} object(s) with {theNewPrefabList.Length} prefab variant(s)");
        }
        else
        {
            Debug.LogWarning($"⚠️ Failed to replace any objects. Check console for details.");
        }
    }

    private void HandlePrefabDragAndDrop(Rect dropArea)
    {
        Event evt = Event.current;
        
        switch (evt.type)
        {
            case EventType.DragUpdated:
            case EventType.DragPerform:
                if (!dropArea.Contains(evt.mousePosition))
                    return;

                DragAndDrop.visualMode = DragAndDropVisualMode.Copy;

                if (evt.type == EventType.DragPerform)
                {
                    DragAndDrop.AcceptDrag();

                    foreach (Object draggedObject in DragAndDrop.objectReferences)
                    {
                        if (draggedObject is GameObject gameObject)
                        {
                            if (PrefabUtility.IsPartOfPrefabAsset(gameObject) || PrefabUtility.GetPrefabAssetType(gameObject) != PrefabAssetType.NotAPrefab)
                            {
                                // Add to prefab list if not already present
                                bool alreadyExists = false;
                                foreach (var existingPrefab in theNewPrefabList)
                                {
                                    if (existingPrefab == gameObject)
                                    {
                                        alreadyExists = true;
                                        break;
                                    }
                                }
                                
                                if (!alreadyExists)
                                {
                                    GameObject[] newArray = new GameObject[theNewPrefabList.Length + 1];
                                    for (int i = 0; i < theNewPrefabList.Length; i++)
                                    {
                                        newArray[i] = theNewPrefabList[i];
                                    }
                                    newArray[theNewPrefabList.Length] = gameObject;
                                    theNewPrefabList = newArray;
                                }
                            }
                            else
                            {
                                Debug.LogWarning($"'{gameObject.name}' is not a prefab and cannot be added to the prefab list.");
                            }
                        }
                    }
                }
            break;
        }
    }
}
