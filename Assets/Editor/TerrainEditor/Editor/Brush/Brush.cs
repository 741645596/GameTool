using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace OmegaEditor.TerrainEditor
{
    public class Brush
    {
        [SerializeField] protected Texture2D m_texture;
        [SerializeField] protected string m_name;

        public static implicit operator Texture(Brush brush)
        {
            return brush.m_texture;
        }
    }
}