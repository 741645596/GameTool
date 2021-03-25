Shader "Omega/FX/Ghost"
{
	Properties
	{
		_BumpMap("Normal map", 2D) = "bump" {}
		_RimColor("RimColor", Color) = (1,1,1,1)
		_RimPower("RimPower", Range(0.000001, 8)) = 0.1
		_RimStrength("RimStrength",Range(0, 100)) = 2
		[HideInInspector]_MainTex ("MainTex", 2D) = "black" {}
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		//LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal d3d11_9x xboxone ps4 psp2 n3ds wiiu 
			#pragma target 3.0

			#include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float2 uv : TEXCOORD1;
				//在vertex shader中计算观察方向传递给fragment shader
				float3 worldViewDir : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				float2 baseUV : TEXCOORD4;
				float3 tangentDir : TEXCOORD5;
				float3 bitangentDir : TEXCOORD6;
			};

		    struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };

			float4 _RimColor;
			float _RimPower;
			float _RimStrength;
			uniform sampler2D _BumpMap; uniform float4 _BumpMap_ST;
			
			v2f vert (VertexInput v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				//通过TRANSFORM_TEX宏转化纹理坐标，主要处理了Offset和Tiling的改变,默认时等同于o.uv = v.texcoord.xy;
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				o.uv = TRANSFORM_TEX(v.texcoord0, _BumpMap);
				//顶点转化到世界空间
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				//可以把计算计算ViewDir的操作放在vertex shader阶段，毕竟逐顶点计算比较省
				o.worldViewDir = _WorldSpaceCameraPos.xyz - o.worldPos;
				o.baseUV = v.texcoord0;
				o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.bitangentDir = normalize(cross(o.worldNormal, o.tangentDir) * v.tangent.w);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float3 worldViewDir = normalize(i.worldViewDir);
				float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap, i.uv));
				//计算视线方向与法线方向的夹角，夹角越大，dot值越接近0，说明视线方向越偏离该点，也就是平视，该点越接近边缘
				//float rim_1 = max(0, 1 - abs(dot(i.worldNormal, normalize(i.worldViewDir))) * _RimStrength);
				float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.worldNormal);
				float3 node_7657 = lerp(float3(0, 0, 1), _BumpMap_var.rgb, _RimStrength);
				float3 Normalmap = node_7657;
				float3 normalLocal = Normalmap;
				float3 normalDirection = normalize(mul(normalLocal, tangentTransform)); // Perturbed normals
				float3 viewReflectDirection = reflect(-i.worldViewDir, normalDirection);

				float rim_1 = max(0, 1 - abs(dot(i.worldNormal, viewReflectDirection)) * _RimStrength);
				//计算rimLight
				fixed4 rimColor = _RimColor * pow(rim_1, 1 / _RimPower);

				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, rimColor);
				return rimColor;
			}
			ENDCG
		}
	}
}
