Shader "Omega/Env/OmegaScene_customlightmap_normalmap"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_MainTex("MainTex", 2D) = "white" {}
		_BumpMap("NormalMap a for specular", 2D) = "bump" {}
		[Header(Lightmap)]
		_Lightmap("Lightmap", 2D) = "white" {}
	}

		SubShader
		{
			Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry-100" "Shadow" = "Character"}
			Cull Back

			Pass
			{
				Name "FORWARD"
				Tags { "LightMode" = "ForwardBase" }
				//Lighting On
				CGPROGRAM
				#pragma target 3.0

				#pragma multi_compile _ _RECEIVESHADOW
				#pragma multi_compile _ _CASCADE_SHADOW

				#pragma multi_compile_fog
				#pragma multi_compile_instancing

				#pragma vertex CustomvertBase
				#pragma fragment CustomfragBase
//#define _Unlit
#define _CUSTOM_LIGHTMAP
#define _LIGHTMAP
#define _USENORMAL
				#include "../cginc/SceneCore.cginc"

				ENDCG
			}
		}
}