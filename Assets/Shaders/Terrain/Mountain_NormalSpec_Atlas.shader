Shader "Omega/Env/Mountain_NormalSpec_Atlas"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		[PowerSlider(5.0)] _Shininess("Shininess", Range(0.03, 1)) = 0.078125

		
		[NoScaleOffset] _MainTex("Diffuse", 2D) = "white" {}
		[NoScaleOffset] _BumpMap("Normalmap", 2D) = "bump" {}

		_Index ("Index", Vector) = (0,0,0,0)

		[Space]
		_Tile1("Tile_1", Vector) = (1,1,1,1)
		_Tile2("Tile_2", Vector) = (1,1,1,1)
		_Tile3("Tile_2", Vector) = (1,1,1,1)
		_Tile4("Tile_2", Vector) = (1,1,1,1)

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
			#pragma target 3.0
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

			#define _USEVERTEXCOLOR
			#define USE_NORMAL

			float4 _Tile1, _Tile2, _Tile3, _Tile4;

			static float4x4 _Scale = float4x4(_Tile4, _Tile3, _Tile2, _Tile1);

			#include "../cginc/TerrainCore.cginc"

			ENDCG 
		}
	}
FallBack "Legacy Shaders/Override/VertexLit"
}
