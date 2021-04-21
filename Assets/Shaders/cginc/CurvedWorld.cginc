#ifndef CURVED_WORLD
#define CURVED_WORLD

uniform float3 _CW_Bend;
uniform float3 _CW_Pivot;

// 顶点变换
inline void CW_TransformPoint(inout float4 vertex)
{
	float4 worldPos = mul( unity_ObjectToWorld, vertex ); 
	worldPos.xyz -= _CW_Pivot.xyz;

	float2 xzOff = worldPos.xz*worldPos.xz;
	worldPos = float4(0, (_CW_Bend.x * xzOff.x + _CW_Bend.z * xzOff.y) * 0.001f, 0, 0); 

	vertex += mul(unity_WorldToObject, worldPos);
}
// 顶点变换
inline float4 CW_TransformWorldPoint(float4 worldPos) 
{
	worldPos.xyz -= _CW_Pivot.xyz;
	float2 xzOff = worldPos.xz * worldPos.xz;
	return float4(0, (_CW_Bend.x * xzOff.x + _CW_Bend.z * xzOff.y) * 0.001f, 0, 0);
}

#endif