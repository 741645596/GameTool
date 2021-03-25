Shader "Omega/FX/ParticleMask" {
Properties {
	[HideInInspector]_MAINTintColor ("Tint Color", Color) = (1,1,1,1)
	[HideInInspector]_MAINBrightness("Brightness", Range(0,4)) = 1
	[HideInInspector]_MAINCutoff("Cutoff", Range(0,1)) = 0.5
	[Enum(Color,1)] _MAINMODE("Texture1", Float) = 1
	[HideInInspector]_MAINTex ("Main Texture", 2D) = "white" {}
	[HideInInspector][Toggle] _MAINALPHA ("Main Alpha", Float) = 0
	[HideInInspector][Toggle] _MAINUVANI("UVAnimation",Float) = 0
	[HideInInspector]_MAINTexScrollU("ScrollU", Range(-5,5)) = 0
	[HideInInspector]_MAINTexScrollV("ScrollV", Range(-5,5)) = 0
	[HideInInspector][Toggle] _MAINUSEHUE("Hue",Float) = 0
	[HideInInspector]_MAINHueShift("Hue Color", Range(0,360)) = 0
	[HideInInspector][Toggle] _MAINRGBXA("RGBxA",Float) = 0
	[HideInInspector][Toggle] _MAINAXGRAY("AxGray",Float) = 0
	[HideInInspector][Toggle] _MAINUSEDATA("CustomData", Float) = 0

	[HideInInspector]_MASKTintColor("Tint Color", Color) = (1,1,1,1)
	[HideInInspector]_MASKBrightness("Brightness", Range(0,4)) = 1
	[HideInInspector]_MASKCutoff("Cutoff", Range(0,1)) = 0.5
	[KeywordEnum(None,Mask)]_MASKMODE("Texture2", Float) = 2
	[HideInInspector]_MASKTex("Mask Texture", 2D) = "white" {}
	[HideInInspector][Toggle] _MASKALPHA ("Mask Alpha", Float) = 0
	[HideInInspector][Toggle] _MASKUVANI("UVAnimation",Float) = 0
	[HideInInspector]_MASKTexScrollU("ScrollU", Range(-5,5)) = 0
	[HideInInspector]_MASKTexScrollV("ScrollV", Range(-5,5)) = 0
	[HideInInspector][Toggle] _MASKUSEHUE("Hue",Float) = 0
	[HideInInspector]_MASKHueShift("Hue Color", Range(0,360)) = 0
	[HideInInspector][Toggle] _MASKRGBXA("RGBxA",Float) = 0
	[HideInInspector][Toggle] _MASKAXGRAY("AxGray",Float) = 0
	[HideInInspector][Toggle] _MASKUSEDATA("CustomData", Float) = 0

	[HideInInspector]_NOISETintColor("Tint Color", Color) = (1,1,1,1)
	[HideInInspector]_NOISEBrightness("Brightness", Range(0,4)) = 1
	[HideInInspector]_NOISECutoff("Cutoff", Range(0,1)) = 0.5
	[KeywordEnum(None,Mask,Noise,Distortion)] _NOISEMODE("Texture3", Float) = 3
	[HideInInspector]_NOISETex("Noise Texture", 2D) = "white" {}
	[HideInInspector][Toggle] _NOISEALPHA ("Noise Alpha", Float) = 0
	[HideInInspector][Toggle] _NOISEUVANI("UVAnimation",Float) = 0
	[HideInInspector]_NOISETexScrollU("ScrollU", Range(-5,5)) = 0
	[HideInInspector]_NOISETexScrollV("ScrollV", Range(-5,5)) = 0
	[HideInInspector][Toggle] _NOISEUSEHUE("Hue",Float) = 0
	[HideInInspector]_NOISEHueShift("Hue Color", Range(0,360)) = 0
	[HideInInspector][Toggle] _NOISERGBXA("RGBxA",Float) = 0
	[HideInInspector][Toggle] _NOISEAXGRAY("AxGray",Float) = 0
	[HideInInspector][Toggle] _NOISEUSEDATA("CustomData", Float) = 0

	[HideInInspector]_MainTex("Base (RGB) Trans (A)", 2D) = "white" {} //fix UI bug

	[Header(TexcoordMask)]
	//[KeywordEnum(None,Up,Down,Right,Left,Centre,Side)] _TM("Type", Float) = 0
	//_TMPow("Power", Range(0.01,8)) = 1
	
	[Header(AlphaBlendMode)] //Zero = 0,One = 1,DstColor = 2,SrcColor = 3,OneMinusDstColor = 4,SrcAlpha = 5,OneMinusSrcColor = 6,DstAlpha = 7,OneMinusDstAlpha = 8,SrcAlphaSaturate = 9,OneMinusSrcAlpha = 10
	[Enum(Zero,0,One,1,DstColor,2,SrcAlpha,5)]	_SrcBlend("SrcFactor",Float) = 5
	[Enum(Zero,0,One,1,OneMinusSrcAlpha,10)]  _DstBlend("DstFactor",Float) = 1
	//[Header(Additive(SrcAlpha.One))][Header(AlphaBlend(SrcAlpha.OneMinusSrcAlpha))][Header(Transparent(One.OneMinusSrcAlpha))][Header(Opaque(One.Zero))][Header(AdditiveSoft(One.OneMinusSrcColor))]
	[Header(RenderState)]
	[Enum(RGB,14,RGBA,15)] _ColorMask("Color Mask", Float) = 14 //Alpha = 1,Blue = 2,Green = 4,Red = 8,All = 15
	[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode",Float) = 0
	[Enum(Off,0,On,1)] _Zwrite("Zwrite", Float) = 0
	[Enum(Off,0,On,2)] _Ztest("Ztest", Float) = 2	
	[Toggle] _Billboard("Billboard", Float) = 0

	_StencilComp ("Stencil Comparison", Float) = 8
    _Stencil ("Stencil ID", Float) = 0
    _StencilOp ("Stencil Operation", Float) = 0
    _StencilWriteMask ("Stencil Write Mask", Float) = 255
    _StencilReadMask ("Stencil Read Mask", Float) = 255
	[Toggle] _ZClip ("Z Clip", Float) = 1

}

Category {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas" = "True"}
	Blend [_SrcBlend] [_DstBlend]
	ColorMask [_ColorMask]
	Cull [_Cull] Lighting Off 
	
	ZWrite [_Zwrite] 
	ZTest[unity_GUIZTestMode]
	ZClip [_ZClip]

	Stencil
    {
        Ref [_Stencil]
        Comp [_StencilComp]
        Pass [_StencilOp]
        ReadMask [_StencilReadMask]
        WriteMask [_StencilWriteMask]
    }

	SubShader {
		Pass {
			Name "ParticleMask"
			CGPROGRAM
			#pragma vertex vert_particle_mask
			#pragma fragment frag_particle_mask
			#pragma target 2.0

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"
			#include "../Fog/FogCore.cginc"
			#include "ParticleCore.cginc"

			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma multi_compile __ UNITY_UI_CLIP_RECT
			//#pragma multi_compile _MAINMODE_NONE _MAINMODE_COLOR _MAINMODE_MASK _MAINMODE_NOISE _MAINMODE_DISTORTION
			//#pragma multi_compile _MAINUVANI
			//#pragma shader_feature _MAINSHEET
			//#pragma shader_feature _MAINUSEHUE
			//#pragma shader_feature _MAINRGBXA
			//#pragma shader_feature _MAINAXGRAY
			//#pragma shader_feature _MAINUSEDATA

			#pragma multi_compile _MASKMODE_NONE  _MASKMODE_MASK //_MASKMODE_COLOR
			//#pragma multi_compile _MASKUVANI
			//#pragma shader_feature _MASKSHEET
			//#pragma shader_feature _MASKUSEHUE
			//#pragma shader_feature _MASKRGBXA
			//#pragma shader_feature _MASKAXGRAY
			//#pragma shader_feature _MASKUSEDATA

			#pragma multi_compile _NOISEMODE_NONE _NOISEMODE_MASK _NOISEMODE_NOISE _NOISEMODE_DISTORTION
			//#pragma multi_compile _NOISEUVANI
			//#pragma shader_feature _NOISESHEET
			//#pragma shader_feature _NOISEUSEHUE
			//#pragma shader_feature _NOISERGBXA
			//#pragma shader_feature _NOISEAXGRAY
			//#pragma shader_feature _NOISEUSEDATA

			//#pragma shader_feature _TM_NONE _TM_UP _TM_DOWN _TM_RIGHT _TM_LEFT _TM_CENTRE _TM_SIDE

			ENDCG
		}
	}
}
CustomEditor "ParticleMaskGUI"
}
