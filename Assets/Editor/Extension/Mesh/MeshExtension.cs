using System;
using System.Collections.Generic;
using System.Reflection;
using System.Text;
using UnityEngine;
using UnityEngine.Rendering;

namespace OmegaEditor.Extension
{
    public static class MeshExtension
    {
        public static void Merge(this Mesh mesh, Mesh other, IEnumerable<VertexAttribute> channels)
        {

        }
        public static void Merge(this Mesh mesh, Mesh other, params VertexAttribute[] channels)
        {
            List<Vector3> vertices = new List<Vector3>(mesh.vertices);
            List<Vector3> normals = new List<Vector3>(mesh.normals);
            List<int> triangles = new List<int>(mesh.triangles);
            foreach (var it in other.triangles)
            {
                triangles.Add(it + vertices.Count);
            }
            vertices.AddRange(other.vertices);
            normals.AddRange(other.normals);

            if ((uint)vertices.Count > uint.MaxValue)
            {
                mesh.indexFormat = IndexFormat.UInt32;
            }

            mesh.vertices = vertices.ToArray();
            mesh.normals = normals.ToArray();
            mesh.uv = new Vector2[vertices.Count];
            mesh.triangles = triangles.ToArray();
        }

        public static Mesh Merge(this Mesh[] submesh)
        {
            Mesh merged = new Mesh();
            merged.indexFormat = IndexFormat.UInt32;
            List<Vector3> vertices = new List<Vector3>();
            List<Vector3> normals = new List<Vector3>();
            //List<Vector2> uv = new List<Vector2>();
            List<int> triangles = new List<int>();
            foreach (var mesh in submesh)
            {
                Debug.Log(mesh.indexFormat);
                int idxOffset = vertices.Count;
                foreach (var idx in mesh.triangles)
                {
                    triangles.Add(idx + idxOffset);
                }
                vertices.AddRange(mesh.vertices);
                normals.AddRange(mesh.normals);
                //uv.AddRange(mesh.uv);
            }
            merged.vertices = vertices.ToArray();
            merged.normals = normals.ToArray();
            //merged.uv = uv.ToArray();
            merged.triangles = triangles.ToArray();
            return merged;
        }

        public static Array GetChannel(this Mesh mesh, VertexAttribute channel)
        {
            switch (channel)
            {
                case VertexAttribute.Position: return mesh.vertices;
                case VertexAttribute.Normal: return mesh.normals;
                case VertexAttribute.Tangent: return mesh.tangents;
                case VertexAttribute.Color: return mesh.colors;
                case VertexAttribute.TexCoord0: return mesh.uv;
                case VertexAttribute.TexCoord1: return mesh.uv2;
                case VertexAttribute.TexCoord2: return mesh.uv3;
                case VertexAttribute.TexCoord3: return mesh.uv4;
                case VertexAttribute.TexCoord4: return mesh.uv5;
                case VertexAttribute.TexCoord5: return mesh.uv6;
                case VertexAttribute.TexCoord6: return mesh.uv7;
                case VertexAttribute.TexCoord7: return mesh.uv8;
                default: return new object[0];
            }
        }

        public static void SetChannel(this Mesh mesh, VertexAttribute channel, Array attributes)
        {
            if (attributes is Vector2[])
            {
                switch (channel)
                {
                    case VertexAttribute.TexCoord0:
                        {
                            mesh.uv = attributes as Vector2[];
                            break;
                        }
                    case VertexAttribute.TexCoord1:
                        {
                            mesh.uv2 = attributes as Vector2[];
                            break;
                        }
                    case VertexAttribute.TexCoord2:
                        {
                            mesh.uv3 = attributes as Vector2[];
                            break;
                        }
                    case VertexAttribute.TexCoord3:
                        {
                            mesh.uv4 = attributes as Vector2[];
                            break;
                        }
                    case VertexAttribute.TexCoord4:
                        {
                            mesh.uv5 = attributes as Vector2[];
                            break;
                        }
                    case VertexAttribute.TexCoord5:
                        {
                            mesh.uv6 = attributes as Vector2[];
                            break;
                        }
                    case VertexAttribute.TexCoord6:
                        {
                            mesh.uv7 = attributes as Vector2[];
                            break;
                        }
                    case VertexAttribute.TexCoord7:
                        {
                            mesh.uv8 = attributes as Vector2[];
                            break;
                        }
                }
            }
            if (attributes is Vector3[])
            {
                switch (channel)
                {
                    case VertexAttribute.Position:
                        {
                            mesh.vertices = attributes as Vector3[];
                            break;
                        }
                    case VertexAttribute.Normal:
                        {
                            mesh.normals = attributes as Vector3[];
                            break;
                        }
                }
            }
            if (attributes is Vector4[] && channel == VertexAttribute.Tangent)
            {
                mesh.tangents = attributes as Vector4[]; ;
            }
            if (attributes is Color[] && channel == VertexAttribute.Color)
            {
                mesh.colors = attributes as Color[];
            }
            if (attributes is BoneWeight[] && channel == VertexAttribute.BlendWeight)
            {
                mesh.boneWeights = attributes as BoneWeight[];
            }
        }

        public static bool HasChannel(this Mesh mesh, VertexAttribute channel)
        {
            Type tMesh = typeof(Mesh);
            MethodInfo hasChannel = tMesh.GetMethod("HasVertexAttribute");
            if (hasChannel == null)
            {
                Debug.LogError("Null");
            }
            return (bool)hasChannel.Invoke(mesh, new object[] { channel });
        }

        public static Mesh Clone(this Mesh mesh)
        {
            return new Mesh()
            {
                indexFormat = mesh.indexFormat,
                vertices = mesh.vertices,
                normals = mesh.normals,
                tangents = mesh.tangents,
                uv = mesh.uv,
                uv2 = mesh.uv2,
                uv3 = mesh.uv3,
                uv4 = mesh.uv4,
                uv5 = mesh.uv5,
                uv6 = mesh.uv6,
                uv7 = mesh.uv7,
                uv8 = mesh.uv8,
                colors = mesh.colors,
                triangles = mesh.triangles
            };
        }

        public static Mesh Clone(this Mesh mesh, VertexAttributeMask attributes)
        {
            Mesh clone = new Mesh();
            {
                clone.indexFormat = mesh.indexFormat;
                clone.vertices = mesh.vertices;
                if (attributes[VertexAttribute.Normal])
                    clone.normals = mesh.normals;
                if (attributes[VertexAttribute.Tangent])
                    clone.tangents = mesh.tangents;
                if (attributes[VertexAttribute.Color])
                    clone.colors = mesh.colors;
                if (attributes[VertexAttribute.TexCoord0])
                    clone.uv = mesh.uv;
                if (attributes[VertexAttribute.TexCoord1])
                    clone.uv = mesh.uv2;
                if (attributes[VertexAttribute.TexCoord2])
                    clone.uv = mesh.uv3;
                if (attributes[VertexAttribute.TexCoord3])
                    clone.uv = mesh.uv4;
                if (attributes[VertexAttribute.TexCoord4])
                    clone.uv = mesh.uv5;
                if (attributes[VertexAttribute.TexCoord5])
                    clone.uv = mesh.uv6;
                if (attributes[VertexAttribute.TexCoord6])
                    clone.uv = mesh.uv7;
                if (attributes[VertexAttribute.TexCoord7])
                    clone.uv = mesh.uv8;
                if (attributes[VertexAttribute.BlendWeight])
                    clone.boneWeights = mesh.boneWeights;
            }
            return clone;
        }

        public static Mesh Translated(this Mesh mesh, Matrix4x4 translation)
        {
            Mesh translated = mesh.Clone();
            Vector3[] vertices = mesh.vertices;
            Vector3[] normals = mesh.normals;
            Vector4[] tangents = mesh.tangents;
            for (int i = 0; i < vertices.Length; ++i)
            {
                Vector4 vert = vertices[i];
                vert.w = 1;
                vertices[i] = translation * vert;
            }
            for (int i = 0; i < normals.Length; ++i)
            {
                Vector4 norm = normals[i];
                norm.w = 0;
                normals[i] = translation * norm;
            }
            for (int i = 0; i < tangents.Length; ++i)
            {
                Vector4 tan = tangents[i];
                tan.w = 0;
                tan = translation * tan;
                tangents[i] = new Vector4(tan.x, tan.y, tan.z, tangents[i].w);
            }
            translated.vertices = vertices;
            if (normals.Length > 0)
                translated.normals = normals;
            if (tangents.Length > 0)
                translated.tangents = tangents;
            return translated;
        }

        public static float GetRuntimeMemorySizeKB(this Mesh mesh)
        {
            return UnityEngine.Profiling.Profiler.GetRuntimeMemorySizeLong(mesh) / 1024f;
        }

        public static float GetStorageMemorySizeKB(this Mesh mesh)
        {
            int vertSize = 4 * 3;
            if (mesh.normals.Length > 0)
                vertSize += 4 * 3;
            if (mesh.tangents.Length > 0)
                vertSize += 4 * 4;
            if (mesh.colors.Length > 0)
                vertSize += 4;
            if (mesh.uv.Length > 0)
                vertSize += 4 * 2;
            if (mesh.uv2.Length > 0)
                vertSize += 4 * 2;
            if (mesh.uv3.Length > 0)
                vertSize += 4 * 2;
            if (mesh.uv4.Length > 0)
                vertSize += 4 * 2;
            if (mesh.uv5.Length > 0)
                vertSize += 4 * 2;
            if (mesh.uv6.Length > 0)
                vertSize += 4 * 2;
            if (mesh.uv7.Length > 0)
                vertSize += 4 * 2;
            if (mesh.uv8.Length > 0)
                vertSize += 4 * 2;
            int triSize = mesh.indexFormat == IndexFormat.UInt16 ? 2 * 3 : 4 * 3;
            vertSize *= mesh.vertices.Length;
            triSize *= mesh.triangles.Length / 3;
            int size = (vertSize + triSize);
            return size / 1024f;
        }

        public static string GetInfo(this Mesh mesh)
        {
            StringBuilder info = new StringBuilder();
            info.AppendFormat(
                "{0} verts {1} tris", 
                mesh.vertices.Length, 
                mesh.triangles.Length / 3);
            float size = mesh.GetRuntimeMemorySizeKB();
            if (size >= 1024)
            {
                size /= 1024f;
                info.AppendFormat(" {0}MB", size.ToString("F2"));
            }
            else
            {
                info.AppendFormat(" {0}KB", size.ToString("F2"));
            }
            return info.ToString();
        }
    }
}