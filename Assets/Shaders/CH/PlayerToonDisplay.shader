Shader "Omega/Actors/PlayerToonDisplay"
{
    Properties
    {
        _ColorE ("ColorE", 2D) = "white" {}
        _Normal ("Bump Map", 2D) = "bump" {}
        _NormalScale ("Normal Scale", Range(0, 1)) = 1.0
        _SMMS ("Mask", 2D) = "white" {}
        _Reflect("Env Map", CUBE) = "white" {}
        BRDF_LUT("BRDF LUT", 2D) = "black" {}
        [Header(Ramp)]
        _DiffuseRamp  ("Diffuse  (From (Pos,Val), To (Pos,Val))", Vector) = (0,0,1,1)
        _SpecularRamp ("Specular (From (Pos,Val), To (Pos,Val))", Vector) = (0,0,1,1)
        _FresnelRamp  ("Fresnel  (From (Pos,Val), To (Pos,Val))", Vector) = (0,0,1,1)
        _MetallicRamp ("Metallic (From (Pos,Val), To (Pos,Val))", Vector) = (0,0,1,1)
        _AO("AO", Float) = 1.0
        [Header(Outline)]
        _Outline ("Outline", Range(0, 0.01)) = 0.003
        [Toggle]
        _VertexThickness ("Per Vertex Thickness", Int) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        CGINCLUDE
        #include "UnityCG.cginc"
        #include "CHCore.cginc"
        #include "BRDF.cginc"
        half4 _DiffuseRamp;
        half4 _SpecularRamp;
        half4 _FresnelRamp;
        half4 _MetallicRamp;
        float _Outline;
        int   _VertexThickness;
        TextureCube _Reflect;

        #define Ramp(ramp,val) lerp(ramp.y,ramp.w,saturate((val-ramp.x)/(ramp.z-ramp.x)))
        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile _ _RECEIVESHADOW
			#pragma multi_compile _ _SOFTSHADOW
            #pragma multi_compile_fog

            struct appdata
            {
                float4 vertex  : POSITION;
                float3 normal  : NORMAL;
                float4 tangent : TANGENT;
                float2 uv      : TEXCOORD0;
            };

            struct v2f
            {
                float4   pos        : SV_POSITION;
                float2   uv         : TEXCOORD0;
                float3x3 tanToWorld : TEXCOORD1;
                float3   worldPos   : TEXCOORD4;
                half4    fogCoord   : TEXCOORD5;
                MY_SHADOW_COORDS(6)
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.pos = mul(UNITY_MATRIX_VP, float4(o.worldPos, 1));
                o.tanToWorld = Tan2WorldMatrix(v.normal, v.tangent);
                o.fogCoord = GetFogCoord(o.pos, o.worldPos);
                //#ifdef _RECEIVESHADOW
                TRANSFER_MY_SHADOW(o, o.worldPos);
                //#endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 albedo = tex2D(_ColorE, i.uv);
                float3 bump = UnpackNormal(tex2D(_Normal, i.uv));
                bump = lerp(float3(0,0,1), bump, _NormalScale);
                fixed4 smms = tex2D(_SMMS, i.uv);
                float roughness = smms.r;
                float metallic = smms.g;
                float ao = 1 - pow(1 - smms.b, _AO);
                float3 normal   = normalize(mul(i.tanToWorld, bump));
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                float3 viewDir  = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 reflDir = reflect(normal, viewDir);
                float3 halfNorm = normalize(viewDir + lightDir);
                float NoL = max(0, dot(normal,  lightDir));
                float NoV = max(0, dot(normal,  viewDir));
                float NoH = max(0, dot(normal,  halfNorm));
                float VoH = max(0, dot(viewDir, halfNorm));
                float shadow = MY_SHADOW_ATTENTION(i, normal, i.worldPos);
                fixed3 specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, 1, metallic);
                fixed3 ibl = ApproximateSpecularIBL(_Reflect, specColor, roughness, normal, viewDir, reflDir);
                float diffuse = Ramp(_DiffuseRamp, NoL) * shadow;;
                float specular = GetSpecTerm(roughness, NoH, NoL, NoV) * shadow;
                specular = Ramp(_SpecularRamp, specular);
                float fresnel = pow(1 - NoV, 2) * NoL * shadow;
                fresnel = Ramp(_FresnelRamp, fresnel);
                ibl = Ramp(_MetallicRamp, ibl);
                fixed4 col = 1;
                col.rgb = albedo.rgb * (diffuse + max(specular, fresnel)) * ao;
                col.rgb = lerp(col.rgb, albedo.rgb * ibl, metallic);
                col.rgb = lerp(albedo.rgb, col.rgb, albedo.a);
                col.rgb = ApplySunFog(col, i.fogCoord, viewDir);
                return col;
            }
            ENDCG
        }
        
        Pass
        {
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            struct appdata
            {
                float4 vertex : POSITION;
                fixed4 color  : COLOR;
                float3 normal : NORMAL;
            };

            float4 vert(appdata v) : SV_POSITION
            {
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                float4 pos = UnityObjectToClipPos(v.vertex);
                float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz)) * pos.w;
                float aspect = (_ScreenParams.x / _ScreenParams.y);
                ndcNormal.y *= aspect;
                pos.xy += _Outline * max(v.color.r, _VertexThickness) * ndcNormal.xy;
                return pos;
            }

            fixed4 frag() : SV_Target
            {
                return fixed4(0,0,0,1);
            }
            ENDCG
        }
    }
}