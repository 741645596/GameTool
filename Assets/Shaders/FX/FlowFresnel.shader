Shader "Omega/FX/FlowFresnel"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Displacement ("Displacement", 2D) = "black" {}
		_Dir ("Direction", Vector) = (0.5, 0.5, 0, 0)
		_Bias("Bias Factor", Range(0, 1)) = 0.1
		_FallOff("Fall Off", Vector) = (0.1, 0.9, 2)
		[Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("Src Blend", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)]_DestBlend("Dest Blend", Float) = 10
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Float) = 2
	}
	SubShader
	{
		Tags { "Queue"="Transparent" }
		LOD 100

		Pass
		{
			ZWrite Off
			ZTest LEqual
			Blend [_SrcBlend] [_DestBlend]
			Cull [_CullMode]
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Displacement;
			float4 _Displacement_ST;
			float4 _Dir;
			float _Bias;
			float3 _FallOff;

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
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv -= frac(_Dir.xy * _Time.y);
				float2 dispUV = TRANSFORM_TEX(v.uv, _Displacement) - frac(_Dir.zw * _Time.y);
				float noise = tex2Dlod(_Displacement, float4(dispUV, 0, 0));
				o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
				v.vertex *= 1 + _Bias * (1 - noise)  * (1 - abs(v.uv.y - 0.5) * 2);
				o.pos = UnityObjectToClipPos(v.vertex);

				o.normal = UnityObjectToWorldNormal(v.normal);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float fresnel = abs(dot(i.normal, i.viewDir));
				fresnel = 1 - pow(1 - fresnel, _FallOff.z);
				fixed4 col = tex2D(_MainTex, i.uv);
				col.a = lerp(_FallOff.x, _FallOff.y * col.a, fresnel);
				return col;
			}
			ENDCG
		}
	}
}
