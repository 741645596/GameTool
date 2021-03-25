Shader "Omega/FX/ScreenBorderEffect"
{
    Properties
    {
		_TintColor("Tint Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _MainTex ("Texture", 2D) = "white" {}
		_Border ("Border Size (Hori, Vert)", Vector) = (0.5, 0.5, 1, 1)
    }
    SubShader
    {
		Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "ScreenBorderEffect.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _TintColor;

			struct appdata_t
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

            struct v2f
            {
                float2 texcoord : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata_t v)
            {
                v2f o;
				o.vertex = ObjectToClipPosBorder(v.vertex);
                o.texcoord = TRANSFORM_TEX(ClipPosToScreenUV(o.vertex), _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
				fixed4 tex = tex2D(_MainTex, i.texcoord);
				return _TintColor * tex;
            }
            ENDCG
        }
    }
}
