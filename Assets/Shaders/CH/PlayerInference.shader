Shader "Omega/Actors/PlayerInference"
{
    Properties
    {
        _OwnerLightAmbient("环境光颜色", Color) = (0.1,0.1, 0.2, 1)
		_SkinColor("表皮肤色", Color) = (0.6,0.54,0.5,1)
		_SkinDeepColor("真皮透光颜色", Color) = (0.691,0.267,0.142,1)
		_EmissiveColor("自发光颜色", Color) = (0.5,0.5,0.5,1)

		[Header((Mask))]
		_Gloss("光滑度补偿", Range(0.0, 2.0)) = 1
		_Metal("金属补偿", Range(0.0, 2.0)) = 1
		_EnvMin ("环境光下限值",Range(0,0.5)) = 0.1
		_SKin("皮肤补偿", Range(0, 2.0)) = 1
		_SKinShadow("皮肤暗部补偿", Range(0, 8.0)) = 0.5

		[Header((Saturation))]
		_ColorfulAll("整体饱和度", Range(0.0, 2.0)) = 1
		_ColorfulMetal("反光饱和度", Range(0.0, 2.0)) = 1
		_HighlightSaturation("高光饱和度", Range(0,2)) = 1

		[Header((Light))]
		_MainLightIntensity("照明光", Range(0,2)) = 1	
		_Highlight("高光强度", Range(0,2)) = 1
		_AmbientLight("环境光", Range(0,2)) = 1
		_CubeIntensity("环境反光", Range(0,2)) = 1

		_Rotation("旋转Cubemap", Range(-360,360)) = 0

		[Header((Rim))]
		_RimLight("贴图边缘光", Range(0,2)) = 1
		_RimShaodowLight("暗部贴图边缘光", Range(0,2)) = 0

		[Header((Shadow))]
		_ShadowIntensity("阴影强度", Range(0, 1)) = 0.5
		_SelfShadowSize("阴影范围", Range(0, 1)) = 0.1
		_SelfShadowHardness("阴影硬度", Range(0, 1)) = 0.55
		_AO("AO", Range(0, 2)) = 0.5
		_MaskModeHeight("渐变", Range(0.0, 2.0)) = 1
		_MaskVector("渐变方向",Vector) = (0,0,0,1)

		[Header((Option))]
		[Toggle] _ANiEmi("循环自发光动画",float) = 0
		_AniSpeed("Emissive Shark", Range(0.0, 1.0)) = 0.5
		[Toggle] _Luminance("Luminance",float) = 0

		[Space(20)]
		_ColorE("Color+E", 2D) = "white" {}
		_SMMS("SMMS", 2D) = "white" {}
		_Normal("Normal", 2D) = "bump" {}
		//_ReflTex("ReflTex",CUBE) = "white" {}
		_MatcapTex ("MatcapTex",2D) = "black" {}
		//[KeywordEnum(NOSHADOW, HARD_SHADOW, SOFT_SHADOW)]shadow("shadow options", float) = 2
        //_Cubemap("Cubemap",Cube) = "cube" {}
		_WholeAO("明暗度", Range(0, 1.0)) = 1

		[HideInInspector] _PatternMaskTex("PatternMaskTex",2D) = "black" {}
		[HideInInspector] _PatternColor1("PatternColor1", Color) = (1,1,1,1)
		[HideInInspector] _PatternColor2("PatternColor2", Color) = (1,1,1,0)
		[HideInInspector] _PatternTex("PatternTex",2D) = "white" {}

		[HideInInspector] _CustomSkinMode("", Float) = 0.0
		[HideInInspector][Toggle]_CUSTOMSKIN_BOOL("", Float) = 0.0
		[HideInInspector][Toggle]_CUSTOMSKINADDCOLOR_BOOL("", Float) = 0.0
		[HideInInspector][Toggle]_CUSTOMSKINPATTERNTEX_BOOL("", Float) = 0.0
		[HideInInspector][KeywordEnum(Add,Alpha)] _PATTERNMODE("", Float) = 0

		[HideInInspector]
		_MainTex ("MainTex", 2D) = "white" {}

        [Header(Inference)]

        _InferenceColorfulMetal ("反光饱和度", Range(0, 2)) = 1.0
        _InferenceHighlight ("高光强度", Range(0, 2)) = 1.0
        _InferenceMainLightIntensity ("照明光", Range(0, 2)) = 1.0
		_InferenceCubeIntensity("环境反光", Range(0,2)) = 1
		_InferenceShadowIntensity("阴影强度", Range(0, 1)) = 0.5
        _Ramp ("Ramp", 2D) = "white" {}
        _Tint("Tint", Range(0, 1)) = 1.0
        _Reflect("Reflect", CUBE) = "white" {}
        _Thickness ("Thickness", 2D) = "white" {}
        _ThicknessFactor ("Thickness Factor", Range(0, 1)) = 0.5
        BRDF_LUT("BRDF LUT", 2D) = "black" {}
        _InferenceMask ("Inference Mask", 2D) = "white"
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex CHVertBase
            #pragma fragment CHFragBase
            #define _CHDISPLAY
			#define _MATCAP
			#define _EMISSION
			#define _RAMP
            #define _INFERENCE
			#pragma multi_compile _ _SOFTSHADOW
			#pragma multi_compile _ _RECEIVESHADOW
			#pragma multi_compile __ _SKINMASK
			#pragma multi_compile __ _SKINADDCOLOR
			#pragma multi_compile __ _SKINPATTERN
			#pragma multi_compile _PATTERNMODE_ADD _PATTERNMODE_ALPHA

            #include "UnityCG.cginc"
            #include "BRDF.cginc"
            #include "CHCore.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            /*float3 UnpackBump(float4 packedbump, float3 normal, float4 tangent, float scale)
            {
                float3 bump = UnpackNormal(packedbump);
                bump.xy *= scale;
                bump = normalize(bump);
                float3 binormal = normalize(cross(normal, tangent.xyz)) * tangent.w;
                float3x3 tan2obj = float3x3(
                    float3(tangent.x, binormal.x, normal.x),
                    float3(tangent.y, binormal.y, normal.y),
                    float3(tangent.z, binormal.z, normal.z));
                float3 bumpedNormal = mul((tan2obj), bump);
                return normalize(bumpedNormal);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent.xyz = UnityObjectToWorldNormal(v.tangent.xyz);
                o.tangent.w = v.tangent.w;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)).xyz;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 albedo = tex2D(_MainTex, i.uv);
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 normal = UnpackBump(tex2D(_BumpMap, i.uv), i.normal, i.tangent, _BumpScale);
                float NoL = saturate(dot(normal, lightDir));
                float NoV = saturate(dot(normal, viewDir));
                float3 H = normalize(lightDir + viewDir);
                float NoH = saturate(dot(normal, H));
                float VoH = saturate(dot(viewDir, H));
                float3 refl = normalize(reflect(-viewDir, normal));
                float metallic = _Metallic;
                float roughness = _Roughness;
                fixed3 diffuse = albedo * OneMinusReflectivityFromMetallic(metallic);
                float thickness = tex2D(_Thickness, i.uv).r * _ThicknessFactor + NoV;
                fixed3 tint = tex2D(_Ramp, float2(thickness * _Ramp_ST.x + _Ramp_ST.z, 0.5)).rgb * _Tint;
                fixed3 specular = lerp(unity_ColorSpaceDielectricSpec.rgb, 1, metallic);
                fixed3 diffTerm = Diffuse_Lambert(diffuse * (1 - specular)) * NoL * PI;
                float a2 = pow(roughness, 4);
                float D = D_GGX(a2, NoH);
                float vis = Vis_Schlick(a2, NoV, NoL);
                float3 F = F_Schlick(specular, VoH);
                fixed3 specTerm = saturate(max(0, D * vis * F) * NoL * PI) * specular;
                fixed3 ibl = ApproximateSpecularIBL(_Reflect, specular, roughness, normal, viewDir, refl);
                ibl = lerp(ibl, tint, _Tint);
                return fixed4(diffTerm + ibl + specTerm, 1);
            }*/
            ENDHLSL
        }
    }
}
