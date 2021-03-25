Shader "Unlit/WorldLOD"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Header(ZBias)]
        _OffsetFactor("Offset Factor", Float) = 0
        _OffsetUnits("Offset Units", Float) = 0
    }
        SubShader
    {
        Tags { "RenderType" = "Geometry" }
        LOD 100
        Offset[_OffsetFactor],[_OffsetUnits]
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "../Fog/FogCore.cginc"

            struct appdata
            {
                float4 vertex   : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                half   fogCoord : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _GridRegion;
            float4 _LightMapFactor;
            float _CullWorldLOD;

            v2f vert (appdata v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1));
                o.vertex = mul(UNITY_MATRIX_VP, worldPos);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldPos = worldPos.xyz;
                o.fogCoord = GetFogCoord(o.vertex, worldPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed c = _GridRegion.x - i.worldPos.x;
                c = max(c, i.worldPos.x - _GridRegion.y);
                c = max(c, _GridRegion.z - i.worldPos.z);
                c = max(c, i.worldPos.z - _GridRegion.w);
                c *= _CullWorldLOD;
                clip(c + 0.01);
                col.rgb *= _LightMapFactor.rgb;
                col.rgb = ApplySunFog(col.rgb, i.fogCoord, UnityWorldSpaceViewDir(i.worldPos));
                return col;
            }
            ENDCG
        }
    }
}
