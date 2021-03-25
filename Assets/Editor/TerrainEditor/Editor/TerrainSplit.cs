using UnityEngine;
using System.IO;
using UnityEditor;
using OmegaEditor.Extension;
using System.Linq;

namespace OmegaEditor
{
    public static class TerrainSplit
    {
        [MenuItem("Tools/SplitTerrain")]
        static void SplitTerrainEntry()
        {
            var terrain = Selection.activeGameObject?.GetComponent<Terrain>();
            if(terrain!= null)
            {
                SplitTerrain(terrain, Mathf.CeilToInt(terrain.terrainData.size.x / 256f));
            }
        }

        [MenuItem("Tools/TerrainToMesh")]
        static void TerrainToMesh()
        {
            foreach (var terrain in Selection.gameObjects
                .Select((go) => go.GetComponent<Terrain>())
                .Where((terr) => terr != null))
            {
                string terrainPath = AssetDatabase.GetAssetPath(terrain.terrainData);
                terrainPath = Path.Combine(
                    Path.GetDirectoryName(terrainPath),
                    Path.GetFileNameWithoutExtension(terrainPath));
                string meshPath = terrainPath + "_Mesh.asset";
                string matPath = terrainPath + "_Main_Material.mat";

                Mesh mesh = terrain
                    .ToMesh(64)
                    .Translated(terrain.transform.localToWorldMatrix);
                {
                    mesh.name = terrain.gameObject.name;
                }
                Material mat = new Material(Shader.Find("Nature/Terrain/Standard"))
                { 
                    name = terrain.gameObject.name + "_Main_Material"
                };
                AssetDatabase.CreateAsset(mesh, meshPath);
                AssetDatabase.CreateAsset(mat, matPath);
                GameObject terrainGO = new GameObject(terrain.gameObject.name);
                MeshFilter meshFilter = terrainGO.AddComponent<MeshFilter>();
                {
                    meshFilter.sharedMesh = mesh;
                }
                MeshRenderer meshRenderer = terrainGO.AddComponent<MeshRenderer>();
                {
                    meshRenderer.sharedMaterial = mat;
                }
            }
        }

        [MenuItem("Tools/ReconnectTerrains")]
        static void ConnectTerrainEntry()
        {
            foreach (var terrain in Selection.gameObjects
               .Select((go) => go.GetComponent<Terrain>())
               .Where((terr) => terr != null))
            {
                // 指定是否将地形图块自动连接到相邻的图块
                terrain.allowAutoConnect = true;
            }
        }
        /// <summary>
        /// 地形分割
        /// </summary>
        /// <param name="terrain"></param>
        /// <param name="tileCount"></param>
        static void SplitTerrain(Terrain terrain, int tileCount)
        {
            TerrainData terrainData = terrain.terrainData;
            string terrainDataPath = AssetDatabase.GetAssetPath(terrainData);
            Vector3 tileSize = terrainData.size / tileCount;
            tileSize.y = terrainData.size.y;
            int tileRes = terrainData.heightmapResolution / tileCount;
            for (int tileX = 0; tileX < tileCount; ++tileX)
            {
                for (int tileZ = 0; tileZ < tileCount; ++tileZ)
                {
                    GameObject tileGO = new GameObject();
                    string tileName = "_X" + tileX + "_Z" + tileZ;
                    tileGO.name = terrain.gameObject.name + tileName;
                    string path = Path.Combine(
                        Path.GetDirectoryName(terrainDataPath),
                        Path.GetFileNameWithoutExtension(terrainDataPath) + tileName +
                        Path.GetExtension(terrainDataPath));
                    Terrain tile = tileGO.AddComponent<Terrain>();
                    
                    TerrainData tileData = new TerrainData();
                    tileData.name = terrainData.name + tileName;
                    AssetDatabase.CreateAsset(tileData, path);


                    #region parent properties
                    tile.basemapDistance = terrain.basemapDistance;
                    //tile.castShadows = terrain.castShadows;
                    tile.shadowCastingMode = terrain.shadowCastingMode;
                    tile.detailObjectDensity = terrain.detailObjectDensity;
                    tile.detailObjectDistance = terrain.detailObjectDistance;
                    tile.heightmapMaximumLOD = terrain.heightmapMaximumLOD;
                    tile.heightmapPixelError = terrain.heightmapPixelError;
                    tile.treeBillboardDistance = terrain.treeBillboardDistance;
                    tile.treeCrossFadeLength = terrain.treeCrossFadeLength;
                    tile.treeDistance = terrain.treeDistance;
                    tile.treeMaximumFullLODCount = terrain.treeMaximumFullLODCount;
                    tile.materialType = terrain.materialType;
                    tile.materialTemplate = terrain.materialTemplate;
                    #endregion

                    #region translate peace to right position 
                    tileGO.transform.parent = terrain.transform;
                    tileGO.transform.localPosition = new Vector3(tileSize.x * tileX, 0, tileSize.z * tileZ);
                    #endregion

                    tile.terrainData = tileData;
                    tileGO.AddComponent<TerrainCollider>().terrainData = tileData;

                    tileData.heightmapResolution = tileRes;
                    float[,] heights = terrainData.GetHeights(
                       tileX * tileRes, tileZ * tileRes,
                       tileRes + 1, tileRes + 1);
                    tileData.SetHeights(0, 0, heights);
                    tileData.size = tileSize;
                    EditorUtility.SetDirty(tileData);
                    Debug.Log(tileData.size);
                }
            }
            AssetDatabase.SaveAssets();
        }
    }
}

