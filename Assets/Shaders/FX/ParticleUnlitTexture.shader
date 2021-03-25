Shader "Omega/FX/ParticleUnlitTexture" 
{
	Properties 
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)

		[Header(AlphaBlendMode)]
		[Enum(UnityEngine.Rendering.BlendMode)]
		_SrcBlend("SrcFactor",Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)]
		_DstBlend("DstFactor",Float) = 1
		
		[Header(RenderState)]
		[Enum(UnityEngine.Rendering.ColoraWriteMask)]
		_ColorMask("Color Mask", Float) = 14
		[Enum(UnityEngine.Rendering.CullMode)]
		_Cull("Cull Mode",Float) = 0
		[Enum(Off,0,On,1)]
		_Zwrite("Zwrite", Float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)]
		_Ztest("Ztest", Float) = 2
	}

	Category 
	{
		Tags 
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
		}
		Cull [_Cull]
		ZWrite [_Zwrite] ZTest[_Ztest]
		Blend [_SrcBlend] [_DstBlend]
		ColorMask [_ColorMask]
		Lighting Off

		SubShader 
		{
			Pass 
			{
				CGPROGRAM
				#pragma target 2.0
				#pragma multi_compile_fog

				#pragma vertex CustomvertBase
				#pragma fragment CustomfragBase

				#include "UnityCG.cginc"

				sampler2D _MainTex;
				float4 _MainTex_ST;
				//color			
				half4 _TintColor;

				struct CustomVertexInput
				{
					half4 vertex : POSITION;
					half4 color : COLOR;
					float2 uv : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct CustomVertexOutput
				{
					half4 vertex : SV_POSITION;
					half4 color : COLOR;
					float2 uv : TEXCOORD0;
					UNITY_FOG_COORDS(1)
				};

				CustomVertexOutput CustomvertBase(CustomVertexInput v)
				{
					CustomVertexOutput o;
					UNITY_SETUP_INSTANCE_ID(v);
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.color = v.color;
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					UNITY_TRANSFER_FOG(o, o.vertex);
					return o;
				}

				half4 CustomfragBase(CustomVertexOutput i) : COLOR
				{
					half4 col = tex2D(_MainTex, i.uv) * _TintColor * i.color;
					UNITY_APPLY_FOG(i.fogCoord, col);
					return col;
				}
				ENDCG
			}
		}
	}
}