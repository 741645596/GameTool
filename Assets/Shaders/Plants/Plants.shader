Shader "Omega/Plants/Plants"
{
	Properties {
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		[HideInInspector] _Mode("__mode", Float) = 2

		
		[Header(Wind)]
		_RateX("NoiseRateX",Range(0.01,16)) = 0.8
		_RateY("NoiseRateY",Range(0.01,16)) = 4.3
		_Speed("NoiseSpeed",Range(0,8)) = 2.27
		_Strength("Strength",Range(0,2)) = 0.25
		[Toggle(_USEWIND)]_USEWIND("Use Wind", FLOAT) = 0.0
		

		[Header(Lightmap)]
		_Lightmap("Lightmap", 2D) = "white" {}
		_WorldSize("World Size", Vector) = (9, 9, 0, 0)
		_LightmapBrightness("Lightmap Brightness", Range(0 , 3)) = 1
		_LightmapContrast("Lightmap Contrast", Range(0 , 3)) = 1
		_DesaturateLightmap("Desaturate Lightmap", Range(-2 , 2)) = 0


		//[Header(Shadow)]
		//_ShadowColor("ShadowColor (RGB)", Color) = (0.5,0.5,0.5,1)
		//_ShadowDistance("ShadowDistance",float) = 20
		//_ShadowFade("ShadowFade",Range(0.1,1)) = 0.1

		[Header(Culling)]
		_DistCull("CullingDistance",float) = 85

    }
    SubShader {
		Tags {"Queue" = "AlphaTest+50"  "RenderType" = "TransparentCutout"}
		Cull Off

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Lighting On
			CGPROGRAM
			#pragma target 3.0

			//#pragma multi_compile _LIGHTMAP
			#pragma multi_compile _ _USEWIND
			//#pragma multi_compile _USECULL
			#pragma multi_compile _ _RECEIVESHADOW
			#pragma multi_compile _ _CASCADE_SHADOW

			//#pragma multi_compile_fwdadd_fullshadows
			//#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			#pragma vertex CustomvertBase
			#pragma fragment CustomfragBase

			#include "../cginc/PlantsCore.cginc"

			ENDCG
		}
    }
//FallBack "Legacy Shaders/Transparent/Cutout/VertexLit"
}