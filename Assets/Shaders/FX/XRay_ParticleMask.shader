Shader "Omega/FX/XRay_ParticleMask"
{
	Properties 
	{
		_Color ("Color", COLOR) = (1.0,0.5,0.5,1.0)
		_MAINTintColor ("Tint Color", Color) = (1,1,1,1)
		_MAINBrightness("Brightness", Range(0,4)) = 1
		_MAINCutoff("Cutoff", Range(0,1)) = 0.5
		[Enum(Color,1)] _MAINMODE("Texture1", Float) = 1
		_MAINTex ("Main Texture", 2D) = "white" {}
		[Toggle] _MAINUVANI("UVAnimation",Float) = 0
		_MAINTexScrollU("ScrollU", Range(-5,5)) = 0
		_MAINTexScrollV("ScrollV", Range(-5,5)) = 0
		[Toggle] _MAINUSEHUE("Hue",Float) = 0
		_MAINHueShift("Hue Color", Range(0,360)) = 0
		[Toggle] _MAINRGBXA("RGBxA",Float) = 0
		[Toggle] _MAINAXGRAY("AxGray",Float) = 0
		[Toggle] _MAINUSEDATA("CustomData", Float) = 0

		_MASKTintColor("Tint Color", Color) = (1,1,1,1)
		_MASKBrightness("Brightness", Range(0,4)) = 1
		_MASKCutoff("Cutoff", Range(0,1)) = 0.5
		[KeywordEnum(None,Mask)]_MASKMODE("Texture2", Float) = 2
		_MASKTex("Mask Texture", 2D) = "white" {}
		[Toggle] _MASKUVANI("UVAnimation",Float) = 0
		_MASKTexScrollU("ScrollU", Range(-5,5)) = 0
		_MASKTexScrollV("ScrollV", Range(-5,5)) = 0
		[Toggle] _MASKUSEHUE("Hue",Float) = 0
		_MASKHueShift("Hue Color", Range(0,360)) = 0
		[Toggle] _MASKRGBXA("RGBxA",Float) = 0
		[Toggle] _MASKAXGRAY("AxGray",Float) = 0
		[Toggle] _MASKUSEDATA("CustomData", Float) = 0

		_NOISETintColor("Tint Color", Color) = (1,1,1,1)
		_NOISEBrightness("Brightness", Range(0,4)) = 1
		_NOISECutoff("Cutoff", Range(0,1)) = 0.5
		[KeywordEnum(None,Mask,Noise,Distortion)] _NOISEMODE("Texture3", Float) = 3
		_NOISETex("Noise Texture", 2D) = "white" {}
		[Toggle] _NOISEUVANI("UVAnimation",Float) = 0
		_NOISETexScrollU("ScrollU", Range(-5,5)) = 0
		_NOISETexScrollV("ScrollV", Range(-5,5)) = 0
		[Toggle] _NOISEUSEHUE("Hue",Float) = 0
		_NOISEHueShift("Hue Color", Range(0,360)) = 0
		[Toggle] _NOISERGBXA("RGBxA",Float) = 0
		[Toggle] _NOISEAXGRAY("AxGray",Float) = 0
		[Toggle] _NOISEUSEDATA("CustomData", Float) = 0

		_MainTex("Base (RGB) Trans (A)", 2D) = "white" {} //fix UI bug

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
		[Toggle] _UseFog("UseFog", Float) = 0
}
	SubShader
	{
		Tags { "Queue"="Transparent+20" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas" = "True"}
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha Zero
			Cull Off ZWrite Off ZTest LEqual
			CGPROGRAM
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"
			#include "../Fog/FogCore.cginc"
			#include "ParticleCore.cginc"
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma multi_compile __ UNITY_UI_CLIP_RECT
			#pragma multi_compile _MASKMODE_NONE  _MASKMODE_MASK //_MASKMODE_COLOR
			#pragma multi_compile _NOISEMODE_NONE _NOISEMODE_MASK _NOISEMODE_NOISE _NOISEMODE_DISTORTION
			#pragma vertex vert_particle_mask
			#pragma fragment frag_particle_mask
			ENDCG
		}

		Pass
		{
			ZTest Less
			ZWrite Off
			Blend DstAlpha OneMinusDstAlpha
			//Blend One Zero
			Stencil
			{
				Ref 2
				ReadMask 2
				Comp Equal
			}
			CGPROGRAM
			#include "UnityCG.cginc"

			#pragma target 3.0

			#pragma vertex vert
			#pragma fragment frag

			fixed4 _Color;

			float4 vert(float4 vertex : POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}

			fixed4 frag() : SV_Target
			{
				return _Color;
			}

			ENDCG
		}
	}
}
