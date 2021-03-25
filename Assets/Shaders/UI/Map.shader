Shader "Omega/UI/Map"
{
	Properties
	{
		[PerRendererData]_MainTex ("Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,1)

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255

		_ColorMask("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0

		_LineSize("Line Size", Range(1, 100)) = 1

		_MoveRoundColor("Move round color", Color) = (1, 1, 1, 1)
		_MoveRoundColor_2("Move round color 2", Color) = (1, 1, 1, 1)
		_LerpDistance("Move Color Lerp Distance", Range(0, 1)) = 0.1 
		_LerpPower("Move Color Lerp Power", Range(1, 600)) = 90
		_TargetRoundColor("Target round color", Color) = (1, 1, 1, 1)

		//[Space(15)][Header(Direction Line)]
		//_DirectionLineColor("Player direction line color", Color) = (1, 1, 1, 1)
		//_DirectionLineFragLength("direction line frag length", Range(0, 10000)) = 100
		//[HideInInspector]m_drawLinePoint("draw direction Line", INT) = 0			

		//[Space(15)][Header(Mask Line 1)]
		//_MaskLineColor_1("Line Color", Color) = (1, 1, 1, 1)
		//_MaskLineFragLength_1("Line frag length", Range(20, 900)) = 100
		//[HideInInspector]_DrawMaskLine1("draw Line 1", INT) = 0
		//[HideInInspector]_MaskLinePoint_1("line point", Vector) = (0, 0, 0, 0)

		//[Space(15)][Header(Mask Line 2)]
		//_MaskLineColor_2("Line Color", Color) = (1, 1, 1, 1)
		//_MaskLineFragLength_2("Line frag length", Range(20, 900)) = 100
		//[HideInInspector]_DrawMaskLine2("draw Line 2", INT) = 0
		//[HideInInspector]_MaskLinePoint_2("line point", Vector) = (0, 0, 0, 0)

		//[Space(15)][Header(Mask Line 3)]
		//_MaskLineColor_3("Line Color", Color) = (1, 1, 1, 1)
		//_MaskLineFragLength_3("Line frag length", Range(20, 900)) = 100
		//[HideInInspector]_DrawMaskLine3("draw Line 3", INT) = 0
		//[HideInInspector]_MaskLinePoint_3("line point", Vector) = (0, 0, 0, 0)
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

		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask[_ColorMask]

		Pass
		{

			//Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_fog
			#pragma target 2.0

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"
			#include "MapFunction.cginc"

			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma multi_compile __ UNITY_UI_CLIP_RECT

			float _LineSize;
			
			//uniform int m_drawLinePoint;
			//uniform float4 m_linePoint;
			//uniform float _DirectionLineFragLength;
			//uniform fixed4 _DirectionLineColor;

			//uniform int _DrawMaskLine1;
			//uniform float4 _MaskLinePoint_1;
			//uniform float4 _MaskLineColor_1;
			//uniform float _MaskLineFragLength_1;

			//uniform int _DrawMaskLine2;
			//uniform float4 _MaskLinePoint_2;
			//uniform float4 _MaskLineColor_2;
			//uniform float _MaskLineFragLength_2;

			//uniform int _DrawMaskLine3;
			//uniform float4 _MaskLinePoint_3;
			//uniform float4 _MaskLineColor_3;
			//uniform float _MaskLineFragLength_3;

			uniform float fMapScale = 1.0f;
			uniform float4 m_MoveRoundInfo;
			uniform float4 m_TargetRoundInfo;
			fixed4 _MoveRoundColor;
			fixed4 _MoveRoundColor_2;
			float _LerpDistance;
			float _LerpPower;
			fixed4 _TargetRoundColor;

			struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

                OUT.color = v.color * _Color;
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                //half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;

				float lineScale = 10000 * fMapScale;
				float lineSize = _LineSize / lineScale;

				float4 center = float4(m_MoveRoundInfo.xy, 0, 0);
				float dis = distance(IN.texcoord, center);
				dis -= m_MoveRoundInfo.z;
				dis /= _LerpDistance;
				dis = min(1, dis);
				dis = max(0, dis);
				float4 move_round_color_lerp = lerp(_MoveRoundColor_2, _MoveRoundColor, pow(smoothstep(0, 1, dis), _LerpPower / 300));

				fixed4 roundColor = DrawRound(IN.texcoord, lineSize, fixed4(0, 0, 0, 0), 
					m_TargetRoundInfo, _TargetRoundColor, m_MoveRoundInfo, move_round_color_lerp);
				//roundColor.a = move_round_color_lerp.a;

				//float4 v1 = float4(m_linePoint.xy, 0, 0);
				//float4 v2 = float4(m_linePoint.zw, 0, 0);

				//if (m_drawLinePoint > 0 && distance(v1, v2) >= m_TargetRoundInfo.z)
				//{
				//	fixed4 drawLineColor = DrawLine(m_linePoint, 
				//		1, IN.texcoord, lineSize, _DirectionLineColor.rgb, 0);

				//	roundColor = lerp(roundColor, drawLineColor, drawLineColor.a);
				//}

				//if (_DrawMaskLine1 > 0 && _MaskLinePoint_1.x != _MaskLinePoint_1.z && _MaskLinePoint_1.y != _MaskLinePoint_1.w)
				//{
				//	fixed4 drawLineColor = DrawLine(_MaskLinePoint_1,
				//		_MaskLineFragLength_1 / lineScale, IN.texcoord, lineSize, _MaskLineColor_1.rgb, 0);

				//	roundColor = lerp(roundColor, drawLineColor, drawLineColor.a);
				//}

				//if (_DrawMaskLine2 > 0 && _MaskLinePoint_2.x != _MaskLinePoint_2.z && _MaskLinePoint_2.y != _MaskLinePoint_2.w)
				//{
				//	fixed4 drawLineColor = DrawLine(_MaskLinePoint_2,
				//		_MaskLineFragLength_2 / lineScale, IN.texcoord, lineSize, _MaskLineColor_2.rgb, 0);

				//	roundColor = lerp(roundColor, drawLineColor, drawLineColor.a);
				//}

				//if (_DrawMaskLine3 > 0 && _MaskLinePoint_3.x != _MaskLinePoint_3.z && _MaskLinePoint_3.y != _MaskLinePoint_3.w)
				//{
				//	fixed4 drawLineColor = DrawLine(_MaskLinePoint_3,
				//		_MaskLineFragLength_3 / lineScale, IN.texcoord, lineSize, _MaskLineColor_3.rgb, 0);

				//	roundColor = lerp(roundColor, drawLineColor, drawLineColor.a);
				//}

				//color.rgb = lerp(color.rgb, roundColor.rgb, roundColor.a);				

                #ifdef UNITY_UI_CLIP_RECT
				roundColor.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (roundColor.a - 0.001);
                #endif

				//color.a = roundColor.a;

                return roundColor;
            }

			ENDCG
		}
	}
}
