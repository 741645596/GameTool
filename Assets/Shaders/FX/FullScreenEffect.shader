Shader "Omega/FX/FullScreenEffect"
{
    Properties
    {
        _Smoke_MainTex ("Smoke Texture", 2D) = "white" {}
		_Smoke_Params("Smoke Params", Vector) = (0,0,0,0)
		_Smoke_XRayColor("Smoke XRay Color", COLOR) = (0.9433,0.4778,0.2358,1)
		_Smoke_Alpha("Smoke Alpha", Range(0,1)) = 0.8
		_Smoke_Dir("Smoke Dir", Vector) = (0,1,2,0.5)

    }
    SubShader
    {
		Tags {"Queue" = "Transparent+1000"}
        Pass
        {
			Cull Off
			ZWrite Off ZTest Always
			Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#define INV_PI    0.31830988618379
			#define INV_TWOPI 0.15915494309189

			fixed4 _Smoke_Params;
			sampler2D _Smoke_MainTex;
			float4 _Smoke_MainTex_ST;
			float _Smoke_Alpha;
			float4 _Smoke_Dir;

            struct v2f
            {
                float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
            };

            v2f vert (appdata_img v)
            {
                v2f o;
				o.pos = float4(v.vertex.xy, 0, 1);
				o.uv.zw = v.texcoord;
				float3x3 cameraToWorldDir = transpose(UNITY_MATRIX_V);
				float3 viewDir = normalize(mul(cameraToWorldDir, float3(0, 0, 1)));
				v.texcoord.x += atan2(viewDir.x, viewDir.z) * INV_TWOPI * _Smoke_Dir.z;
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _Smoke_MainTex);
				o.uv.x += frac(_Time.x * _Smoke_Dir.x);

			#if UNITY_UV_STARTS_AT_TOP
				o.uv.y += asin(viewDir.y) * _Smoke_Dir.w + frac(_Time.x * _Smoke_Dir.y);
				o.uv.y = 1 - o.uv.y;
			#else
				o.uv.y -= asin(viewDir.y) * _Smoke_Dir.w + frac(_Time.x);
			#endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_Smoke_MainTex, i.uv.xy);
				float2 screenUV = i.pos.xy / i.pos.w;
				fixed2 hori = lerp(_Smoke_Params.xy, _Smoke_Params.wz, frac(i.uv.z)); //yz
				col.a = lerp(hori.x, hori.y, frac(i.uv.w));                           //xw
				col.a *= _Smoke_Alpha;
				return col;
            }
            ENDCG
        }

		Pass
		{
			Cull Off
			ZWrite Off ZTest Always
			Blend DstAlpha OneMinusDstAlpha
			Stencil
			{
				Ref 2
				ReadMask 2
				Comp Equal
			}
			CGPROGRAM
			#include "UnityCG.cginc"

			#pragma target 3.0

			#pragma vertex vert
			#pragma fragment frag

			fixed4 _Smoke_XRayColor;

			float4 vert(float4 vertex : POSITION) : SV_POSITION
			{
				return float4(vertex.xy, 0, 1);
			}

			fixed4 frag() : SV_Target
			{
				return _Smoke_XRayColor;
			}
			ENDCG
		}

		Pass
		{
			Cull Off
			ZWrite Off ZTest Always
			Blend SrcAlpha One
			CGPROGRAM
			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			fixed4 _TransferColor;
			half _TransferStartTime;
			half _TransferEndTime;
			half _TransferCurrentTime;

			float4 vert(float4 vertex : POSITION) : SV_POSITION
			{
				return float4(vertex.xy, 0, 1);
			}

			fixed4 frag() : SV_Target
			{
				return _TransferColor;
			}
			ENDCG
		}
		
    }
}
