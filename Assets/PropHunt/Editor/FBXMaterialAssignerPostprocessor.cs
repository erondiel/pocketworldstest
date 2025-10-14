using UnityEngine;
using UnityEditor;
using System.Linq;

namespace PropHunt.Editor
{
    /// <summary>
    /// Automatically assigns existing materials to imported FBX models by searching project-wide by name.
    /// Runs during asset import pipeline to prevent duplicate material creation.
    /// </summary>
    public class FBXMaterialAssignerPostprocessor : AssetPostprocessor
    {
        // Enable/disable debug logging
        private const bool DEBUG_LOGGING = true;

        /// <summary>
        /// Called before the model is imported. Sets up material search mode.
        /// </summary>
        private void OnPreprocessModel()
        {
            // Only process FBX files
            if (!assetPath.ToLower().EndsWith(".fbx"))
                return;

            var importer = assetImporter as ModelImporter;
            if (importer == null)
                return;

            // Use external materials search mode to allow material assignment
            importer.materialImportMode = ModelImporterMaterialImportMode.ImportStandard;
            importer.SearchAndRemapMaterials(ModelImporterMaterialName.BasedOnMaterialName, ModelImporterMaterialSearch.Everywhere);

            if (DEBUG_LOGGING)
                Debug.Log($"[FBXMaterialAssigner] Preprocessing FBX: {assetPath}");
        }

        /// <summary>
        /// Called after the model is imported. Searches for and assigns existing materials.
        /// </summary>
        private void OnPostprocessModel(GameObject model)
        {
            // Only process FBX files
            if (!assetPath.ToLower().EndsWith(".fbx"))
                return;

            if (DEBUG_LOGGING)
                Debug.Log($"[FBXMaterialAssigner] Post-processing FBX: {assetPath}");

            var importer = assetImporter as ModelImporter;
            if (importer == null)
                return;

            // Get all renderers in the model
            var renderers = model.GetComponentsInChildren<Renderer>(true);
            if (renderers.Length == 0)
            {
                if (DEBUG_LOGGING)
                    Debug.Log($"[FBXMaterialAssigner] No renderers found in {assetPath}");
                return;
            }

            int materialsFound = 0;
            int materialsAssigned = 0;

            // Process each renderer
            foreach (var renderer in renderers)
            {
                var sharedMaterials = renderer.sharedMaterials;
                bool materialsChanged = false;

                for (int i = 0; i < sharedMaterials.Length; i++)
                {
                    var material = sharedMaterials[i];

                    // Skip if material is null or already assigned
                    if (material == null)
                        continue;

                    materialsFound++;
                    string materialName = material.name;

                    // Remove common suffixes that Unity adds
                    materialName = CleanMaterialName(materialName);

                    if (DEBUG_LOGGING)
                        Debug.Log($"[FBXMaterialAssigner] Searching for material: '{materialName}'");

                    // Search for existing material in project
                    Material existingMaterial = FindMaterialByName(materialName);

                    if (existingMaterial != null)
                    {
                        sharedMaterials[i] = existingMaterial;
                        materialsChanged = true;
                        materialsAssigned++;

                        if (DEBUG_LOGGING)
                            Debug.Log($"[FBXMaterialAssigner] ✓ Assigned material '{materialName}' from {AssetDatabase.GetAssetPath(existingMaterial)}");
                    }
                    else
                    {
                        if (DEBUG_LOGGING)
                            Debug.LogWarning($"[FBXMaterialAssigner] ✗ Material '{materialName}' not found in project");
                    }
                }

                // Apply changed materials
                if (materialsChanged)
                {
                    renderer.sharedMaterials = sharedMaterials;
                }
            }

            if (DEBUG_LOGGING)
            {
                Debug.Log($"[FBXMaterialAssigner] Completed: {materialsAssigned}/{materialsFound} materials assigned for {assetPath}");
            }
        }

        /// <summary>
        /// Removes Unity's automatic suffixes from material names.
        /// </summary>
        private string CleanMaterialName(string materialName)
        {
            // Remove " (Instance)" suffix
            if (materialName.EndsWith(" (Instance)"))
                materialName = materialName.Replace(" (Instance)", "");

            // Remove numbered suffixes like " 1", " 2", etc.
            var lastSpace = materialName.LastIndexOf(' ');
            if (lastSpace > 0 && int.TryParse(materialName.Substring(lastSpace + 1), out _))
                materialName = materialName.Substring(0, lastSpace);

            return materialName.Trim();
        }

        /// <summary>
        /// Searches for a material by name across the entire project.
        /// Supports exact match and partial name matching.
        /// </summary>
        private Material FindMaterialByName(string materialName)
        {
            // Search for all materials in project
            string[] guids = AssetDatabase.FindAssets("t:Material");

            Material exactMatch = null;
            Material partialMatch = null;

            foreach (string guid in guids)
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                Material mat = AssetDatabase.LoadAssetAtPath<Material>(path);

                if (mat == null)
                    continue;

                // Exact name match (highest priority)
                if (mat.name == materialName)
                {
                    exactMatch = mat;
                    break;
                }

                // Partial match (case insensitive, fallback)
                if (partialMatch == null && mat.name.ToLower().Contains(materialName.ToLower()))
                {
                    partialMatch = mat;
                }
            }

            // Return exact match if found, otherwise partial match
            return exactMatch ?? partialMatch;
        }

        /// <summary>
        /// Called after all assets are imported. Can be used for batch processing.
        /// </summary>
        private static void OnPostprocessAllAssets(
            string[] importedAssets,
            string[] deletedAssets,
            string[] movedAssets,
            string[] movedFromAssetPaths)
        {
            // Count FBX imports
            int fbxCount = importedAssets.Count(path => path.ToLower().EndsWith(".fbx"));

            if (DEBUG_LOGGING && fbxCount > 0)
            {
                Debug.Log($"[FBXMaterialAssigner] Batch import completed: {fbxCount} FBX file(s) processed");
            }
        }
    }
}
