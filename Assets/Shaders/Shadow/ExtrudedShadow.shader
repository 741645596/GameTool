Shader "Omega/Shadow/ExtrudedShadow"
{
    Properties
    {
        _Extrude ("Extrude", Float) = 1000
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        CGINCLUDE
        #include "UnityCG.cginc"
        float _Extrude;
        struct appdata
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
        };
        
        struct v2f
        {
            float4 pos : SV_POSITION;
        };
        
        v2f vert (appdata v)
        {
            v2f o;
            float3 normal = UnityObjectToWorldNormal(v.normal);
            float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
            float3 lightDir = UnityWorldSpaceLightDir(worldPos);
            float NoL = dot(normal, lightDir);
            NoL = step(0, NoL) * 2 - 1;
            worldPos.xyz += lightDir * NoL * _Extrude;
            o.pos = mul(UNITY_MATRIX_VP, worldPos);
            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            return 0;
        }
        ENDCG

        Pass
        {
            ZTest Greater
            ZWrite Off
            Cull Off
            Stencil
            {
                Ref 8
                ReadMask 8
                WriteMask 8
                Comp Always
                Fail Replace
                Pass Replace
            }
            ColorMask 0
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
        Pass
        {
            ZTest Less
            ZWrite Off
            Cull Off
            Stencil
            {
                Ref 8
                ReadMask 8
                WriteMask 8
                Comp Equal
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest Always
            ZWrite Off
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_alpha
            fixed4 frag_alpha(v2f i) : SV_Target
            {
                //return fixed4(1,0,0,1);
                return fixed4(0.5, 0, 0, 0.05);
            }
            ENDCG
        }
    }
}
