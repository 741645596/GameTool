#ifndef SHADOW_INCLUDED
#define SHADOW_INCLUDED
#include "HLSLSupport.cginc"

SamplerState sampler_point_clamp;

#define SHADOWMAP_MAX_MIP (11)
#define SOFT_SHADOW_SAMPLER 4

float4x4 _ShadowMatrix;
float4 _ShadowParams;
#define shadowStrength   (_ShadowParams.x)
//#define shadowBias       (_ShadowParams.y)
#define shadowBias       (-0.002)
//#define shadowBias       (0)
//#define shadowNormalBias (_ShadowParams.z)
#define shadowNormalBias (-0.001)
//#define shadowNormalBias (0)
#define shadowDistance   (_ShadowParams.w)
Texture2D _ShadowMap;
TextureCube _ShadowMapCUBE;
int _ShadowMapMipLevel;
float4 _ShadowMap_TexelSize;
float4x4 _CascadeShadowMatrix[4];
float _CascadeShadowSplit;

struct v2f_shadow
{
	float4 pos : SV_POSITION;
	float depth : TEXCOORD0;
};

float Screen(float a, float b)
{
	return 1 - (1 - a) * (1 - b);
}

float ShadowCompare(float3 shadowCoord, float cascadeLevel)
{
	float4 shadowmap = _ShadowMap.SampleLevel(
		sampler_point_clamp,
		float3(shadowCoord.xy, cascadeLevel),
		0);
	float2 encodedShadow = cascadeLevel == 1 ? shadowmap.ba : shadowmap.rg;//fixed2(shadowmap[cascadeLevel * 2], shadowmap[cascadeLevel * 2 + 1]);
	float shadow = DecodeFloatRG(encodedShadow) / 0.99;
	return step(shadow, shadowCoord.z);
}

float ShadowCompare(float2 shadowCoord, float depth, float cascadeLevel)
{
	return ShadowCompare(float3(shadowCoord, depth), cascadeLevel);
}

float ShadowCompareBilinear(float2 shadowCoord, float depth, float cascadeLevel)
{
	float2 uv_lb = floor(shadowCoord.xy * _ShadowMap_TexelSize.zw) * _ShadowMap_TexelSize.xy;
	float2 uv_rt = ceil(shadowCoord.xy * _ShadowMap_TexelSize.zw) * _ShadowMap_TexelSize.xy;
	float2 t = frac(shadowCoord.xy * _ShadowMap_TexelSize.zw);
	float lb = ShadowCompare(uv_lb, depth, cascadeLevel);
	float lt = ShadowCompare(float2(uv_lb.x, uv_rt.y), depth, cascadeLevel);
	float rb = ShadowCompare(float2(uv_rt.x, uv_lb.y), depth, cascadeLevel);
	float rt = ShadowCompare(uv_rt, depth, cascadeLevel);
	float2 hori = lerp(float2(lb, lt), float2(rb, rt), t.x);
	float bilinear = lerp(hori.x, hori.y, t.y);
	return bilinear;
}

float GetShadowAttenuation(float4 shadowCoord)
{
	float cascadeLevel = step(_CascadeShadowSplit, shadowCoord.w);
	float2 uv_lb = floor(shadowCoord.xy * _ShadowMap_TexelSize.zw) * _ShadowMap_TexelSize.xy;
	float2 uv_rt = ceil(shadowCoord.xy * _ShadowMap_TexelSize.zw) * _ShadowMap_TexelSize.xy;
	float2 t = frac(shadowCoord.xy * _ShadowMap_TexelSize.zw);
	float lb = ShadowCompare(uv_lb, shadowCoord.z, cascadeLevel);
	float lt = ShadowCompare(float2(uv_lb.x, uv_rt.y), shadowCoord.z, cascadeLevel);
	float rb = ShadowCompare(float2(uv_rt.x, uv_lb.y), shadowCoord.z, cascadeLevel);
	float rt = ShadowCompare(uv_rt, shadowCoord.z, cascadeLevel);
	float2 hori = lerp(float2(lb, lt), float2(rb, rt), t.x);
	float bilinear = lerp(hori.x, hori.y, t.y);
	
	float pcf = dot(0.25, float4(lb,lt,rb,rt));

	//return pcf;
	//return  bilinear;
	//return Screen(pcf, bilinear);
	return (pcf + bilinear) * 0.5;
}

float4 GetShadowCoord(float3 worldPos)
{
	float3 viewDir = normalize(mul(unity_CameraToWorld, float3(0, 0, 1)));
	float dist = (dot(viewDir, worldPos - _WorldSpaceCameraPos) / shadowDistance);
	float cascadeLevel = step(_CascadeShadowSplit, dist);
	float4 shadowCoord = mul(_CascadeShadowMatrix[cascadeLevel], float4(worldPos, 1));
	shadowCoord.xyz /= shadowCoord.w;
	shadowCoord.xy = shadowCoord.xy * 0.5 + 0.5;
	shadowCoord.w = dist;
	return shadowCoord;
}

float GetShadowAttenuation(float3 worldPos, float3 worldNormal)
{
	float4 shadowCoord = GetShadowCoord(worldPos);
	float3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	float bias = max(shadowNormalBias * (1 - dot(normalize(worldNormal), lightDir)), shadowBias);
	shadowCoord.z += bias;
	float falloff = saturate((shadowCoord.w - 0.9) / 0.1);
	float shadow = GetShadowAttenuation(shadowCoord);
	return Screen(shadow, falloff);
}

#endif //SHADOW_INCLUDED