Shader "Omega/Env/OmegaScene_normalmap"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_MainTex("MainTex", 2D) = "white" {}
		_BumpMap("BumpMap a for specular", 2D) = "bump" {}
		[Enum(UnityEngine.Rendering.BlendMode)]
		_SrcFactor ("Src Factor", Int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]
		_DstFactor ("Dest Factor", Int) = 0
		_Transparency ("Transparency", Range(0, 1)) = 1.0
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry-100" "Shadow" = "Character"}
		Cull Back
		Blend [_SrcFactor] [_DstFactor]
		ColorMask RGB

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0
			#define _USENORMAL
			#pragma multi_compile _ _RECEIVESHADOW
			#pragma multi_compile _ _CASCADE_SHADOW

			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			#pragma vertex CustomvertBase
			#pragma fragment CustomfragBase

			#include "SceneCore.cginc"

			ENDCG
		}
	}
}