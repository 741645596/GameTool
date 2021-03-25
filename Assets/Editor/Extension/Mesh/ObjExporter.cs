using System.IO;
using System.Text;
using UnityEngine;

namespace OmegaEditor.Extension
{

    public static class ObjExporter
    {
        public static string EncodeToObj(this Mesh mesh)
        {
            StringBuilder obj = new StringBuilder();

            obj.AppendFormat("g m_{0} \n", mesh.name);
            foreach (Vector3 v in mesh.vertices)
            {
                obj.Append(string.Format("v {0} {1} {2}\n", v.x, v.y, v.z));
            }
            obj.Append("\n");
            foreach (Vector3 vn in mesh.normals)
            {
                obj.Append(string.Format("vn {0} {1} {2}\n", vn.x, vn.y, vn.z));
            }
            obj.Append("\n");
            Vector2[] uv = mesh.uv;
            if (mesh.uv.Length == 0)
            {
                uv = new Vector2[mesh.vertices.Length];
            }
            foreach (Vector2 vt in mesh.uv)
            {
                obj.Append(string.Format("vt {0} {1}\n", vt.x, vt.y));
            }
            obj.Append("usemtl default \n");
            int[] triangles = mesh.triangles;
            for (int i = 0; i < triangles.Length; i += 3)
            {
                obj.Append(string.Format("f {0} {1} {2}\n",
                    triangles[i] + 1, triangles[i + 1] + 1, triangles[i + 2] + 1));
            }
            return obj.ToString();
        }
        public static void DumpObj(this Mesh mesh, string fileName)
        {
            string obj = mesh.EncodeToObj();
            using (StreamWriter sw = new StreamWriter(fileName))
            {
                sw.Write(obj.ToString());
            }
        }
    }
}
