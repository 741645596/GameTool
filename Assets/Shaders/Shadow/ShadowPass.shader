Shader "Omega/Shadow/ShadowPass" 
{
    Properties
    {
        _MainTex     ("Texture", 2D) = "white" {}
        _Cutoff      ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        
        //[Enum(UnityEngine.Rendering.ColorWriteMask)]
        //_CascadeMask ("Cascade Mask", Int) = 0
    }
    SubShader
    {
        Tags { "RenderType" = "TransparentCutout" }
        CGINCLUDE
        int _CascadeLevel;
        float4x4 _ShadowCasterVP;
        ENDCG
        Pass
        {
            Name "AlphaTest"
            ColorMask [_CascadeMask]
            ZClip Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;

            v2f_img vert(appdata_img v)
            {
                v2f_img o;
                float4 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1));
                o.pos = mul(_ShadowCasterVP, worldPos);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag(v2f_img i) : SV_Target
            {
                clip(tex2D(_MainTex, i.uv).a - _Cutoff);
                #if UNITY_REVERSED_Z
                float depth = i.pos.z / i.pos.w;
                #else
                float depth = 1 - i.pos.z / i.pos.w; 
                #endif
                fixed2 encode = EncodeFloatRG(saturate(depth) * 0.99);
                fixed2 mask = fixed2(1 - _CascadeLevel, _CascadeLevel);
                return encode.rgrg * mask.rrgg;
            }
            ENDCG
        }
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Pass
        {
            Name "Opaque"
            ColorMask [_CascadeMask]
            Cull Front
            ZClip Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 vert (float4 vertex : POSITION) : SV_POSITION
            {
                float4 worldPos = mul(unity_ObjectToWorld, float4(vertex.xyz, 1));
                return mul(_ShadowCasterVP, worldPos);
            }
            
            fixed4 frag (float4 pos : SV_POSITION) : SV_Target 
            {
                #if UNITY_REVERSED_Z
                float depth = pos.z / pos.w;
                #else
                float depth = 1 - pos.z / pos.w; 
                #endif
                fixed2 encode = EncodeFloatRG(saturate(depth) * 0.99);
                fixed2 mask = fixed2(1 - _CascadeLevel, _CascadeLevel);
                return encode.rgrg * mask.rrgg;
            }
            ENDCG
        }
    }
}