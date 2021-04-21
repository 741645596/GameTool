Shader "Omega/Env/OmegaScene_alphatest"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_MainTex("MainTex", 2D) = "white" {}

		[Header(Alpha)]
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

		[Header(ZBias)]
		_OffsetFactor ("Offset Factor", Float) = 0
		_OffsetUnits ("Offset Units", Float) = 0

		[Enum(UnityEngine.Rendering.BlendMode)]
		_SrcFactor ("Src Factor", Int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]
		_DstFactor ("Dest Factor", Int) = 0
		_Transparency ("Transparency", Range(0, 1)) = 1.0
	}

	SubShader
	{
		Tags{ "RenderType" = "TransparentCutout"  "Queue" = "AlphaTest" "Shadow" = "Character"}
		Cull Off
		Blend [_SrcFactor] [_DstFactor]
		ColorMask RGB

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Offset [_OffsetFactor], [_OffsetUnits]
			CGPROGRAM
			#pragma target 3.0

			#pragma multi_compile _ _RECEIVESHADOW
			#pragma multi_compile _ _CASCADE_SHADOW

			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			#pragma vertex CustomvertBase
			#pragma fragment CustomfragBase
			#define _ALPHATEST
			#include "../cginc/SceneCore.cginc"

			ENDCG
		}
	}
}