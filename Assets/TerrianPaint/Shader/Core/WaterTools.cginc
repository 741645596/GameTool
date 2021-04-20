#ifndef WATER_TOOLS
#define WATER_TOOLS

void SimpleWaterScattering(half viewDist, half3 worldPos, half depth, half3 diffuseRadiance,
					half3 attenuation_c, half3 kd, out half3 outScattering, out half3 inScattering)
{
	half t = depth / (_WorldSpaceCameraPos.y - worldPos.y);

	// Water scattering
	half d = viewDist*t;  // one way!
	outScattering = exp(-attenuation_c*d);
	inScattering = diffuseRadiance* (1 - outScattering*exp(-depth*kd));
}

half3 SimpleWaterOutScattering(half viewDist, half3 worldPos, half depth, half3 attenuation_c)
{
	half t = depth / (_WorldSpaceCameraPos.y - worldPos.y);

	// Water scattering
	half d = viewDist*t;  // one way!
	return exp(-attenuation_c*d);
}

half3 PerPixelNormal(sampler2D bumpMap, half4 coords, half bumpStrength)
{
	float2 bump = (UnpackNormal(tex2D(bumpMap, coords.xy)) + UnpackNormal(tex2D(bumpMap, coords.zw))) * 0.5;
	bump += (UnpackNormal(tex2D(bumpMap, coords.xy*2))*0.5 + UnpackNormal(tex2D(bumpMap, coords.zw*2))*0.5) * 0.5;
	bump += (UnpackNormal(tex2D(bumpMap, coords.xy*8))*0.5 + UnpackNormal(tex2D(bumpMap, coords.zw*8))*0.5) * 0.5;
	half3 worldNormal = half3(0,0,0);
	worldNormal.xz = -bump.xy * bumpStrength;
	worldNormal.y = 1;
	return worldNormal;
}
// Fresnel approximation, power = 5
half FastFresnel(half3 I, half3 N, half R0)
{
	half icosIN = saturate(1-dot(I, N));
	half i2 = icosIN*icosIN, i4 = i2*i2;
	return saturate(R0 + (1-R0)*(i4*icosIN));
}
#endif