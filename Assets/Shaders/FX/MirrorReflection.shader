Shader "Omega/FX/MirrorReflection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_PatternMaskTex("PatternMaskTex",2D) = "black" {}
		_PatternTex("PatternTex",2D) = "white" {}
        _Color ("Color", COLOR) = (1,1,1,1)
        _Height ("Height", Float) = 0.0
        _Fade ("Fade", Vector) = (0,1,0.5,0)
        //_Blur ("Blur", Float) = 0
		_ModelWorldPos("ModelWorldPos", Vector) = (0,0,0,0)
		_PatternColor1("PatternColor", Color) = (1,1,1,1)
		[Toggle(_SKINMASK)]_SkinMask("Skin Mask", Int) = 1
		[Toggle(_SKINPATTERN)]_SkinPattern("Skin Pattern", Int) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent+500" }
        LOD 100

        Pass // DepthPass
        {
            Cull Front
            ColorMask 0
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			uniform float4 _ModelWorldPos;

            float4 vert(float4 vertex : POSITION) : SV_POSITION
            {
                float4 worldPos = mul(unity_ObjectToWorld, float4(vertex.xyz, 1));
				worldPos.y = _ModelWorldPos.y - (worldPos.y - _ModelWorldPos.y);				
                return mul(UNITY_MATRIX_VP, worldPos);
            }

            fixed4 frag(float4 pos : SV_POSITION) : SV_Target
            {
                return 0;
            }
            ENDCG
        }
        
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Front
            ZTest LEqual
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _SKINPATTERN
            #pragma multi_compile _ _SKINMASK

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
		    sampler2D _PatternMaskTex;
		    float4 _PatternMaskTex_ST;
		    sampler2D _PatternTex;
            float4 _PatternTex_ST;
            fixed4 _PatternColor1;
            fixed4 _Color;
            float _Height;
            float4 _Fade;
            //float _Blur;
			uniform float4 _ModelWorldPos;

            struct v2f
            {
                float4 pos    : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv     : TEXCOORD0;
                float  alpha  : TEXCOORD1;
                float3 vertex : TEXCOORD2;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1));
                float alpha = saturate((worldPos.y - _Fade.x) / (_Fade.y - _Fade.x));
                alpha = lerp(_Fade.z, _Fade.w, alpha);
				worldPos.y = _ModelWorldPos.y - (worldPos.y - _ModelWorldPos.y);				
                o.pos = mul(UNITY_MATRIX_VP, worldPos);
                o.normal = v.normal;
                o.uv = v.texcoord;
                o.vertex = v.vertex.xyz;
                o.alpha = alpha;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex));
                #if _SKINMASK
                fixed mask = tex2D(_PatternMaskTex, TRANSFORM_TEX(i.uv, _PatternMaskTex)).a;
                fixed4 pattern = _PatternColor1; 
                #if _SKINPATTERN
                half3 patternUV = i.vertex;
                half4 patternX = tex2D(_PatternTex,TRANSFORM_TEX(patternUV.zy, _PatternTex) + _Time.yy*_PatternTex_ST.zw);
                half4 patternY = tex2D(_PatternTex,TRANSFORM_TEX(patternUV.xz, _PatternTex) + _Time.yy*_PatternTex_ST.zw);
                half4 patternZ = tex2D(_PatternTex,TRANSFORM_TEX(patternUV.xy, _PatternTex) + _Time.yy*_PatternTex_ST.zw);
                half3 triBlend = pow(i.normal.xyz, 8);
                triBlend /= dot(triBlend,1);
                triBlend = saturate(triBlend);
                pattern = patternX*triBlend.x + patternY*triBlend.y + patternZ*triBlend.z;
                #endif
                col = lerp(col, pattern, mask);
                #endif
                col.a = saturate(i.alpha);
                return col;
            }
            ENDCG
        }
    }
}
