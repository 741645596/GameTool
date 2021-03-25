using UnityEngine;

namespace OmegaEditor.TerrainEditor
{
    public class RampMap
    {
        protected Texture2D texture;

        public int size
        {
            get
            {
                return texture == null ? 0 : texture.width;
            }
        }
        public RampMap(AnimationCurve curve, int size)
        {
            texture = new Texture2D(size, 1, TextureFormat.RGBA32, false);
            texture.wrapMode = TextureWrapMode.Clamp;
            Update(curve);
        }

        public void Update(AnimationCurve curve)
        {
            for (int u = 0; u < texture.width; ++u)
            {
                float val = curve.Evaluate((u + 0.5f) / texture.width);
                texture.SetPixel(u, 0, new Color(val, val, val));
            }
            texture.Apply();
        }

        public static implicit operator Texture2D(RampMap rampMap)
        {
            if (rampMap != null && rampMap.texture != null)
                return rampMap.texture;
            else return null;
        }
    }
}