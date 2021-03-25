#if !UNITY_EDITOR_OSX
using OmegaEditor.Coroutine;
using System;
using System.Collections;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using System.Threading;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using OmegaEditor.Extension;

namespace OmegaEditor.RecastNavigation
{
    [System.Serializable]
    public class RecastConfig
    {
        public float BoundMinX = -1000.0f;
        public float BoundMinY = -1000.0f;
        public float BoundMinZ = -1000.0f;
        public float BoundMaxX = 1000.0f;
        public float BoundMaxY = 1000.0f;
        public float BoundMaxZ = 1000.0f;
        public float CellSize = 4.0f;
        public float CellHeight = 0.2f;
        public float AgentHeight = 2.0f;
        public float AgentRadius = 0.6f;
        public float AgentMaxClimb = 2.0f;
        public float MaxEdgeLength = 12.0f;
        public float MaxEdgeError = 1.3f;
        public float MinRegionSize = 50.0f;
        public float RegionMergeSize = 20.0f;
        public float DetailSampleDistance = 6.0f;
        public float DetailSampleMaxError = 1.0f;
        public float AgentMaxSlope = 45.0f;
        public float TileSize = 32.0f;
        public uint VerticesPerPoly = 6;
        public int BorderOffest = 3;
        public int TileOffest = 2;
        public bool ShowNAVMeshInfo = false;
    }

    //[InitializeOnLoad]
    public class RecastBuilder : EditorWindow
    {
        private const string _navPathName = "RecastData";
        private const string _configFilePathName = "Assets/Editor/SceneDataExport/RecastWrapper/RecastConfig.bytes";
        private const uint _maxBufferCount = 200000;
        private static float[] _vertBuffer = new float[_maxBufferCount * 3];
        private static int[] _triBuffer = new int[_maxBufferCount * 3];

        private static int _debugInfoAvailableCount;
        private static Material _material = null;
        private static Color _drawColor = new Color(0.3137f, 0.9196f, 1.0f, 0.5f);
        private static RecastConfig _recastConfig = new RecastConfig();
        private const float _refereshDebugInfoTime = 0.5f;
        private static float _restRefereshDebugInfoTime = -1.0f;

        static RecastBuilder()
        {
            if (File.Exists(_configFilePathName))
            {
                Stream stream = File.Open(_configFilePathName, FileMode.Open);
                BinaryFormatter bin = new BinaryFormatter();
                _recastConfig = (RecastConfig)bin.Deserialize(stream);
                stream.Close();
                stream.Dispose();
            }
            else
            {
                Stream stream = File.Open(_configFilePathName, FileMode.OpenOrCreate);
                BinaryFormatter bin = new BinaryFormatter();
                bin.Serialize(stream, _recastConfig);
                stream.Close();
                stream.Dispose();
            }
            SetupConfigParameters();

            if (!Directory.Exists(_navPathName))
            {
                Directory.CreateDirectory(_navPathName);
            }
        }

        private static Mesh BuildDebugMesh()
        {
            int vertexCount = _debugInfoAvailableCount / 3;

            Mesh mesh = new Mesh();

            //if (vertexCount > ushort.MaxValue)
                mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;

            Vector3[] vertices = new Vector3[vertexCount];
            int[] triangles = new int[vertexCount];

            int destIndex;
            for (int vertexIndex = 0; vertexIndex < vertexCount; ++vertexIndex)
            {
                destIndex = 3 * vertexIndex;
                vertices[vertexIndex].x = _vertBuffer[destIndex];

                destIndex = 3 * vertexIndex + 1;
                vertices[vertexIndex].y = _vertBuffer[destIndex] + 1.0f;

                destIndex = 3 * vertexIndex + 2;
                vertices[vertexIndex].z = _vertBuffer[destIndex];

                triangles[vertexIndex] = vertexIndex;
            }
            mesh.vertices = vertices;
            mesh.triangles = triangles;

            return mesh;
        }

        [MenuItem("Tools/场景工具/Recast/修改配置")]
        public static void ShowWindow()
        {
            EditorWindow.GetWindow(typeof(RecastBuilder));
        }

        private static void SetParameterFromLineString(ref string lineString, out string parameterName,
            out string valueString)
        {
            parameterName = "";
            valueString = "";
            string[] fieldValue = lineString.Split('=');
            parameterName = fieldValue[0];
            valueString = fieldValue[1];
        }

        private static void SetParameter(ref string parameterName, ref string valueString)
        {
            if (parameterName == "fMinBoundX")
                _recastConfig.BoundMinX = float.Parse(valueString);
            else if (parameterName == "fMinBoundY")
                _recastConfig.BoundMinY = float.Parse(valueString);
            else if (parameterName == "fMinBoundZ")
                _recastConfig.BoundMinZ = float.Parse(valueString);
            else if (parameterName == "fMaxBoundX")
                _recastConfig.BoundMaxX = float.Parse(valueString);
            else if (parameterName == "fMaxBoundY")
                _recastConfig.BoundMaxY = float.Parse(valueString);
            else if (parameterName == "fMaxBoundZ")
                _recastConfig.BoundMaxZ = float.Parse(valueString);
            else if (parameterName == "fCellSize")
                _recastConfig.CellSize = float.Parse(valueString);
            else if (parameterName == "fCellHeight")
                _recastConfig.CellHeight = float.Parse(valueString);
            else if (parameterName == "fAgentHeight")
                _recastConfig.AgentHeight = float.Parse(valueString);
            else if (parameterName == "fAgentRadius")
                _recastConfig.AgentRadius = float.Parse(valueString);
            else if (parameterName == "fAgentMaxClimb")
                _recastConfig.AgentMaxClimb = float.Parse(valueString);
            else if (parameterName == "fEdgeMaxLen")
                _recastConfig.MaxEdgeLength = float.Parse(valueString);
            else if (parameterName == "fEdgeMaxError")
                _recastConfig.MaxEdgeError = float.Parse(valueString);
            else if (parameterName == "fRegionMinSize")
                _recastConfig.MinRegionSize = float.Parse(valueString);
            else if (parameterName == "fRegionMergeSize")
                _recastConfig.RegionMergeSize = float.Parse(valueString);
            else if (parameterName == "fDetailSampleDist")
                _recastConfig.DetailSampleDistance = float.Parse(valueString);
            else if (parameterName == "fDetailSampleMaxError")
                _recastConfig.DetailSampleMaxError = float.Parse(valueString);
            else if (parameterName == "fAgentMaxSlope")
                _recastConfig.AgentMaxSlope = float.Parse(valueString);
            else if (parameterName == "fTileSize")
                _recastConfig.TileSize = float.Parse(valueString);
            else if (parameterName == "szVertsPerPoly")
                _recastConfig.VerticesPerPoly = uint.Parse(valueString);
            else if (parameterName == "szBorderOffest")
                _recastConfig.BorderOffest = int.Parse(valueString);
            else if (parameterName == "szTileOffest")
                _recastConfig.TileOffest = int.Parse(valueString);
        }

        private static void SetupConfigParameters()
        {
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            sb.AppendFormat("fMinBoundX={0}", _recastConfig.BoundMinX);
            sb.AppendFormat(",fMinBoundY={0}", _recastConfig.BoundMinY);
            sb.AppendFormat(",fMinBoundZ={0}", _recastConfig.BoundMinZ);
            sb.AppendFormat(",fMaxBoundX={0}", _recastConfig.BoundMaxX);
            sb.AppendFormat(",fMaxBoundY={0}", _recastConfig.BoundMaxY);
            sb.AppendFormat(",fMaxBoundZ={0}", _recastConfig.BoundMaxZ);
            sb.AppendFormat(",fCellSize={0}", _recastConfig.CellSize);
            sb.AppendFormat(",fCellHeight={0}", _recastConfig.CellHeight);
            sb.AppendFormat(",fAgentHeight={0}", _recastConfig.AgentHeight);
            sb.AppendFormat(",fAgentRadius={0}", _recastConfig.AgentRadius);
            sb.AppendFormat(",fAgentMaxClimb={0}", _recastConfig.AgentMaxClimb);
            sb.AppendFormat(",fEdgeMaxLen={0}", _recastConfig.MaxEdgeLength);
            sb.AppendFormat(",fEdgeMaxError={0}", _recastConfig.MaxEdgeError);
            sb.AppendFormat(",fRegionMinSize={0}", _recastConfig.MinRegionSize);
            sb.AppendFormat(",fRegionMergeSize={0}", _recastConfig.RegionMergeSize);
            sb.AppendFormat(",fDetailSampleDist={0}", _recastConfig.DetailSampleDistance);
            sb.AppendFormat(",fDetailSampleMaxError={0}", _recastConfig.DetailSampleMaxError);
            sb.AppendFormat(",fAgentMaxSlope={0}", _recastConfig.AgentMaxSlope);
            sb.AppendFormat(",fTileSize={0}", _recastConfig.TileSize);
            sb.AppendFormat(",szVertsPerPoly={0}", _recastConfig.VerticesPerPoly);
            sb.AppendFormat(",szBorderOffest={0}", _recastConfig.BorderOffest);
            sb.AppendFormat(",szTileOffest={0}", _recastConfig.TileOffest);
            NAVMeshSystem.SetupBuildConfig(sb.ToString());
        }

        [MenuItem("Tools/场景工具/Recast/导出寻路网格")]
        public static void RebuildRecastNAV()
        {
            Action<float> setProgress;
            Action<string> setMessage;
            CustomAsyncOperation asyncOperation = new CustomAsyncOperation(out setProgress, out setMessage);
            EditorCoroutine.StartCoroutine(RebuildRecastNavRoutine(setProgress, setMessage));
            EditorProgressBar.DisplayProgressBar(asyncOperation);
        }

        public static IEnumerator RebuildRecastNavRoutine(Action<float> setProgress, Action<string> setMessage)
        {
            setMessage("Collecting Colliders");
            yield return null;
            Collider[] colliders = Resources.FindObjectsOfTypeAll<Collider>();

            Array.Clear(_vertBuffer, 0, _vertBuffer.Length);
            Array.Clear(_triBuffer, 0, _triBuffer.Length);
            uint vertexCount = 0;
            uint triangleBufferCount = 0;

            for (int i = 0; i < colliders.Length; ++i)
            {
                if (i % 10 == 0)
                {
                    setProgress((float)i / colliders.Length * 0.3f);
                    yield return null;
                }
                    
                Collider collider = colliders[i];
                if (!collider.gameObject.activeInHierarchy || collider.gameObject.layer == LayerMask.NameToLayer("Water"))
                    continue;

                Transform transform = collider.transform;
                Mesh mesh = GetMesh(collider);

                if (mesh == null)
                {
                    Debug.LogWarningFormat("Failed to fetch the mesh of " + collider.gameObject.name);
                    continue;
                }

                AppendMesh(mesh, transform, ref vertexCount, ref triangleBufferCount);
            }

            setMessage("Building Nav Mesh... (this can take a while)");
            yield return null; 

            if (vertexCount <= 0)
            {
                setProgress(1.0f);
                yield break;
            }

            Thread thread = 
                new Thread( () =>
                {
                    NAVMeshSystem.ConvertNAVMesh(0, _vertBuffer, vertexCount, _triBuffer, triangleBufferCount / 3);
                });
            thread.Start();
            while (thread.IsAlive)
            {
                yield return null;
            }

            _debugInfoAvailableCount = (int)NAVMeshSystem.BuildNAVMeshDebugInfo(0, _vertBuffer, _maxBufferCount);
            Mesh debugMesh = BuildDebugMesh();
            GameObject.CreatePrimitive(PrimitiveType.Cube).GetComponent<MeshFilter>().mesh = debugMesh;


            string sceneName = "world01";// EditorSceneManager.GetActiveScene().name;
            string navPath = _navPathName + "/" + sceneName;
            if (Directory.Exists(navPath))
            {
                Directory.Delete(navPath, true);
            }
            Directory.CreateDirectory(navPath);
            string filePathName = navPath + "/" + sceneName + ".bytes";
            NAVMeshSystem.SaveNAVMeshFile(0, filePathName);

            setProgress(1.0f);
        }

        public static Mesh GetMesh(Collider collider)
        {
            if (collider.GetType() == typeof(MeshCollider))
            {
                return (collider as MeshCollider).sharedMesh;
            }
            if(collider.GetType() == typeof(BoxCollider))
            {
                var box = collider as BoxCollider;
                return PrimitiveMesh.Cube(box.center, box.size);
            }
            if (collider.GetType() == typeof(TerrainCollider))
            {
                return null;//collider.GetComponent<Terrain>().ToMesh(256);
            }
            return null;
        }

        private static void AppendMesh(Mesh mesh, Transform transform, ref uint vertexCount, ref uint triangleBufferCount)
        {
            int[] triangles = mesh.triangles;
            for (int triIdx = 0; triIdx < triangles.Length; ++triIdx)
            {
                if (triangleBufferCount + triIdx >= _triBuffer.Length)
                {
                    Debug.LogError("超出_maxBufferCount");
                }
                _triBuffer[triangleBufferCount + triIdx] = triangles[triIdx] + (int)vertexCount;
            }
            triangleBufferCount += (uint)triangles.Length;

            Vector3[] vertices = mesh.vertices;
            for (int vertIdx = 0; vertIdx < vertices.Length; ++vertIdx)
            {
                Vector3 worldPos = transform
                    .localToWorldMatrix
                    .MultiplyPoint(vertices[vertIdx]);
                _vertBuffer[vertexCount * 3] = worldPos.x;
                _vertBuffer[vertexCount * 3 + 1] = worldPos.y;
                _vertBuffer[vertexCount * 3 + 2] = worldPos.z;
                ++vertexCount;
            }
        }

        private void OnGUI()
        {
            Bounds bounding = new Bounds();
            bounding.min = new Vector3(_recastConfig.BoundMinX, _recastConfig.BoundMinY, _recastConfig.BoundMinZ);
            bounding.max = new Vector3(_recastConfig.BoundMaxX, _recastConfig.BoundMaxY, _recastConfig.BoundMaxZ);
            bounding = EditorGUILayout.BoundsField("NAVSceneBound:", bounding);
            _recastConfig.BoundMinX = bounding.min.x;
            _recastConfig.BoundMinY = bounding.min.y;
            _recastConfig.BoundMinZ = bounding.min.z;
            _recastConfig.BoundMaxX = bounding.max.x;
            _recastConfig.BoundMaxY = bounding.max.y;
            _recastConfig.BoundMaxZ = bounding.max.z;
            _recastConfig.CellSize = EditorGUILayout.FloatField("CellSize", _recastConfig.CellSize);
            _recastConfig.CellHeight = EditorGUILayout.FloatField("CellHeight", _recastConfig.CellHeight);
            _recastConfig.AgentHeight = EditorGUILayout.FloatField("AgentHeight", _recastConfig.AgentHeight);
            _recastConfig.AgentRadius = EditorGUILayout.FloatField("AgentRadius", _recastConfig.AgentRadius);
            _recastConfig.AgentMaxClimb = EditorGUILayout.FloatField("AgentMaxClimb", _recastConfig.AgentMaxClimb);
            _recastConfig.MaxEdgeLength = EditorGUILayout.FloatField("MaxEdgeLength", _recastConfig.MaxEdgeLength);
            _recastConfig.MaxEdgeError = EditorGUILayout.FloatField("MaxEdgeError", _recastConfig.MaxEdgeError);
            _recastConfig.MinRegionSize = EditorGUILayout.FloatField("MinRegionSize", _recastConfig.MinRegionSize);
            _recastConfig.RegionMergeSize = EditorGUILayout.FloatField("RegionMergeSize", _recastConfig.RegionMergeSize);
            _recastConfig.DetailSampleDistance = EditorGUILayout.FloatField("DetailSampleDistance",
                _recastConfig.DetailSampleDistance);
            _recastConfig.DetailSampleMaxError = EditorGUILayout.FloatField("DetailSampleMaxError",
                _recastConfig.DetailSampleMaxError);
            _recastConfig.AgentMaxSlope = EditorGUILayout.FloatField("AgentMaxSlope", _recastConfig.AgentMaxSlope);
            _recastConfig.TileSize = EditorGUILayout.FloatField("TileSize", _recastConfig.TileSize);
            //_recastConfig.VerticesPerPoly = (uint)EditorGUILayout.IntField("VerticesPerPoly",
            //    (int)_recastConfig.VerticesPerPoly);
            //_recastConfig.BorderOffest = EditorGUILayout.IntField("BorderOffest", _recastConfig.BorderOffest);
            //_recastConfig.TileOffest = EditorGUILayout.IntField("TileOffest", _recastConfig.TileOffest);
            //_recastConfig.ShowNAVMeshInfo = EditorGUILayout.Toggle("ShowNAVMeshInfo", _recastConfig.ShowNAVMeshInfo);

            if (GUI.changed)
            {
                SetupConfigParameters();

                Stream stream = File.Open(_configFilePathName, FileMode.OpenOrCreate);
                BinaryFormatter bin = new BinaryFormatter();
                bin.Serialize(stream, _recastConfig);
                stream.Flush();
                stream.Close();
                stream.Dispose();
            }
            return;
        }
    }
}
#endif