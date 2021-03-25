Shader "Omega/Env/OmegaScene_unlit"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_MainTex("MainTex", 2D) = "white" {}
		_CullBack("CullBack", Float) = 2
		[Toggle] _ZClip ("Z Clip", Float) = 1.0
		//[Header(Lightmap)]
		//_Lightmap("Lightmap", 2D) = "white" {}
		////_LightmapClamp("Lightmap Clamp", Range(0.5 , 3)) = 2
		//_LightmapBrightness("Lightmap Brightness", Range(0 , 3)) = 1
		//_LightmapContrast("Lightmap Contrast", Range(0 , 3)) = 1
		//_DesaturateLightmap("Desaturate Lightmap", Range(-2 , 2)) = 0

		//[Header(Shadow)]
		//_ShadowColor("ShadowColor (RGB)", Color) = (0.5,0.5,0.5,1)
		//_ShadowDistance("ShadowDistance",float) = 20
		//_ShadowFade("ShadowFade",Range(0.1,1)) = 0.1

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

				//#pragma multi_compile _Unlit
				//#pragma multi_compile _LIGHTMAP
				#pragma multi_compile _ _RECEIVESHADOW
				#pragma multi_compile _ _CASCADE_SHADOW
				//#pragma multi_compile _USENORMAL
				//#pragma multi_compile _ALPHA
				//#pragma multi_compile _SPLATX4

				//#pragma multi_compile_fwdadd_fullshadows
				//#pragma multi_compile_fwdbase
				#pragma multi_compile_fog
				#pragma multi_compile_instancing

				#pragma vertex CustomvertBase
				#pragma fragment CustomfragBase
#define _Unlit
				#include "SceneCore.cginc"

				ENDCG
			}
		}
			//FallBack "Legacy Shaders/Override/VertexLit"
}