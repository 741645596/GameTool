Shader "Omega/FX/ParticleStencilOutlineTwoSided" 
{
	Properties 
	{	
		//_TintColor("TintColor",color) = (0.5,0.5,0.5,0.5)
		_EdgeColor("EdgeColor",color) = (0.5,0.5,0.5,0.5)
		_EdgeThickness("EdgeThickness",Range(1,1.1)) = 1.02
		[Enum(UnityEngine.Rendering.BlendMode)]  _SrcBlend("SrcFactor",Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]  _DstBlend("DstFactor",Float) = 1
	}

	SubShader
	{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "PreviewType" = "Plane" }
		Lighting Off
		CGINCLUDE
		#include "UnityCG.cginc"

		half _EdgeThickness;
		fixed4 _EdgeColor;

		float4 vert_mask(float4 vertex : POSITION) : SV_POSITION
		{
			return UnityObjectToClipPos(vertex*_EdgeThickness);
		}

		float4 vert(float4 vertex : POSITION) : SV_POSITION
		{
			return UnityObjectToClipPos(vertex);
		}

		fixed4 frag_mask() : SV_Target
		{
			return 0;
		}

		fixed4 frag() : SV_Target
		{
			return _EdgeColor;
		}
		ENDCG
		Pass
		{
			Name "EdgeMask"
			Blend[_SrcBlend][_DstBlend]
			Cull front ZTest Less
			ZWrite off
			ColorMask 0
			Stencil 
			{
				Ref 4
				ReadMask 4
				WriteMask 4
				Comp Always
				Pass Keep
				ZFail Replace
			}

			CGPROGRAM
			#pragma vertex vert_mask
			#pragma fragment frag_mask
			#pragma target 2.0
			ENDCG
		}
		Pass
		{
			Name "Edge"
			Blend[_SrcBlend][_DstBlend]
			Cull front ZTest Less
			ZWrite off

			Stencil 
			{
				Ref 4
				ReadMask 4
				WriteMask 4
				Comp Equal
				Pass Zero
				Fail Zero
				ZFail Zero
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#include "UnityCG.cginc"
			ENDCG
		}
		Pass
		{
			Name "EdgeMask"
			Blend[_SrcBlend][_DstBlend]
			Cull back ZTest Less
			ZWrite off
			ColorMask 0
			Stencil 
			{
				Ref 4
				ReadMask 4
				WriteMask 4
				Comp Always
				Pass Keep
				ZFail Replace
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_mask
			#pragma target 2.0
			ENDCG
		}
		Pass
		{
			Name "Edge"
			Blend[_SrcBlend][_DstBlend]
			Cull back ZTest Less
			ZWrite off

			Stencil 
			{
				Ref 4
				ReadMask 4
				WriteMask 4
				Comp Equal
				Pass Zero
				Fail Zero
				ZFail Zero
			}

			CGPROGRAM
			#pragma vertex vert_mask
			#pragma fragment frag
			#pragma target 2.0
			#include "UnityCG.cginc"
			ENDCG
		}	
	}
}
