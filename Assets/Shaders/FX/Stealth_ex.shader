// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Omega/FX/Stealth_ex" {
	Properties{
		[Header((MainPass))]
		_DissolveMap("Dissolve Map", 2D) = "white" {}
		_DissolveColorMap("Dissolve Color Map", 2D) = "white" {}

		_DissolveColor("Dissolve Color", Color) = (1,1,1,1)
		_DissolveEdgeColor("Dissolve Edge Color", Color) = (1,1,1,1)

		_DissolveThreshold("DissolveThreshold", Range(0, 1)) = 0.17
		_ColorFactor("Color Factor", Range(0, 1)) = 0.7
		_Transparency("Transparency", Range(0, 1)) = 0.9
		[HideInInspector]_Cutoff("Alpha cutoff", Range(0,1)) = 0.5


		[Space(30)]
		[Header((SubPass))]
		[HideInInspector]_OwnerLightAmbient("环境光颜色", Color) = (0.1,0.1, 0.2, 1)
		[HideInInspector]_SkinColor("表皮肤色", Color) = (0.6,0.54,0.5,1)
		[HideInInspector]_SkinDeepColor("真皮透光颜色", Color) = (0.691,0.267,0.142,1)
		[HideInInspector]_EmissiveColor("自发光颜色", Color) = (0.5,0.5,0.5,1)
		[HideInInspector]_Gloss("光滑度补偿", Range(0.0, 2.0)) = 1
		[HideInInspector]_Metal("金属补偿", Range(0.0, 2.0)) = 1
		[HideInInspector]_EnvMin("环境光下限值",Range(0,0.5)) = 0.1
		[HideInInspector]_ColorfulAll("整体饱和度", Range(0.0, 2.0)) = 1
		[HideInInspector]_ColorfulMetal("反光饱和度", Range(0.0, 2.0)) = 1
		[HideInInspector]_HighlightSaturation("高光饱和度", Range(0,2)) = 1
		[HideInInspector]_SKin("皮肤补偿", Range(0, 2.0)) = 1
		[HideInInspector]_SKinShadow("皮肤暗部补偿", Range(0, 8.0)) = 0.5
		[HideInInspector]_MainLightIntensity("照明光", Range(0,2)) = 1
		[HideInInspector]_Highlight("高光强度", Range(0,2)) = 1
		[HideInInspector]_AmbientLight("环境光", Range(0,2)) = 1
		[HideInInspector]_CubeIntensity("环境反光", Range(0,2)) = 1
		[HideInInspector]_Rotation("旋转Cubemap", Range(-360,360)) = 0
		[HideInInspector]_ShadowIntensity("阴影强度", Range(0, 1)) = 0.5
		[HideInInspector]_SelfShadowSize("阴影范围", Range(0, 1)) = 0.1
		[HideInInspector]_SelfShadowHardness("阴影硬度", Range(0, 1)) = 0.55
		[HideInInspector]_AO("AO", Range(0, 2)) = 0.5
		[HideInInspector]_MaskModeHeight("渐变", Range(0.0, 2.0)) = 1
		[HideInInspector]_MaskVector("渐变方向",Vector) = (0,0,0,1)
		[HideInInspector][Toggle]_ANiEmi("循环自发光动画",float) = 0
		[HideInInspector]_AniSpeed("Emissive Shark", Range(0.0, 1.0)) = 0.5
		[HideInInspector]_ColorE("Color+E", 2D) = "white" {}
		[HideInInspector]_SMMS("SMMS", 2D) = "white" {}
		[HideInInspector]_Normal("Normal", 2D) = "bump" {}
		[HideInInspector]_Cubemap("Cubemap",Cube) = "cube" {}
	}
		SubShader
	{
		Tags {"Queue" = "Transparent" "Shadow" = "Character"}

		GrabPass{ }

		Pass
		{

			Tags {"LightMode" = "ForwardBase" }
			ColorMask RGBA
			ZTest LEqual
			ZWrite On

			CGPROGRAM
			#pragma target 3.0
			#pragma only_renderers d3d11 glcore gles gles3 metal d3d9
			//#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

			#define _CHLODZERO
			#define _EMISSION
			#define _RAMP
			//#pragma multi_compile _ _SOFTSHADOW
			//#pragma multi_compile _ _RECEIVESHADOW
			#pragma multi_compile_fog

			#pragma vertex CHVertLow
			#pragma fragment CHFragLow

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "../CH/CHCore.cginc"
			ENDCG
		}

		Pass
		{
			Tags {"LightMode" = "ForwardBase" }
			ColorMask RGBA
			ZTest LEqual
			ZWrite On
			Blend One OneMinusSrcAlpha

			CGPROGRAM
			#pragma target 3.0
			#pragma only_renderers d3d11 glcore gles gles3 metal d3d9

			#pragma vertex CustomvertStealth
			#pragma fragment CustomfragStealth

			#include "UnityCG.cginc"

			sampler2D _DissolveMap;
			float4 _DissolveMap_ST;
			sampler2D _GrabTexture;
			//sampler2D _Normal;
			//half4 _Normal_ST;
			sampler2D _DissolveColorMap;
			half4 _DissolveColorMap_ST;
			fixed _DissolveThreshold;
			fixed _ColorFactor;
			fixed _Transparency;

			half4 _DissolveColor;
			half4 _DissolveEdgeColor;

			//in
			struct CustomVertexInput
			{
				half4 vertex   : POSITION;
				half3 normal    : NORMAL;
				half2 uv0      : TEXCOORD0;
			};

			//out
			struct CustomVertexOutputForward
			{
				UNITY_POSITION(pos);
				half4 uv                                : TEXCOORD0;    //VertexUV.xy | Mask.zw
				float3 normal							: TEXCOORD1;
				float3 posWorld							: TEXCOORD2;
			};

			CustomVertexOutputForward CustomvertStealth(CustomVertexInput v)
			{
				CustomVertexOutputForward o;
				UNITY_INITIALIZE_OUTPUT(CustomVertexOutputForward, o);

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.uv0.xy;
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;

	#if UNITY_UV_STARTS_AT_TOP
					float scale = -1.0;
	#else
					float scale = 1.0;
	#endif
					o.uv.zw = (float2(o.pos.x / o.pos.w, o.pos.y / o.pos.w * scale) + float2(1.0, 1.0)) * 0.5;
					return o;
			}

			half4 CustomfragStealth(CustomVertexOutputForward i) : COLOR
			{
				//input tex
				float4 dissolvetex = tex2D(_DissolveMap, TRANSFORM_TEX(i.uv, _DissolveMap));
				fixed4 destColortex = tex2D(_DissolveColorMap, TRANSFORM_TEX(i.uv, _DissolveColorMap));
				//float3 normaltex = UnpackNormal(tex2D(_Normal,TRANSFORM_TEX(i.uv, _Normal)));


				//Setup
				half3 normal = i.normal.xyz;
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld);
				float NoV = 1 - saturate(dot(normal, viewDir));

				float4 grabTex = tex2D(_GrabTexture, i.uv.zw + i.normal.xy*0.1* NoV);
				//return float4(grabTex.rgb, dissolvetex.r + destColortex.r * 0.25);
				//out						
				half alphaPercent = _DissolveThreshold - dissolvetex.r;
				half edgePercent = alphaPercent - _ColorFactor * 0.1;
				half dissolvePercent = alphaPercent - _ColorFactor;

				destColortex = lerp(_DissolveColor, destColortex, destColortex.a);
				destColortex.rgb = destColortex.rgb + _DissolveColor.rgb * destColortex.a;

				half alpha = saturate(ceil(alphaPercent));
				half edge = saturate(ceil(-edgePercent));
				half dissolve = saturate(ceil(dissolvePercent));

				float3 finalColor = lerp(NoV, grabTex.rgb, _Transparency);
				destColortex.rgb += _DissolveEdgeColor.rgb*edge;
				finalColor = lerp(destColortex.rgb*alpha, finalColor, dissolve);

				return half4(finalColor, alpha);
			}
		ENDCG
		}
	}
}
