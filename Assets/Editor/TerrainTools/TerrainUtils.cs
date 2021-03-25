using System.IO;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Linq;
using System.Reflection;
using OmegaEditor.Extension;
using UnityEngine.SceneManagement;

namespace OmegaEditor
{
    public static class TerrainUtils
    {
        [MenuItem("Tools/TerrainTools/ExportTerrain")]
        static void ExportTerrain()
        {
            var terrains = Selection.gameObjects
                .Select((go) => go.GetComponent<Terrain>())
                .Where((t) => t != null);
            Material convertSplatMat = new Material(Shader.Find("Hidden/ConvertSplatmap"));
            RenderTexture converted = new RenderTexture(512, 512, 0, RenderTextureFormat.ARGB32);
            Matrix4x4 splatIdx = new Matrix4x4(
                new Vector4(0, 1, 2, 3), 
                new Vector4(4, 5, 6, 7), 
                new Vector4(8, 9, 10, 11), 
                new Vector4(12, 13, 14, 15));
            foreach(var terrain in terrains)
            {
                foreach(var (index, splatAlpha) in terrain.terrainData.GetAlphamapTextures())
                {
                    convertSplatMat.SetTexture("_SplatAlpha" + index, splatAlpha);
                }
                var terrainLayers = terrain.terrainData.terrainLayers;
                for(int layerIdx = 0; layerIdx < terrainLayers.Length; ++layerIdx)
                {
                    int index = -1;
                    if(!int.TryParse(terrainLayers[layerIdx]?.diffuseTexture?.name.Split('_').Last(), out index))
                    {
                        Debug.LogErrorFormat("Invalid Terrain Layer: {0} in {1}", layerIdx, terrain.name);
                    }
                    splatIdx[layerIdx] = index;
                }
                convertSplatMat.SetMatrix("_SplatIdx", splatIdx.transpose);
                Graphics.Blit(null, converted, convertSplatMat);
                RenderTexture.active = converted;
                Texture2D splatmap = new Texture2D(512, 512, TextureFormat.ARGB32, false);
                splatmap.ReadPixels(new Rect(0, 0, 512, 512), 0, 0);
                splatmap.Apply();
                
                var mesh = terrain
                    .ToMesh(64)
                    .Translated(Matrix4x4.Translate(terrain.transform.position));
                string obj = mesh.EncodeToObj();
                //string path = EditorUtility.SaveFilePanelInProject("Save Splatmap", terrain.name + "_Splat", "png", "Save Splatmap");
                string dir = Path.Combine(Path.GetDirectoryName(terrain.gameObject.scene.path), terrain.name, terrain.name.Replace("Terrain_", "") + "_Grounds");
                string systemDir = dir.Replace(@"Assets\", Application.dataPath + "/");
                string splatFileName = terrain.name + "_Splatmap.png";
                string objFileName = terrain.name + ".obj";
                if(!Directory.Exists(systemDir))
                {
                    Directory.CreateDirectory(systemDir);
                }
                File.WriteAllText(Path.Combine(systemDir, objFileName), obj);
                File.WriteAllBytes(Path.Combine(systemDir, splatFileName), splatmap.EncodeToPNG());
                AssetDatabase.Refresh();
                Material mat = new Material(Shader.Find("Omega/Env/Terrain_NormalSpec_Array"));
                mat.name = terrain.name + "_Main_Material";
                mat.SetTexture("_Splat", AssetDatabase.LoadAssetAtPath<Texture2D>(Path.Combine(dir, splatFileName)));
                AssetDatabase.CreateAsset(mat, Path.Combine(dir, mat.name + ".mat"));
                ModelImporter importer = AssetImporter.GetAtPath(Path.Combine(dir, objFileName)) as ModelImporter;
                var sourceMaterials = typeof(ModelImporter)
                    .GetProperty("sourceMaterials", BindingFlags.NonPublic | BindingFlags.Instance)?
                    .GetValue(importer) as AssetImporter.SourceAssetIdentifier[];
                foreach (var identifier in sourceMaterials ?? Enumerable.Empty<AssetImporter.SourceAssetIdentifier>())
                {
                    importer.AddRemap(identifier, AssetDatabase.LoadAssetAtPath<Material>(Path.Combine(dir, mat.name + ".mat")));
                }
                importer.SaveAndReimport();
            }
        }

        [MenuItem("Tools/TerrainTools/ExportTerrainToFolder")]
        static void ExportTerrainToFolder()
        {
            var terrains = Selection.gameObjects
                .Select((go) => go.GetComponent<Terrain>())
                .Where((t) => t != null);
            foreach(var terrain in terrains)
            {
                var mesh = terrain
                    .ToMesh(64)
                    .Translated(Matrix4x4.Translate(terrain.transform.position));
                string obj = mesh.EncodeToObj();
                string path = EditorUtility.SaveFilePanelInProject("另存为", terrain.name, "obj", "另存为");
                path = path.Replace(@"Assets\", Application.dataPath + "/");
                if(!Directory.Exists(Path.GetDirectoryName(path)))
                {
                    Directory.CreateDirectory(Path.GetDirectoryName(path));
                }
                File.WriteAllText(path, obj);
            }
            AssetDatabase.Refresh();
        }

        [MenuItem("Tools/TerrainTools/ExportRoads")]
        static void ExportRoads()
        {
            string path = EditorUtility.SaveFilePanelInProject("导出到", "Road", "obj", "");
            Mesh mesh = new Mesh()
            {
                name = Path.GetFileNameWithoutExtension(path)
            };
            foreach(var go in Selection.gameObjects)
            {
                var m = go.GetComponent<MeshFilter>()?.sharedMesh;
                if(m != null)
                {
                    mesh.Merge(m, VertexAttributeMask.Tan);
                }
            }
            string obj = mesh.EncodeToObj();
            File.WriteAllText(path, obj);
            AssetDatabase.Refresh();
        }

        public static IEnumerable<(int, Texture2D)> GetAlphamapTextures(this TerrainData terrainData)
        {
            return Enumerable.Range(0, terrainData.alphamapLayers - 1)
                    .Select((idx) => (idx, terrainData.GetAlphamapTexture(idx)));
        }

        [MenuItem("Tools/TerrainTools/CreateTerrainPrefabs")]
        public static void CreatePrefab()
        {
            foreach(var go in Selection.gameObjects)
            {
                GameObject collision = new GameObject(go.name + "_collision");
                collision.AddComponent<MeshCollider>().sharedMesh = go.GetComponentInChildren<MeshFilter>().sharedMesh;
                collision.transform.SetParent(go.transform);
                string name = go.name.Replace(" ", "");
                PrefabUtility.SaveAsPrefabAsset(go, "Assets/PublicAssets/Prefabs/SceneObject/Terrain_3x3/" + name + ".prefab");
            }
        }

        [MenuItem("Tools/TerrainTools/AddTerrainPrefab")]
        public static void AddPrefab()
        {
            foreach(var rootGO in 
                Enumerable.Range(0, SceneManager.sceneCount)
                .SelectMany((sceneIdx) => SceneManager.GetSceneAt(sceneIdx).GetRootGameObjects()))
            {
                if(rootGO.name.Contains("Terrain_X"))
                {
                    var grounds = rootGO.transform.Find("Grounds");
                    foreach(var child in Enumerable.Range(0, grounds.transform.childCount).Select((childIdx) => grounds.transform.GetChild(childIdx)))
                    {
                        if(child.GetComponent<Terrain>() == null)
                        {
                            child.gameObject.SetActive(false);
                            try
                            {
                                var prefab = PrefabUtility.InstantiatePrefab(AssetDatabase.LoadAssetAtPath<GameObject>("Assets/PublicAssets/Prefabs/SceneObject/Terrain_3x3/" + rootGO.name.Replace(" ", "").Trim() + ".prefab")) as GameObject;
                                prefab.transform.SetParent(grounds);
                            }
                            catch(System.Exception e)
                            {
                                Debug.LogError(e.Message);
                            }
                        }
                    }
                }
            }
        }

        [MenuItem("Tools/TerrainTools/CaptureSmallMap")]
        public static void CaptureSmallMap()
        {
            Camera camera = Selection.GetFiltered<Camera>(SelectionMode.TopLevel).First();
            RenderTexture target = RenderTexture.GetTemporary(2048, 2048, 24, RenderTextureFormat.ARGB32);
            camera.targetTexture = target;
            camera.Render();
            string path = EditorUtility.SaveFilePanel("另存为", Application.dataPath, "Capture", "tga");
            target.Dump(path);
            RenderTexture.ReleaseTemporary(target);
        }

        [MenuItem("Tools/TerrainTools/ExportHeightMap")]
        static void Entry()
        {
            var terrains = Selection.gameObjects
                .Select((go) => go.GetComponent<Terrain>().terrainData)
                .Where((t) => t != null)
                .Concat(Selection.GetFiltered<TerrainData>(SelectionMode.Assets));
            foreach(var terrain in terrains)
            {
                string path = string.Format("{0}/HeightMaps/{1}.exr", Application.dataPath, terrain.name);
                string dir = Path.GetDirectoryName(path);
                if(!Directory.Exists(dir))
                {
                    Directory.CreateDirectory(dir);
                }
                terrain.ExportHeightMap(path);
            }
        }

        [MenuItem("Tools/TerrainTools/BuildTerrainGrounds")]
        public static void BuildTerrainGrounds()
        {
            Material roadMat = AssetDatabase.LoadAssetAtPath<Material>("Assets/Art/SceneObject/FBX/Ground_fbx/Materials/road_material.mat");
            //foreach(var scene in Enumerable.Range(0, SceneManager.sceneCount).Select(idx => SceneManager.GetSceneAt(idx)))
            foreach(var scene in Enumerable.Range(0, 1).Select(idx => SceneManager.GetSceneAt(idx)))
            {
                foreach(var terrain in scene.GetRootGameObjects().Where(go => go.name.StartsWith("Terrain_X")))
                {
                    var ground = terrain.transform.Find("Grounds");
                    if(ground == null)
                    {
                        Debug.LogErrorFormat("Missing Ground: {0}", terrain.name);
                        continue;
                    }
                    for(int i = ground.childCount - 1; i >= 0; --i)
                    {
                        if(!ground.GetChild(i).name.Contains("ater"))
                        {
                            Object.DestroyImmediate(ground.GetChild(i).gameObject, false);
                        }
                    }
                    GameObject terrainPrefab = new GameObject(terrain.name);
                    terrainPrefab.transform.SetParent(ground);
                    GameObject terrainLod = new GameObject(terrain.name + "_LOD0");
                    terrainLod.transform.SetParent(terrainPrefab.transform);

                    string folder = string.Format(
                        "Assets/World/world02/{0}/{1}/{2}", 
                        scene.name, 
                        terrain.name, 
                        terrain.name.Replace("Terrain_", "") + "_Grounds");
                    foreach(var model in AssetDatabase.FindAssets(
                            string.Format("{0} t:model", terrain.name), 
                            new[] { folder })
                        .Select(guid => AssetDatabase.GUIDToAssetPath(guid)))
                    {
                        AssetDatabase.DeleteAsset(model);
                    }
                    foreach(var collisionModel in AssetDatabase.FindAssets(
                            string.Format("{0} t:model", terrain.name),
                            new[] { "Assets/World/world02/TerrainCollision" })
                        .Select(guid => AssetDatabase.GUIDToAssetPath(guid))
                        .Where(name => name.EndsWith("FBX") || name.EndsWith("fbx")))
                    {
                        string fbxPath = Path.Combine(
                            folder, 
                            Path.GetFileName(collisionModel));
                        string fbxName = Path.GetFileNameWithoutExtension(fbxPath);
                        AssetDatabase.CopyAsset(collisionModel, fbxPath);
                        GameObject fbxGO = AssetDatabase.LoadAssetAtPath<GameObject>(fbxPath);
                        if(fbxGO == null)
                        {
                            Debug.LogErrorFormat("Missing Collision Frame: {0}", fbxPath);
                        }
                        foreach(var collisionMesh in fbxGO.GetComponentsInChildren<MeshFilter>().Select(mf => mf.sharedMesh))
                        {
                            var collision = new GameObject(collisionMesh.name);
                            collision.transform.SetParent(terrainPrefab.transform);
                            collision.AddComponent<MeshCollider>().sharedMesh = collisionMesh;
                        }
                    }
                    Debug.LogFormat("Procesing Terrain{0}:", terrain.name);
                    var lod = AssetDatabase.FindAssets(
                            string.Format("t:model {0}", terrain.name),
                            new[] { "Assets/World/world02/TerrainLOD" })
                        .Select(guid => AssetDatabase.GUIDToAssetPath(guid))
                        .Where(name => name.EndsWith("FBX") || name.EndsWith("fbx")).First();
                    {
                        string lodPath = Path.Combine(
                            folder, 
                            Path.GetFileName(lod));
                        AssetDatabase.CopyAsset(lod, lodPath);
                        ModelImporter importer = AssetImporter.GetAtPath(lodPath) as ModelImporter;
                        if(importer == null)
                        {
                            Debug.LogErrorFormat("Missing LOD frame: {0}", terrain.name);
                        }
                        //importer.importMaterials = true;
                        importer.materialImportMode = ModelImporterMaterialImportMode.ImportViaMaterialDescription;
                        importer.globalScale = 1.0f;
                        importer.SaveAndReimport();
                        if(importer == null)
                        {
                            Debug.LogErrorFormat("Empty Importer {0}", terrain.name);
                        }
                        var sourceMaterials = typeof(ModelImporter)
                            .GetProperty("sourceMaterials", BindingFlags.NonPublic | BindingFlags.Instance)?
                            .GetValue(importer) as AssetImporter.SourceAssetIdentifier[];
                        var terrainMat = AssetDatabase.LoadAssetAtPath<Material>(
                            Path.Combine(
                                Path.GetDirectoryName(lodPath), 
                                terrain.name + "_Main_Material.mat"));
                        List<Material> materials = new List<Material>();
                        for(int idx = 0; idx < sourceMaterials.Length; ++idx)
                        {
                            var mat = idx > 0 ? roadMat : terrainMat;
                            importer.AddRemap(sourceMaterials[idx], mat);
                            materials.Add(mat);
                        }
                        importer.SaveAndReimport();
                        terrainLod.AddComponent<MeshFilter>().sharedMesh = AssetDatabase.LoadAssetAtPath<Mesh>(lodPath);
                        terrainLod.AddComponent<MeshRenderer>().materials = materials.ToArray();
                    }
                    string prefabPath = Path.Combine(
                        "Assets/PublicAssets/Prefabs/SceneObject/Terrain_world02",
                        terrain.name + ".prefab");
                    AssetDatabase.DeleteAsset(prefabPath);
                    PrefabUtility.SaveAsPrefabAssetAndConnect(
                        terrainPrefab, 
                        prefabPath, 
                        InteractionMode.AutomatedAction);
                }
            }
        }

        public static void ExportHeightMap(this TerrainData terrainData, string path = "")
        {
            RenderTexture height = terrainData.heightmapTexture;
            Texture2D heightmap = new Texture2D(height.width, height.height, TextureFormat.RGBAFloat, false);
            RenderTexture.active = height;
            heightmap.ReadPixels(new Rect(0, 0, height.width, height.height), 0, 0);
            heightmap.Apply();
            byte[] exr = heightmap.EncodeToEXR(Texture2D.EXRFlags.None);
            if(string.IsNullOrEmpty(path))
            {
                path = EditorUtility.SaveFilePanelInProject("Export HeightMap", terrainData.name, "exr", "Export HeightMap");
            }
            using(var fs = File.Create(path))
            {
                using(var bw = new BinaryWriter(fs))
                {
                    bw.Write(exr);
                }
            }
            Object.DestroyImmediate(heightmap);
        }

        [MenuItem("Tools/TerrainTools/RaycastTest")]
        public static void RaycastTest()
        {
            Vector3 posTarget = new Vector3(0, 500, 0);
            int nLoopTimes = 8192;
            float step = 0.5f;
            Vector3[] pos = new Vector3[nLoopTimes * nLoopTimes];
            Vector3 vecBeginPos = posTarget;
            RaycastHit[] hitInfos = new RaycastHit[20];
            for (int x = 0; x < nLoopTimes; ++x)
            {
                posTarget.x = vecBeginPos.x + x * step;
                for (int z = 0; z < nLoopTimes; ++z)
                {
                    // ray for RayCast
                    posTarget.z = vecBeginPos.z + z * step;
                    Ray ray = new Ray(posTarget, Vector3.down);
                    // raycast for check the ground distance
                    int hits = Physics.RaycastNonAlloc(ray, hitInfos, 1000f, ~(1 << 4));
                    float height = 0;
                    for (int i = 0; i < hits; ++i)
                    {
                        RaycastHit hitInfo = hitInfos[i];
                        if (!(hitInfo.collider is CapsuleCollider))
                        {
                            height = Mathf.Max(hitInfos[i].point.y, height);
                        }
                    }
                    pos[x * nLoopTimes + z] = new Vector3(posTarget.x, height, posTarget.z);
                }
            }

            //SaveRayCastInfo
            string outPath = Application.dataPath + "/RayCastInfo.txt";       
            if (File.Exists(outPath))
                File.Delete(outPath);
            
            using(var sw = File.CreateText(outPath))
            {
                for (int i = 0; i < pos.Length; ++i)
                {                        
                    sw.WriteLine(
                        "{0},{1},{2}", 
                        pos[i].x.ToString("f3"), 
                        pos[i].y.ToString("f3"), 
                        pos[i].z.ToString("f3"));
                }
                sw.Flush();
                sw.Close();
            }
            Debug.LogFormat("Raycast info write to {0}", outPath);
        }
        
        [MenuItem("TerrainTools/CleanLocalPos")]
        public static void CleanLocalPos()
        {
            foreach (var boxCollider in Selection.gameObjects
                .SelectMany((go) => go.GetComponentsInChildren<BoxCollider>()))
            {
                Vector3 center = boxCollider.center;
                Vector3 scale = boxCollider.size;
                Transform transform = boxCollider.transform;
                boxCollider.center = Vector3.zero;
                boxCollider.size = Vector3.one;
                transform.localPosition += center;
                transform.localScale = Vector3.Scale(transform.localScale, scale);
                PrefabUtility.SavePrefabAsset(transform.root.gameObject);
            }
        }
    }
}