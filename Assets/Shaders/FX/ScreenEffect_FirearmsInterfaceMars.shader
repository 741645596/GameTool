Shader "Omega/FX/ScreenEffect_FirearmsInterfaceMar" {
Properties {
	_MAINTintColor ("Main Tint Color", Color) = (1,1,1,1)
	_MAINBrightness("Main Brightness", Range(0,4)) = 1
	_MAINCutoff("Main Cutoff", Range(0,1)) = 0.5

	_MAINTex ("Main Texture", 2D) = "white" {}
	//[Toggle] _MAINUVANI("UVAnimation",Float) = 0
	_MAINTexScrollU("Main ScrollU", Range(-5,5)) = 0
	_MAINTexScrollV("Main ScrollV", Range(-5,5)) = 0
	//[Toggle] _MAINUSEHUE("Hue",Float) = 0
	_MAINHueShift("Main Hue Color", Range(0,360)) = 0


    _MASKTintColor("Mask Tint Color", Color) = (1,1,1,1)
	_MASKBrightness("Mask Brightness", Range(0,4)) = 1
	_MASKCutoff("Mask Cutoff", Range(0,1)) = 0.5

	_MASKTex("Mask Texture", 2D) = "white" {}
	//[Toggle] _MASKUVANI("UVAnimation",Float) = 0
	_MASKTexScrollU("Mask ScrollU", Range(-5,5)) = 0
	_MASKTexScrollV("Mask ScrollV", Range(-5,5)) = 0


	_NOISETintColor("Noise Tint Color", Color) = (1,1,1,1)
	_NOISEBrightness("Noise Brightness", Range(0,4)) = 1
	_NOISECutoff("Noise Cutoff", Range(0,1)) = 0.5
	//[KeywordEnum(None,Mask,Noise,Distortion)] _NOISEMODE("Texture3", Float) = 3
	_NOISETex("Noise Texture", 2D) = "white" {}
	//[Toggle] _NOISEUVANI("UVAnimation",Float) = 0
	_NOISETexScrollU("Noise ScrollU", Range(-5,5)) = 0
	_NOISETexScrollV("Noise ScrollV", Range(-5,5)) = 0
	//[Toggle] _NOISEUSEHUE("Hue",Float) = 0
	_NOISEHueShift("Noise Hue Color", Range(0,360)) = 0
	//[Toggle] _NOISERGBXA("RGBxA",Float) = 0
	//[Toggle] _NOISEAXGRAY("AxGray",Float) = 0
	//[Toggle] _NOISEUSEDATA("CustomData", Float) = 0

	//_MainTex("Base (RGB) Trans (A)", 2D) = "white" {} //fix UI bug

	[Header(TexcoordMask)]
	//[KeywordEnum(None,Up,Down,Right,Left,Centre,Side)] _TM("Type", Float) = 0
	//_TMPow("Power", Range(0.01,8)) = 1
	
	[Header(AlphaBlendMode)] //Zero = 0,One = 1,DstColor = 2,SrcColor = 3,OneMinusDstColor = 4,SrcAlpha = 5,OneMinusSrcColor = 6,DstAlpha = 7,OneMinusDstAlpha = 8,SrcAlphaSaturate = 9,OneMinusSrcAlpha = 10
	[Enum(Zero,0,One,1,DstColor,2,SrcAlpha,5)]  _SrcBlend("SrcFactor",Float) = 5
	[Enum(Zero,0,One,1,OneMinusSrcAlpha,10)]  _DstBlend("DstFactor",Float) = 1
	//[Header(Additive(SrcAlpha.One))][Header(AlphaBlend(SrcAlpha.OneMinusSrcAlpha))][Header(Transparent(One.OneMinusSrcAlpha))][Header(Opaque(One.Zero))][Header(AdditiveSoft(One.OneMinusSrcColor))]
	[Header(RenderState)]
	[Enum(RGB,14,RGBA,15)] _ColorMask("Color Mask", Float) = 14 //Alpha = 1,Blue = 2,Green = 4,Red = 8,All = 15
	[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode",Float) = 0
	[Enum(Off,0,On,1)] _Zwrite("Zwrite", Float) = 0
	[Enum(Off,0,On,2)] _Ztest("Ztest", Float) = 2	
	//[Toggle] _Billboard("Billboard", Float) = 0
	//[Toggle] _UseFog("UseFog", Float) = 0
}

Category {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas" = "True"}
    Blend [_SrcBlend] [_DstBlend]
    ColorMask [_ColorMask]
    Cull [_Cull] Lighting Off ZWrite [_Zwrite] ZTest[unity_GUIZTestMode]


    SubShader {
        Pass {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma multi_compile __ UNITY_UI_CLIP_RECT
#define _MASKTEX
#define _MASKMODE_MASK

            #include "ScreenEffect.cginc"
            ENDCG
        }
    }
}
//CustomEditor "ParticleMaskGUI"
}
