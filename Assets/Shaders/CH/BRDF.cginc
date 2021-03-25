#ifndef BRDF_INCLUDED
#define BRDF_INCLUDED

#define PI     3.14159265358979323846
#define INV_PI 0.31830988618379067154

/*SamplerState sampler_point_clamp;*/
SamplerState sampler_point_repeat;
SamplerState sampler_linear_clamp;
SamplerState sampler_linear_repeat;
SamplerState sampler_trilinear_clamp;
SamplerState sampler_trilinear_repeat;

Texture2D BRDF_LUT;

inline half OneMinusReflectivityFromMetallic(half metallic)
{
    // We'll need oneMinusReflectivity, so
    //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
    // store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
    //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
    //                  = alpha - metallic * alpha
    half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

inline half3 DiffuseAndSpecularFromMetallic (half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
{
    specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
    oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
    return albedo * oneMinusReflectivity;
}

float3 Diffuse_Lambert( float3 DiffuseColor )
{
    return DiffuseColor * INV_PI;
}

float D_GGX( float a2, float NoH )
{
    float d = ( NoH * a2 - NoH ) * NoH + 1;
    return a2 / ( PI*d*d );
}

float Vis_Schlick( float a2, float NoV, float NoL )
{
    float k = sqrt(a2) * 0.5;
    float Vis_SchlickV = NoV * (1 - k) + k;
    float Vis_SchlickL = NoL * (1 - k) + k;
    return 0.25 / ( Vis_SchlickV * Vis_SchlickL );
}

float3 F_Schlick( float3 SpecularColor, float VoH )
{
    float Fc = pow( 1 - VoH , 5);
    //return Fc + (1 - Fc) * SpecularColor;
    
    // Anything less than 2% is physically impossible and is instead considered to be shadowing
    return saturate( 50.0 * SpecularColor.g ) * Fc + (1 - Fc) * SpecularColor;
}

fixed3 ApproximateSpecularIBL(TextureCube envMap, float3 SpecularColor, float Roughness, float3 N, float3 V, float3 refl)
{
    float NoV = saturate(dot(N,V));
    float3 R = 2 * dot(N,V) * N - V;
    
    float mipCount = 6;
    float mipLevel = floor(Roughness * mipCount);
    float blend = frac(Roughness * mipCount);
    float3 PrefilteredColor = lerp(
        envMap.SampleLevel(sampler_linear_repeat, refl, mipLevel),
        envMap.SampleLevel(sampler_linear_repeat, refl, mipLevel + 1),
        blend);
    float2 EnvBRDF = BRDF_LUT.Sample(sampler_linear_clamp, float2(NoV, Roughness)).rg;//IntergrateBRDF(Roughness, NoV);
    fixed3 env = PrefilteredColor * (SpecularColor * EnvBRDF.x + EnvBRDF.y);
    return saturate(env);
}

#endif // BRDF_INCLUDED