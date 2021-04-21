Shader "Omega/Env/OmegaScene_normalmap_alphatest"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_MainTex("MainTex", 2D) = "white" {}
		_BumpMap("Normalmap", 2D) = "bump" {}
		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		[PowerSlider(5.0)] _Shininess("Shininess", Range(0.03, 1)) = 0.078125
		[Header(Alpha)]
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
	}

	SubShader
	{
		Tags{ "RenderType" = "TransparentCutout"  "Queue" = "AlphaTest" "Shadow" = "Character"}
		Cull Off

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#define _ALPHATEST
			#define _USENORMAL
			#define _CUSTOM_SPEC

			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			#pragma vertex CustomvertBase
			#pragma fragment CustomfragBase

			#include "../cginc/SceneCore.cginc"

			ENDCG
		}
	}
}