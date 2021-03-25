Shader "Omega/UI/HeadGray"
{
	Properties
	{
		[PerRendererData] _MainTex ("Texture", 2D) = "white" {}
		isGary("is gary", Int) = 1
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }

		Pass
		{
			Cull Off
			Lighting Off
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			uniform int isGary = 1;

			struct a2v
			{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 texColor = tex2D(_MainTex, i.uv);
				if (isGary > 0) {
					float grey = dot(texColor.rgb, float3(0.299, 0.587, 0.114))*0.5;
					return float4(grey.xxx, texColor.a);
				}
				else {
					return texColor;
				}
			}
			ENDCG
		}
	}
	FallBack "Transparent/VertexLit"
}
