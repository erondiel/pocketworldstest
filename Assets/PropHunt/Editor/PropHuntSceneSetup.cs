using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace PropHunt.Editor
{
    /// <summary>
    /// Automated Unity scene setup for PropHunt V1
    /// Creates all required GameObjects, zones, spawn points, and sample props
    /// </summary>
    public class PropHuntSceneSetup : EditorWindow
    {
        private bool createLobbyArea = true;
        private bool createArenaArea = true;
        private bool createZones = true;
        private bool createSampleProps = true;
        private int propCount = 10;

        private Vector3 lobbyPosition = new Vector3(0, 0, 0);
        private Vector3 arenaPosition = new Vector3(100, 0, 0);

        [MenuItem("PropHunt/Scene Setup Wizard")]
        public static void ShowWindow()
        {
            GetWindow<PropHuntSceneSetup>("PropHunt Setup");
        }

        private void OnGUI()
        {
            GUILayout.Label("PropHunt Scene Setup", EditorStyles.boldLabel);
            EditorGUILayout.Space();

            EditorGUILayout.HelpBox("This will create all required GameObjects for PropHunt in your current scene.", MessageType.Info);
            EditorGUILayout.Space();

            // Configuration
            GUILayout.Label("Configuration", EditorStyles.boldLabel);
            lobbyPosition = EditorGUILayout.Vector3Field("Lobby Position", lobbyPosition);
            arenaPosition = EditorGUILayout.Vector3Field("Arena Position", arenaPosition);
            EditorGUILayout.Space();

            // Options
            GUILayout.Label("What to Create", EditorStyles.boldLabel);
            createLobbyArea = EditorGUILayout.Toggle("Create Lobby Area", createLobbyArea);
            createArenaArea = EditorGUILayout.Toggle("Create Arena Area", createArenaArea);
            createZones = EditorGUILayout.Toggle("Create Zone Volumes", createZones);
            createSampleProps = EditorGUILayout.Toggle("Create Sample Props", createSampleProps);

            if (createSampleProps)
            {
                propCount = EditorGUILayout.IntSlider("Number of Props", propCount, 5, 20);
            }

            EditorGUILayout.Space();
            EditorGUILayout.Space();

            // Setup button
            if (GUILayout.Button("Setup Scene", GUILayout.Height(40)))
            {
                SetupScene();
            }

            EditorGUILayout.Space();

            if (GUILayout.Button("Clear All PropHunt Objects", GUILayout.Height(30)))
            {
                if (EditorUtility.DisplayDialog("Clear Scene",
                    "This will DELETE all PropHunt GameObjects. Are you sure?",
                    "Yes, Clear", "Cancel"))
                {
                    ClearScene();
                }
            }
        }

        private void SetupScene()
        {
            Debug.Log("[PropHunt Setup] Starting scene setup...");

            // Create root container
            GameObject root = GameObject.Find("PropHunt_Root");
            if (root == null)
            {
                root = new GameObject("PropHunt_Root");
                Undo.RegisterCreatedObjectUndo(root, "Create PropHunt Root");
            }

            // Create spawn points
            CreateSpawnPoints(root.transform);

            // Create lobby area
            if (createLobbyArea)
            {
                CreateLobbyArea(root.transform);
            }

            // Create arena area
            if (createArenaArea)
            {
                CreateArenaArea(root.transform);
            }

            // Create zones
            if (createZones)
            {
                CreateZoneVolumes(root.transform);
            }

            // Create sample props
            if (createSampleProps)
            {
                CreateSampleProps(root.transform);
            }

            Debug.Log("[PropHunt Setup] ✅ Scene setup complete!");
            EditorUtility.DisplayDialog("Setup Complete",
                "PropHunt scene has been set up successfully!\n\n" +
                "Next steps:\n" +
                "1. Select PropHuntModules GameObject\n" +
                "2. Add HunterTagSystem, PropDisguiseSystem, PropHuntRangeIndicator components\n" +
                "3. Configure PropHuntTeleporter with LobbySpawn and ArenaSpawn\n" +
                "4. Hit Play!",
                "OK");
        }

        private void CreateSpawnPoints(Transform parent)
        {
            // Lobby Spawn
            GameObject lobbySpawn = new GameObject("LobbySpawn");
            lobbySpawn.transform.SetParent(parent);
            lobbySpawn.transform.position = lobbyPosition;
            Undo.RegisterCreatedObjectUndo(lobbySpawn, "Create LobbySpawn");
            Debug.Log($"[PropHunt Setup] Created LobbySpawn at {lobbyPosition}");

            // Arena Spawn
            GameObject arenaSpawn = new GameObject("ArenaSpawn");
            arenaSpawn.transform.SetParent(parent);
            arenaSpawn.transform.position = arenaPosition;
            Undo.RegisterCreatedObjectUndo(arenaSpawn, "Create ArenaSpawn");
            Debug.Log($"[PropHunt Setup] Created ArenaSpawn at {arenaPosition}");
        }

        private void CreateLobbyArea(Transform parent)
        {
            GameObject lobbyArea = new GameObject("Lobby_Area");
            lobbyArea.transform.SetParent(parent);
            lobbyArea.transform.position = lobbyPosition;
            Undo.RegisterCreatedObjectUndo(lobbyArea, "Create Lobby Area");

            // Ground plane
            GameObject ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Lobby_Ground";
            ground.transform.SetParent(lobbyArea.transform);
            ground.transform.position = lobbyPosition;
            ground.transform.localScale = new Vector3(5, 1, 5); // 50x50 units
            Undo.RegisterCreatedObjectUndo(ground, "Create Lobby Ground");

            // Spawn marker
            GameObject marker = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            marker.name = "Lobby_SpawnMarker";
            marker.transform.SetParent(lobbyArea.transform);
            marker.transform.position = lobbyPosition + Vector3.up * 0.5f;
            marker.transform.localScale = new Vector3(2, 0.1f, 2);

            // Make it green
            var renderer = marker.GetComponent<Renderer>();
            if (renderer != null)
            {
                renderer.sharedMaterial = new Material(Shader.Find("Standard"));
                renderer.sharedMaterial.color = Color.green;
            }
            Undo.RegisterCreatedObjectUndo(marker, "Create Lobby Marker");

            Debug.Log($"[PropHunt Setup] Created Lobby Area at {lobbyPosition}");
        }

        private void CreateArenaArea(Transform parent)
        {
            GameObject arenaArea = new GameObject("Arena_Area");
            arenaArea.transform.SetParent(parent);
            arenaArea.transform.position = arenaPosition;
            Undo.RegisterCreatedObjectUndo(arenaArea, "Create Arena Area");

            // Ground plane (larger for arena)
            GameObject ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Arena_Ground";
            ground.transform.SetParent(arenaArea.transform);
            ground.transform.position = arenaPosition;
            ground.transform.localScale = new Vector3(10, 1, 10); // 100x100 units
            Undo.RegisterCreatedObjectUndo(ground, "Create Arena Ground");

            // Spawn marker
            GameObject marker = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            marker.name = "Arena_SpawnMarker";
            marker.transform.SetParent(arenaArea.transform);
            marker.transform.position = arenaPosition + Vector3.up * 0.5f;
            marker.transform.localScale = new Vector3(3, 0.1f, 3);

            // Make it red
            var renderer = marker.GetComponent<Renderer>();
            if (renderer != null)
            {
                renderer.sharedMaterial = new Material(Shader.Find("Standard"));
                renderer.sharedMaterial.color = Color.red;
            }
            Undo.RegisterCreatedObjectUndo(marker, "Create Arena Marker");

            Debug.Log($"[PropHunt Setup] Created Arena Area at {arenaPosition}");
        }

        private void CreateZoneVolumes(Transform parent)
        {
            GameObject zonesParent = new GameObject("Zones");
            zonesParent.transform.SetParent(parent);
            zonesParent.transform.position = arenaPosition;
            Undo.RegisterCreatedObjectUndo(zonesParent, "Create Zones Parent");

            // Zone 1: NearSpawn (High Risk, High Reward)
            CreateZone(zonesParent.transform, "Zone_NearSpawn", arenaPosition + new Vector3(0, 0.5f, 0),
                new Vector3(20, 10, 20), 1.5f, new Color(1f, 0.3f, 0.3f, 0.3f));

            // Zone 2: Mid (Balanced)
            CreateZone(zonesParent.transform, "Zone_Mid", arenaPosition + new Vector3(25, 0.5f, 0),
                new Vector3(30, 10, 30), 1.0f, new Color(1f, 1f, 0.3f, 0.3f));

            // Zone 3: Far (Safe, Low Reward)
            CreateZone(zonesParent.transform, "Zone_Far", arenaPosition + new Vector3(50, 0.5f, 0),
                new Vector3(40, 10, 40), 0.6f, new Color(0.3f, 1f, 0.3f, 0.3f));

            Debug.Log("[PropHunt Setup] Created 3 Zone Volumes (NearSpawn, Mid, Far)");
        }

        private void CreateZone(Transform parent, string zoneName, Vector3 position, Vector3 size, float weight, Color debugColor)
        {
            GameObject zone = new GameObject(zoneName);
            zone.transform.SetParent(parent);
            zone.transform.position = position;
            Undo.RegisterCreatedObjectUndo(zone, $"Create {zoneName}");

            // Add BoxCollider (trigger)
            BoxCollider collider = zone.AddComponent<BoxCollider>();
            collider.isTrigger = true;
            collider.size = size;

            // Add visual debug cube (semi-transparent)
            GameObject debugCube = GameObject.CreatePrimitive(PrimitiveType.Cube);
            debugCube.name = "DebugVisual";
            debugCube.transform.SetParent(zone.transform);
            debugCube.transform.localPosition = Vector3.zero;
            debugCube.transform.localScale = size;

            // Remove the collider from debug cube (we only want the visual)
            DestroyImmediate(debugCube.GetComponent<BoxCollider>());

            // Set transparent material
            var renderer = debugCube.GetComponent<Renderer>();
            if (renderer != null)
            {
                Material mat = new Material(Shader.Find("Standard"));
                mat.color = debugColor;
                mat.SetFloat("_Mode", 3); // Transparent mode
                mat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                mat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                mat.SetInt("_ZWrite", 0);
                mat.DisableKeyword("_ALPHATEST_ON");
                mat.EnableKeyword("_ALPHABLEND_ON");
                mat.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                mat.renderQueue = 3000;
                renderer.sharedMaterial = mat;
            }

            // Add a label to help visualize in scene
            GameObject label = new GameObject("ZoneLabel");
            label.transform.SetParent(zone.transform);
            label.transform.localPosition = Vector3.up * (size.y / 2 + 1);

            Debug.Log($"[PropHunt Setup] Created {zoneName} (weight: {weight}) at {position}");

            EditorUtility.DisplayDialog("ZoneVolume Component Required",
                $"IMPORTANT: You must manually add the ZoneVolume component to '{zoneName}' and set:\n\n" +
                $"- Zone Name: {zoneName.Replace("Zone_", "")}\n" +
                $"- Zone Weight: {weight}\n\n" +
                "The Lua ZoneVolume script cannot be added via C# editor scripts.",
                "OK");
        }

        private void CreateSampleProps(Transform parent)
        {
            GameObject propsParent = new GameObject("Props");
            propsParent.transform.SetParent(parent);
            propsParent.transform.position = arenaPosition;
            Undo.RegisterCreatedObjectUndo(propsParent, "Create Props Parent");

            List<PrimitiveType> propTypes = new List<PrimitiveType>
            {
                PrimitiveType.Cube,
                PrimitiveType.Sphere,
                PrimitiveType.Cylinder,
                PrimitiveType.Capsule
            };

            for (int i = 0; i < propCount; i++)
            {
                // Random position in arena area
                Vector3 randomPos = arenaPosition + new Vector3(
                    Random.Range(-40f, 40f),
                    1f,
                    Random.Range(-40f, 40f)
                );

                // Random prop type
                PrimitiveType propType = propTypes[Random.Range(0, propTypes.Count)];
                GameObject prop = GameObject.CreatePrimitive(propType);
                prop.name = $"Prop_{propType}_{i:00}";
                prop.transform.SetParent(propsParent.transform);
                prop.transform.position = randomPos;

                // Random scale variation
                float scale = Random.Range(0.8f, 2.5f);
                prop.transform.localScale = Vector3.one * scale;

                // Random rotation
                prop.transform.rotation = Quaternion.Euler(0, Random.Range(0f, 360f), 0);

                // Random color
                var renderer = prop.GetComponent<Renderer>();
                if (renderer != null)
                {
                    Material mat = new Material(Shader.Find("Standard"));
                    mat.color = new Color(Random.value, Random.value, Random.value);
                    renderer.sharedMaterial = mat;
                }

                Undo.RegisterCreatedObjectUndo(prop, $"Create Prop {i}");
            }

            Debug.Log($"[PropHunt Setup] Created {propCount} sample props");

            EditorUtility.DisplayDialog("Possessable Component Required",
                $"IMPORTANT: You must manually add the Possessable component to each prop in the 'Props' folder.\n\n" +
                "The Lua Possessable script cannot be added via C# editor scripts.\n\n" +
                "Select all props and add the component in one batch.",
                "OK");
        }

        private void ClearScene()
        {
            GameObject root = GameObject.Find("PropHunt_Root");
            if (root != null)
            {
                Undo.DestroyObjectImmediate(root);
                Debug.Log("[PropHunt Setup] Cleared all PropHunt objects");
            }
            else
            {
                Debug.LogWarning("[PropHunt Setup] No PropHunt_Root found to clear");
            }
        }
    }
}
