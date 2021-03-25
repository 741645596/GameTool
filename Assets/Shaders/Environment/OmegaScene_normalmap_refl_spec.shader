Shader "Omega/Env/OmegaScene_normalmap_refl_spec"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_MainTex("MainTex", 2D) = "white" {}
		_BumpMap("BumpMap a for specular", 2D) = "bump" {}
		_SpecularMap("SpecularMap r for spec", 2D) = "black" {}
		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		[PowerSlider(5.0)] _Shininess("Shininess", Range(0.03, 1)) = 0.078125
		_MetalV("Metal",Range(0,1)) = 0
		_FresnelRange("FresnelRange",Range(1,8)) = 4
		[Enum(UnityEngine.Rendering.CullMode)]_CullingMode ("Culling Mode", Int) = 2

		[Enum(UnityEngine.Rendering.BlendMode)]
		_SrcFactor ("Src Factor", Int) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]
		_DstFactor ("Dest Factor", Int) = 0
		_Transparency ("Transparency", Range(0, 1)) = 1.0
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry-100" "Shadow" = "Character"}
		Cull [_CullingMode]
		Blend [_SrcFactor] [_DstFactor]
		ColorMask RGB

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			//Lighting On
			CGPROGRAM
			#pragma target 3.0

			#define _USENORMAL
			#define _USEREFL
			#define _SPEC
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