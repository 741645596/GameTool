using UnityEngine;

namespace OmegaEditor.Extension
{
    public static class TerrainToMesh
    {
        public static Mesh ToMesh(this Terrain terrain, int resolution)
        {
            TerrainData terrainData = terrain.terrainData;
            Vector2 size = new Vector2(terrainData.size.x, terrainData.size.z);
            Vector3 offset = new Vector3(size.x / 2, 0, size.y / 2);
            Vector3 position = terrain.GetPosition();
            Mesh mesh = PrimitiveMesh.Plane(size, new Vector2Int(resolution, resolution), offset);

            Vector3[] vertices = mesh.vertices;

            for (int i = 0; i < vertices.Length; ++i)
            {
                vertices[i].y = terrain.SampleHeight(vertices[i] + position);
            }

            mesh.vertices = vertices;
            mesh.RecalculateNormals();
            mesh.RecalculateTangents();

            return mesh;
        }
    }
}
