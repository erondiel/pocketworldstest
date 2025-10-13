// Editor script: Assets/ExportSelectedTexture.cs
using UnityEditor;
using UnityEngine;
using System.IO;

public class ExportSelectedTexture : Editor
{
    [MenuItem("Tools/Export Selected Texture As PNG")]
    static void Export()
    {
        var tex = Selection.activeObject as Texture2D;
        if (!tex) { Debug.LogError("Select a Texture2D asset."); return; }

        var path = EditorUtility.SaveFilePanel("Save PNG", "", tex.name + ".png", "png");
        if (string.IsNullOrEmpty(path)) return;

        // Ensure import is readable
        var importer = (TextureImporter)AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(tex));
        if (importer != null && !importer.isReadable) { importer.isReadable = true; importer.SaveAndReimport(); }

        // Read pixels into CPU texture
        var tmp = new Texture2D(tex.width, tex.height, TextureFormat.RGBA32, false, true);
        Graphics.ConvertTexture(tex, tmp);
        var bytes = tmp.EncodeToPNG();
        File.WriteAllBytes(path, bytes);
        Debug.Log("Saved to " + path);
    }
}
