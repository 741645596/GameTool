Shader "Omega/FX/XRay"
{
	Properties
	{
		_Color ("Color", COLOR) = (1.0,0.5,0.5,1.0)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue" = "AlphaTest-20" }
		LOD 100

		Pass
		{
			ZTest Greater
			ZWrite Off
			Stencil 
			{
				Ref 3
				ReadMask 1
				WriteMask 2
				Comp NotEqual
				Fail Replace
				Pass Replace
			}
				
			CGPROGRAM
			#include "UnityCG.cginc"


			#pragma target 3.0

			#pragma vertex vert
			#pragma fragment frag

			fixed4 _Color;

			float4 vert(float4 vertex : POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}

			fixed4 frag() : SV_Target
			{
				return _Color;
			}

			ENDCG
		}
	}
}
