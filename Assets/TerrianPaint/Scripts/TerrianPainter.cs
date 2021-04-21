using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;
[ExecuteInEditMode]
[RequireComponent(typeof(MeshCollider))]
public class TerrianPainter : MonoBehaviour {

    [MenuItem("Tools/TK/地图/刷地形工具")]
    public static void OpenTerrainPainter()
    {
        EditorSceneManager.OpenScene("Assets/TerrianPaint/Scene/TerrianEditor.unity");
    }
}
#endif
