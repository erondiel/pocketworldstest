using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

namespace PropHunt.Editor
{
    /// <summary>
    /// Automated Unity scene setup for PropHunt V1
    /// NO MENU ITEMS - Use via Create Asset Menu or Inspector button
    ///
    /// HOW TO USE:
    /// 1. Right-click in Project window → Create → PropHunt → Scene Setup Wizard
    /// 2. Select the created asset in Project
    /// 3. Click "Setup Scene" button in Inspector
    /// </summary>
    [CreateAssetMenu(fileName = "PropHuntSetupWizard", menuName = "PropHunt/Scene Setup Wizard", order = 1)]
    public class PropHuntSceneSetupWizard : ScriptableObject
    {
        [Header("Spawn Positions")]
        [Tooltip("Where the lobby area will be located")]
        public Vector3 lobbyPosition = new Vector3(0, 0, 0);

        [Tooltip("Where the arena area will be located (50-100 units from lobby)")]
        public Vector3 arenaPosition = new Vector3(100, 0, 0);

        [Header("What to Create")]
        public bool createLobbyArea = true;
        public bool createArenaArea = true;
        public bool createZones = true;
        public bool createSampleProps = true;

        [Header("Props Configuration")]
        [Range(5, 30)]
        [Tooltip("Number of random props to create in arena")]
        public int propCount = 10;

        [Header("Zone Configuration")]
        public Vector3 nearSpawnSize = new Vector3(20, 10, 20);
        public Vector3 midSize = new Vector3(30, 10, 30);
        public Vector3 farSize = new Vector3(40, 10, 40);

        [Header("Visual Settings")]
        public Color lobbyMarkerColor = Color.green;
        public Color arenaMarkerColor = Color.red;
        public Color nearSpawnZoneColor = new Color(1f, 0.3f, 0.3f, 0.3f);
        public Color midZoneColor = new Color(1f, 1f, 0.3f, 0.3f);
        public Color farZoneColor = new Color(0.3f, 1f, 0.3f, 0.3f);
    }

    [CustomEditor(typeof(PropHuntSceneSetupWizard))]
    public class PropHuntSceneSetupWizardEditor : UnityEditor.Editor
    {
        public override void OnInspectorGUI()
        {
            DrawDefaultInspector();

            EditorGUILayout.Space();
            EditorGUILayout.Space();

            PropHuntSceneSetupWizard wizard = (PropHuntSceneSetupWizard)target;

            EditorGUILayout.HelpBox(
                "This wizard will create all PropHunt GameObjects in your current scene.\n\n" +
                "⚠️ Manual steps still required after setup:\n" +
                "• Add ZoneVolume components to zones\n" +
                "• Add Possessable components to props\n" +
                "• Add client systems to PropHuntModules",
                MessageType.Info);

            EditorGUILayout.Space();

            // Big setup button
            GUI.backgroundColor = Color.green;
            if (GUILayout.Button("🚀 SETUP SCENE", GUILayout.Height(50)))
            {
                SetupScene(wizard);
            }
            GUI.backgroundColor = Color.white;

            EditorGUILayout.Space();

            // Clear button
            GUI.backgroundColor = new Color(1f, 0.5f, 0.5f);
            if (GUILayout.Button("Clear All PropHunt Objects", GUILayout.Height(30)))
            {
                if (EditorUtility.DisplayDialog("Clear Scene",
                    "This will DELETE all PropHunt GameObjects. Are you sure?",
                    "Yes, Clear", "Cancel"))
                {
                    ClearScene();
                }
            }
            GUI.backgroundColor = Color.white;
        }

        private void SetupScene(PropHuntSceneSetupWizard wizard)
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
            CreateSpawnPoints(wizard, root.transform);

            // Create lobby area
            if (wizard.createLobbyArea)
            {
                CreateLobbyArea(wizard, root.transform);
            }

            // Create arena area
            if (wizard.createArenaArea)
            {
                CreateArenaArea(wizard, root.transform);
            }

            // Create zones
            if (wizard.createZones)
            {
                CreateZoneVolumes(wizard, root.transform);
            }

            // Create sample props
            if (wizard.createSampleProps)
            {
                CreateSampleProps(wizard, root.transform);
            }

            Debug.Log("[PropHunt Setup] ✅ Scene setup complete!");

            ShowCompletionDialog();
        }

        private void CreateSpawnPoints(PropHuntSceneSetupWizard wizard, Transform parent)
        {
            // Lobby Spawn
            GameObject lobbySpawn = new GameObject("LobbySpawn");
            lobbySpawn.transform.SetParent(parent);
            lobbySpawn.transform.position = wizard.lobbyPosition;
            Undo.RegisterCreatedObjectUndo(lobbySpawn, "Create LobbySpawn");
            Debug.Log($"[PropHunt Setup] Created LobbySpawn at {wizard.lobbyPosition}");

            // Arena Spawn
            GameObject arenaSpawn = new GameObject("ArenaSpawn");
            arenaSpawn.transform.SetParent(parent);
            arenaSpawn.transform.position = wizard.arenaPosition;
            Undo.RegisterCreatedObjectUndo(arenaSpawn, "Create ArenaSpawn");
            Debug.Log($"[PropHunt Setup] Created ArenaSpawn at {wizard.arenaPosition}");
        }

        private void CreateLobbyArea(PropHuntSceneSetupWizard wizard, Transform parent)
        {
            GameObject lobbyArea = new GameObject("Lobby_Area");
            lobbyArea.transform.SetParent(parent);
            lobbyArea.transform.position = wizard.lobbyPosition;
            Undo.RegisterCreatedObjectUndo(lobbyArea, "Create Lobby Area");

            // Ground plane
            GameObject ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Lobby_Ground";
            ground.transform.SetParent(lobbyArea.transform);
            ground.transform.position = wizard.lobbyPosition;
            ground.transform.localScale = new Vector3(5, 1, 5); // 50x50 units
            Undo.RegisterCreatedObjectUndo(ground, "Create Lobby Ground");

            // Spawn marker
            GameObject marker = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            marker.name = "Lobby_SpawnMarker";
            marker.transform.SetParent(lobbyArea.transform);
            marker.transform.position = wizard.lobbyPosition + Vector3.up * 0.5f;
            marker.transform.localScale = new Vector3(2, 0.1f, 2);

            var renderer = marker.GetComponent<Renderer>();
            if (renderer != null)
            {
                renderer.sharedMaterial = new Material(Shader.Find("Standard"));
                renderer.sharedMaterial.color = wizard.lobbyMarkerColor;
            }
            Undo.RegisterCreatedObjectUndo(marker, "Create Lobby Marker");

            Debug.Log($"[PropHunt Setup] Created Lobby Area at {wizard.lobbyPosition}");
        }

        private void CreateArenaArea(PropHuntSceneSetupWizard wizard, Transform parent)
        {
            GameObject arenaArea = new GameObject("Arena_Area");
            arenaArea.transform.SetParent(parent);
            arenaArea.transform.position = wizard.arenaPosition;
            Undo.RegisterCreatedObjectUndo(arenaArea, "Create Arena Area");

            // Ground plane (larger for arena)
            GameObject ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Arena_Ground";
            ground.transform.SetParent(arenaArea.transform);
            ground.transform.position = wizard.arenaPosition;
            ground.transform.localScale = new Vector3(10, 1, 10); // 100x100 units
            Undo.RegisterCreatedObjectUndo(ground, "Create Arena Ground");

            // Spawn marker
            GameObject marker = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            marker.name = "Arena_SpawnMarker";
            marker.transform.SetParent(arenaArea.transform);
            marker.transform.position = wizard.arenaPosition + Vector3.up * 0.5f;
            marker.transform.localScale = new Vector3(3, 0.1f, 3);

            var renderer = marker.GetComponent<Renderer>();
            if (renderer != null)
            {
                renderer.sharedMaterial = new Material(Shader.Find("Standard"));
                renderer.sharedMaterial.color = wizard.arenaMarkerColor;
            }
            Undo.RegisterCreatedObjectUndo(marker, "Create Arena Marker");

            Debug.Log($"[PropHunt Setup] Created Arena Area at {wizard.arenaPosition}");
        }

        private void CreateZoneVolumes(PropHuntSceneSetupWizard wizard, Transform parent)
        {
            GameObject zonesParent = new GameObject("Zones");
            zonesParent.transform.SetParent(parent);
            zonesParent.transform.position = wizard.arenaPosition;
            Undo.RegisterCreatedObjectUndo(zonesParent, "Create Zones Parent");

            // Zone 1: NearSpawn (High Risk, High Reward)
            CreateZone(wizard, zonesParent.transform, "Zone_NearSpawn",
                wizard.arenaPosition + new Vector3(0, 0.5f, 0),
                wizard.nearSpawnSize, 1.5f, wizard.nearSpawnZoneColor);

            // Zone 2: Mid (Balanced)
            CreateZone(wizard, zonesParent.transform, "Zone_Mid",
                wizard.arenaPosition + new Vector3(25, 0.5f, 0),
                wizard.midSize, 1.0f, wizard.midZoneColor);

            // Zone 3: Far (Safe, Low Reward)
            CreateZone(wizard, zonesParent.transform, "Zone_Far",
                wizard.arenaPosition + new Vector3(50, 0.5f, 0),
                wizard.farSize, 0.6f, wizard.farZoneColor);

            Debug.Log("[PropHunt Setup] Created 3 Zone Volumes (NearSpawn, Mid, Far)");
        }

        private void CreateZone(PropHuntSceneSetupWizard wizard, Transform parent, string zoneName,
            Vector3 position, Vector3 size, float weight, Color debugColor)
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

            Debug.Log($"[PropHunt Setup] Created {zoneName} (weight: {weight}) at {position}");
        }

        private void CreateSampleProps(PropHuntSceneSetupWizard wizard, Transform parent)
        {
            GameObject propsParent = new GameObject("Props");
            propsParent.transform.SetParent(parent);
            propsParent.transform.position = wizard.arenaPosition;
            Undo.RegisterCreatedObjectUndo(propsParent, "Create Props Parent");

            List<PrimitiveType> propTypes = new List<PrimitiveType>
            {
                PrimitiveType.Cube,
                PrimitiveType.Sphere,
                PrimitiveType.Cylinder,
                PrimitiveType.Capsule
            };

            for (int i = 0; i < wizard.propCount; i++)
            {
                // Random position in arena area
                Vector3 randomPos = wizard.arenaPosition + new Vector3(
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

            Debug.Log($"[PropHunt Setup] Created {wizard.propCount} sample props");
        }

        private void ShowCompletionDialog()
        {
            EditorUtility.DisplayDialog("Setup Complete! ✅",
                "PropHunt scene has been set up successfully!\n\n" +
                "⚠️ MANUAL STEPS REQUIRED:\n\n" +
                "1. Add ZoneVolume to zones:\n" +
                "   • Zone_NearSpawn (zoneName='NearSpawn', weight=1.5)\n" +
                "   • Zone_Mid (zoneName='Mid', weight=1.0)\n" +
                "   • Zone_Far (zoneName='Far', weight=0.6)\n\n" +
                "2. Add Possessable to all props:\n" +
                "   • Select all in 'Props' folder → Add Component\n\n" +
                "3. Add to PropHuntModules GameObject:\n" +
                "   • HunterTagSystem\n" +
                "   • PropDisguiseSystem\n" +
                "   • PropHuntRangeIndicator\n\n" +
                "4. Configure PropHuntTeleporter:\n" +
                "   • Drag LobbySpawn → Lobby Spawn Position\n" +
                "   • Drag ArenaSpawn → Arena Spawn Position\n\n" +
                "Then hit Play!",
                "Got It!");
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
