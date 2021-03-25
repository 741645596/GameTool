using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text;
using UnityEngine;
using UnityEngine.Rendering;

namespace OmegaEditor.Extension
{

    public class MeshBuilder
    {
        Mesh m_mesh = null;
        public Mesh mesh
        {
            get
            {
                if (m_mesh == null)
                {
                    m_mesh = new Mesh();
                }
                return m_mesh;
            }
        }

        VertexAttributeMask channelMask = VertexAttribute.Position;

        public string name
        {
            get => mesh.name;
            set => mesh.name = value;
        }
        public void Append(Mesh mesh)
        {
            int vtxcount = this.mesh.vertexCount + mesh.vertexCount;
            foreach (var channel in channelMask)
            {
                var a = this.mesh.GetChannel(channel);
                var b = mesh.GetChannel(channel);
                var typeA = a.GetType().GetElementType();
                var typeB = b.GetType().GetElementType();
                if (typeA != typeB)
                {
                    throw new Exception("Attribute type mismatch");
                }
                var array = Array.CreateInstance(typeA, vtxcount);
                int idx = 0;
                for (int i = 0; i < a.Length; ++i)
                {
                    array.SetValue(a.GetValue(i), idx);
                    ++idx;
                }
                for (int j = 0; j < b.Length; ++j)
                {
                    array.SetValue(b.GetValue(j), idx);
                    ++idx;
                }
                this.mesh.SetChannel(channel, array);
            }
        }

        public static implicit operator Mesh(MeshBuilder meshBuilder)
        {
            return meshBuilder.mesh;
        }
    }
}
