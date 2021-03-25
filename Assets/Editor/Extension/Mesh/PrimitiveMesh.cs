using UnityEngine;
using UnityEngine.Rendering;

namespace OmegaEditor.Extension
{
    public static class PrimitiveMesh
    {
        public static Mesh Plane(Vector2 size, Vector2Int cells)
        {
            return Plane(size, cells, Vector3.zero);
        }
        public static Mesh Plane(Vector2 size, Vector2Int cells, Vector3 position)
        {
            Mesh mesh = new Mesh();

            Vector2 cellSize = size / cells;
            Vector3 center = new Vector3(size.x / 2f, 0f, size.y / 2f);

            Vector3[] vertices = new Vector3[(cells.x + 1) * (cells.y + 1)];
            Vector3[] normals = new Vector3[(cells.x + 1) * (cells.y + 1)];
            Vector2[] uv = new Vector2[(cells.x + 1) * (cells.y + 1)];
            int[] triangles = new int[cells.x * cells.y * 2 * 3];

            int vertIdx = 0;
            for (int z = 0; z <= cells.y; ++z)
            {
                for (int x = 0; x <= cells.x; ++x)
                {
                    Vector3 vertex = new Vector3(x * cellSize.x, 0, z * cellSize.y);
                    vertex = vertex - center + position;
                    vertices[vertIdx] = vertex;
                    normals[vertIdx] = Vector3.up;
                    uv[vertIdx] = new Vector2((float)x / cells.x, (float)z / cells.y);
                    ++vertIdx;
                }
            }

            int triIdx = 0;
            for (int z = 0; z < cells.y; ++z)
            {
                int idxOffsetA = z * (cells.x + 1);
                int idxOffsetC = (z + 1) * (cells.x + 1);
                for (int x = 0; x < cells.x; ++x)
                {
                    int idxA = x + idxOffsetA;
                    int idxC = x + idxOffsetC;
                    triangles[triIdx++] = idxA;
                    triangles[triIdx++] = idxC + 1;
                    triangles[triIdx++] = idxA + 1;

                    triangles[triIdx++] = idxA;
                    triangles[triIdx++] = idxC;
                    triangles[triIdx++] = idxC + 1;
                }
            }

            if (vertices.Length > ushort.MaxValue)
            {
                mesh.indexFormat = IndexFormat.UInt32;
            }

            mesh.vertices = vertices;
            mesh.normals = normals;
            mesh.uv = uv;
            mesh.triangles = triangles;

            return mesh;
        }

        public static Mesh Plane(Vector2 size, Vector2Int cells, Vector3 position, Vector3 normal)
        {
            Mesh mesh = Plane(size, cells);
            Quaternion rotation = Quaternion.FromToRotation(Vector3.up, normal);
            return mesh.Translated(Matrix4x4.TRS(position, rotation, Vector3.one));
        }

        public static Mesh Cube(Vector3 position, Vector3 size)
        {
            Vector3 halfSize = 0.5f * size;
            Mesh up = Plane(
                new Vector2(size.x, size.z),
                Vector2Int.one,
                halfSize.Scaled(Vector3.up));
            Mesh down = Plane(
                new Vector2(size.x, size.z),
                Vector2Int.one,
                halfSize.Scaled(-Vector3.up),
                Vector3.down);
            Mesh right = Plane(
                new Vector2(size.y, size.z),
                Vector2Int.one,
                halfSize.Scaled(Vector3.right),
                Vector3.right);
            Mesh left = Plane(
                new Vector2(size.y, size.z),
                Vector2Int.one,
                halfSize.Scaled(-Vector3.right),
                Vector3.left);
            Mesh front = Plane(
                new Vector2(size.x, size.y),
                Vector2Int.one,
                halfSize.Scaled(Vector3.forward),
                Vector3.forward);
            Mesh back = Plane(
                new Vector2(size.x, size.y),
                Vector2Int.one,
                halfSize.Scaled(-Vector3.forward),
                Vector3.back);
            Mesh cube = new Mesh();
            cube.Merge(up);
            cube.Merge(down);
            cube.Merge(right);
            cube.Merge(left);
            cube.Merge(front);
            cube.Merge(back);
            return cube;
        }

        /*TODO
        public static Mesh Sphere(float radius, Vector3 position)
        {
            return null;
        }
        */
    }
}
