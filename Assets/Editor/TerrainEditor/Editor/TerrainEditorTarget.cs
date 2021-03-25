using UnityEngine;
using UnityEngine.Events;

namespace OmegaEditor.TerrainEditor
{
    public class TerrainEditorTarget
    {
        public GameObject gameObject
        {
            get => m_gameObject;
            set
            {
                if (value != null && value != gameObject)
                {
                    MeshRenderer renderer = value.GetComponent<MeshRenderer>();
                    Material terrainMat;
                    if (TryGetTerrainMaterial(renderer, out terrainMat))
                    {
                        material = terrainMat;
                        collider = null;
                        var oldValue = m_gameObject;
                        m_gameObject = value;
                        if (onTargetChanged != null)
                            onTargetChanged.Invoke();
                    }
                }
            }
        }
        public Collider   collider
        {
            get => m_collider;
            set
            {
                if (collider != null)
                {
                    Object.DestroyImmediate(collider, false);
                }
                m_collider = value;
            }
        }
        public Material   material
        {
            get => m_material;
            protected set
            {
                if (material != null)
                {
                    material.shader = TerrainEditor.terrainShader;
                    material.SetTexture("_Splat", srcSplat);
                }
                m_material = value;
                srcSplat = material.GetTexture("_Splat");
            }
        }
        public Shader     shader
        {
            get => material?.shader;
            set
            {
                if (material != null)
                {
                    material.shader = value;
                }
            }
        }
        public Texture    albedo
        {
            get => material ? material.GetTexture("_MainTexArray") : null;
            set
            {
                if (material != null)
                {
                    material.SetTexture("_MainTexArray", value);
                }
            }
        }
        public Texture    bump
        {
            get => material ? material.GetTexture("_BumpMapArray") : null;
            set
            {
                if (material != null)
                {
                    material.SetTexture("_BumpMapArray", value);
                }
            }
        }
        public Texture    splat
        {
            get => material ? material.GetTexture("_Splat") : null;
            set
            {
                if (material != null)
                {
                    material.SetTexture("_Splat", value);
                }
            }
        }
        public Texture    srcSplat;
        public Texture    brush
        {
            get => material ? material.GetTexture("_Brush") : null;
            set
            {
                if (material != null)
                {
                    material.SetTexture("_Brush", value);
                }
            }
        }
        public Vector2    cursor
        {
            get => material ? material.GetVector("_Cursor") : Vector4.zero;
            set
            {
                if (material != null)
                {
                    material.SetVector("_Cursor", value);
                }
            }
        }
        public float      brushSize
        {
            get => material ? material.GetFloat("_BrushScale") : 0f;
            set
            {
                if (material != null)
                {
                    material.SetFloat("_BrushScale", value);
                }
            }
        }
        public float density
        {
            get => material ? material.GetFloat("_Density") : 0f;
            set
            {
                if (material != null)
                {
                    material.SetFloat("_Density", value);
                }
            }
        }

        public UnityAction onTargetChanged;

        protected bool TryGetTerrainMaterial(MeshRenderer renderer, out Material terrainMat)
        {
            foreach (var mat in renderer.sharedMaterials)
            {
                if (mat.shader == TerrainEditor.terrainShader)
                {
                    terrainMat = mat;
                    return true;
                } 
            }
            terrainMat = null;
            return false;
        }

        protected GameObject m_gameObject;
        protected Collider   m_collider;
        protected Material   m_material;
    }
}