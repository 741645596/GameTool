Shader "Omega/Actors/PlayerLow"
{
	Properties
	{
		_OwnerLightAmbient("环境光颜色", Color) = (0.1,0.1, 0.2, 1)

		[Header((Light))]
		_MainLightIntensity("照明光", Range(0,2)) = 1
		_Highlight("高光强度", Range(0,2)) = 1
		_AmbientLight("环境光", Range(0,2)) = 1

		[Space(20)]
		_ColorE("Color+E", 2D) = "white" {}

		[Header((Shadow))]
		_ShadowIntensity("阴影强度", Range(0, 1)) = 0.5
		_SelfShadowSize("阴影范围", Range(0, 1)) = 0.1
		_SelfShadowHardness("阴影硬度", Range(0, 1)) = 0.55

		//[Toggle]_IgnoreXray("Ignore Xray", Int) = 1

	}

		SubShader
	{
		Tags {"RenderType" = "Opaque" "RenderType" = "Opaque" "Shadow" = "Character" "Queue"="AlphaTest-30"}

		Pass
		{

			Tags {"LightMode" = "ForwardBase" }
			ColorMask RGBA
			ZTest LEqual
			ZWrite On
			Stencil
			{
				WriteMask 9
				Ref 9
				Comp Always
				Pass Replace
			}
		 
			CGPROGRAM
			#pragma target 3.0
			#pragma only_renderers d3d11 glcore gles gles3 metal d3d9
			//#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
			#pragma multi_compile _ _CASCADE_SHADOW
			#pragma multi_compile _ _RECEIVESHADOW
			#pragma multi_compile_fog

			#pragma vertex CHVertLow 
			#pragma fragment CHFragLow

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "CHCore.cginc"
			ENDCG
		}

	}
//FallBack "Legacy Shaders/Override/Diffuse"
}