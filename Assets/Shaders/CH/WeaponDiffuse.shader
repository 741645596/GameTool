Shader "Omega/Actors/WeaponDiffuse"
{
	Properties
	{
		[Space(20)]
		_NormalTex("Normal", 2D) = "bump" {}
		_MainTex ("MainTex", 2D) = "white" {}

		[HideInInspector] _PatternMaskTex("PatternMaskTex",2D) = "black" {}
		[HideInInspector] _PatternColor1("PatternColor1", Color) = (1,1,1,1)
		[HideInInspector] _PatternColor2("PatternColor2", Color) = (1,1,1,0)
		[HideInInspector] _PatternTex("PatternTex",2D) = "white" {}

		[HideInInspector] _CustomSkinMode("", Float) = 0.0
		[HideInInspector][Toggle]_CUSTOMSKIN_BOOL("", Float) = 0.0
		[HideInInspector][Toggle]_CUSTOMSKINADDCOLOR_BOOL("", Float) = 0.0
		[HideInInspector][Toggle]_CUSTOMSKINPATTERNTEX_BOOL("", Float) = 0.0
		[HideInInspector][KeywordEnum(Add,Alpha)] _PATTERNMODE("", Float) = 0
	}

		SubShader
	{
		Tags {"RenderType" = "Opaque" }

		Pass
		{

			Tags {"LightMode" = "ForwardBase" }
			ColorMask RGBA
			ZTest Less
			ZWrite On


			CGPROGRAM
			#pragma target 3.0
			#pragma only_renderers d3d11 glcore gles gles3 metal d3d9

			#pragma multi_compile_fog

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			
			struct appdata_t
			{
				float4 vertex   : POSITION;
				float3 normal   : NORMAL;
				float2 texcoord : TEXCOORD0;
				float4 tangent	: TANGENT;
			};

			struct v2f
			{
				float4 pos   : SV_POSITION;
				half4 uv : TEXCOORD0;
				half4 uv2 :TEXCOORD1;
				half3 normalWorld : TEXCOORD2;
				half3 posWorld : TEXCOORD3;
				half3 tangentWorld : TEXCOORD4;
				half3 binormalWorld : TEXCOORD5;

			};

			sampler2D _NormalTex;
			float4 _NormalTex_ST;

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _LightColor0;

		#if defined(_SKINMASK)
			float4 _PatternColor1;
			sampler2D _PatternMaskTex; 
			float4 _PatternMaskTex_ST;
		#endif
			#ifdef _SKINADDCOLOR
			float4 _PatternColor2;
		#endif
		#ifdef _SKINPATTERN
			sampler2D _PatternTex; 
			float4 _PatternTex_ST;
		#endif

			v2f vert(appdata_t v)
			{
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				//TANGENT_SPACE_ROTATION;
				o.uv.xy = v.texcoord;
			#ifdef _SKINMASK
				o.uv.zw = v.vertex.xz;
				o.uv2.w = v.vertex.y;
				o.uv2.xyz = v.normal.xyz;
			#else
				o.uv.zw = 0;
				o.uv2 = 0;
			#endif //_SKINMASK
				o.normalWorld = UnityObjectToWorldNormal(v.normal);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				//TRANSFER_VERTEX_TO_FRAGMENT(o);
				o.tangentWorld = UnityObjectToWorldDir(v.tangent.xyz);
				o.binormalWorld = cross(normalize(o.normalWorld), normalize(o.tangentWorld.xyz)) * v.tangent.w;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3x3 mTangentToWorld = transpose(float3x3(i.tangentWorld, i.binormalWorld, i.normalWorld));
				fixed3 tangentNormal = UnpackNormal(tex2D(_NormalTex, i.uv));
				fixed3 normalDirection = normalize(mul(mTangentToWorld, tangentNormal));  //法线贴图的世界坐标

				fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				float NdL = max(dot(normalDirection, lightDirection), 0);
				float4 albedo = tex2D(_MainTex, i.uv.xy * _MainTex_ST.xy);

			#ifdef _SKINMASK 
				float4 mask = tex2D(_PatternMaskTex,TRANSFORM_TEX(i.uv, _PatternMaskTex));
				float4 pattern = _PatternColor1;

				#ifdef _SKINADDCOLOR    
				pattern = lerp(_PatternColor1,_PatternColor2,sin(i.uv.z* (3*_PatternColor2.a) + (1-_PatternColor1.a)*2));
				#endif //_SKINADDCOLOR

				#ifdef _SKINPATTERN
				half3 patternUV = half3(i.uv.z,i.uv2.w,i.uv.w); // v.vertex.xyz
				half4 patternX = tex2D(_PatternTex,TRANSFORM_TEX(patternUV.zy, _PatternTex) + _Time.yy*_PatternTex_ST.zw);
				half4 patternY = tex2D(_PatternTex,TRANSFORM_TEX(patternUV.xz, _PatternTex) + _Time.yy*_PatternTex_ST.zw);
				half4 patternZ = tex2D(_PatternTex,TRANSFORM_TEX(patternUV.xy, _PatternTex) + _Time.yy*_PatternTex_ST.zw);
				half3 triBlend = pow(i.uv2.xyz,8); //v.normal.xyz
				triBlend /= dot(triBlend,1);
				triBlend = saturate(triBlend);
				pattern.rgb *= patternX*triBlend.x + patternY*triBlend.y + patternZ*triBlend.z;
				//pattern.rgb *= patternZ;
				#endif // _SKINPATTERN

				#ifdef _PATTERNMODE_ADD
				albedo.rgb += pattern.rgb*mask.r;
				#elif _PATTERNMODE_ALPHA
				albedo.rgb = lerp(albedo,pattern,mask.r).rgb;
				#endif // _PATTERNMODE_ADD/_PATTERNMODE_ALPHA
			#endif // _SKINMASK


				half3 lightcolor = (_LightColor0.rgb * NdL + UNITY_LIGHTMODEL_AMBIENT.rgb); // *NoL;
				float3 finalColor = lightcolor * albedo.rgb;

				return half4(finalColor, 1);
			}
			ENDCG
		}

	}
}
