Shader "Custom/Color"
{
	Properties
	{
		_Color("Main Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		LOD 100
		Tags
		{
			"Queue" = "Transparent"
			"RenderType" = "Transparent"
			//"RenderPipeline" = "LightweightPipeline"
			"IgnoreProjector" = "True"
		}
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			//ZTest Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};
			uniform fixed4 _Color;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return _Color;
			}
			ENDCG
		}
	}
}
