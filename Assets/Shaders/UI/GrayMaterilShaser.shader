// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Omega/UI/GrayMaterilShaser"
{
	Properties
	{
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		_Power("_Power", Range(0,10.0)) = 0.35
	_Color("Tint", Color) = (1,1,1,1)
	}

		SubShader
	{
		Tags
	{
		"Queue" = "Transparent"
		"IgnoreProjector" = "True"
		"RenderType" = "Transparent"
		"PreviewType" = "Plane"
		"CanUseSpriteAtlas" = "True"
	}
		// 源rgba*源a + 背景rgba*(1-源A值)   
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
	{
		CGPROGRAM
#pragma vertex vert     
#pragma fragment frag     
#include "UnityCG.cginc"     

		struct appdata_t
	{
		float4 vertex   : POSITION;
		float4 color    : COLOR;
		float2 texcoord : TEXCOORD0;
	};

	struct v2f
	{
		float4 vertex   : SV_POSITION;
		fixed4 color : COLOR;
		half2 texcoord  : TEXCOORD0;
	};

	sampler2D _MainTex;
	fixed4 _Color;
	float _Power;

	v2f vert(appdata_t IN)
	{
		v2f OUT;
		OUT.vertex = UnityObjectToClipPos(IN.vertex);
		OUT.texcoord = IN.texcoord;
#ifdef UNITY_HALF_TEXEL_OFFSET     
		OUT.vertex.xy -= (_ScreenParams.zw - 1.0);
#endif     
		OUT.color = IN.color * _Color;
		return OUT;
	}

	fixed4 frag(v2f IN) : SV_Target
	{
		half4 color = tex2D(_MainTex, IN.texcoord) * IN.color;

		return half4(color.rgb * _Power, color.a);
	}
		ENDCG
	}
	}

}
