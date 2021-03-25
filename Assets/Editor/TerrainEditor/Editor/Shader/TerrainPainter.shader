Shader "CustomRenderTexture/TerrainPainter"
{
    Properties
    {
        _Brush ("Brush", 2D) = "black" {}
		_Idx ("Idx", RANGE(0, 1)) = 0.0
		_IdxBG("Idx BG", Range(0, 1)) = 0.0
		_IdxFG("Idx FG", Range(0, 1)) = 0.0
		_Prev_Cursor("Prev Cursor", Vector) = (1,1,1,1)
		_Current_Cursor("Current Cursor", Vector) = (1,1,1,1)
		_Scale ("Scale", Range(0, 10)) = 0.0
		_Density ("Density", Range(0, 1)) = 1.0
		_Mode ("Use Hard Brush", Range(0, 1)) = 0.0
    }
    SubShader
    {
		Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
			#include "UnityCG.cginc"
			#include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
			#pragma target 3.0

			#define EQUAL(x,y) (step(1e-2,abs((x)-(y))))
			#define AND(x,y) ((x)*(y))
			#define OR(x,y) max((x),(y))

			sampler2D _Brush;
			float _Idx;
			float _IdxBG;
			float _IdxFG;
			float2 _Prev_Cursor;
			float2 _Current_Cursor;
			float _Scale;
			float _Density;
			float _Mode;

			fixed4 blend(fixed4 src, fixed brush, float idx, fixed mask) // Auto swap BG & FG
			{
				fixed4 col = 1;
				float diff = EQUAL(src.g, idx);
				col.rg = lerp(src.rg, float2(src.g, idx), mask * diff);
				col.b = lerp(max(src.b, brush), lerp(src.b, brush, mask), diff);
				return col;
			}

			fixed4 blend(fixed4 src, fixed4 brush, float idxBG, float idxFG, fixed mask)
			{
				fixed4 col = float4(idxBG, idxFG, 1, 1);
				float reorder = step(col.g, col.r + 1e-6); // col.g < col.r

				float2 srcRG_colG = EQUAL(src.rg,col.gg); // float2(src.r == col.g, src.g == col.g)
				float srcB = lerp(src.b, 1 - src.b, srcRG_colG.g);
				srcB *= OR(srcRG_colG.r, srcRG_colG.g);
				/*
					if(src.r == idxFG || src.g == idxFG)
					{
						srcB = (src.g == idxFG) ? src.b : (1 - src.b);
					}
					else srcB = 0;
				*/
				brush = max(brush, srcB);
				brush = max(brush, 1 - OR(srcRG_colG.r, srcRG_colG.g));

				col.rg = lerp(col.rg, col.gr, reorder);
				col.b = lerp(brush, 1 - brush, reorder);
				return lerp(src, col, mask);
			}

			float distLine(float2 a, float2 b, float2 p)
			{
				float2 ab = b - a;
				float t = dot(p - a, ab) / dot(ab, ab);
				t = clamp(t, 0, 1);
				float2 c = a + t * ab;
				return length(p - c);
			}

			fixed4 frag(v2f_customrendertexture i) : SV_Target
			{
				float2 uv = i.localTexcoord.xy;
                fixed4 src = tex2D(_SelfTexture2D, uv);

				float dist = distLine(_Prev_Cursor, _Current_Cursor, uv); //Draw line instead of point
				dist = clamp(dist, 0, _Scale * 0.5) / _Scale * 2;
				float2 uv_brush = float2(1 - dist, 0);
				fixed brush = tex2D(_Brush, uv_brush).r * _Density;
				brush = lerp(brush, _Density, _Mode);
				fixed mask = step(dist, 0.9999);
				brush *= mask;
				//fixed4 autoSwap = blend(src, brush, _Idx, mask);
				fixed4 manualSwap = blend(src, brush, _IdxBG, _IdxFG, mask);
				//fixed4 col = lerp(autoSwap, manualSwap, _Mode);
				return manualSwap;
            }
            ENDCG
        }
    }
}
