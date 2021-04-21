Shader "Omega/Env/Mountain_NormalSpec_Array"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		[PowerSlider(5.0)] _Shininess("Shininess", Range(0.03, 1)) = 0.078125

		[NoScaleOffset] _MainTexArray("Diffuse (Array)", 2DArray) = "white" {}
		[NoScaleOffset] _BumpMapArray("Normalmap (Array)", 2DArray) = "bump" {}

		[NoScaleOffset] _MainTex("Diffuse (Atlas)", 2D) = "white" {}
		[NoScaleOffset] _BumpMap("Normalmap (Atlas)", 2D) = "bump" {}

		_Index ("Index", Vector) = (0,0,0,0)

		[Space]
		_Tile1("Tile_1", Vector) = (1,1,1,1)
		_Tile2("Tile_2", Vector) = (1,1,1,1)
		_Tile3("Tile_3", Vector) = (1,1,1,1)
		_Tile4("Tile_4", Vector) = (1,1,1,1)

		[Toggle(_SPLAT_X4)] _Splat("_SPLAT_X4", Float) = 0
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry" "Shadow" = "Character"}
		Cull Back

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Lighting On
			CGPROGRAM
			#pragma require 2darray
			#pragma multi_compile _ _RECEIVESHADOW
			#pragma multi_compile _ _CASCADE_SHADOW
			#pragma multi_compile _ _SPLAT_X4
			//#pragma multi_compile PCF_OFF PCF_ON
			//#pragma shader_feature SHADOWMAP_OFF SHADOWMAP_ON
			//#pragma multi_compile SHADOW_NOSHADOW SHADOW_HARD_SHADOW SHADOW_SOFT_SHADOW

			//#pragma multi_compile_fwdadd_fullshadows
			//#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			#pragma vertex CustomvertBase
			#pragma fragment CustomfragBase

			#define USE_2DARRAY
			#define USE_VERTEXCOLOR
			#define USE_NORMAL

			float4 _Tile1, _Tile2, _Tile3, _Tile4;

			static float4x4 _Scale = float4x4(_Tile4, _Tile3, _Tile2, _Tile1);

			#include "Core/TerrainCore.cginc"

			ENDCG 
		}
	}
	FallBack "Omega/Env/Mountain_NormalSpec_Atlas"
}
