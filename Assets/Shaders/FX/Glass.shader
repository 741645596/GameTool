Shader "Unlit/Glass"
{
    Properties
    {
        _EnvMap ("Env Map", CUBE) = "white" {}
        _Reflection ("Reflection", Range(0, 1)) = 0.2
        _Fresnel ("Fresnel", Float) = 2
        _Alpha ("Alpha", Range(0, 1)) = 0.2
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "../Fog/FogCore.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos     : SV_POSITION;
                float3 normal  : NORMAL;
                float3 viewDir : TEXCOORD0;
            };

            samplerCUBE _EnvMap;
            float _Reflection;
            float _Fresnel;
            float _Alpha;

            v2f vert (appdata v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1));
                o.pos = mul(UNITY_MATRIX_VP, worldPos);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = normalize(UnityWorldSpaceViewDir(worldPos.xyz));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 refl = reflect(-i.viewDir, i.normal);
                fixed4 col = texCUBE(_EnvMap, refl);
                col.a = 0.5;
                float NoV = dot(i.normal, i.viewDir);
                col.a = 1 - pow(NoV, _Fresnel);
                col.a *= step(_Reflection, Luminance(col.rgb));
                col.a *= _Alpha;
                return col;
            }
            ENDCG
        }
    }
}
