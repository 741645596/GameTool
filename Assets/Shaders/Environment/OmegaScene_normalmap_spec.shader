Shader "Omega/Env/OmegaScene_normalmap_spec"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_MainTex("MainTex", 2D) = "white" {}
		_BumpMap("BumpMap", 2D) = "bump" {}
		_SpecularMap("SpecularMap r for spec", 2D) = "black" {}
	    _SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_OffsetFactor("Offset Factor", Float) = 0
		_OffsetUnits("Offset Units", Float) = 0
	    [PowerSlider(5.0)] _Shininess("Shininess", Range(0.03, 1)) = 0.078125
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
			Offset[_OffsetFactor],[_OffsetUnits]
			Pass
			{
				Name "FORWARD"
				Tags { "LightMode" = "ForwardBase" }
				//Lighting On
				CGPROGRAM
				#pragma target 3.0
#define _USENORMAL
#define _SPEC
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

				#include "SceneCore.cginc"

				ENDCG
			}
		}
			//FallBack "Legacy Shaders/Override/VertexLit"
}