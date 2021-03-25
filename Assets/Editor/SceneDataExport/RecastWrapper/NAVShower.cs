using System.Collections.Generic;
using BATTLE_ID = System.Int64;
using UnityEngine;

public class NAVShower : MonoBehaviour
{
    [SerializeField]
    private Shader _targetShader = null;
    private const uint _maxBufferCount = 30000000;

    public string usedSceneID;
    //private BATTLE_ID _sceneID;

    private float[] _tempFloatBuffer = new float[_maxBufferCount * 3];
    private Material _material = null;
    private Color _drawColor = new Color(0.3137f, 0.9196f, 1.0f, 0.5f);
    //private Mesh _debugMesh = null;
    private static List<Mesh> _debugMeshs = new List<Mesh>();
    private uint _debugInfoAvailableCount;

    private void Awake()
    {
        NAVMeshSystem.AfterBuildNAVFromMemoryData += AfterBuildNAVFromMemoryData;
        SetupDebugMeshAndMaterial();
    }
    private void OnDestroy()
    {
        NAVMeshSystem.AfterBuildNAVFromMemoryData -= AfterBuildNAVFromMemoryData;
    }

    public void AfterBuildNAVFromMemoryData(BATTLE_ID sceneID)
    {
        _debugInfoAvailableCount = NAVMeshSystem.BuildNAVMeshDebugInfo(sceneID, _tempFloatBuffer, _maxBufferCount);
        SetupDebugMesh();
    }


    private void SetupDebugMeshAndMaterial()
    {
        //if (!_debugMesh)
            //_debugMesh = new Mesh();
        if ((!_material) && (_targetShader != null))
        {
            _material = new Material(_targetShader);
            _material.SetColor("_Color", _drawColor);
        }
    }
    
    private void LateUpdate()
    {
        //if ((!_debugMesh) || (!_material))
        if((_debugMeshs.Count == 0) || (!_material))
            return;
        _material.SetPass(0);
        var element = _debugMeshs.GetEnumerator();
        while (element.MoveNext())
        {
            Graphics.DrawMesh(element.Current, Matrix4x4.identity, _material, 0);
        }
        element.Dispose();
        //Graphics.DrawMesh(_debugMesh, Matrix4x4.identity, _material, 0);
    }

    public void SetupDebugMesh()
    {
        int vertexCount = (int)_debugInfoAvailableCount / 3;
        int meshCounts = vertexCount / 65535;
        if (vertexCount % 65535 > 0)
            ++meshCounts;

        for (int meshIndex = 0; meshIndex < meshCounts; ++meshIndex)
            //for (int meshIndex = 0; meshIndex < 2; ++meshIndex)
            BuildMesh(meshIndex, vertexCount);

        //_debugMesh.Clear();
        //int vertexCount = (int)_debugInfoAvailableCount / 3;

        //Vector3[] vertices = new Vector3[vertexCount];
        //int[] triangles = new int[vertexCount];

        //int destIndex;
        //for (int vertexIndex = 0; vertexIndex < vertexCount; ++vertexIndex)
        //{
        //    destIndex = 3 * vertexIndex;
        //    vertices[vertexIndex].x = _tempFloatBuffer[destIndex];

        //    destIndex = 3 * vertexIndex + 1;
        //    vertices[vertexIndex].y = _tempFloatBuffer[destIndex];

        //    destIndex = 3 * vertexIndex + 2;
        //    vertices[vertexIndex].z = _tempFloatBuffer[destIndex];

        //    triangles[vertexIndex] = vertexIndex;
        //}
        //_debugMesh.vertices = vertices;
        //_debugMesh.triangles = triangles;
    }

    private void BuildMesh(int meshIndex, int vertexCount)
    {
        if (meshIndex == 1)
        {
            int akilar = 10;
        }
        Mesh mesh = new Mesh();
        //int destVertexCount = 65535;
        //if (65535 * (meshIndex + 1) > vertexCount)
        //destVertexCount = vertexCount% 65535;


        int destVertexCount = 65535 * (meshIndex + 1) < vertexCount ? 65535 : vertexCount % 65535;

        Vector3[] vertices = new Vector3[destVertexCount];
        int[] triangles = new int[destVertexCount];

        int destVertexIndex;
        int destIndex;
        for (int vertexIndex = 0; vertexIndex < destVertexCount; ++vertexIndex)
        {
            destVertexIndex = vertexIndex + 65535 * meshIndex;
            destIndex = 3 * destVertexIndex;
            vertices[vertexIndex].x = _tempFloatBuffer[destIndex];

            destIndex = 3 * destVertexIndex + 1;
            float value = _tempFloatBuffer[destIndex];
            vertices[vertexIndex].y = _tempFloatBuffer[destIndex] + 5.0f;

            destIndex = 3 * destVertexIndex + 2;
            vertices[vertexIndex].z = _tempFloatBuffer[destIndex];

            triangles[vertexIndex] = vertexIndex;
        }
        mesh.vertices = vertices;
        mesh.triangles = triangles;
        _debugMeshs.Add(mesh);
    }

    //private void Start()
    //{
    //    if (BATTLE_ID.TryParse(usedSceneID, out _sceneID) == false)
    //    {
    //        _sceneID = 1;
    //    }
    //}
}
