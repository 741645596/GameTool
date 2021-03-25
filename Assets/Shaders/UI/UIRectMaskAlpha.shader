Shader "Omega/UI/UIRectMaskAlpha"
{
    Properties
    {
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,1)

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255

		_ColorMask("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
		
		_X_Alpha_limit("x limit (0 - 1)", Float) = 0.1
		_X_Alpha_Offset("x offset (0 - 1)", Float) = 0.5
		//_Y_Alpha_limit("y limit (0 - 1)", Float) = 0
		//_Y_Alpha_Offset("y offset (0 - 1)", Float) = 0.5

		_X_MidClip("x clip (从中间往两侧)(0 - 1)", Float) = 0.1
		//_Y_MidClip("y clip (从中间往上下)(0 - 1)", Float) = 0
		
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
			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP

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
			float _X_Alpha_limit;
			float _X_Alpha_Offset;
			float _X_MidClip;
			//float _Y_Alpha_limit;
			//float _Y_Alpha_Offset;
			//float _Y_MidClip;

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
                half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;

				#ifdef UNITY_UI_CLIP_RECT
				color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
				#endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

				#ifdef UNITY_UI_CLIP_RECT

				float x_length = (_ClipRect.z - _ClipRect.x);
				float x_offset = x_length * _X_Alpha_Offset;
				float x_clip = x_length * _X_MidClip;
				float x_limit = x_length * _X_Alpha_limit;

				float x_min = _ClipRect.x;
				float x_min_r = x_min + x_limit;
				
				float x_clip_min = x_min + (x_offset - x_clip * 0.5);
				float x_clip_min_l = x_clip_min - x_limit;
				
				float x_clip_max = x_min + (x_offset + x_clip * 0.5);
				float x_clip_max_r = x_clip_max + x_limit;

				float x_max = _ClipRect.z;
				float x_max_l = x_max - x_limit;

				float inside = step(IN.worldPosition.x, x_clip_max) * step(x_clip_min, IN.worldPosition.x);

				float inside_1 = smoothstep(x_min, x_min_r, IN.worldPosition.x);
				float inside_2 = smoothstep(x_clip_min, x_clip_min_l, IN.worldPosition.x);

				float inside_3 = smoothstep(x_clip_max, x_clip_max_r, IN.worldPosition.x);
				float inside_4 = smoothstep(x_max, x_max_l, IN.worldPosition.x);

				color.a *= inside_1 * inside_2 + inside_3 * inside_4;
				color.a *= (1 - inside);

				//float mid_offset = (_ClipRect.z - _ClipRect.x) * _X_Alpha_Offset;

				//float mid = mid_offset * _X_Alpha_limit;
				//float inside1 = smoothstep(_ClipRect.x, _ClipRect.x + mid, IN.worldPosition.x);
				//float inside2 = smoothstep(_ClipRect.x + mid_offset, _ClipRect.x - mid, IN.worldPosition.x);

				////mid_offset = (_ClipRect.z - _ClipRect.x) * (1 - _X_Alpha_Offset);
				//mid = mid_offset * _X_Alpha_limit;
				//float inside3 = smoothstep(_ClipRect.z - mid_offset, _ClipRect.z - mid, IN.worldPosition.x);
				//float inside4 = smoothstep(_ClipRect.z, _ClipRect.z - mid, IN.worldPosition.x);
				
				//color.a *= inside1 * inside2 + inside3 * inside4;
				//color.a *= inside3 * inside4;

				//float mid = (_ClipRect.z - _ClipRect.x) *_X_Alpha_limit;
				//float inside1 = smoothstep(_ClipRect.x, _ClipRect.x + mid, IN.worldPosition.x);
				//float inside3 = smoothstep(_ClipRect.z, _ClipRect.z - mid, IN.worldPosition.x);
				//color.a *= inside1 * inside3;

				//mid_offset = (_ClipRect.w - _ClipRect.z) * _Y_Alpha_Offset;

				//mid = mid_offset * _Y_Alpha_limit;
				//inside1 = smoothstep(_ClipRect.y, _ClipRect.y + mid, IN.worldPosition.y);
				//inside2 = smoothstep(_ClipRect.y + mid_offset, _ClipRect.y - mid, IN.worldPosition.y);

				//mid_offset = (_ClipRect.w - _ClipRect.y) * (1 - _Y_Alpha_Offset);
				//mid = mid_offset * _Y_Alpha_limit;
				//inside3 = smoothstep(_ClipRect.w - mid_offset, _ClipRect.w - mid, IN.worldPosition.y);
				//inside4 = smoothstep(_ClipRect.w, _ClipRect.w - mid, IN.worldPosition.y);

				//color.a *= inside1 * inside2 + inside3 * inside4;

				//mid = (_ClipRect.w - _ClipRect.y)*_Y_Alpha_limit;
				//inside1 = smoothstep(_ClipRect.y, _ClipRect.y + mid, IN.worldPosition.y);
				//inside3 = smoothstep(_ClipRect.w, _ClipRect.w - mid, IN.worldPosition.y);
				//color.a *= inside1 * inside3;
				#endif

                return color;
            }
            ENDCG
        }
    }
}
