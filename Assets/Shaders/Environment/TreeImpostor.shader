Shader "Omega/Env/TreeImpostor" {
    Properties{
        _MainTex("Base (RGB) Trans (A)", 2D) = "white" {}
    }

        SubShader{
            Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
            LOD 100

            ZWrite Off
            Cull off
            Blend SrcAlpha OneMinusSrcAlpha
            
            Pass {
                CGPROGRAM
                    #pragma multi_compile _ _WORLD_GRID_CULL
                    #pragma vertex vert
                    #pragma fragment frag
                    #pragma target 2.0
                    #pragma multi_compile_fog
                    #pragma multi_compile_instancing

                    #include "UnityCG.cginc"
                    #include "../Fog/FogCore.cginc"

                    struct appdata_t {
                        float4 vertex : POSITION;
                        float2 texcoord : TEXCOORD0;
                        UNITY_VERTEX_INPUT_INSTANCE_ID
                    };

                    struct v2f {
                        float4 vertex : SV_POSITION;
                        float2 texcoord : TEXCOORD0;
                        float3 worldPos : TEXCOORD1;
                        half   fogCoord : TEXCOORD2;
                    };

                    sampler2D _MainTex;
                    float4 _MainTex_ST;
                    float4 _LightColor0;
                    float4 _GridRegion;
                    half _CullWorldLOD;

                    v2f vert(appdata_t v)
                    {
                        v2f o;
                        UNITY_SETUP_INSTANCE_ID(v);
                        UNITY_INITIALIZE_OUTPUT(v2f, o);
                        float4 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1));
                        o.vertex = mul(UNITY_MATRIX_VP, worldPos);
                        o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                        o.worldPos = worldPos.xyz;
                        o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                        o.fogCoord = GetFogCoord(o.vertex, worldPos);
                        return o;
                    }

                    fixed4 frag(v2f i) : SV_Target
                    {
                    #ifdef _WORLD_GRID_CULL
                        fixed c = _GridRegion.x - i.worldPos.x;
                        c = max(c, i.worldPos.x - _GridRegion.y);
                        c = max(c, _GridRegion.z - i.worldPos.z);
                        c = max(c, i.worldPos.z - _GridRegion.w);
                        c *= _CullWorldLOD;
                        clip(c + 0.01);
                    #endif
                        fixed4 col = tex2D(_MainTex, i.texcoord);
                        col.rgb *= _LightColor0.rgb * 1.5;
                        
                        col.rgb = ApplySunFog(col.rgb, i.fogCoord, UnityWorldSpaceViewDir(i.worldPos));
                        return col;
                    }
                ENDCG
            }
    }

}
