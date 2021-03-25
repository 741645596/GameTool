Shader "Omega/FX/SmoothTrail"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Curvature ("Curvature", Float) = 1.0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float curvature : TEXCOORD1;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Curvature;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = 0;
                o.uv.xy = v.uv;
                o.tangent = v.tangent;
                o.normal = v.normal;
                o.curvature = 0;
                return o;
            }

            [maxvertexcount(3)]
            void geom(triangle v2f points[3], inout TriangleStream<v2f> triStream)
            {
                float3 u = float3(points[0].uv.x, points[1].uv.x, points[2].uv.x);
                float3 v = float3(points[0].uv.y, points[1].uv.y, points[2].uv.y);
                float minU = min(min(u.x, u.y), u.z);
                float maxU = max(max(u.x, u.y), u.z);
                float2 minmaxU = float2(minU, maxU);
                points[0].uv.zw = points[1].uv.zw = points[2].uv.zw = minmaxU;

                float side = dot(v, 1);
                float4 tangent0, tangent1;
                    tangent0 = points[0].tangent;
                    tangent1 = points[side].tangent;
                float3 normal = cross(tangent0.xyz, tangent1.xyz);
                float curvature = -length(normal) * dot(normalize(normal), points[0].normal);
                points[0].curvature = points[1].curvature = points[2].curvature = curvature;
                
                triStream.Append(points[0]);
                triStream.Append(points[1]);
                triStream.Append(points[2]);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float t = (i.uv.x - i.uv.z) / (i.uv.w - i.uv.z);
                float offset = 1 - pow(2 * (t - 0.5), 2);
                i.uv.y += offset * i.curvature * (i.uv.w - i.uv.z) * _Curvature;
                i.uv.y = i.uv.y * 2 - 0.5;
                fixed4 col = tex2D(_MainTex, i.uv.xy).rrra;
                return col;
            }
            ENDCG
        }
    }
}