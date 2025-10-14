using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.Linq;

namespace PropHunt.Editor
{
    /// <summary>
    /// Editor utility for batch-adding outline meshes to possessable props.
    /// Creates outline as child GameObject with MeshRenderer for Lua control.
    /// </summary>
    public class PropOutlineSetupUtility : EditorWindow
    {
        private const string POSSESSABLE_TAG = "Possessable";
        private const string OUTLINE_MATERIAL_PATH = "Assets/PropHunt/Materials/PropOutline.mat";
        private const string OUTLINE_SUFFIX = "_Outline";

        private Material outlineMaterial;
        private bool addLuaComponent = true;
        private Vector2 scrollPosition;
        private List<GameObject> foundProps = new List<GameObject>();

        [MenuItem("PropHunt/Outline Setup", false, 1)]
        private static void OpenWindow()
        {
            var window = GetWindow<PropOutlineSetupUtility>("Outline Setup");
            window.minSize = new Vector2(400, 400);
            window.Show();
        }

        private void OnEnable()
        {
            outlineMaterial = LoadOutlineMaterial();
            RefreshPropList();
        }

        private void OnGUI()
        {
            EditorGUILayout.Space(10);
            EditorGUILayout.LabelField("PropHunt Outline Setup", EditorStyles.boldLabel);
            EditorGUILayout.HelpBox("Creates outline child meshes for possessable props.", MessageType.Info);

            EditorGUILayout.Space(10);

            // Settings
            outlineMaterial = (Material)EditorGUILayout.ObjectField("Outline Material", outlineMaterial, typeof(Material), false);
            addLuaComponent = EditorGUILayout.Toggle("Add PropOutline.lua", addLuaComponent);

            EditorGUILayout.Space(10);

            // Actions
            if (GUILayout.Button("Refresh Prop List", GUILayout.Height(30)))
            {
                RefreshPropList();
            }

            if (GUILayout.Button($"Add Outlines to All Props ({foundProps.Count})", GUILayout.Height(30)))
            {
                AddOutlinesToAllProps();
            }

            if (GUILayout.Button("Remove All Outlines", GUILayout.Height(30)))
            {
                RemoveAllOutlines();
            }

            EditorGUILayout.Space(10);

            // Props List
            EditorGUILayout.LabelField($"Possessable Props ({foundProps.Count})", EditorStyles.boldLabel);

            if (foundProps.Count == 0)
            {
                EditorGUILayout.HelpBox($"No GameObjects with '{POSSESSABLE_TAG}' tag found.", MessageType.Warning);
            }
            else
            {
                scrollPosition = EditorGUILayout.BeginScrollView(scrollPosition, GUILayout.Height(200));

                foreach (GameObject prop in foundProps)
                {
                    if (prop == null) continue;

                    EditorGUILayout.BeginHorizontal();

                    bool hasOutline = HasOutlineMesh(prop);
                    GUI.color = hasOutline ? Color.green : Color.yellow;
                    EditorGUILayout.LabelField(hasOutline ? "✓" : "○", GUILayout.Width(20));
                    GUI.color = Color.white;

                    EditorGUILayout.ObjectField(prop, typeof(GameObject), true);

                    if (GUILayout.Button(hasOutline ? "Remove" : "Add", GUILayout.Width(70)))
                    {
                        if (hasOutline)
                        {
                            RemoveOutlineMesh(prop);
                        }
                        else
                        {
                            AddOutlineMesh(prop);
                        }
                        RefreshPropList();
                    }

                    EditorGUILayout.EndHorizontal();
                }

                EditorGUILayout.EndScrollView();
            }

            EditorGUILayout.Space(10);
            int withOutline = foundProps.Count(p => p != null && HasOutlineMesh(p));
            EditorGUILayout.LabelField($"Props with outlines: {withOutline}/{foundProps.Count}", EditorStyles.miniLabel);
        }

        private void RefreshPropList()
        {
            GameObject[] allObjects = FindObjectsOfType<GameObject>();
            foundProps = allObjects.Where(obj => obj.CompareTag(POSSESSABLE_TAG)).OrderBy(obj => obj.name).ToList();
        }

        private void AddOutlinesToAllProps()
        {
            int count = 0;
            foreach (GameObject prop in foundProps)
            {
                if (prop != null && AddOutlineMesh(prop))
                {
                    count++;
                }
            }
            RefreshPropList();
            Debug.Log($"[PropOutlineSetup] Added outlines to {count}/{foundProps.Count} props");
        }

        private void RemoveAllOutlines()
        {
            if (!EditorUtility.DisplayDialog("Confirm", "Remove all outline meshes?", "Yes", "Cancel"))
                return;

            int count = 0;
            foreach (GameObject prop in foundProps)
            {
                if (prop != null && RemoveOutlineMesh(prop))
                {
                    count++;
                }
            }
            RefreshPropList();
            Debug.Log($"[PropOutlineSetup] Removed {count} outline meshes");
        }

        private bool AddOutlineMesh(GameObject prop)
        {
            // Check requirements
            MeshRenderer sourceRenderer = prop.GetComponent<MeshRenderer>();
            MeshFilter sourceMeshFilter = prop.GetComponent<MeshFilter>();

            if (sourceRenderer == null || sourceMeshFilter == null)
            {
                Debug.LogWarning($"[PropOutlineSetup] {prop.name} missing MeshRenderer or MeshFilter");
                return false;
            }

            // Check if already exists
            if (HasOutlineMesh(prop))
            {
                Debug.Log($"[PropOutlineSetup] {prop.name} already has outline");
                return false;
            }

            // Create outline child
            GameObject outlineObj = new GameObject(prop.name + OUTLINE_SUFFIX);
            outlineObj.transform.SetParent(prop.transform);
            outlineObj.transform.localPosition = Vector3.zero;
            outlineObj.transform.localRotation = Quaternion.identity;
            outlineObj.transform.localScale = Vector3.one;
            outlineObj.layer = prop.layer;

            // Add MeshFilter
            MeshFilter outlineMeshFilter = outlineObj.AddComponent<MeshFilter>();
            outlineMeshFilter.sharedMesh = sourceMeshFilter.sharedMesh;

            // Add MeshRenderer
            MeshRenderer outlineRenderer = outlineObj.AddComponent<MeshRenderer>();
            outlineRenderer.sharedMaterial = outlineMaterial;
            outlineRenderer.enabled = false; // Hidden by default
            outlineRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            outlineRenderer.receiveShadows = false;
            outlineRenderer.lightProbeUsage = UnityEngine.Rendering.LightProbeUsage.Off;
            outlineRenderer.reflectionProbeUsage = UnityEngine.Rendering.ReflectionProbeUsage.Off;

            // Optionally add Lua component
            if (addLuaComponent)
            {
                // Add Lua script reference (Highrise will load it)
                MonoScript luaScript = FindLuaScript("PropOutline");
                if (luaScript != null)
                {
                    // Note: In Highrise, Lua scripts are added via the Inspector manually
                    // or through serialized references. This is a placeholder.
                    Debug.Log($"[PropOutlineSetup] Add PropOutline.lua to {prop.name} manually if needed");
                }
            }

            EditorUtility.SetDirty(prop);
            Debug.Log($"[PropOutlineSetup] Added outline to {prop.name}");
            return true;
        }

        private bool RemoveOutlineMesh(GameObject prop)
        {
            Transform outlineTransform = prop.transform.Find(prop.name + OUTLINE_SUFFIX);
            if (outlineTransform != null)
            {
                DestroyImmediate(outlineTransform.gameObject);
                EditorUtility.SetDirty(prop);
                return true;
            }
            return false;
        }

        private bool HasOutlineMesh(GameObject prop)
        {
            return prop.transform.Find(prop.name + OUTLINE_SUFFIX) != null;
        }

        private static Material LoadOutlineMaterial()
        {
            Material material = AssetDatabase.LoadAssetAtPath<Material>(OUTLINE_MATERIAL_PATH);
            if (material == null)
            {
                Debug.LogWarning($"[PropOutlineSetup] Material not found at {OUTLINE_MATERIAL_PATH}");
            }
            return material;
        }

        private static MonoScript FindLuaScript(string scriptName)
        {
            string[] guids = AssetDatabase.FindAssets($"{scriptName} t:MonoScript");
            foreach (string guid in guids)
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                if (path.EndsWith(".lua"))
                {
                    return AssetDatabase.LoadAssetAtPath<MonoScript>(path);
                }
            }
            return null;
        }
    }
}
