﻿Shader "Omega/Env/Terrain_NormalSpec_Atlas"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		[PowerSlider(5.0)] _Shininess("Shininess", Range(0.03, 1)) = 0.078125


		[Header(Texture)]
		[NoScaleOffset] _Splat("SplatMap", 2D) = "white" {}

		[NoScaleOffset] _MainTex("Diffuse", 2D) = "white" {}
		[NoScaleOffset] _BumpMap("Normalmap", 2D) = "bump" {}

		[Space]
		_Tile1("Tile_1", Vector) = (30,30,30,30)
		_Tile2("Tile_2", Vector) = (30,30,30,30)
		_Tile3("Tile_2", Vector) = (30,30,30,30)
		_Tile4("Tile_2", Vector) = (30,30,30,30)

		//[KeywordEnum(NOSHADOW, HARD_SHADOW, SOFT_SHADOW)]shadow("shadow options", float) = 0
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry"}
		Cull Back

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Lighting On
			CGPROGRAM
			#pragma target 3.0

			//#pragma multi_compile _Unlit
			//#pragma multi_compile _LIGHTMAP
			//#pragma multi_compile _USENORMAL
			//#pragma multi_compile _ALPHA
			#pragma multi_compile _ _RECEIVESHADOW
			#pragma multi_compile _ _CASCADE_SHADOW
			#pragma multi_compile _ USE_NORMAL
			//#pragma multi_compile PCF_OFF PCF_ON
			//#pragma shader_feature SHADOWMAP_OFF SHADOWMAP_ON
			//#pragma multi_compile SHADOW_NOSHADOW SHADOW_HARD_SHADOW SHADOW_SOFT_SHADOW

			//#pragma multi_compile_fwdadd_fullshadows
			//#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			//#pragma multi_compile_instancing

			#pragma vertex CustomvertBase
			#pragma fragment CustomfragBase

			float4 _Tile1, _Tile2, _Tile3, _Tile4;

			static float4x4 _Scale = float4x4(_Tile4, _Tile3, _Tile2, _Tile1);

			#include "TerrainCore.cginc"

			ENDCG 
		}
	}
	FallBack "Legacy Shaders/Override/VertexLit"
}