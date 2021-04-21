#ifndef FOGCORE_INCLUDED
#define FOGCORE_INCLUDED

#include "UnityCG.cginc"

//Variants
half _FogTop = 5.1;
half _FogDown = 1.1;
samplerCUBE _FogCube;
half _FogCubeRot = 430;

//#include "../Fog/FogCore.cginc"
//half fogCoord	: TEXCOORD4;
//float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
//o.fogCoord = GetFogCoord(o.pos, posWorld);
//finalColor = lerp(finalColor.rgb,unity_FogColor.rgb,i.fogCoord);

half3 RotateAround(half3 vertex, half degrees)
{
	half alpha = degrees * UNITY_PI / 180.0;
	half sina, cosa;
	sincos(alpha, sina, cosa);
	float2x2 m = float2x2(cosa, -sina, sina, cosa);
	return half3(mul(m, vertex.xz), vertex.y).xzy;
}


//o.fogCoord = GetFogCoord(o.pos, o.posworld);
inline half GetFogCoord (half3 pos,half3 wpos)
{	
#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
	UNITY_CALC_FOG_FACTOR_RAW(UNITY_Z_0_FAR_FROM_CLIPSPACE(pos.z)); //unityFogFactor
	unityFogFactor = 1-saturate(unityFogFactor);
	half wposY = 1 -wpos.y*(1 - unity_FogColor.a);
	//half lens = distance(_WorldSpaceCameraPos.xyz,wpos.xyz)*0.001;
	half coord = saturate(unityFogFactor*wposY);
	return coord;
#else
	return 0; 
#endif
} 

//float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - posWorld);
//finalColor.rgb = ApplySkyboxFog(finalColor.rgb, i.fogCoord, viewDir);
inline half3 ApplySkyboxFog (half3 c, half fogCoord, half3 viewdir)
{	
	half3 cubefog = texCUBE(_FogCube, RotateAround(viewdir*half3(1,-1,1), 430)).rgb;
	float VoL = saturate(dot(viewdir, -_WorldSpaceLightPos0.xyz));
	//fogCoord = saturate(fogCoord+ fogCoord* VoL*0.5);
	fogCoord = saturate(fogCoord);
	half3 suncolor = saturate(pow(VoL,32)*fixed3(1,0.3,0));
	return lerp(c.rgb, unity_FogColor.rgb+suncolor.rgb, fogCoord);
}

//finalColor = ApplySunFog(finalColor.rgb, i.fogCoord, viewDir);
inline half3 ApplySunFog (half3 c, half fogCoord, half3 viewdir)
{	
	float VoL = saturate(dot(viewdir, -_WorldSpaceLightPos0.xyz));
	fogCoord = saturate(fogCoord);
	//fogCoord = saturate(fogCoord+ fogCoord* VoL*0.5);
	half3 suncolor = saturate(pow(VoL,4)*fixed3(0.3,0.16,0));
	return lerp(c.rgb, unity_FogColor.rgb, fogCoord);
	//return lerp(c.rgb, saturate(unity_FogColor.rgb+suncolor.rgb), fogCoord);
}

//finalColor = ApplyFog(finalColor.rgb, i.fogCoord);
inline half3 ApplyFog (half3 c,half fogCoord)
{			
	half gray = Luminance( c.rgb);
	fogCoord = saturate(fogCoord + (1-gray)*1.5* fogCoord);
	return lerp(c.rgb, unity_FogColor.rgb, fogCoord);
}


#endif