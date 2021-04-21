#ifndef CHCORE_INCLUDED
#define CHCORE_INCLUDED

#include "UnityCG.cginc"
#include "../cginc/shadowmap.cginc"
#include "../cginc/FogCore.cginc"

//variants
float4 _OwnerLightAmbient;
half _Luminance;

float _CubeIntensity;
float _MainLightIntensity;
float _Gloss,_Metal, _Spec, _Highlight;

float _AmbientLight;
half _ColorfulMetal;
float _EnvMin;

sampler2D _SMMS;
float4 _SMMS_ST;

//#ifdef _RECEIVESHADOW
float _ShadowIntensity;
//#endif 

//#ifdef _SOFTSHADOW
float _SelfShadowSize;
float _SelfShadowHardness;
//#endif

#if defined(_MATCAP)
sampler2D _MatcapTex;
float4 _MatcapTex_ST;
float _RimLight;
float _RimShaodowLight; 
//float _Rotation;
#endif // _MATCAP

#if defined(_RAMP)
float4 _MaskVector;
float _MaskModeHeight;
#endif // _RAMP

float _AO;

#if defined(_EMISSION)
float _ANiEmi;
float4 _EmissiveColor; 
float _AniSpeed;
#endif // _EMISSION

#if defined(_ALPHATEST)
fixed _Clip;
#endif // _ALPHATEST

#if defined(_CHDISPLAY) || defined(_CHLODZERO) || defined(_CHLODONE)
float4 _SkinColor;
float4 _SkinDeepColor; 
float _SKin;
float _SKinShadow;
#endif

#if defined(_INFERENCE)
float _InferenceHighlight;
float _InferenceColorfulMetal;
float _InferenceMainLightIntensity;
float _InferenceCubeIntensity;
float _InferenceShadowIntensity;
sampler2D _Ramp;
float4 _Ramp_ST;
float _Tint;
sampler2D _Thickness;
float _ThicknessFactor;
TextureCube _Reflect;
sampler2D _InferenceMask;
#endif

//texture
sampler2D _ColorE; 
float4 _ColorE_ST;
sampler2D _Normal; 
float4 _Normal_ST;
#ifndef NORMAL_SCALE
#define _NormalScale 1.0
#endif // !_NormalScale;

#if defined(_SKINMASK)
float4 _PatternColor1;
sampler2D _PatternMaskTex; 
float4 _PatternMaskTex_ST;
#endif // _SKINMASK

#ifdef _SKINADDCOLOR
float4 _PatternColor2;
#endif // _SKINADDCOLOR

#ifdef _SKINPATTERN
sampler2D _PatternTex; 
float4 _PatternTex_ST;
#endif // _SKINPATTERN

UNITY_DECLARE_TEXCUBE(_ReflTex);

//color
float4 _LightColor0;

half3x3 Tan2WorldMatrix(half3 normal, half4 tangent)
{
	normal = normalize(normal);
	tangent = normalize(tangent);
    half3 normalWorld = UnityObjectToWorldNormal(normal);
    half4 tangentWorld = half4(UnityObjectToWorldDir(tangent.xyz), tangent.w);
    half sign = tangentWorld.w * unity_WorldTransformParams.w;
    half3 binormal = normalize(cross(normalWorld, tangentWorld.xyz) * sign);
    return transpose(half3x3(tangentWorld.xyz, binormal, normalWorld));
}

half GetSpecTerm (half perceptualRoughness,half nh, half nl , half nv)
{
    half roughness = max((perceptualRoughness * perceptualRoughness),0.002);
	half lambdaV = nl * (nv * (1 - roughness) + roughness);
	half lambdaL = nv * (nl * (1 - roughness) + roughness);
	half GGVTerm =  0.5f / (lambdaV + lambdaL + 1e-5f);

	half roughness2 = roughness * roughness;
	half nhroughness = (nh * roughness2 - nh) * nh + 1.0f;
	half GGXTerm = UNITY_INV_PI * roughness2 / (nhroughness * nhroughness + 1e-7f);

	half specularTerm = GGVTerm * GGXTerm * UNITY_PI;
	specularTerm = sqrt(max(1e-4h, specularTerm));
	specularTerm = max(0, specularTerm * nl);
    return specularTerm;
}

half3 CustomUnity_GlossyEnvironment(UNITY_ARGS_TEXCUBE(tex), half4 hdr, half roughness, half3 reflUVW)
{
	half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex, reflUVW,roughness);
    return DecodeHDR(rgbm,hdr);
}

half3 GetEnvCube (half glossness,half3 reflDir)
{
	return CustomUnity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, glossness, reflDir);
}

struct CustomAppData
{
	half4 vertex    : POSITION;
	half3 normal    : NORMAL;
	half4 tangent   : TANGENT;
	half2 texcoord  : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct CHVertexOutputForwardBase
{
	UNITY_POSITION(pos);
    half4 uv             : TEXCOORD0;    //VertexUV.xy | Mask.zw
    half3x3 tanToWorld   : TEXCOORD1;
	float3 worldPos      : TEXCOORD4;
	MY_SHADOW_COORDS(5)
	half4 fogCoord       : TEXCOORD6;
	#if defined(_MATCAP)
    half3 TtoVo[2]       : TEXCOORD7;
    #endif
    #ifdef _SKINPATTERN
    half4 uv2           : TEXCOORD9;
    #endif

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

CHVertexOutputForwardBase CHVertBase(CustomAppData v)
{
	UNITY_SETUP_INSTANCE_ID(v);
	CHVertexOutputForwardBase o;
	UNITY_TRANSFER_INSTANCE_ID(v, o);

	float4 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz,1));
	o.worldPos = worldPos.xyz;
	o.pos = mul(UNITY_MATRIX_VP, worldPos);

	o.uv.xy = v.texcoord;
	o.uv.zw = 0;

	#if defined(_RAMP)
    o.uv.z = dot(_MaskVector.xyz,abs(v.vertex.xyz+_MaskVector.w));
    #elif defined(_SKINMASK)
    o.uv.zw = v.vertex.xz;
    #endif

    o.tanToWorld = Tan2WorldMatrix(v.normal, v.tangent);
    
	#if defined(_MATCAP)
	o.TtoVo[0] = mul(normalize(UNITY_MATRIX_V[0].xyz), o.tanToWorld);
    o.TtoVo[1] = mul(normalize(UNITY_MATRIX_V[1].xyz), o.tanToWorld);
    #endif

    #ifdef _SKINPATTERN
    o.uv2.w = v.vertex.y;
    o.uv2.xyz = v.normal.xyz;
    #endif

    //#ifdef _RECEIVESHADOW
	TRANSFER_MY_SHADOW(o, o.worldPos);
    //#endif

	o.fogCoord = GetFogCoord(o.pos, o.worldPos);

	return o;
}

//Base
half4 CHFragBase(CHVertexOutputForwardBase i) : COLOR
{
    UNITY_SETUP_INSTANCE_ID(i);	

    //input tex
    float4 albedo = tex2D(_ColorE,TRANSFORM_TEX(i.uv, _ColorE));
	#if defined(_ALPHATEST)
	clip(albedo.a - _Clip);
	#endif // _ALPHATEST
	float3 bump = UnpackNormal(tex2D(_Normal,TRANSFORM_TEX(i.uv, _Normal)));
	bump = lerp(float3(0,0,1), bump, _NormalScale);

	//PBR Input
	float4 smms = tex2D(_SMMS, TRANSFORM_TEX(i.uv, _SMMS));

	float smoothness = min(smms.r * _Gloss, 1) ;
    float glossness = saturate(smms.r / _Gloss) ;
    float occ = lerp(0.5, smms.b*0.5, _AO);	

	//NormalSetup
	float3 norDir = normalize(mul(i.tanToWorld, bump));

	//dir
	float3 worldPos = i.worldPos;
	float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
	float3 reflDir = normalize(reflect(-viewDir, norDir));
	float3 halfDir = normalize(viewDir + lightDir);
	float NoV = max(0, dot(norDir, viewDir));
    float NoH = max(0, dot(norDir, halfDir));
    float NoL = max(0, dot(_WorldSpaceLightPos0.xyz, norDir));
	float VoH = max(0, dot(viewDir, halfDir));

	//#ifdef _RECEIVESHADOW
	float ReceiveShadow = MY_SHADOW_ATTENTION(i, norDir, worldPos.xyz);
	//#endif

	float LoD = max(0, min(NoL, ReceiveShadow));
	float LoV = max(0, dot(viewDir, _WorldSpaceLightPos0));

#ifdef _SKINMASK 
    float4 mask = tex2D(_PatternMaskTex,TRANSFORM_TEX(i.uv, _PatternMaskTex));
    float4 pattern =_PatternColor1;

    #ifdef _SKINADDCOLOR    
    pattern = lerp(_PatternColor1,_PatternColor2,sin(i.uv.z* (3*_PatternColor2.a) + (1-_PatternColor1.a)*2));
    #endif //_SKINADDCOLOR

    #ifdef _SKINPATTERN
	//pattern *= tex2D(_PatternTex,TRANSFORM_TEX(i.uv.zw, _PatternTex) + _Time.yy * _PatternTex_ST.zw);
	#ifdef _CHDISPLAY
		half3 patternUV = i.worldPos;
		half4 patternX = tex2D(_PatternTex,TRANSFORM_TEX(patternUV.zy, _PatternTex) + _Time.yy*_PatternTex_ST.zw);
		half4 patternY = tex2D(_PatternTex,TRANSFORM_TEX(patternUV.xz, _PatternTex) + _Time.yy*_PatternTex_ST.zw);
		half4 patternZ = tex2D(_PatternTex,TRANSFORM_TEX(patternUV.xy, _PatternTex) + _Time.yy*_PatternTex_ST.zw);
		half3 triBlend = pow(norDir, 8);
	#else //WeaponDisplay
		half3 patternUV = half3(i.uv.z,i.uv2.w,i.uv.w); // v.vertex.xyz
		half4 patternX = tex2D(_PatternTex,TRANSFORM_TEX(patternUV.zy, _PatternTex) + _Time.yy*_PatternTex_ST.zw);
		half4 patternY = tex2D(_PatternTex,TRANSFORM_TEX(patternUV.xz, _PatternTex) + _Time.yy*_PatternTex_ST.zw);
		half4 patternZ = tex2D(_PatternTex,TRANSFORM_TEX(patternUV.xy, _PatternTex) + _Time.yy*_PatternTex_ST.zw);
		half3 triBlend = pow(i.uv2.xyz, 8); //v.normal.xyz
	#endif //_CHDISPLAY
    triBlend /= dot(triBlend,1);
	triBlend = saturate(triBlend);
    pattern.rgb *= patternX*triBlend.x + patternY*triBlend.y + patternZ*triBlend.z;
    #endif // _SKINPATTERN

    #ifdef _PATTERNMODE_ADD
    albedo.rgb += pattern.rgb*mask.a;
    #elif defined(_PATTERNMODE_ALPHA)
    albedo.rgb = lerp(albedo, pattern, mask.a).rgb;
    #endif // _PATTERNMODE_ADD/_PATTERNMODE_ALPHA
#endif // _SKINMASK

    //Fresnel
    float Fresnel = pow(1.0 - NoV, 2.8) * 0.8 + 0.2;
	
	//#if defined(_CHDISPLAY) || defined(_SOFTSHADOW)
    float shadowSoft = smoothstep(_SelfShadowHardness, 1, NoL + _SelfShadowSize);
    //#endif

    //#ifdef _RECEIVESHADOW
	float shadowIntensity = _ShadowIntensity;
	#ifdef _INFERENCE
	fixed inferenceMask = tex2D(_InferenceMask, i.uv).r;
	shadowIntensity = lerp(shadowIntensity, _InferenceShadowIntensity, inferenceMask);
	#endif // _INFERENCE
    ReceiveShadow = lerp(1, ReceiveShadow * shadowSoft, shadowIntensity);	
    //#endif 

    //IBLDiff
	float mainLightIntensity = _MainLightIntensity;
#ifdef _INFERENCE
	mainLightIntensity = lerp(mainLightIntensity, _InferenceMainLightIntensity, inferenceMask);
#endif // _INFERENCE
	float3 IBLDiffuse = UNITY_LIGHTMODEL_AMBIENT.rgb;
	float3 IBLColor = lerp(IBLDiffuse, min(0.7, IBLDiffuse*1.5), Fresnel);
    half3 IBLShadows = lerp(IBLColor*_AmbientLight, mainLightIntensity, ReceiveShadow);
    float3 albedocolor = (IBLColor.rgb+_OwnerLightAmbient.rgb)*albedo.rgb; 


	//spec
	float highlight = _Highlight;
	float colorfulMetal = _ColorfulMetal;
#ifdef _INFERENCE
	highlight = lerp(highlight, _InferenceHighlight, inferenceMask);
	colorfulMetal = lerp(colorfulMetal, _InferenceColorfulMetal, inferenceMask);
#endif //_INFERENCE
	half3 specularTerm = GetSpecTerm(smoothness, NoH, ReceiveShadow, NoV) * highlight;
    half3 specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, smms.g);
    specColor *= specularTerm;
    specColor = lerp(specColor,specColor * albedocolor * colorfulMetal, smms.g * colorfulMetal);

    specColor *= IBLShadows;

    //skin
	#if defined(_CHDISPLAY) || defined(_CHLODZERO) || defined(_CHLODONE)
	float skinmask = smms.a*_SKin;
	float3 darktone = lerp(_OwnerLightAmbient.rgb, albedo,skinmask);
    float3 deepskin = saturate(LoD - (1.0 - occ) * (1.0 - Fresnel) * 0.8 + smms.a *_SkinDeepColor.rgb);
	float3 albedoLight = 1.0 - ((1.0 - deepskin)*(1.0 - darktone));
	albedocolor = lerp((IBLColor + albedoLight)*albedo, _SkinColor* albedo, skinmask*2);
	IBLShadows = saturate(IBLShadows+_SKinShadow * LoV * skinmask);
	specColor = lerp(specColor, albedocolor, skinmask);
    #endif
	albedocolor *= IBLShadows;

	//Refl
	float cubeIntensity = _CubeIntensity;
#ifdef _INFERENCE
	cubeIntensity = lerp(cubeIntensity, _InferenceCubeIntensity, inferenceMask);
#endif // _INFERENCE
	float perceptualRoughness = (1 - _Metal) * smms.g + glossness;
    float3 reflspec = GetEnvCube(perceptualRoughness * 6, reflDir);
	reflspec = pow(reflspec,1.4);
	reflspec *= cubeIntensity * (occ * 0.5 + 0.5);
    reflspec = max(_EnvMin,reflspec);

	//fianl
    float3 metalColor = lerp(Luminance(albedo), albedo, 2) * 2;
    float3 RelfColor = lerp(reflspec,reflspec * metalColor, smms.g * colorfulMetal);
    float3 finalColor = lerp(albedocolor, RelfColor, smms.g) + specColor;

	#if defined(_MATCAP)
    //matcap    
	half2 capUV = half2(dot(i.TtoVo[0], bump), dot(i.TtoVo[1], bump));
    half3 matcap = tex2D(_MatcapTex, capUV * 0.5 + 0.5);
    finalColor += matcap * lerp(_RimShaodowLight,_RimLight,ReceiveShadow);
    #endif // _MATCAP

	#if defined(_RAMP)
    float ramp = i.uv.z * 0.5  + (1 - _MaskModeHeight) + 1;
    finalColor *= clamp(ramp, 0.8, 1);
    #endif // _RAMP

	#if defined(_EMISSION)
	float3 emi = albedo.rgb - albedo.a;
	emi = saturate(emi * 2) * _EmissiveColor;
	if (_ANiEmi == 1) 
	{ 
		emi *= abs(sin(_Time.w * _AniSpeed)); 
	}
	finalColor += emi;
    #endif // _EMISSION

	finalColor.rgb = ApplySunFog(finalColor.rgb, i.fogCoord, viewDir);

    if(_Luminance != 0)
		finalColor.rgb = Luminance(finalColor.rgb);
    
	float heat = max(dot(norDir, viewDir), 0);

	#ifdef _INFERENCE
	float metallic = smms.g;
	float roughness = 1 - smms.r;
	float thickness = tex2D(_Thickness, i.uv).r * _ThicknessFactor + NoV;
	fixed3 tint = tex2D(_Ramp, float2(thickness * _Ramp_ST.x + _Ramp_ST.z, 0.5)).rgb * _Tint;
	fixed3 specular = lerp(unity_ColorSpaceDielectricSpec.rgb, 1, metallic);
	fixed3 inferenceIBL = ApproximateSpecularIBL(_Reflect, specular, roughness, norDir, viewDir, reflDir);
	inferenceIBL = lerp(inferenceIBL, tint, _Tint);
	finalColor = lerp(finalColor, finalColor + inferenceIBL, inferenceMask);
	#endif //_INFERENCE*/
		
    return fixed4(finalColor, heat);
}

struct CHVertexOutputForwardAdd
{
	UNITY_POSITION(pos);
	half4 uv           : TEXCOORD0;
	half3x3 tanToWorld : TEXCOORD1;
    half3 worldPos     : TEXCOORD4;
	half3 lightDir     : TEXCOORD5;
	MY_SHADOW_COORDS(6)
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct CHVertexOutputLow
{
	UNITY_POSITION(pos);
	half2 uv       : TEXCOORD0;
	half3 normal   : TEXCOORD1;
	float3 worldPos : TEXCOORD2;
	MY_SHADOW_COORDS(3)
	half4 fogCoord : TEXCOORD4;
};

CHVertexOutputLow CHVertLow(CustomAppData v)
{
	CHVertexOutputLow o;
	o.pos      = UnityObjectToClipPos(v.vertex);
	o.uv       = v.texcoord.xy;
	o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)).xyz;
	o.normal   = UnityObjectToWorldNormal(v.normal);
	o.fogCoord = GetFogCoord(o.pos, o.worldPos);

	TRANSFER_MY_SHADOW(o, o.worldPos);
	return o;
}

half4 CHFragLow(CHVertexOutputLow i) : COLOR
{
	//input tex
	float4 albedo = tex2D(_ColorE, TRANSFORM_TEX(i.uv, _ColorE));
	
	//dir
	float3 norDir = normalize(i.normal);
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
	float3 lightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
	float3 halfDir = normalize(viewDir + lightDir);
	//float NoV = saturate(dot(norDir, viewDir));
	float NoH = max(dot(norDir, halfDir), 0);
	float NoL = max(dot(norDir,lightDir), 0);

	//float Fresnel = pow(1.0 - NoV, 2.8) * 0.8 + 0.2;
	float ReceiveShadow = MY_SHADOW_ATTENTION(i, norDir, i.worldPos.xyz);
	float shadowSoft = 1;

	//shadowSoft = smoothstep(_SelfShadowHardness, 1, NoL + _SelfShadowSize);

	ReceiveShadow = lerp(1, ReceiveShadow, _ShadowIntensity);
	float3 IBLDiffuse = UNITY_LIGHTMODEL_AMBIENT.rgb;
	float3 IBLColor = IBLDiffuse; // lerp(IBLDiffuse, min(0.7, IBLDiffuse * 1.5), Fresnel);

	float3 albedocolor = (IBLColor.rgb + _OwnerLightAmbient.rgb) * albedo.rgb;
	float3 IBLShadows = lerp(IBLColor * _AmbientLight, _MainLightIntensity, ReceiveShadow);
	albedocolor *= IBLShadows;

	float specularTerm = saturate(pow(NoH, 16))* _Highlight * 0.4;
	float3 specColor = _LightColor0.rgb * step((1 - ReceiveShadow), 0) * specularTerm;
	float3 finalColor = saturate(albedocolor + specColor);

	finalColor.rgb = ApplySunFog(finalColor.rgb, i.fogCoord, viewDir);
	float heat = max(dot(norDir, viewDir), 0);
	return half4(finalColor, heat);
}

#endif // CHCORE_INCLUDED