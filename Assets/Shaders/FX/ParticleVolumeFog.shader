Shader "Omega/FX/ParticleVolumeFog" {
Properties {
    _TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
	[PerRendererData]_MainTex("Sprite Texture", 2D) = "white" {}

	_LightTex("LightTex", 2D) = "white" {}
	_FogOffset("FogOffset", vector) = (0.2,1,0,0)
	_FogColor("FogColor", Color) = (0.5,0.5,0.5,0.5)
	_FogRate("FogRate",Range(0,0.2)) = 0.1
	[IntRange]_FogStep("FogStep",Range(12,32)) = 16
	_NoiseTex("NoiseTex", 2D) = "white" {}	

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
            #pragma target 3.0
            #include "UnityCG.cginc"

            sampler2D _MainTex;
			sampler2D _NoiseTex;
			half4 _NoiseTex_ST;
            fixed4 _TintColor;
			sampler2D _LightTex;
			half4 _LightTex_ST;
			half4 _FogOffset;
			half4 _FogColor;
			half _FogRate;
			int _FogStep;

			inline fixed getFog(sampler2D tex, fixed2 uv, fixed4 offset)
			{
				fixed temp = 0;
				for (int f = 0; f < _FogStep; f++)
				{			
					temp += tex2D(tex,uv.xy + offset.xy*f).a * _FogRate;
				}
				return temp;
			}

            struct appdata_t {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                fixed2 texcoord : TEXCOORD0;
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
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color;

				o.texcoord.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
				o.texcoord.zw = TRANSFORM_TEX(v.texcoord.xy, _NoiseTex)+ frac(_NoiseTex_ST.zw*_Time.xx);
                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 col = tex2D(_MainTex, i.texcoord.xy);
				fixed4 noise = tex2D(_NoiseTex, i.texcoord.zw);
				fixed light = tex2D(_LightTex, i.texcoord.xy*_LightTex_ST.xy + _LightTex_ST.zw).r;
				fixed fog = getFog(_MainTex, i.texcoord.xy, _FogOffset*0.01);

				light *= 1-fog ;

				col += saturate(light*_FogColor* noise.r);
				col *= 2.0f * i.color * _TintColor ;
                return col;
            }
            ENDCG
        }
    }
}
}
