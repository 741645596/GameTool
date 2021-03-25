Shader "Omega/FX/ScreenParticle" {
Properties {
	_MAINTintColor ("Tint Color", Color) = (1,1,1,1)
	_MAINBrightness("Brightness", Range(0,4)) = 1
	_MAINCutoff("Cutoff", Range(0,1)) = 0.5
	[Enum(Color,1)] _MAINMODE("Texture1", Float) = 1
	_MAINTex ("Main Texture", 2D) = "white" {}
	//[Toggle] _MAINUVANI("UVAnimation",Float) = 0
	_MAINTexScrollU("ScrollU", Range(-5,5)) = 0
	_MAINTexScrollV("ScrollV", Range(-5,5)) = 0
	//[Toggle] _MAINUSEHUE("Hue",Float) = 0
	_MAINHueShift("Hue Color", Range(0,360)) = 0
	//[Toggle] _MAINRGBXA("RGBxA",Float) = 0
	//[Toggle] _MAINAXGRAY("AxGray",Float) = 0
	//[Toggle] _MAINUSEDATA("CustomData", Float) = 0

    _MASKTintColor("Tint Color", Color) = (1,1,1,1)
	_MASKBrightness("Brightness", Range(0,4)) = 1
	_MASKCutoff("Cutoff", Range(0,1)) = 0.5
	[KeywordEnum(None,Mask)]_MASKMODE("Texture2", Float) = 2
	_MASKTex("Mask Texture", 2D) = "white" {}
	//[Toggle] _MASKUVANI("UVAnimation",Float) = 0
	_MASKTexScrollU("ScrollU", Range(-5,5)) = 0
	_MASKTexScrollV("ScrollV", Range(-5,5)) = 0
	//[Toggle] _MASKUSEHUE("Hue",Float) = 0
	//_MASKHueShift("Hue Color", Range(0,360)) = 0
	//[Toggle] _MASKRGBXA("RGBxA",Float) = 0
	//[Toggle] _MASKAXGRAY("AxGray",Float) = 0
	//[Toggle] _MASKUSEDATA("CustomData", Float) = 0

	_NOISETintColor("Tint Color", Color) = (1,1,1,1)
	_NOISEBrightness("Brightness", Range(0,4)) = 1
	_NOISECutoff("Cutoff", Range(0,1)) = 0.5
	[KeywordEnum(None,Mask,Noise,Distortion)] _NOISEMODE("Texture3", Float) = 3
	_NOISETex("Noise Texture", 2D) = "white" {}
	//[Toggle] _NOISEUVANI("UVAnimation",Float) = 0
	_NOISETexScrollU("ScrollU", Range(-5,5)) = 0
	_NOISETexScrollV("ScrollV", Range(-5,5)) = 0
	//[Toggle] _NOISEUSEHUE("Hue",Float) = 0
	_NOISEHueShift("Hue Color", Range(0,360)) = 0
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

		/*Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}*/

    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"
			#include "../Fog/FogCore.cginc"

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

            sampler2D _MAINTex;
			half4 _MAINTex_ST;
			half _MAINTexScrollU, _MAINTexScrollV;
			//half _MAINTilesX, _MAINTilesY, _MAINSheetSpeed;
			half _MAINHueShift;
			half4 _MAINTintColor;
			half  _MAINBrightness, _MAINCutoff;

			sampler2D _MASKTex;
			half4 _MASKTex_ST;
			half _MASKTexScrollU, _MASKTexScrollV;
			//half _MASKTilesX, _MASKTilesY, _MASKSheetSpeed;
			//half _MASKHueShift;
			half4 _MASKTintColor;
			half  _MASKBrightness, _MASKCutoff;

			sampler2D _NOISETex;
			half4 _NOISETex_ST;
			half _NOISETexScrollU, _NOISETexScrollV;
			//half _NOISETilesX, _NOISETilesY, _NOISESheetSpeed;
			//half _NOISEHueShift;
			half4 _NOISETintColor;
			half  _NOISEBrightness, _NOISECutoff;

			float4 _ClipRect;

			//fixed _MAINUVANI, _MASKUVANI, _NOISEUVANI;
			//fixed _MAINUSEHUE, _MASKUSEHUE, _NOISEUSEHUE;
			//fixed _MAINRGBXA, _MASKRGBXA, _NOISERGBXA;
			//fixed _MAINAXGRAY, _MASKAXGRAY, _NOISEAXGRAY;
			//fixed _MAINUSEDATA, _MASKUSEDATA, _NOISEUSEDATA;
			//fixed _Billboard;
			//fixed _UseFog;

			half3 applyHue(half3 aColor, half aHue)
			{
				half angle = radians(aHue);
				half3 k = half3(0.57735, 0.57735, 0.57735);
				half cosAngle = cos(angle);
				return aColor * cosAngle + cross(k, aColor) * sin(angle) + k * dot(k, aColor) * (1 - cosAngle);
			}

			#if defined(_NOISEMODE_DISTORTION)
			half applyCutoff(half cutoff,half alpha,half tex,half vertexalpha) 
			{
				half minalpha = min(2.0, (1.0 - vertexalpha)) + alpha * 0.5;
				half soft = saturate(tex + 1.0 + minalpha * (-2.01));
				cutoff = cutoff * 0.5 + 0.5;
				return smoothstep(1 - cutoff, cutoff, soft);
			}
			#endif

            struct appdata_t {
                float4 vertex : POSITION;
                half4 color : COLOR;
				half4 texcoord : TEXCOORD0;
				half4 texcoord1 : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
				float4 vertex : SV_POSITION;
                half4 color : COLOR;
				half4 texcoord : TEXCOORD0;
				half4 texcoord1 : TEXCOORD1;
				float4 posWorld	: TEXCOORD2;
				float4 worldPosition : TEXCOORD3;
				UNITY_VERTEX_OUTPUT_STEREO
			};
         
            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.worldPosition = v.vertex;
                o.vertex = UnityObjectToClipPos(o.worldPosition);
				//if (_Billboard)
				//	o.vertex = mul(UNITY_MATRIX_P, mul(unity_MatrixMV, float4(0.0, 0.0, 0.0, 1.0)) + float4(v.vertex.x, v.vertex.y, 0.0, 0.0) * float4(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].y, 1.0, 1.0));
                o.color = v.color;

				half2 uv1 = v.texcoord.xy;
				half2 uv2 = v.texcoord.xy;
				half2 uv3 = v.texcoord.xy;


				o.texcoord.xy = v.texcoord.xy;
				o.texcoord.zw = TRANSFORM_TEX(uv1, _MAINTex);
				o.texcoord1.xy = TRANSFORM_TEX(uv2, _MASKTex);
				o.texcoord1.zw = TRANSFORM_TEX(uv3, _NOISETex);
		
				//if (_MAINUVANI)
				o.texcoord.zw += frac(_Time.yy* half2(_MAINTexScrollU, _MAINTexScrollV));

				//if(_MASKUVAN
				o.texcoord1.xy += frac(_Time.yy* half2(_MASKTexScrollU, _MASKTexScrollV));


#ifdef _NOISEUVANI
				o.texcoord1.zw += frac(_Time.yy* half2(_NOISETexScrollU, _NOISETexScrollV));
#endif
				
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
				half2 noiseUV = 0;
				half4 final = 0;
				half4 mask = 1;
				half dist = 0;

				#if defined(_NOISEMODE_NOISE)
				noiseUV += tex2D(_NOISETex, i.texcoord1.zw).xy*_NOISEBrightness - _NOISEBrightness *0.5;
				#endif

				//main
				half4 mainT = tex2D(_MAINTex, i.texcoord.zw + noiseUV);
			
				mainT *= _MAINTintColor * _MAINBrightness;

				final += mainT;


				//mask
				#ifndef _MASKMODE_NONE
				half4 maskT = tex2D(_MASKTex, i.texcoord1.xy + noiseUV);

				#ifdef _MASKMODE_MASK
				final += _MASKTintColor;
				mask = pow(mask*maskT*_MASKBrightness, _MASKCutoff*2);
				#endif
				#endif
				
				//noise
				#ifndef _NOISEMODE_NONE
				half4 noiseT = tex2D(_NOISETex, i.texcoord1.zw + noiseUV);



		
				noiseT.a *= Luminance(noiseT.rgb);

			
				#ifdef _NOISEMODE_MASK

				mask = pow(mask*noiseT * _NOISEBrightness, _NOISECutoff*2);

				#elif _NOISEMODE_DISTORTION
				dist += applyCutoff(_NOISECutoff, _NOISEBrightness, noiseT.r, i.color.a);
				final.rgb = lerp(_NOISETintColor*final.a, final.rgb, saturate(dist*dist*dist));
				#endif
				#endif			
				
				final *= saturate(mask);
				final.rgb *= 2.0f * i.color.rgb;
				final.a *= i.color.a;
				final = saturate(final);

				#if defined(_NOISEMODE_DISTORTION)
				final.a *= saturate(dist);
				final.rgb *= saturate(dist);
				#endif

#ifdef UNITY_UI_CLIP_RECT                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
				final.a *= UnityGet2DClipping(i.worldPosition.xy, _ClipRect);
#endif

#ifdef UNITY_UI_ALPHACLIP
				clip(final.a - 0.001);
#endif
			
                return final;
            }
            ENDCG
        }
    }
}
//CustomEditor "ParticleMaskGUI"
}
