Shader "Omega/Actors/Zombie"
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
		_EnvMin ("环境光下限值",Range(0,0.5)) = 0.1
		_SKin("皮肤补偿", Range(0, 2.0)) = 1
		_SKinShadow("皮肤暗部补偿", Range(0, 8.0)) = 0.5

		[Header((Saturation))]
		_ColorfulMetal("反光饱和度", Range(0.0, 2.0)) = 1

		[Header((Light))]
		_MainLightIntensity("照明光", Range(0,2)) = 1	
		_Highlight("高光强度", Range(0,2)) = 1
		_AmbientLight("环境光", Range(0,2)) = 1
		_CubeIntensity("环境反光", Range(0,2)) = 1

		[Header((Rim))]
		_RimLight("贴图边缘光", Range(0,2)) = 1
		_RimShaodowLight("暗部贴图边缘光", Range(0,2)) = 0

		[Header((Shadow))]
		_ShadowIntensity("阴影强度", Range(0, 1)) = 0.5
		_SelfShadowSize("阴影范围", Range(0, 1)) = 0.1
		_SelfShadowHardness("阴影硬度", Range(0, 1)) = 0.55
		_AO("AO", Range(0, 2)) = 0.5
		_MaskModeHeight("渐变", Range(0.0, 2.0)) = 1
		_MaskVector("渐变方向",Vector) = (0,0,0,1)

		[Space(20)]
		_ColorE("Color+E", 2D) = "white" {}
		_SMMS("SMMS", 2D) = "white" {}
		_Normal("Normal", 2D) = "bump" {}
		_MatcapTex ("MatcapTex",2D) = "black" {}


		_PatternMaskTex("PatternMaskTex",2D) = "black" {}
		_PatternTex("PatternTex",2D) = "white" {}
		_PatternColor1("PatternColor", Color) = (1,1,1,1)

		[HideInInspector] _CustomSkinMode("", Float) = 0.0
		[HideInInspector][Toggle]_CUSTOMSKIN_BOOL("", Float) = 0.0
		[HideInInspector][Toggle]_CUSTOMSKINADDCOLOR_BOOL("", Float) = 0.0
		[HideInInspector][Toggle]_CUSTOMSKINPATTERNTEX_BOOL("", Float) = 0.0
		[HideInInspector][KeywordEnum(Add,Alpha)] _PATTERNMODE("", Float) = 0

		[HideInInspector]
		_MainTex ("MainTex", 2D) = "white" {}
	}

	SubShader
	{
		Tags {"RenderType" = "Opaque" "Shadow" = "Character"}
		
		Pass 
		{
			
			Tags {"LightMode" = "ForwardBase"}
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

			#define _CHDISPLAY
			#define _MATCAP
			#define _EMISSION
			#define _RAMP
			#define _SKINMASK
			#define _SKINPATTERN
			#define _PATTERNMODE_ADD
			#pragma multi_compile _ _SOFTSHADOW
			#pragma multi_compile _ _RECEIVESHADOW
			#pragma multi_compile_fog

			#pragma vertex CHVertBase
			#pragma fragment CHFragBase
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "CHCore.cginc"
			ENDCG
		}	
	}
}

