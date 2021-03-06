Shader "Terrain/Terrain_NormalSpec_Array"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		[PowerSlider(5.0)] _Shininess("Shininess", Range(0.03, 1)) = 0.078125
		[Header(Texture)]
		_Splat("SplatMap", 2D) = "white" {}
		[NoScaleOffset] _MainTexArray("Diffuse (Array)", 2DArray) = "white" {}
		[NoScaleOffset] _BumpMapArray("Normalmap (Array)", 2DArray) = "bump" {}

		[NoScaleOffset] _MainTex("Diffuse (Atlas)", 2D) = "white" {}
		[NoScaleOffset] _BumpMap("Normalmap (Atlas)", 2D) = "bump" {}

		[Space]
		_Tile1("Tile_1", Vector) = (30,30,30,30)
		_Tile2("Tile_2", Vector) = (30,30,30,30)
		_Tile3("Tile_3", Vector) = (30,30,30,30)
		_Tile4("Tile_4", Vector) = (30,30,30,30)
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
			#pragma require 2darray
			#pragma multi_compile _LIGHTMAP
			#pragma multi_compile _ _RECEIVESHADOW
			#pragma multi_compile _ _CASCADE_SHADOW
			#pragma multi_compile _ USE_NORMAL
			#pragma multi_compile_fog

			#pragma vertex CustomvertBase
			#pragma fragment CustomfragBase

			float4 _Tile1, _Tile2, _Tile3, _Tile4;

			static float4x4 _Scale = float4x4(_Tile4, _Tile3, _Tile2, _Tile1);

			#include "../cginc/TerrainCoreArray.cginc"

			ENDCG 
		}
	}
	FallBack "Omega/Env/Terrain_NormalSpec_Atlas"
}