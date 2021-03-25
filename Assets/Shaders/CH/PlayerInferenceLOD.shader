Shader "Omega/Actors/PlayerInferenceLOD0"
{
	Properties
	{		
		_OwnerLightAmbient("环境光颜色", Color) = (0.1,0.1, 0.2, 1)
		_SkinColor("表皮肤色", Color) = (0.6,0.54,0.5,1)
		_SkinDeepColor("真皮透光颜色", Color) = (0.691,0.267,0.142,1)
		_EmissiveColor("自发光颜色", Color) = (0.5,0.5,0.5,1)

		[Header((Mask))]
		_Gloss("光滑度补偿", Range(0.0, 2.0)) = 1
		_Metal("金属补偿", Range(0.0, 2.0)) = 1
		_EnvMin("环境光下限值",Range(0,0.5)) = 0.1
		_SKin("皮肤补偿", Range(0, 2.0)) = 1
		_SKinShadow("皮肤暗部补偿", Range(0, 8.0)) = 0.5

		[Header((Saturation))]
		_ColorfulAll("整体饱和度", Range(0.0, 2.0)) = 1
		_ColorfulMetal("反光饱和度", Range(0.0, 2.0)) = 1
		_HighlightSaturation("高光饱和度", Range(0,2)) = 1

		[Header((Light))]
		_MainLightIntensity("照明光", Range(0,2)) = 1
		_Highlight("高光强度", Range(0,2)) = 1
		_AmbientLight("环境光", Range(0,2)) = 1
		_CubeIntensity("环境反光", Range(0,2)) = 1

		_Rotation("旋转Cubemap", Range(-360,360)) = 0

		[Header((Shadow))]
		_ShadowIntensity("阴影强度", Range(0, 1)) = 0.5
		_SelfShadowSize("阴影范围", Range(0, 1)) = 0.1
		_SelfShadowHardness("阴影硬度", Range(0, 1)) = 0.55
		_AO("AO", Range(0, 2)) = 0.5
		_MaskModeHeight("渐变", Range(0.0, 2.0)) = 1
		_MaskVector("渐变方向",Vector) = (0,0,0,1)

		[Header((Option))]
		[Toggle] _ANiEmi("循环自发光动画",float) = 0
		_AniSpeed("Emissive Shark", Range(0.0, 1.0)) = 0.5

		[Space(20)]
		_ColorE("Color+E", 2D) = "white" {}
		_ZombieColor("ZombieColor", Color) = (0,0,0,1)
		_SMMS("SMMS", 2D) = "white" {}
		_Normal("Normal", 2D) = "bump" {}
        //_Cubemap("Cubemap",Cube) = "cube" {}

		//[Toggle]_IgnoreXray("Ignore Xray", Int) = 1

		[HideInInspector]
		_MainTex ("MainTex", 2D) = "white" {}

		_ZombieColor("ZombieColor", color) = (1,1,1,1)

		[Header(Inference)]
        _InferenceColorfulMetal ("反光饱和度", Range(0, 2)) = 1.0
        _InferenceHighlight ("高光强度", Range(0, 2)) = 1.0
        _InferenceMainLightIntensity ("照明光", Range(0, 2)) = 1.0
		_InferenceCubeIntensity("环境反光", Range(0,2)) = 1
		_InferenceShadowIntensity("阴影强度", Range(0, 1)) = 0.5
        _Ramp ("Ramp", 2D) = "white" {}
        _Tint("Tint", Range(0, 1)) = 1.0
        _Reflect("Reflect", CUBE) = "white" {}
        _Thickness ("Thickness", 2D) = "white" {}
        _ThicknessFactor ("Thickness Factor", Range(0, 1)) = 0.5
        BRDF_LUT("BRDF LUT", 2D) = "black" {}
        _InferenceMask ("Inference Mask", 2D) = "white"
	}

	SubShader
	{
		Tags {"RenderType" = "Opaque" "Shadow"="Character" "Queue"="AlphaTest-30"}

		Pass
		{
			Tags {"LightMode" = "ForwardBase" }
			ColorMask RGBA
			ZTest Less
			ZWrite On

			Stencil
			{
				WriteMask 9
				Ref 9
				Comp Always
				Pass Replace
			}

			CGPROGRAM
			#pragma target 3.0
			#pragma only_renderers d3d11 glcore gles gles3 metal d3d9
			//#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

			//#pragma multi_compile _CHLODZERO
			#pragma multi_compile _ _CASCADE_SHADOW
			#pragma multi_compile _ _RECEIVESHADOW
			#pragma multi_compile_fog

			#pragma vertex CHVertBase
			#pragma fragment CHFragBase

			#define _CHLODZERO
			#define _EMISSION
			#define _RAMP
			#define _INFERENCE

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "BRDF.cginc"
			#include "CHCore.cginc"
			ENDCG
		}
	}
	CustomEditor "ZombieGUI"
		//FallBack "Legacy Shaders/Override/Diffuse"
}
