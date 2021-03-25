Shader "Omega/FX/Ghost_ex"
{
	Properties
	{
		_RimColor("RimColor", Color) = (1,1,1,1)
		_RimPower("RimPower", Range(0.000001, 8)) = 0.1
		_RimStrength("RimStrength",Range(0, 100)) = 2
		[Toggle] _IsRun("Shader Run", Float) = 1
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
				//在vertex shader中计算观察方向传递给fragment shader
				float3 worldViewDir : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float2 baseUV : TEXCOORD3;
			};

			float4 _RimColor;
			float _RimPower;
			float _RimStrength;
			uniform float _IsRun;
			
			v2f vert (appdata_base v)
			{
				v2f o;
				if (_IsRun == 1) {
					//通过TRANSFORM_TEX宏转化纹理坐标，主要处理了Offset和Tiling的改变,默认时等同于o.uv = v.texcoord.xy;
					o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
					//顶点转化到世界空间
					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					//可以把计算计算ViewDir的操作放在vertex shader阶段，毕竟逐顶点计算比较省
					o.worldViewDir = _WorldSpaceCameraPos.xyz - o.worldPos;
					o.baseUV = v.texcoord;
				}

				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				if (_IsRun != 1) return fixed4(0, 0, 0, 0);
				// sample the texture
				float3 worldViewDir = normalize(i.worldViewDir);
				//计算视线方向与法线方向的夹角，夹角越大，dot值越接近0，说明视线方向越偏离该点，也就是平视，该点越接近边缘
				float rim_1 = max(0, 1 - abs(dot(i.worldNormal, normalize(i.worldViewDir))) * _RimStrength);
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
