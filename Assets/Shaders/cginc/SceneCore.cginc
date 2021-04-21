#ifndef ENVCORE_INCLUDED
#define ENVCORE_INCLUDED

#include "AutoLight.cginc"
#include "UnityCG.cginc"
#include "../cginc/FogCore.cginc"
#include "../cginc/shadowmap.cginc"

#ifdef _USEROCKGRASS
float _GrassHeightBlend;
float _GrassThreshold;
sampler2D _GrassTex;
half4 _GrassTex_ST;
#endif

float4 Omega_Lightmap_HDR;

#define PI 3.14159265359
//Variants
half4 _TintColor;
fixed _Shadow;

#ifdef _ALPHATEST
fixed _Cutoff;
#endif
fixed _Transparency;

#ifdef _USEREFL
samplerCUBE _ReflTex;
half4 _ReflTex_ST;
fixed _MetalV;
fixed _FresnelRange;
#endif

#ifdef _LIGHTMAP
sampler2D _Lightmap;
half _LightmapContrast;
half _LightmapBrightness;
half _DesaturateLightmap;
half4 _LightmapParams;
#endif

#ifdef _SPOTLIGHT
half4 _SpotLightParams;
half _SpotRad;
half4 _SpotLightColor;
#endif

#ifdef _MATCAP
sampler2D _MatcapTex;
#endif


#ifdef _USENORMAL

half _LightmapClamp;

sampler2D _BumpMap;
half4 _BumpMap_ST;

#endif

#ifdef _SPEC
sampler2D _SpecularMap;
half4 _SpecularMap_ST;
half _Shininess;
half4 _SpecColor;
#endif

#ifdef _CUSTOM_SPEC
half _Shininess;
half4 _SpecColor;
#endif

//texture
sampler2D _MainTex;
half4 _MainTex_ST;

//color			
float4 _LightColor0;
float4 _LightMapFactor;


struct appdata
{
	float4 vertex   : POSITION;
	half3 normal    : NORMAL;
#ifdef _USENORMAL
	half4 tangent   : TANGENT;
#endif
	float2 uv0      : TEXCOORD0;
#ifdef _LIGHTMAP
	float2 uv1      : TEXCOORD1;  //lightmap
#endif

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
	UNITY_POSITION(pos);
	float4 uv           : TEXCOORD0; //VertexUV.xy | HighMask.z
	float3x3 tanToWorld : TEXCOORD1;
	float3 worldPos     : TEXCOORD4;
	half4 fogCoord	    : TEXCOORD5;
	MY_SHADOW_COORDS(6)
};

v2f CustomvertBase(appdata v)
{
	UNITY_SETUP_INSTANCE_ID(v);
	v2f o;
	UNITY_INITIALIZE_OUTPUT(v2f, o);

	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	o.pos = UnityObjectToClipPos(v.vertex);

	half3 normal = UnityObjectToWorldNormal(v.normal);
#ifdef _USENORMAL
	half4 tangent = half4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	half sign = tangent.w * unity_WorldTransformParams.w;
	half3 binormal = cross(normal, tangent.xyz) * sign;
	o.tanToWorld = transpose(half3x3(tangent.xyz, binormal, normal));
#else
	o.tanToWorld[0].z = normal.x;
	o.tanToWorld[1].z = normal.y;
	o.tanToWorld[2].z = normal.z;
#endif // _USENORMAL

	o.uv.xy = v.uv0.xy;
#ifdef _LIGHTMAP
	o.uv.zw = v.uv1.xy;
#endif // _LIGHTMAP

	TRANSFER_MY_SHADOW(o, o.worldPos)
	o.fogCoord = GetFogCoord(o.pos, o.worldPos);
	return o;
}

half4 CustomfragBase(v2f i) : COLOR
{
	float4 albedo = tex2D(_MainTex, i.uv.xy * _MainTex_ST.xy);

#ifdef _ALPHATEST
	clip(albedo.a - _Cutoff);
#endif // _ALPHATEST

	half3 vnormal = half3(
		i.tanToWorld[0].z, 
		i.tanToWorld[1].z, 
		i.tanToWorld[2].z);

#ifdef _USENORMAL
	half3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.xy*_BumpMap_ST.xy));
	half3 normal = mul(i.tanToWorld, bump);
#else
	half3 normal = vnormal;
#endif

	float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
	float3 reflLight = reflect(-lightDir, normal);
	float3 reflView = reflect(-viewDir, normal);
	float GNoL = saturate(dot(vnormal, lightDir)); // Geometry NoL
    float NoL = saturate(dot(normal, lightDir));
	float NoV = saturate(dot(normal, viewDir));
	float VoL = max(dot(viewDir, reflLight), 0.0);

#ifdef _USEROCKGRASS
	float4 grassCol = tex2D(_GrassTex, i.uv.xy * _GrassTex_ST.xy + _GrassTex_ST.zw);
	half ler = smoothstep(_GrassHeightBlend - 1, _GrassHeightBlend + 1, i.worldPos.y);
	ler = smoothstep(0, 1 - _GrassThreshold, ler * vnormal.y);
	albedo = lerp(albedo, grassCol, ler);
#endif // _USEROCKGRASS

    float3 sAlbedo = albedo * _TintColor.rgb;

#ifdef SHADER_API_METAL
	Omega_Lightmap_HDR = float4(2, 1, 0, 0);
#else
	Omega_Lightmap_HDR = float4(1, 1, 0, 0);
	#ifdef UNITY_COLORSPACE_GAMMA
	#ifdef UNITY_NO_RGBM
		Omega_Lightmap_HDR.x = 2.0;
	#else
		Omega_Lightmap_HDR.x = 5.0;
	#endif
	#else
	#ifdef UNITY_NO_RGBM
		Omega_Lightmap_HDR.x = GammaToLinearSpaceExact(2.0);
	#else
		Omega_Lightmap_HDR.x = pow(5.0, 2.2);
		Omega_Lightmap_HDR.y = 2.2;
	#endif
	#endif
#endif

	float ReceiveShadow = 1;
#if defined(_LIGHTMAP)
	if (GNoL > 0.2)
		ReceiveShadow = MY_SHADOW_ATTENTION(i, normal, i.worldPos);
#else
	ReceiveShadow = MY_SHADOW_ATTENTION(i, normal, i.worldPos);
#endif

#ifdef _RECEIVESHADOW
	#if !defined(_LIGHTMAP)
	ReceiveShadow *= NoL * 1.5;
	#endif
#endif
    float3 ShadowColor = lerp(_ShadowColor.rgb, 1, ReceiveShadow);

#ifdef _LIGHTMAP
	half2 lmUV = i.uv.zw * unity_LightmapST.xy + unity_LightmapST.zw;
	#ifdef _CUSTOM_LIGHTMAP
	float4 lightmap = tex2D(_Lightmap, lmUV) * float4(2.0, 2.0, 2.0, 1.0);
	#else
	float4 lightmap = float4(DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, lmUV), Omega_Lightmap_HDR), 1);
	#endif // _CUSTOM_LIGHTMAP
	
	float3 lmcolor = lightmap.rgb *_LightMapFactor;

	#ifdef _RECEIVESHADOW
	lmcolor *= ShadowColor;
	#endif // _RECEIVESHADOW
	half3 lightcolor = lmcolor;
#else
	half3 lightcolor = (_LightColor0.rgb * NoL + UNITY_LIGHTMODEL_AMBIENT.rgb) * ShadowColor;
#endif // _LIGHTMAP
	
	float3 finalColor = lightcolor * sAlbedo;

#ifdef _SPEC
	float specular = tex2D(_SpecularMap, i.uv.xy * _SpecularMap_ST.xy).r;
	half3 specularTerm = pow(VoL, 128 * _Shininess) * specular;
	finalColor += _SpecColor.rgb * specularTerm * sAlbedo;
#elif defined(_CUSTOM_SPEC)
	half3 specularTerm = pow(VoL, 48 * _Shininess);
	finalColor += _SpecColor.rgb * specularTerm * sAlbedo;
#endif

#ifdef _USEREFL
	//Fresnel
	float Fresnel = pow((1.0 - NoV)*NoL, _FresnelRange);

	float perceptualRoughness = albedo.a + (1 - _MetalV) * floor(albedo.a + _MetalV);
	float3 reflspec = texCUBElod(_ReflTex, float4(reflView, 0)).rgb;

	reflspec = pow(reflspec, 1.4);
	float Term = pow(perceptualRoughness, _MetalV) * Fresnel;
	finalColor = lerp(finalColor, reflspec, Term);
#endif

#ifdef _MATCAP
	half2 capUV = half2(dot(UNITY_MATRIX_V[0].xyz, reflLight), dot(UNITY_MATRIX_V[1].xyz, reflLight));
	half3 matcap = tex2D(_MatcapTex, capUV * 0.5 + 0.5);
	finalColor.rgb += matcap;
#endif

#ifdef _SPOTLIGHT
	half dis = saturate((length(i.worldPos.xz - _SpotLightParams.xy)) / _SpotRad);
	half spotStrenth = lerp(_SpotLightParams.z, _SpotLightParams.w, smoothstep(0, 1, 1 - dis));// sqrt(1 - dis * dis);
	finalColor = finalColor * spotStrenth * _SpotLightColor.rgb;
#endif

    float finalAlpha = _Transparency;

#ifdef _Unlit
	finalColor = sAlbedo;
#endif // _Unlit

	finalColor.rgb = ApplySunFog(finalColor.rgb, i.fogCoord, viewDir);

    return saturate(half4(finalColor,finalAlpha));
}

#endif // ENVCORE_INCLUDED
