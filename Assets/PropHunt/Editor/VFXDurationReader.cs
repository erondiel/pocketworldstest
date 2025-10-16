using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

/// <summary>
/// Simple utility to read VFX durations from particle systems
/// Access via: Tools > PropHunt > Read VFX Durations
/// </summary>
public class VFXDurationReader : EditorWindow
{
    private List<GameObject> vfxList = new List<GameObject>();
    private Vector2 scrollPosition;

    [MenuItem("Tools/PropHunt/Read VFX Durations")]
    public static void ShowWindow()
    {
        VFXDurationReader window = GetWindow<VFXDurationReader>("VFX Duration Reader");
        window.minSize = new Vector2(450, 300);
    }

    private void OnGUI()
    {
        GUILayout.Space(10);
        EditorGUILayout.LabelField("VFX Duration Reader", EditorStyles.boldLabel);
        GUILayout.Space(5);

        EditorGUILayout.HelpBox(
            "Add VFX GameObjects to the list below to read their particle system durations. You can drag from Project or Hierarchy (even if disabled).",
            MessageType.Info
        );

        GUILayout.Space(10);

        // Add/Remove buttons
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button("Add VFX Slot", GUILayout.Height(25)))
        {
            vfxList.Add(null);
        }
        if (GUILayout.Button("Clear All", GUILayout.Height(25)))
        {
            vfxList.Clear();
        }
        EditorGUILayout.EndHorizontal();

        GUILayout.Space(10);

        // Scrollable list
        scrollPosition = EditorGUILayout.BeginScrollView(scrollPosition);

        for (int i = 0; i < vfxList.Count; i++)
        {
            EditorGUILayout.BeginVertical("box");

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField($"VFX {i + 1}", EditorStyles.boldLabel, GUILayout.Width(50));

            vfxList[i] = (GameObject)EditorGUILayout.ObjectField(vfxList[i], typeof(GameObject), true);

            if (GUILayout.Button("X", GUILayout.Width(30)))
            {
                vfxList.RemoveAt(i);
                EditorGUILayout.EndHorizontal();
                EditorGUILayout.EndVertical();
                break;
            }
            EditorGUILayout.EndHorizontal();

            // Display duration info
            if (vfxList[i] != null)
            {
                DisplayDuration(vfxList[i]);
            }
            else
            {
                EditorGUILayout.HelpBox("Drop a VFX GameObject here", MessageType.None);
            }

            EditorGUILayout.EndVertical();
            GUILayout.Space(5);
        }

        EditorGUILayout.EndScrollView();

        GUILayout.Space(10);

        if (vfxList.Count == 0)
        {
            EditorGUILayout.HelpBox("Click 'Add VFX Slot' to start adding VFX GameObjects", MessageType.Info);
        }
    }

    private void DisplayDuration(GameObject vfxGameObject)
    {
        // Get all particle systems (including children)
        ParticleSystem[] particleSystems = vfxGameObject.GetComponentsInChildren<ParticleSystem>(true);

        if (particleSystems == null || particleSystems.Length == 0)
        {
            EditorGUILayout.HelpBox($"❌ No ParticleSystem on '{vfxGameObject.name}' or its children", MessageType.Warning);
            return;
        }

        // Find the longest total duration (duration + max particle lifetime) across all particle systems
        float maxTotalDuration = 0f;
        string longestSystemName = "";
        int systemCount = particleSystems.Length;
        float longestDuration = 0f;
        float longestLifetime = 0f;

        foreach (ParticleSystem ps in particleSystems)
        {
            float psDuration = ps.main.duration;
            float psMaxLifetime = ps.main.startLifetime.constantMax; // Max particle lifetime
            float totalDuration = psDuration + psMaxLifetime;

            if (totalDuration > maxTotalDuration)
            {
                maxTotalDuration = totalDuration;
                longestSystemName = ps.gameObject.name;
                longestDuration = psDuration;
                longestLifetime = psMaxLifetime;
            }
        }

        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField($"Name: {vfxGameObject.name}", GUILayout.Width(250));
        EditorGUILayout.LabelField($"Total: {maxTotalDuration:F2}s", EditorStyles.boldLabel, GUILayout.Width(100));

        if (GUILayout.Button("Copy", GUILayout.Width(60)))
        {
            GUIUtility.systemCopyBuffer = maxTotalDuration.ToString("F2");
            Debug.Log($"[VFXDurationReader] Copied total duration for '{vfxGameObject.name}': {maxTotalDuration:F2}s " +
                      $"(Duration: {longestDuration:F2}s + Particle Lifetime: {longestLifetime:F2}s from '{longestSystemName}')");
        }
        EditorGUILayout.EndHorizontal();

        if (systemCount > 1)
        {
            EditorGUILayout.HelpBox($"✓ Total Duration: {maxTotalDuration:F2}s (found {systemCount} particle systems)\n" +
                                    $"Longest: '{longestSystemName}' (Duration: {longestDuration:F2}s + Particle Lifetime: {longestLifetime:F2}s)",
                                    MessageType.Info);
        }
        else
        {
            EditorGUILayout.HelpBox($"✓ Total Duration: {maxTotalDuration:F2}s (Duration: {longestDuration:F2}s + Particle Lifetime: {longestLifetime:F2}s)",
                                    MessageType.Info);
        }
    }
}
