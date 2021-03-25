#ifndef SAMPLING_INCLUDED
#define SAMPLING_INCLUDED

// Standard box filtering
half4 DownsampleBox4Tap(sampler2D tex, float2 uv, float2 texelSize)
{
    float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0);

    half4 s;
    s =  (tex2D(tex, UnityStereoTransformScreenSpaceTex(uv + d.xy)));
    s += (tex2D(tex, UnityStereoTransformScreenSpaceTex(uv + d.zy)));
    s += (tex2D(tex, UnityStereoTransformScreenSpaceTex(uv + d.xw)));
    s += (tex2D(tex, UnityStereoTransformScreenSpaceTex(uv + d.zw)));

    return s * (1.0 / 4.0);
}

// Standard box filtering
half4 UpsampleBox(sampler2D tex, float2 uv, float2 texelSize, float4 sampleScale)
{
    float4 d = texelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0) * (sampleScale * 0.5);

    half4 s;
    s =  (tex2D(tex, UnityStereoTransformScreenSpaceTex(uv + d.xy)));
    s += (tex2D(tex, UnityStereoTransformScreenSpaceTex(uv + d.zy)));
    s += (tex2D(tex, UnityStereoTransformScreenSpaceTex(uv + d.xw)));
    s += (tex2D(tex, UnityStereoTransformScreenSpaceTex(uv + d.zw)));

    return s * (1.0 / 4.0);
}

#endif // SAMPLING_INCLUDED
