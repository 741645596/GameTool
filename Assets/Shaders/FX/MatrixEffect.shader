Shader "Omega/FX/MatrixEffect"
{
	Properties
	{
		_TintColor("TintColor", Color) = (0,1,0.1,0.5)
		_RimColor("EffectColor", Color) = (0,1,0.1,0.7)
		_EdgeColor("RimEdgeColor", Color) = (0,1,0.1,0.7)
		_UVAni1("UVani_1",Range(-8,8)) = 0
		_UVAni2("UVani_2",Range(-8,8)) = 0
		_Offset("Ofset",Vector) = (0,0,0,0)
		[Space(20)]
		//_ColorE("Color+E", 2D) = "white" {}
		_SMMS("SMMS", 2D) = "white" {}
		_Normal("Normal", 2D) = "bump" {}
		[HideInInspector]_MainTex ("MainTex", 2D) = "black" {}
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha

		Pass 
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma only_renderers d3d11 glcore gles gles3 metal d3d9
			#include "UnityCG.cginc"

			//sampler2D _ColorE;
			//float4 _ColorE_ST;
			sampler2D _Normal;
			float4 _Normal_ST;
			sampler2D _SMMS;
			float4 _SMMS_ST;

			half4 _TintColor;
			half4 _RimColor;
			half4 _EdgeColor;
			half _UVAni1,_UVAni2;
			half4 _Offset;

			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 texcoord0 : TEXCOORD0;
			};

			struct VertexOutput {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 tangentToWorldAndPackedData[3]   : TEXCOORD1;
				float4 ViewPos : TEXCOORD4;
			};

			VertexOutput vert(VertexInput v)
			{
				VertexOutput o;

				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.tangentToWorldAndPackedData[0].w = posWorld.x;
				o.tangentToWorldAndPackedData[1].w = posWorld.y;
				o.tangentToWorldAndPackedData[2].w = posWorld.z;
				o.pos = UnityObjectToClipPos(v.vertex);


				half3 normalWorld = UnityObjectToWorldNormal(v.normal);
				half4 tangentWorld = half4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
				half sign = tangentWorld.w * unity_WorldTransformParams.w;
				half3 binormal = cross(normalWorld, tangentWorld.xyz) * sign;
				half3x3 tangentToWorld = half3x3(tangentWorld.xyz, binormal, normalWorld);
				o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
				o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
				o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];

				o.uv.xy = v.texcoord0;
				o.ViewPos = ComputeScreenPos(o.pos);
				
				return o;
			}

			fixed4 frag(VertexOutput i) : COLOR
			{			
				//float4 albedo = tex2D(_ColorE, TRANSFORM_TEX(i.uv, _ColorE));
				fixed gray = 0.5;//Luminance(albedo);

				float3 normaltex = UnpackNormal(tex2D(_Normal, TRANSFORM_TEX(i.uv, _Normal)));

				//NormalSetup
				half3 tangent = i.tangentToWorldAndPackedData[0].xyz;
				half3 binormal = i.tangentToWorldAndPackedData[1].xyz;
				half3 normal = i.tangentToWorldAndPackedData[2].xyz;
				float3 norDir = normalize(tangent * normaltex.x + binormal * normaltex.y + normal * normaltex.z);

				//dir
				float3 posWorld = float3(i.tangentToWorldAndPackedData[0].w, i.tangentToWorldAndPackedData[1].w, i.tangentToWorldAndPackedData[2].w);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - posWorld);
				float NoV = saturate(dot(norDir, viewDir));
				float Rim = 1 - NoV.r;

				fixed2 screenPos = i.ViewPos.xy / i.ViewPos.w;
				fixed2 checkUV = frac(screenPos);

				fixed4 m = tex2D(_SMMS, checkUV.xy*_SMMS_ST.xy + fixed2(0,frac(_Time.y*_UVAni1)));
				fixed4 m2 = tex2D(_SMMS, checkUV.xy*_SMMS_ST.xy - fixed2(0, frac(_Time.y*_UVAni2)));
				fixed4 m3 = tex2D(_SMMS, checkUV.xy*_SMMS_ST.xy);

				fixed3 mulityrimcolor = _RimColor.rgb * 4;
				fixed3 final = _TintColor.rgb;
				final += Rim * _EdgeColor.rgb * gray * 4;
				final += pow(Rim,4) * _EdgeColor.a;
				final += gray * (m.r * m2.g + m.b + m3.g* m2.a) * mulityrimcolor * _RimColor.rgb;
				final = saturate(final);
				fixed alpha = _TintColor.a;

				return fixed4(final.rgb, alpha);
			}
			ENDCG
		}
	}
}


