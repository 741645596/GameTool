#ifndef PLANTSCORE_INCLUDED
#define PLANTSCORE_INCLUDED

#include "AutoLight.cginc"
#include "UnityCG.cginc"
#include "../Fog/FogCore.cginc"
#include "../Shadow/shadowmap.cginc"
//color			
half4 _Color;
 
//Variants
fixed _Cutoff;
#define _DistCull 35

half plantScopeDist;

//fixed _ShadowDistance, _ShadowFade;
#ifdef _USEWIND
fixed _RateX, _RateY, _Speed, _Strength;
#endif

//texture
sampler2D _Lightmap;
float2 _WorldSize;
half _LightmapContrast;
half _LightmapBrightness;
half _DesaturateLightmap;
sampler2D _MainTex;
half4 _MainTex_ST;

half4 _LightColor0;

//in
struct CustomVertexInput
{
	half4 vertex   : POSITION;
	half3 normal    : NORMAL;
	half4 color : COLOR;
	half2 uv0      : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

//out
struct CustomVertexOutputForwardBase
{
	UNITY_POSITION(pos);
	half4 color : COLOR0;
	half3 uv                                : TEXCOORD0;
	half4  posworld							: TEXCOORD1;
	half4 fogCoord	: TEXCOORD2;
	MY_SHADOW_COORDS(3)
};

float4 CalculateContrast(float contrastValue, float4 colorTarget)
{
	float t = 0.5 * (1.0 - contrastValue);
	return mul(float4x4(contrastValue, 0, 0, t, 0, contrastValue, 0, t, 0, 0, contrastValue, t, 0, 0, 0, 1), colorTarget);
}

//vs
CustomVertexOutputForwardBase CustomvertBase(CustomVertexInput v)
{
	UNITY_SETUP_INSTANCE_ID(v);
	CustomVertexOutputForwardBase o;
	UNITY_INITIALIZE_OUTPUT(CustomVertexOutputForwardBase, o);
	//UNITY_TRANSFER_INSTANCE_ID(v, o);

	o.posworld = mul(unity_ObjectToWorld, v.vertex);

#ifdef _USEWIND
	float2 windPos = o.posworld.xy / float2(_RateX, _RateY) + _Time.y* _Speed;
	float windmask = clamp(v.vertex.y,-8,8);
	v.vertex.z += sin(windPos.x)*windmask*_Strength;
	v.vertex.x += cos(windPos.y)*windmask*_Strength;
#endif

	o.uv.z = distance(_WorldSpaceCameraPos.xz, o.posworld.xz);
	o.pos = UnityObjectToClipPos(v.vertex);  
	o.uv.xy = v.uv0.xy*_MainTex_ST.xy + _MainTex_ST.zw; 
	o.color = v.color;

	half2 lmUV = o.posworld.xz / (_WorldSize * 256.0);
	half4 lm = tex2Dlod(_Lightmap, half4(lmUV.xy, 0, 0));
	half3 Contrastlm = CalculateContrast(_LightmapContrast, (lm * _LightmapBrightness)).rgb;
	o.color.a = dot(Contrastlm, half3(0.299, 0.587, 0.114));
	o.color.rgb = lerp(Contrastlm, o.color.aaa, _DesaturateLightmap);

//#ifdef _RECEIVESHADOW
	TRANSFER_MY_SHADOW(o, o.posworld.xyz)
//#endif
	o.fogCoord = GetFogCoord(o.pos, o.posworld);
	return o;
} 

//Base
half4 CustomfragBase(CustomVertexOutputForwardBase i) : COLOR
{
	//UNITY_SETUP_INSTANCE_ID(i);

	//input tex
	float4 albedo = tex2D(_MainTex,i.uv.xy);
	albedo.a *= 1 - saturate(i.uv.z - _DistCull);
	clip(albedo.a - _Cutoff);

	float ReceiveShadow = MY_SHADOW_ATTENTION(i, half3(0, 1, 0), i.posworld);

	float3 ShadowColor = ReceiveShadow + (1 - ReceiveShadow)*_ShadowColor.rgb;
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posworld);

	//fianl
	float3 finalColor = albedo * _Color.rgb * 4;

	float lmshadow = i.color.a;
	float3 lmcolor = i.color.rgb;
	finalColor *= lerp(lmcolor, ShadowColor, lmshadow) * _LightColor0.rgb;

	float finalAlpha = albedo.a;

	finalColor.rgb = ApplySunFog(finalColor.rgb, i.fogCoord, viewDir);

	return saturate(half4(finalColor, finalAlpha));
}
#endif
