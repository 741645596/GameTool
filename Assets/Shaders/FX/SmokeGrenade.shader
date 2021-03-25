Shader "Omega/FX/SmokeGrenade"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Alpha("Alpha", Range(0, 1)) = 1
		_Dir ("Direction", Vector) = (0.5, 0.5, 0, 0)
		_XRayColor ("XRay Color", COLOR) = (0.9433,0.4778,0.2358,1)
		_Bias("Bias Factor", Range(0, 1)) = 0.1
		_FallOff("Fall Off", Float) = 2
		[Enum(Off,0,On,1)] _Zwrite("Zwrite", Float) = 0
	}
	SubShader
	{
		Tags { "Queue"="Transparent" }
		LOD 100

		Pass
		{
			ZWrite [_Zwrite]
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma multi_compile_fog
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "../Fog/FogCore.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Alpha;
			float2 _Dir;
			float _Bias;
			float _FallOff;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal: NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
				half4 fogCoord : TEXCOORD3;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv -= frac(_Dir * _Time.y);
				float noise = tex2Dlod(_MainTex, float4(o.uv, 0, 0));
				o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
				v.vertex *= 1 + _Bias * (1 - noise)  * (1 - abs(v.uv.y - 0.5) * 2);
				float4 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1));
				o.pos = mul(UNITY_MATRIX_VP, worldPos);

				//Disable Near-Plane Clipping
			#if UNITY_REVERSED_Z
				o.pos.z = min(o.pos.w, o.pos.z);
			#else
				o.pos.z = max(-o.pos.w, o.pos.z);
			#endif //UNITY_REVERSE_Z

				o.normal = UnityObjectToWorldNormal(v.normal);
				o.fogCoord = GetFogCoord(o.pos, worldPos.xyz);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float fresnel = saturate(dot(i.normal, i.viewDir));
				fresnel = 1 - pow(1 - fresnel, _FallOff);
				fixed4 col = tex2D(_MainTex, i.uv);
				col.a = fresnel * lerp(_Alpha, 1, col.r * _Alpha);
				col.rgb = ApplyFog(col.rgb, i.fogCoord);
				return col;
			}
			ENDCG
		}

		Pass
		{
			ZTest Less
			ZWrite Off
			Blend One Zero
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

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Speed;
			fixed4 _XRayColor;
			float _Bias;

			float4 vert(appdata_img v) : SV_POSITION
			{
				float2 uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				uv.y -= _Speed * _Time.y;
				float noise = tex2Dlod(_MainTex, float4(uv, 0, 0));
				v.vertex *= 1 + _Bias * (1 - noise) * (1 - abs(uv.y - 0.5) * 2);
				return UnityObjectToClipPos(v.vertex);
			}

			fixed4 frag() : SV_Target
			{
				return _XRayColor;
			}

			ENDCG
		}
	}
}
