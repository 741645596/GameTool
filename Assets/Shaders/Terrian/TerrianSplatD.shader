Shader "Terrian/TerrianSplatD"
{
    Properties
    {
        _Splat0("Layer 1(RGBA)", 2D) = "white" {}
        _Splat1("Layer 2(RGBA)", 2D) = "white" {}
        _Splat2("Layer 3(RGBA)", 2D) = "white" {}
        _Splat3("Layer 4(RGBA)", 2D) = "white" {}
        _Control("Control (RGBA)", 2D) = "white" {}
        _Weight("Blend Weight" , Range(0.001,1)) = 0.2
        _SnowTex("SnowTex", 2D) = "white" {}
        _SnowDepthTex("SnowDepthTex", 2D) = "white" {}
        _ShowSnowDepth("ShowSnowDepth" , Range(0.0,1)) = 1.0


    }
    SubShader
    {
        Tags {
           "SplatCount" = "4"
           "RenderType" = "Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma target 3.0
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 uv_splat12 : TEXCOORD2;
                float4 uv_splat34 : TEXCOORD3;
                UNITY_FOG_COORDS(7)
                fixed3 diff : COLOR1;
            };


            sampler2D _Control;
            float4 _Control_ST;
            sampler2D _Splat0, _Splat1, _Splat2, _Splat3;
            float4 _Splat0_ST, _Splat1_ST, _Splat2_ST, _Splat3_ST;
            float _Weight;
            //
            sampler2D _SnowTex;
            float4 _SnowTex_ST;
            sampler2D _SnowDepthTex;
            float4 _SnowDepthTex_ST;
            float _ShowSnowDepth;
            // 混合
            inline half4 Blend(half depth1, half depth2, half depth3, half depth4, fixed4 control)
            {
                half4 blend;

                blend.r = depth1 * control.r;
                blend.g = depth2 * control.g;
                blend.b = depth3 * control.b;
                blend.a = depth4 * control.a;

                half ma = max(blend.r, max(blend.g, max(blend.b, blend.a)));
                blend = max(blend - ma + _Weight, 0) * control;
                return blend / (blend.r + blend.g + blend.b + blend.a);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                o.uv = TRANSFORM_TEX(v.uv, _SnowTex);
                o.uv_splat12.xy = TRANSFORM_TEX(v.uv, _Splat0);
                o.uv_splat12.zw = TRANSFORM_TEX(v.uv, _Splat1);
                o.uv_splat34.xy = TRANSFORM_TEX(v.uv, _Splat2);
                o.uv_splat34.zw = TRANSFORM_TEX(v.uv, _Splat3);

                // calculate light 
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
                o.diff = nl * _LightColor0.rgb;

                UNITY_TRANSFER_FOG(o, o.vertex);

                return o;
            }

            fixed4 frag (v2f IN) : SV_Target
            {

                half4 col = half4(0, 0, 0, 1);
                half4 splat_control = tex2D(_Control, IN.uv.xy).rgba;

                half4 splat1 = tex2D(_Splat0, IN.uv_splat12.xy);
                half4 splat2 = tex2D(_Splat1, IN.uv_splat12.zw);
                half4 splat3 = tex2D(_Splat2, IN.uv_splat34.xy);
                half4 splat4 = tex2D(_Splat3, IN.uv_splat34.zw);
                half4 blend = Blend(splat1.a, splat2.a, splat3.a, splat4.a, splat_control);
                col.rgb = blend.r * splat1 + blend.g * splat2 + blend.b * splat3 + blend.a * splat4;
                //
                // sample the texture
                half4 SnowCol = tex2D(_SnowTex, IN.uv.xy);
                float depth = tex2D(_SnowDepthTex, IN.uv.xy).r;
                // _Depth < depth sign1 = 1
                float sign = step(_ShowSnowDepth, depth);
                col.rgb = col.rgb * (1.0 -sign) +  SnowCol.rgb * sign;

                /*if (depth > _ShowSnowDepth)
                {
                    col.rgb = SnowCol.rgb;
                }*/

                // light
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                col.rgb *= IN.diff + ambient;

                UNITY_APPLY_FOG(IN.fogCoord, col);

                return col;
            }
            ENDCG
        }
    }
}
