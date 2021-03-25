#ifndef SCREEN_BORDER_EFFECT_INCLUDED
#define SCREEN_BORDER_EFFECT_INCLUDED

float4 _Border;

float4 ObjectToClipPosBorder(float4 vertex)
{
    float4 clipPos;
	clipPos.xy = vertex.xy;
	clipPos.xy -= vertex.xy * _Border.xy * vertex.z;
	clipPos.z = 0;
	clipPos.w = 1;
    return clipPos;
}

float2 ClipPosToScreenUV(float4 clipPos)
{
	float2 uv = clipPos.xy * 0.5 + 0.5;
	#if UNITY_UV_STARTS_AT_TOP
	uv.y = 1 - uv.y;
	#endif
	return uv;
}

#endif //SCREEN_BORDER_EFFECT_INCLUDED