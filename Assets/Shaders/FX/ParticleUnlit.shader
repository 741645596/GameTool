Shader "Omega/FX/ParticleUnlit" {
Properties {
    _TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)

	[Header(AlphaBlendMode)]
	[Enum(Zero,0,One,1,DstColor,2,SrcAlpha,5)]  _SrcBlend("SrcFactor",Float) = 5
	[Enum(Zero,0,One,1,OneMinusSrcAlpha,10)]  _DstBlend("DstFactor",Float) = 1
	[Header(RenderState)]
	[Enum(RGB,14,RGBA,15)] _ColorMask("Color Mask", Float) = 14
	[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode",Float) = 0
	[Enum(Off,0,On,1)] _Zwrite("Zwrite", Float) = 0
	[Enum(Off,0,On,2)] _Ztest("Ztest", Float) = 2
}

Category {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane"}
    Blend [_SrcBlend] [_DstBlend]
    ColorMask [_ColorMask]
    Cull [_Cull] Lighting Off ZWrite [_Zwrite] ZTest[_Ztest]

    SubShader 
	{
        Pass 
		{
            CGPROGRAM
            #pragma target 2.0
			#pragma multi_compile_fog

			#pragma vertex CustomvertBase
			#pragma fragment CustomfragBase

            #include "UnityCG.cginc"

			//color			
			half4 _TintColor;


			//in
			struct CustomVertexInput
			{
				half4 vertex : POSITION;
				half4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			//out
			struct CustomVertexOutput
			{
				half4 vertex : SV_POSITION;
				half4 color : COLOR;		
				UNITY_FOG_COORDS(1)
			};

			//vs
			CustomVertexOutput CustomvertBase(CustomVertexInput v)
			{
				CustomVertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}

			//ps
			half4 CustomfragBase(CustomVertexOutput i) : COLOR
			{
				half4 col = 2.0f * i.color * _TintColor;
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
          
            ENDCG
        }
    }
}
}
