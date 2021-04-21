Shader "Omega/Env/OmegaScene_unlit_nofog"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_MainTex("MainTex", 2D) = "white" {}
		_CullBack("CullBack", Float) = 2
		[Toggle] _ZClip ("Z Clip", Float) = 1.0
	}

		SubShader
		{
			Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry-100" "Shadow" = "Character"}
			Cull [_CullBack]
			ZTest LEqual
			ZClip [_ZClip]

			Pass
			{
				Name "FORWARD"
				Tags { "LightMode" = "ForwardBase" }
				//Lighting On
				CGPROGRAM
				#pragma target 3.0

				#pragma multi_compile_instancing
				#define _Unlit

				#pragma vertex CustomvertBase
				#pragma fragment CustomfragBase
				#include "../cginc/SceneCore.cginc"

				ENDCG
			}
		}
}