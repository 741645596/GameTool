Shader "Omega/FX/ParticleBase_Billboard" {
Properties {
	[HideInInspector][HDR]_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)


	[HideInInspector][Toggle] _MAINUVANI("UVAnimation",Float) = 0
	[HideInInspector]_MainTexScrollU("ScrollU", Range(-5,5)) = 0
	[HideInInspector]_MainTexScrollV("ScrollV", Range(-5,5)) = 0
	[HideInInspector][Toggle] _RGBXA("RGB x A", Float) = 0
	[HideInInspector][Toggle] _USEHUE("Hue",Float) = 0
	[HideInInspector]_Hue("Hue Color", Range(0,360)) = 0
	[HideInInspector][Toggle] _USEDATA("CustomData", Float) = 0
	[HideInInspector][Toggle] _SHEET("Sheet",Float) = 0
	[HideInInspector][IntRange]_TilesX("TilesX", Range(1, 8)) = 4
	[HideInInspector][IntRange]_TilesY("TilesY", Range(1, 8)) = 4
	[HideInInspector]_SheetSpeed("SheetAnimationSpeed",float) = 4

	[HideInInspector]_MainTex("Base (RGB) Trans (A)", 2D) = "white" {} //fix UI bug
	
	[Header(AlphaBlendMode)] //Zero = 0,One = 1,DstColor = 2,SrcColor = 3,OneMinusDstColor = 4,SrcAlpha = 5,OneMinusSrcColor = 6,DstAlpha = 7,OneMinusDstAlpha = 8,SrcAlphaSaturate = 9,OneMinusSrcAlpha = 10
	[Enum(Zero,0,One,1,DstColor,2,SrcAlpha,5)]  _SrcBlend("SrcFactor",Float) = 5
	[Enum(Zero,0,One,1,OneMinusSrcAlpha,10)]  _DstBlend("DstFactor",Float) = 1
	//[Header(Additive(SrcAlpha.One))][Header(AlphaBlend(SrcAlpha.OneMinusSrcAlpha))][Header(Transparent(One.OneMinusSrcAlpha))][Header(Opaque(One.Zero))][Header(AdditiveSoft(One.OneMinusSrcColor))]
	[Header(RenderState)]
	[Enum(RGB,14,RGBA,15)] _ColorMask("Color Mask", Float) = 14 //Alpha = 1,Blue = 2,Green = 4,Red = 8,All = 15
	[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode",Float) = 0
	[Enum(Off,0,On,1)] _Zwrite("Zwrite", Float) = 0
	[Enum(Off,0,On,2)] _Ztest("Ztest", Float) = 2
	[KeywordEnum(None,Left,Right,Centre)] _TM("Type", Float) = 0
	_TMPow("Power", Range(0.01,8)) = 1
	_ZBias ("ZBias", Range(-10, 10)) = 0
	[Toggle] _ZClip ("Z Clip", Float) = 1
}

Category {
    Tags 
	{ 
		"Queue"="Transparent" 
		"IgnoreProjector"="True" 
		"RenderType"="Transparent" 
		"PreviewType"="Plane"
		"DisableBatching" = "true" 
	}
    Blend [_SrcBlend] [_DstBlend]
    ColorMask [_ColorMask]
    Cull [_Cull] 
    Lighting Off 
    ZWrite [_Zwrite] 
    ZTest[_Ztest]
    ZClip [_ZClip]

    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_fog
			//#pragma multi_compile __ _MAINUVANI_ON
			//#pragma multi_compile __ _RGBXA_ON
			#pragma multi_compile __ _USEHUE_ON
			#pragma multi_compile __ _SHEET_ON
			//#pragma multi_compile __ _USEDATA_ON 
            #include "UnityCG.cginc"
            #include "UnityShaderVariables.cginc"
			#include "ScreenBorderEffect.cginc"

            sampler2D _MainTex;
            half4 _TintColor;
			half _Hue;
			half _TilesX, _TilesY;
			half _SheetSpeed;
			half _MainTexScrollU, _MainTexScrollV;
			fixed _USEDATA;
			fixed _MAINUVANI;
			fixed _RGBXA;
			half _TM;
			float _TMPow;
			float _ZBias;

#ifdef _USEHUE_ON
			inline half3 applyHue(half3 aColor, half aHue)
			{
				half angle = radians(aHue);
				half3 k = half3(0.57735, 0.57735, 0.57735);
				half cosAngle = cos(angle);
				return aColor * cosAngle + cross(k, aColor) * sin(angle) + k * dot(k, aColor) * (1 - cosAngle);
			}
#endif

            struct appdata_t {
                float4 vertex : POSITION;
                half4 color : COLOR;
				half4 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
				float4 vertex : SV_POSITION;
                half4 color : COLOR;
                half4 texcoord : TEXCOORD0;
                UNITY_FOG_COORDS(1)
            };

            half4 _MainTex_ST;

            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
				v.vertex.xyz += _ZBias * normalize(ObjSpaceViewDir(v.vertex));
				//o.vertex = UnityObjectToClipPos(v.vertex);
                
				float2 scale = float2(length(unity_ObjectToWorld[0].xyz), length(unity_ObjectToWorld[1].xyz));
				float4 viewPos = mul(unity_MatrixMV, float4(0.0, 0.0, 0.0, 1.0)) + float4(v.vertex.xy * scale, 0.0, 0.0);
				o.vertex = mul(UNITY_MATRIX_P, viewPos);
				o.color = v.color;
				o.texcoord.zw = v.texcoord.xy;
#ifdef _SHEET_ON
				half2 size = half2(1 / _TilesX, 1 / _TilesY);
				half totalFrames = floor(_TilesX * _TilesY);

				half index = floor(_Time.w * _SheetSpeed);
				half indexX = floor(index % _TilesX);
				half indexY = floor((index % totalFrames) / _TilesX);

				half2 offset = half2(size.x * indexX, -size.y * indexY);
				half2 newUV = v.texcoord * size;
				newUV.y = newUV.y + size.y*(_TilesY - 1);
				v.texcoord.xy = newUV + offset;
#endif

				o.texcoord.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex);

				if (_USEDATA == 1.0)
					o.texcoord.xy += v.texcoord.zw;

				if(_MAINUVANI == 1.0)
					o.texcoord.xy += frac(_Time.yy* half2(_MainTexScrollU, _MainTexScrollV));

                UNITY_TRANSFER_FOG(o,o.vertex);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.texcoord.xy);
				col *= 2.0f * i.color * _TintColor;

#ifdef _USEHUE_ON
				col.rgb = applyHue(col.rgb, _Hue);
#endif

				if(_RGBXA == 1.0)
					col.rgb *= col.a;

				col = saturate(col);
				
				half tm = 1;
				if (_TM == 1)
					tm = 1 - i.texcoord.z;
				if (_TM == 2)
					tm = i.texcoord.z;
				if (_TM == 3)
					tm = 1 - distance(half2(0.5, 0.5), i.texcoord.zw);
				if (_TM != 0)
					col *= pow(saturate(tm), _TMPow)*max(1, _TMPow);;
			
				UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
CustomEditor "ParticleBaseGUI"
}
