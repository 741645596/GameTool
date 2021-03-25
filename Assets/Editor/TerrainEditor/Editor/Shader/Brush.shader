Shader "Hidden/Brush"
{
	Properties
	{
		_TintColor("MainColor", color) = (0.5,0.5,0.5,1)
		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		[PowerSlider(5.0)] _Shininess("Shininess", Range(0.03, 1)) = 0.078125

		[Header(Lightmap)]
		_Lightmap("Lightmap", 2D) = "white" {}
		_LightmapClamp("Lightmap Clamp", Range(0.5 , 3)) = 1.2
		_LightmapBrightness("Lightmap Brightness", Range(0 , 3)) = 1
		_LightmapContrast("Lightmap Contrast", Range(0 , 3)) = 1
		_DesaturateLightmap("Desaturate Lightmap", Range(-2 , 2)) = 0

		[Header(Shadow)]
		_ShadowColor("ShadowColor (RGB)", Color) = (0.5,0.5,0.5,1)
		//_ShadowDistance("ShadowDistance",float) = 20
		//_ShadowFade("ShadowFade",Range(0.1,1)) = 0.1

		[Header(Texture)]
		[Toggle] _USEVERTEXCOLOR("UseVertexColor",float) = 0
		_Splat("SplatMap", 2D) = "white" {}

		
		_MainTexArray("Diffuse", 2DArray) = "white" {}
		_MainTexArray("Normalmap", 2DArray) = "bump" {}

		[Space]
		_Tile1("Tile_1", Vector) = (30,30,30,30)
		_Tile2("Tile_2", Vector) = (30,30,30,30)
		_Tile3("Tile_2", Vector) = (30,30,30,30)
		_Tile4("Tile_2", Vector) = (30,30,30,30)

		//[KeywordEnum(NOSHADOW, HARD_SHADOW, SOFT_SHADOW)]shadow("shadow options", float) = 0

        _Brush ("Brush", 2D) = "black" {}
        _Cursor("Cursor", Vector) = (1,1,1,1)
		_BrushScale ("Scale", Range(0, 10)) = 0.0
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+600"}
		Cull Back

        UsePass "Omega/Env/Terrain_NormalSpec_Array/FORWARD"

		Pass
		{
            Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
            #include "UnityCG.cginc"
			#pragma vertex vert_img
            #pragma fragment frag

            sampler2D _Brush;
            float2 _Cursor;
			float _Density;
			float _BrushScale;

			float4 _Tile1, _Tile2, _Tile3, _Tile4;

			/*static float _Scale[16] = {
				_4_1, _4_2, _4_3, _4_4,
				_3_1, _3_2, _3_3, _3_4,
				_2_1, _2_2, _2_3, _2_4,
				_1_1, _1_2, _1_3, _1_4
			};*/

			static float4x4 _Scale = float4x4(_Tile4, _Tile3, _Tile2, _Tile1);

            fixed4 frag(v2f_img i)  : SV_Target
            {
                float dist = length(_Cursor - i.uv);
                dist = clamp(dist, 0, _BrushScale * 0.5) / _BrushScale * 2;
				float2 uv_brush = float2(1 - dist, 0);
				fixed brush = tex2D(_Brush, uv_brush).r * _Density;
                fixed mask = step(dist, 0.9999);
				brush *= mask;
                return fixed4(1,1,1,brush * 0.5);
            }

			ENDCG 
		}
	}
FallBack "Legacy Shaders/Override/VertexLit"
}
