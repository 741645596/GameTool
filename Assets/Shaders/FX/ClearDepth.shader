Shader "Hidden/ClearDepth"
{
    Properties {}
    SubShader
    {
        Cull Off
        ZWrite On
        ZTest Always
        ZClip Off
        ColorMask 0

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 vert (float4 vertex : POSITION) : SV_POSITION
            {
                #ifdef UNITY_REVERSED_Z
                return float4(vertex.xy, 0, 1);
                #else
                return float4(vertex.xy, 1, 1);
                #endif
            }

            fixed4 frag () : SV_Target
            {
                return 0;
            }
            ENDCG
        }
    }
}
