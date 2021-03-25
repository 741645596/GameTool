Shader "Omega/FX/ParticleVHSEffect" {
Properties {
    _TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
	[PerRendererData]_MainTex("Sprite Texture", 2D) = "white" {}
	_NoiseTex("NoiseTex", 2D) = "white" {}
	_Noise("Noise",Range(0,1)) = 0.5
	_NoiseScoll("NoiseScoll",Range(0,1)) = 0.5
	[Header(HueColor)]
	[Toggle] _USEHUE("Hue",Float) = 0
	_Hue("Hue Color", Range(0,360)) = 0
	[Header(SheetAnimation)]
	[Toggle] _SHEET("Sheet",Float) = 0
	[IntRange]_TilesX("TilesX", Range(1, 8)) = 4
	[IntRange]_TilesY("TilesY", Range(1, 8)) = 4
	_SheetSpeed("SheetAnimationSpeed",float) = 4
	[Header(AlphaBlendMode)] //Zero = 0,One = 1,DstColor = 2,SrcColor = 3,OneMinusDstColor = 4,SrcAlpha = 5,OneMinusSrcColor = 6,DstAlpha = 7,OneMinusDstAlpha = 8,SrcAlphaSaturate = 9,OneMinusSrcAlpha = 10
	[Enum(One,1,SrcAlpha,5)]  _SrcBlend("SrcFactor",Float) = 5
	[Enum(One,1,OneMinusSrcAlpha,10)]  _DstBlend("DstFactor",Float) = 1
	//[Header(Additive(SrcAlpha.One))][Header(AlphaBlend(SrcAlpha.OneMinusSrcAlpha))][Header(Transparent(One.OneMinusSrcAlpha))][Header(Opaque(One.Zero))][Header(AdditiveSoft(One.OneMinusSrcColor))]
	[Header(RenderState)]
	[Enum(RGB,14,RGBA,15)] _ColorMask("Color Mask", Float) = 14 //Alpha = 1,Blue = 2,Green = 4,Red = 8,All = 15
	[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode",Float) = 0
	[Enum(Off,0,On,1)] _Zwrite("Zwrite", Float) = 0
	[Enum(Off,0,On,2)] _Ztest("Ztest", Float) = 2
	[KeywordEnum(No,Fade,Color)] _FOG("Fog", Float) = 0
	[Toggle] _RGBXA("RGB x A", Float) = 0
}

Category {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
    Blend [_SrcBlend] [_DstBlend]
    ColorMask [_ColorMask]
    Cull [_Cull] Lighting Off ZWrite [_Zwrite] ZTest[_Ztest]

    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

			//#pragma multi_compile __ _RGBXA_ON
			#pragma multi_compile __ _USEHUE_ON
			//#pragma multi_compile __ _USEFX_ON
			#pragma multi_compile __ _SHEET_ON
            #include "UnityCG.cginc"

            sampler2D _MainTex;
			sampler2D _NoiseTex;
			half4 _NoiseTex_ST;
            fixed4 _TintColor;
			fixed _Hue;
			half _TilesX, _TilesY;
			half _SheetSpeed;
			half _Noise, _NoiseScoll;
			fixed _RGBXA;

			inline fixed3 applyHue(fixed3 aColor, fixed aHue)
			{
				fixed angle = radians(aHue);
				fixed3 k = fixed3(0.57735, 0.57735, 0.57735);
				fixed cosAngle = cos(angle);
				return aColor * cosAngle + cross(k, aColor) * sin(angle) + k * dot(k, aColor) * (1 - cosAngle);
			}

            struct appdata_t {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                fixed2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
				float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                fixed4 texcoord : TEXCOORD0;
            };

            fixed4 _MainTex_ST;

            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color;

				o.texcoord.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
#ifdef _SHEET_ON
				fixed2 size = fixed2(1 / _TilesX, 1 / _TilesY);
				fixed totalFrames = floor(_TilesX * _TilesY);

				fixed index = floor(_Time.w * _SheetSpeed);
				fixed indexX = floor(index % _TilesX);
				fixed indexY = floor((index % totalFrames) / _TilesX);

				fixed2 offset = fixed2(size.x * indexX, -size.y * indexY);
				fixed2 newUV = v.texcoord.xy * size;
				newUV.y = newUV.y + size.y*(_TilesY - 1);
				v.texcoord.xy = newUV + offset;
#endif


				o.texcoord.zw = TRANSFORM_TEX(v.texcoord.xy, _NoiseTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

				half2 noriseUV = tex2D(_NoiseTex, i.texcoord.zw + frac(_Time.xy*_NoiseScoll)).xy;
				noriseUV = (noriseUV*2-1)*_Noise;

				fixed4 col = tex2D(_MainTex, i.texcoord.xy + noriseUV);

				half4 shiftR = tex2D(_MainTex, i.texcoord.xy - noriseUV.yx*1.5);
				col.r = saturate(shiftR.r);

				half4 shiftB = tex2D(_MainTex, i.texcoord.xy + noriseUV.yx);
				col.b = saturate(shiftB.b);

				col.a += shiftR.a + shiftB.a;
				col *= 2.0f * i.color * _TintColor;

#if _USEHUE_ON
				col.rgb = applyHue(col.rgb, _Hue);
#endif


				if(_RGBXA == 1.0)
					col.rgb *= col.a;

				col = saturate(col);

                return col;
            }
            ENDCG
        }
    }
}
}
