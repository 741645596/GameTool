Shader "Omega/Water/OmegaWaterSimple"
{
	Properties
	{
		[Header(Cubemap)]
		_TintColor("NealColor", Color) = (0.6,0.4,0.5,0.5)
		_RelfColor("FarColor", Color) = (0.6,0.4,0.5,0.5)
		_ReflTex("ReflTex",CUBE) = "white" {}
		_Rotation("RotationCubemap", Range(-360,360)) = 0
		_AlphaScale("AlphaScale", Range(0 , 3)) = 1.5

		[Header(Normal)]
		_SpecColor("SpecColor", Color) = (0.6,0.4,0.5,0.5)
		_BumpMap("Normalmap", 2D) = "bump" {}
		_Normal("DiffNormalScale", Range(0 , 1)) = 0.5
		_RelfNormal("SpecNormalScale", Range(0 , 1)) = 0.5
		[PowerSlider(5.0)] _Shininess("Shininess", Range(0.03, 1)) = 0.078125

		[Header(Animation)]
		_VertexSpeed("VertexSpeed",vector) = (0,0,0,0)
		_WaterSpeed("NormalSpeed",vector) = (1,1,0,0)
		_Water2Speed("Normal2Speed",vector) = (1,1,0,0)

		//[Header(Lightmap)]
		//_Lightmap("Lightmap", 2D) = "white" {}
		//_DesaturateLightmap("Desaturate Lightmap", Range(-2 , 2)) = 0

		//[Header(Shadow)]
		//_ShadowColor("ShadowColor (RGB)", Color) = (0.5,0.5,0.5,1)
		//_ShadowDistance("ShadowDistance",float) = 20
		//_ShadowFade("ShadowFade",Range(0.1,1)) = 0.1
		[Enum(Zero,0,One,1,DstColor,2,SrcAlpha,5)]  _SrcBlend("SrcFactor",Int) = 5
		[Enum(Zero,0,One,1,OneMinusSrcAlpha,10)]  _DstBlend("DstFactor",Int) = 10
	}

	SubShader
	{ 
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent"}
		//Cull off
		//Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
		Blend[_SrcBlend][_DstBlend]
	
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 3.0

			//#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			//#pragma multi_compile _LIGHTMAP
			#pragma multi_compile _USENORMAL
			#pragma multi_compile _ HIGH_LEVEL_WATER

			#pragma vertex CustomvertBase
			#pragma fragment CustomfragBase

			#include "AutoLight.cginc"
			#include "UnityCG.cginc"
			#include "../Fog/FogCore.cginc"

			//Variants
			float _Shadow;
			float _Rotation;
			float _Normal;
			float _RelfNormal;
			float _AlphaScale;

			float4 _VertexSpeed; 
			float4 _WaterSpeed,_Water2Speed;

			//UNITY_DECLARE_TEX2D(_Lightmap);
			//float _DesaturateLightmap;

			float _Shininess;

			UNITY_DECLARE_TEX2D(_BumpMap); 
			float4 _BumpMap_ST;

			samplerCUBE _ReflTex;
			sampler2D _CameraDepthTexture;

			//color			
			float4 _TintColor;
			float4 _RelfColor;
			float4 _LightColor0;
			float4 _SpecColor;
			//float4 _ShadowColor;
			//float _ShadowDistance,_ShadowFade;


			//in
			struct CustomVertexInput
			{
				float4 vertex   : POSITION;
				float3 normal    : NORMAL;
				float2 uv0      : TEXCOORD0;
				float4 uv1      : TEXCOORD1;
				float4 tangent   : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				float4 color		:COLOR;
			};

			//out
			struct CustomVertexOutputForwardBase
			{
				UNITY_POSITION(pos);
				float4 uv                                : TEXCOORD0;    //VertexUV.xy
				float4 tangentToWorldAndPackedData[3]   : TEXCOORD1;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
				//UNITY_FOG_COORDS(4)
				half fogCoord	: TEXCOORD4;
				//UNITY_SHADOW_COORDS(5)
				float4 color								: COLOR;
			};

			float4 BlendNormals(float4 n1, float4 n2)
			{
				return lerp(n1,n2,0.5);
			}

			float3 CustomRotateAroundYInDegrees (float3 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float3(mul(m, vertex.xz), vertex.y).xzy;
            }   

			//vs
			CustomVertexOutputForwardBase CustomvertBase(CustomVertexInput v)
			{ 
				UNITY_SETUP_INSTANCE_ID(v);  
				CustomVertexOutputForwardBase o;
				//UNITY_INITIALIZE_OUTPUT(CustomVertexOutputForwardBase, o);
				//UNITY_TRANSFER_INSTANCE_ID(v, o);

				float waveh = cos(sin((_VertexSpeed.x*v.vertex.x + v.vertex.z*_VertexSpeed.y)*(_Time.x*_VertexSpeed.z))) *_VertexSpeed.w - (_VertexSpeed.w*0.55);
				//v.vertex.y += waveh;
				 
				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.tangentToWorldAndPackedData[0].w = posWorld.x; 
				o.tangentToWorldAndPackedData[1].w = posWorld.y; 
				o.tangentToWorldAndPackedData[2].w = posWorld.z;
				o.pos = UnityObjectToClipPos(v.vertex);

				//WorldUV  
				o.uv.xy = mul(unity_ObjectToWorld, v.vertex).xz;
				o.uv.zw = v.uv1.xy;

				float3 normalWorld = UnityObjectToWorldNormal(v.normal);
				float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
				float sign = tangentWorld.w * unity_WorldTransformParams.w;
				float3 binormal = cross(normalWorld, tangentWorld.xyz) * sign;
				float3x3 tangentToWorld = float3x3(tangentWorld.xyz, binormal, normalWorld);
				o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
				o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
				o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];

#if defined(HIGH_LEVEL_WATER)
				o.color = v.color;
				o.color.a *= _AlphaScale;
#else
				o.color = float4(1, 1, 1, 1);//v.color;
#endif
				//o.color.a *= saturate(waveh);
				//TRANSFER_SHADOW(o);
				//UNITY_TRANSFER_FOG(o, o.pos);

				//o.fogCoord = saturate(distance(_WorldSpaceCameraPos.xyz, abs( posWorld.xyz))*0.0006);
				o.fogCoord = GetFogCoord(o.pos, posWorld);
				return o;
			}

			 
			//Base
			float4 CustomfragBase(CustomVertexOutputForwardBase i) : COLOR
			{
				UNITY_SETUP_INSTANCE_ID(i); 
				//wave 
				
				float2 norUV = i.uv.xy*_BumpMap_ST.xy;
				float4 nor1 = UNITY_SAMPLE_TEX2D(_BumpMap, norUV + frac(_Time.x*_WaterSpeed.xy));
				float4 nor2 = UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _BumpMap,norUV * 1.2 - frac(_Time.x*_WaterSpeed.zw));
				float4 nor3 = UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _BumpMap,norUV * 0.3 + frac(_Time.x*_Water2Speed.xy));
				float4 nor4 = UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _BumpMap,norUV * 0.2 - frac(_Time.x*_Water2Speed.zw));

				float4 NorMix1 = BlendNormals(nor1, nor2);
				float4 NorMix2 = BlendNormals(nor3, nor4);
				float4 blendNor =  BlendNormals(NorMix1, NorMix2);

				//normal
				float3 tangent = i.tangentToWorldAndPackedData[0].xyz;
				float3 binormal = i.tangentToWorldAndPackedData[1].xyz;
				float3 unpackNor = UnpackNormal(blendNor);
				float3 norDir = tangent * unpackNor.x + binormal * unpackNor.y + i.tangentToWorldAndPackedData[2].xyz * unpackNor.z;
				float3 softnorDir = lerp(i.tangentToWorldAndPackedData[2].xyz,norDir, _RelfNormal);
				norDir = lerp(i.tangentToWorldAndPackedData[2].xyz, norDir, _Normal);
				//norDir = saturate(norDir);
				//softnorDir = saturate(softnorDir);
				//dir
				float3 posWorld = float3(i.tangentToWorldAndPackedData[0].w, i.tangentToWorldAndPackedData[1].w, i.tangentToWorldAndPackedData[2].w);
				float NoL = saturate(dot(softnorDir, _WorldSpaceLightPos0.xyz));
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - posWorld);
				float3 reflDir = normalize(reflect(-viewDir, softnorDir));
				float3 LoV = normalize(viewDir + _WorldSpaceLightPos0.xyz);
				float NoH = saturate(dot(norDir, LoV));
				float NoV = saturate(dot(softnorDir, viewDir));
				float3 specularTerm = pow(NoH, 128 * _Shininess)*_SpecColor;

				//lm
				/*
				float4 lmoffset = float4(43.38, 43.43, 3.34, -1.97);
				float2 lmUV = i.uv.xy * lmoffset.xy*0.00001 + lmoffset.zw*0.0001;
				float4 lightmap = UNITY_SAMPLE_TEX2D(_Lightmap, lmUV);
				float lmshadow = dot(lightmap.rgb, float3(0.299, 0.587, 0.114));
				float3 lmcolor = lerp(lightmap.rgb, lmshadow.xxx, _DesaturateLightmap);
				*/
				//lmcolor = saturate(lmcolor);

				//shadow
				//float ReceiveShadow = SHADOW_ATTENUATION(i);
				//ReceiveShadow = saturate(lerp(ReceiveShadow, 1.0, (distance(posWorld.xyz, _WorldSpaceCameraPos.xyz) - _ShadowDistance) * _ShadowFade));
				//float3 ShadowColor = ReceiveShadow + (1 - ReceiveShadow)*_ShadowColor.rgb;

				//Fresnel
				float Fresnel = pow(1.0 - NoV, 2.8)*0.9 + 0.1;

				//Refl
				reflDir = CustomRotateAroundYInDegrees(reflDir, _Rotation);
				float3 reflspec = texCUBE(_ReflTex, reflDir).rgb;

				//fianl
				float3 sAlbedo = _TintColor.rgb;
				//sAlbedo *= lmcolor;

				float3 finalColor = lerp(sAlbedo * NoL, reflspec* _RelfColor.rgb, Fresnel);

				finalColor *= i.color.rgb ;
				finalColor += specularTerm;

				float finalAlpha = i.color.a * _TintColor.a;

				//UNITY_APPLY_FOG(i.fogCoord, finalColor.rgb);
				//finalColor.rgb = lerp(finalColor.rgb, unity_FogColor.rgb, i.fogCoord);
				//float fogcoord = distance(_WorldSpaceCameraPos.xyz, posWorld.xyz) * 0.00036;
				finalColor = ApplySunFog(finalColor.rgb, i.fogCoord, viewDir);

				//finalColor = finalColor;
				//finalAlpha = 1;
				return saturate(float4(finalColor, finalAlpha));
			}			
			ENDCG
		}	
	}
//FallBack "Legacy Shaders/Override/VertexLit"
}
