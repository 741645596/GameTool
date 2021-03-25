Shader "Omega/FX/MatrixMusual"
{
	Properties
	{
		_TintColor("Tint Color", Color) = (0.5,0.5,0.5,0.5)
		_TintColor2("Tint Color2", Color) = (0.5,0.5,0.5,0.5)
		_MainTex("Sprite Texture", 2D) = "white" {}

		_MusicData("MusicData (Alpha)", 2D) = "white" {}
		_RowSpacing ("RowSpacing", Range(0,0.98)) = 0.2
		_LineSpacing ("LineSpacing", Range(0,1)) = 0.2
		//_AlphaGradation ("AlphaGradation",Range(0,2)) = 0.2
		_ScrollSpeed ("ScrollSpeed", Vector) = (0,0,0,0)

		[Header(AlphaBlendMode)] //Zero = 0,One = 1,DstColor = 2,SrcColor = 3,OneMinusDstColor = 4,SrcAlpha = 5,OneMinusSrcColor = 6,DstAlpha = 7,OneMinusDstAlpha = 8,SrcAlphaSaturate = 9,OneMinusSrcAlpha = 10
		[Enum(One,1,SrcAlpha,5)]  _SrcBlend("SrcFactor",Float) = 5
		[Enum(One,1,OneMinusSrcAlpha,10)]  _DstBlend("DstFactor",Float) = 1
		//[Header(Additive(SrcAlpha.One))][Header(AlphaBlend(SrcAlpha.OneMinusSrcAlpha))][Header(Transparent(One.OneMinusSrcAlpha))][Header(Opaque(One.Zero))][Header(AdditiveSoft(One.OneMinusSrcColor))]
		[Header(RenderState)]
		[Enum(RGB,14,RGBA,15)] _ColorMask("Color Mask", Float) = 14 //Alpha = 1,Blue = 2,Green = 4,Red = 8,All = 15
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode",Float) = 0
		[Enum(Off,0,On,1)] _Zwrite("Zwrite", Float) = 0
		[Enum(Off,0,On,2)] _Ztest("Ztest", Float) = 2
	}
		SubShader
	{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "PreviewType" = "Plane" }
		Blend[_SrcBlend][_DstBlend]
		ColorMask[_ColorMask]
		Cull[_Cull] Lighting Off ZWrite[_Zwrite] ZTest[_Ztest]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MusicData;
			float4 _MusicData_ST;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			half _RowSpacing, _LineSpacing;
			half4 _TintColor,_TintColor2;
			float2 _ScrollSpeed;
			//half _AlphaGradation;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MusicData);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//Musual
				const float segs =  100 * (1-_RowSpacing);
				float2 p;
				p.x = floor(i.uv.y*segs) / segs;
				p.y = floor(i.uv.x*segs) / segs;

				float fft = tex2D(_MusicData, p.y + frac(_Time.y*_ScrollSpeed.xy)).x;
				float mask = (p.x < fft) ? 1.0 : 0;
				//mask *= saturate(_AlphaGradation -  p.x);

				float2 d = frac((i.uv - p) * float2(segs, segs));
				//d.x = saturate(d.x - _LineSpacing);
		
				float4 c = tex2D(_MainTex,fixed2(i.uv.x,i.uv.y)*_MainTex_ST.xy + frac(_MainTex_ST.zw*_Time.y));
				c *= mask *ceil(d.x - _LineSpacing);

				c *= lerp(_TintColor,_TintColor2,i.uv.y)*2;
				return float4(c.rgb, c.a*mask);
			}
			ENDCG
		}
	}
}