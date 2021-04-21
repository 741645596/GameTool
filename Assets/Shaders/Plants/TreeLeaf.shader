Shader "Omega/Plants/TreeLeaf"
{
	Properties
	{
		_Color("Main Color", Color) = (1,1,1,1)
		_SpecularColor("Specular Color", Color) = (.2,.2,.2,1)
		_Shininess("Shininess", Range(0.01, 1)) = 0.5
		//_Shadow("Shadow", Range(0.01, 1)) = 0.9
		_MainTex("Base (RGB) TransGloss (A)", 2D) = "white" {}
		_BumpMap("Normalmap", 2D) = "bump" {}
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		//_Mode("__mode", Float) = 2
	}

	SubShader
	{
		Tags {"Queue" = "AlphaTest"  "RenderType" = "TransparentCutout"}
		Cull Off
		Pass 
		{
			Tags {"LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			//#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "UnityLightingCommon.cginc"
			#include "../cginc/FogCore.cginc"

			fixed4 _Color;
			fixed4 _SpecularColor;
			half _Shininess;
			//half _Shadow;
			
			sampler2D _MainTex;
			sampler2D _BumpMap;

			half _Cutoff;
			//half _Mode;

			struct CustomLeafOutput 
			{
				fixed4 albedo;
				fixed3 normal;
				fixed alpha;
				fixed3 emission;
			};

			struct a2v 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f 
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 tanSpace0 : TEXCOORD1;
				float4 tanSpace1 : TEXCOORD2;
				float4 tanSpace2 : TEXCOORD3;
				float3 viewDir : TEXCOORD4;
				float3 lightDir : TEXCOORD5;
				//UNITY_SHADOW_COORDS(6)
				//UNITY_FOG_COORDS(7)
				half fogCoord	: TEXCOORD6;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.texcoord;
				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				float3 normal = UnityObjectToWorldNormal(v.normal);
				float3 tangent = UnityObjectToWorldDir(v.tangent.xyz);
				float3 binormal = cross(normal, tangent) * v.tangent.w * unity_WorldTransformParams.w;
				o.tanSpace0 = float4(tangent.x, binormal.x, normal.x, posWorld.x);
				o.tanSpace1 = float4(tangent.y, binormal.y, normal.y, posWorld.y);
				o.tanSpace2 = float4(tangent.z, binormal.z, normal.z, posWorld.z);
				o.viewDir  = normalize(UnityWorldSpaceViewDir(posWorld));
				o.lightDir = normalize(UnityWorldSpaceLightDir(posWorld));
				//UNITY_TRANSFER_SHADOW(o, v.texcoord0.xy);
				//UNITY_TRANSFER_FOG(o, o.pos);
				o.fogCoord = GetFogCoord(o.pos, posWorld);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 albedo = tex2D(_MainTex, i.uv);
				clip(albedo.a - _Cutoff);
				fixed3 normal = UnpackNormal(tex2D(_BumpMap, i.uv));
				fixed3 worldNormal;
				worldNormal.x = dot(i.tanSpace0.xyz, normal); 
				worldNormal.y = dot(i.tanSpace1.xyz, normal); 
				worldNormal.z = dot(i.tanSpace2.xyz, normal);
				
				//UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos)
				
				albedo = albedo * _Color;

				half3 h = normalize(i.lightDir + i.viewDir);
				half NoL = max(0, dot(worldNormal, i.lightDir));
				half NoH = max(0, dot(worldNormal, h));
				half spec = pow(NoH, 38 * _Shininess);
				
				half3 light = _LightColor0.rgb;
				
				/*atten = lerp(1, atten, _Shadow);
				NoL = lerp(1, NoL, _Shadow);
				light = lerp(1, light, _Shadow);*/
				
				fixed4 col;
				col.rgb = albedo.rgb * UNITY_LIGHTMODEL_AMBIENT;
				col.rgb += (albedo.rgb * light.rgb * NoL + light.rgb * spec * _SpecularColor.rgb);// * atten;
				col.a = albedo.a;

				//UNITY_APPLY_FOG(i.fogCoord, col);
				//col.rgb = ApplyFog(col.rgb, i.fogCoord);
				col.rgb = ApplySunFog(col.rgb, i.fogCoord, i.viewDir);
				//UNITY_OPAQUE_ALPHA(col.a);
				return col;
			}
			ENDCG
		}
		/*CGPROGRAM
		#pragma surface surf CustomLeafLight addshadow 
		#pragma target 3.0

		struct CustomLeafOutput {
			fixed3 Albedo;
			fixed3 Normal;
			fixed Alpha;
			fixed3 Emission;
		};

		sampler2D _MainTex;
		sampler2D _BumpMap;
		fixed4 _Color;
		fixed4 _SpecularColor;
		fixed _Shininess;
		fixed _Shadow;
		fixed _Cutoff;

		struct Input {
			fixed2 uv_MainTex;
			fixed2 uv_BumpMap;
		};

		void surf(Input IN, inout CustomLeafOutput o) {
			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			o.Albedo = tex.rgb*_Color.rgb;
			o.Alpha = tex.a*_Color.a;
			clip(tex.a - _Cutoff);
		}

		half4 LightingCustomLeafLight(CustomLeafOutput s, half3 lightDir, half3 viewDir, half atten)
		{
			half3 h = normalize(lightDir + viewDir);
			half diff = max(0, dot(s.Normal, lightDir));

			half nh = max(0, dot(s.Normal, h));
			half spec = pow(nh, 48*_Shininess);

			half3 light = _LightColor0.rgb;

			atten = lerp(1, atten, _Shadow);
			diff = lerp(1, diff, _Shadow);
			light = lerp(1, light, _Shadow);


			half4 c;
			c.rgb = (s.Albedo * light.rgb * diff   + light.rgb*spec*_SpecularColor.rgb) * atten;
			c.a = s.Alpha;

			return c;
		}
		ENDCG*/
	}
//FallBack "Legacy Shaders/Transparent/Cutout/VertexLit"
}
