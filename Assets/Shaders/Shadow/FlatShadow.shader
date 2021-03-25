Shader "Omega/Shadow/FlatShadow"
{
    Properties
    {
        _PlaneHeight("Plane Height", Float) = 0.0
        _Intensity("Intensity", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "LightMode"="ForwardBase" "Queue"="Transparent"}
        ZTest LEqual
        ZWrite Off
        Offset -1, -1
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            float _PlaneHeight;
            float _Intensity;

            float4 vert (float4 vertex : POSITION) : SV_POSITION
            {
                float4 worldPos = mul(unity_ObjectToWorld, float4(vertex.xyz, 1));
                float3 lightDir = -normalize(UnityWorldSpaceLightDir(worldPos.xyz));
                float t = (_PlaneHeight - worldPos.y) / lightDir.y;
                t = max(0, t);
                float3 shadowPos = worldPos + t * lightDir;
                return mul(UNITY_MATRIX_VP, float4(shadowPos, 1));
            }

            fixed4 frag () : SV_Target
            {
                return fixed4(0, 0, 0, _Intensity);
            }
            ENDCG
        }
    }
}
