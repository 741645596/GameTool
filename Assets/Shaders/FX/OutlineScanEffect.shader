Shader "Omega/FX/OutlineScanEffect"
{
	Properties
	{		
		_TintColor("TintColor", Color) = (0,0,0,0)
		[Header(Inline)]
		_MainTex("Main Texture", 2D) = "white" {}
		_InlineColor("Color", Color)  = (1,0.6,0,0.5)
		_InlineScroll("Scroll", range(-16, 16)) = 1
		[Header(Outline)]
		_OutlineColor("Color", Color) = (1,0.9,0.5,1)
		_OutlineSize("Size", range(0, 0.05)) = 0.01
		[enum(UnityEngine.Rendering.CompareFunction)]_ZTest("Z Test", Float) = 8
		
	}
	SubShader
	{
		Tags{"Queue" = "Transparent"}
	
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Back
			ZWrite Off
			ZTest [_ZTest]
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			fixed4 _TintColor;
			fixed4 _InlineColor;
			half _InlineScroll;
			sampler2D _MainTex;
			half4 _MainTex_ST;

			v2f vert(float4 vertex : POSITION)
			{
				v2f o;
				float3 worldPos = mul(unity_ObjectToWorld, float4(vertex.xyz, 1)).xyz;
				o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
				o.uv = worldPos.xy * _MainTex_ST.xy + _MainTex_ST.zw + frac(_Time.yy)*_InlineScroll;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				half4 col = tex2D(_MainTex, i.uv.xy);
				return lerp(_TintColor, _InlineColor, col.r);
			}
			ENDCG
		}

		/*Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
			ZWrite Off
			Offset 50,10

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
				float4 vertex : SV_POSITION;
			};

			fixed4 _OutlineColor;
			uniform fixed _OutlineSize;

			v2f vert(appdata v)
			{
				v2f o;

				float3 norm = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				float2 offset = TransformViewToProjection(norm.xy);

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertex.xy += offset * o.vertex.z * _OutlineSize * 40;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return _OutlineColor;
			}
			ENDCG
		}*/
	}
}
