Shader "Omega/Env/OmegaScene_normalmap_refl_spotlight_matcap"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_MainTex("MainTex", 2D) = "white" {}
		_BumpMap("BumpMap a for specular", 2D) = "bump" {}
		[PowerSlider(5.0)] _Shininess("Shininess", Range(0.03, 1)) = 0.078125
		_MetalV("Metal",Range(0,1)) = 0
		_ReflTex("ReflTex", CUBE) = "white" {}
		_FresnelRange("FresnelRange",Range(1,8)) = 4
		_MatcapTex("MatcapTex", 2D) = "Black" {}
		_SpotLightParams("SpotLightParams", Vector) = (-115.4,-8.1,0.2,1)
		_SpotRad("SpotRad", Float) = 7.1
		_SpotLightColor("SpotLightCoolr", Color) = (1,1,1,1)
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
			Cull Back

			Pass
			{
				Name "FORWARD"
				Tags { "LightMode" = "ForwardBase" }
				//Lighting On
				CGPROGRAM
				#pragma target 3.0
#define _USENORMAL
#define _USEREFL
#define _SPOTLIGHT
#define _MATCAP
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

				#include "../cginc/SceneCore.cginc"

				ENDCG
			}
		}
}