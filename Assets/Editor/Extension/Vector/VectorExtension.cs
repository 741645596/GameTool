using UnityEngine;
namespace OmegaEditor.Extension
{
    public static class VectorExtension
    {
        public static Vector3 Scaled(this Vector3 vec, Vector3 scalar)
        {
            Vector3 scaled = vec;
            scaled.Scale(scalar);
            return scaled;
        }
    }
}