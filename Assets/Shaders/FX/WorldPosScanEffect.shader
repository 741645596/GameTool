Shader "Omega/FX/WorldPosScanEffect"
{
	Properties
	{
		_TineColor ("TintColor(RGB), EdgeAlpha(A)", Color)  = (0.5,0.5,0.5,1)
		_MainTex("Texture", 2D) = "white" {}
		_MaskEdge ("MaskEdge",range(1,32)) = 15	
		_MaxRange("MaxRange", float) = 3
		_OutEdgeSize("Out edge size", range(0, 0.05)) = 0.015
		_RimPow("RimPow", range(0.1, 8)) = 2
		_RimMul("RimMul", range(1, 64)) = 4
	}
	SubShader
	{
		Tags{"Queue" = "Geometry"}
	
		Pass
		{
			Blend One One
			Cull Back
			ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float3 uv : TEXCOORD0;
				float3 worldpos : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			fixed4 _MainTex_ST;
			fixed3 _FXOffset;
			fixed4 _TineColor;
			fixed  _MaxRange;
			fixed _MaskEdge;
			fixed _RimPow, _RimMul;
			uniform fixed _OutEdgeSize;

			v2f vert(appdata v)
			{
				v2f o;
				v.vertex.xyz += v.normal.xyz * _OutEdgeSize;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.uv;
				o.worldpos = mul(unity_ObjectToWorld, v.vertex).xyz;
				UNITY_TRANSFER_FOG(o,o.vertex);

				//rim
				fixed3 norDir = (mul(fixed4(v.normal, 0), unity_WorldToObject)).xyz;
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
				fixed rimDir = 1 - saturate(dot(norDir, viewDir));
				o.uv.z = saturate(pow(rimDir, _RimPow)*_RimMul);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{

				fixed4 col = tex2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex));
				fixed4 mask = tex2D(_MainTex, i.uv);
				fixed3 dis = distance(_FXOffset.xyz, i.worldpos);
				fixed sphere = 1 - saturate(dis.r / _MaxRange);
				sphere = saturate(pow(1 - sphere,_MaskEdge) * 8);
				sphere = abs(sphere*(1 - sphere) * 4);

				col.rgb = sphere * _TineColor.rgb*col.rgb + sphere * _TineColor.rgb *_TineColor.a*4;
				col.rgb *= mask.a * i.uv.z;

				return col;
			}
			ENDCG
		}
	}
}
