Shader "Omega/Actors/WeaponCase"
{
	Properties
	{
		_OwnerLightAmbient("环境光颜色", Color) = (0.1,0.1, 0.2, 1)
		_EmissiveColor("自发光颜色", Color) = (1,1,1,1)

		[Header(Mask)]
		_Gloss("光滑度补偿", Range(0.0, 2.0)) = 1
		_Metal("金属补偿", Range(0.0, 2.0)) = 1
		_EnvMin("环境光下限值",Range(0,0.5)) = 0.1

		[Header((Saturation))]
		_ColorfulAll("整体饱和度", Range(0.0, 2.0)) = 1
		_ColorfulMetal("反光饱和度", Range(0.0, 2.0)) = 1
		_HighlightSaturation("高光饱和度", Range(0,2)) = 1

		[Header((Light))]
		_MainLightIntensity("照明光", Range(0,2)) = 1
		_Highlight("高光强度", Range(0,2)) = 1
		_AmbientLight("环境光", Range(0,2)) = 1
		_CubeIntensity("环境反光", Range(0,2)) = 1

		[Header((Shadow))]
		_ShadowIntensity("阴影强度", Range(0, 1)) = 0.5
		_SelfShadowSize("阴影范围", Range(0, 1)) = 0.1
		_SelfShadowHardness("阴影硬度", Range(0, 1)) = 0.55
		_AO("AO", Range(0, 2)) = 0.5

		[Header((Option))]
		[Toggle] _ANiEmi("循环自发光动画",float) = 0
		_AniSpeed("Emissive Shark", Range(0.0, 1.0)) = 0.5

		[Space(20)]
		_ColorE("Color+E", 2D) = "white" {}
		_SMMS("SMMS", 2D) = "white" {}
		_Normal("Normal", 2D) = "bump" {}

		[HideInInspector] _PatternMaskTex("PatternMaskTex",2D) = "black" {}
		[HideInInspector] _PatternColor1("PatternColor1", Color) = (1,1,1,1)
		[HideInInspector] _PatternColor2("PatternColor2", Color) = (1,1,1,0)
		[HideInInspector] _PatternTex("PatternTex",2D) = "white" {}

		[HideInInspector] _CustomSkinMode("", Float) = 0.0
		[HideInInspector][Toggle]_CUSTOMSKIN_BOOL("", Float) = 0.0
		[HideInInspector][Toggle]_CUSTOMSKINADDCOLOR_BOOL("", Float) = 0.0
		[HideInInspector][Toggle]_CUSTOMSKINPATTERNTEX_BOOL("", Float) = 0.0
		[HideInInspector][KeywordEnum(Add,Alpha)] _PATTERNMODE("", Float) = 0

		[Toggle]_IgnoreXray("Ignore Xray", Int) = 1

		[HideInInspector]
		_MainTex ("MainTex", 2D) = "white" {}
	}

		SubShader
	{
		Tags {"RenderType" = "Opaque" "Shadow" = "Character"}

		Pass
		{

			Tags {"LightMode" = "ForwardBase" }
			ColorMask RGBA
			ZTest Less
			ZWrite On

			Stencil
			{
				WriteMask 1
				Ref [_IgnoreXray]
				Comp Always
				Pass Replace
			}

			CGPROGRAM
			#pragma target 3.0
			#pragma only_renderers d3d11 glcore gles gles3 metal d3d9

			#pragma multi_compile __ _SKINMASK
			#pragma multi_compile __ _SKINADDCOLOR
			#pragma multi_compile __ _SKINPATTERN
			#pragma multi_compile _PATTERNMODE_ADD _PATTERNMODE_ALPHA
			#pragma multi_compile_fog
			#define _WEAPONCASE

			#pragma vertex CHVertBase
			#pragma fragment CHFragBase

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "CHCore.cginc"
			ENDCG
		}
	}
CustomEditor "CHCoreGUI"
}
