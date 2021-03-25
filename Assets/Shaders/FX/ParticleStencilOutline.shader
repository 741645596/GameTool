Shader "Omega/FX/ParticleStencilOutline" {
Properties 
{	
	//_TintColor("TintColor",color) = (0.5,0.5,0.5,0.5)
	_EdgeColor("EdgeColor",color) = (0.5,0.5,0.5,0.5)
	_EdgeThickness("EdgeThickness",Range(1,1.1)) = 1.02
	[Enum(UnityEngine.Rendering.BlendMode)]  _SrcBlend("SrcFactor",Float) = 1
	[Enum(UnityEngine.Rendering.BlendMode)]  _DstBlend("DstFactor",Float) = 1
}

//CompareFunction { Disabled = 0, Never = 1, Less = 2, Equal = 3, LessEqual = 4, Greater = 5, NotEqual = 6, GreaterEqual = 7, Always = 8 }
//StencilOp{Keep = 0,Zero = 1,Replace = 2,IncrementSaturate = 3,DecrementSaturate = 4,Invert = 5,IncrementWrap = 6,DecrementWrap = 7}


Category{
	Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "PreviewType" = "Plane" }
	Lighting Off

	SubShader
	{
		/*
		Pass
		{
			Name "Mask"
			Blend One One
			Cull Back ZTest Greater
			ZWrite off

			Stencil {
				Ref 3
				Comp GEqual
				Pass Replace
				ZFail Zero
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#include "UnityCG.cginc"

			half _EdgeThickness;

			struct appdata_t {
				float4 vertex : POSITION;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				return 0;
			}
				ENDCG
		}

		Pass
		{
			Name "Color"
			Blend[_SrcBlend][_DstBlend]
			Cull Front  ZTest Greater
			ZWrite off

			Stencil {
				Ref 3
				Comp Greater
				Pass Zero
				ZFail Zero
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#include "UnityCG.cginc"


			struct appdata_t {
				float4 vertex : POSITION;
				half4 color : COLOR;
				half3 normal : NORMAL;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				half4 color : COLOR0;
			};

			half4 _TintColor;

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				half3 posWorld = mul(unity_ObjectToWorld, v.vertex);
				half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - posWorld.xyz);
				half3 normalDir = UnityObjectToWorldNormal(-v.normal);
				half rim = 1-dot(normalDir, viewDir);
				o.color = v.color * _TintColor * rim;
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				return i.color;
			}
				ENDCG
		}
		*/
			Pass
		{
			Name "EdgeMask"
			Blend[_SrcBlend][_DstBlend]
			Cull front ZTest Less
			ZWrite off

			Stencil {
				Ref 4
				ReadMask 4
				WriteMask 4
				Comp NotEqual
				Pass Replace
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#include "UnityCG.cginc"

			half _EdgeThickness;

			struct appdata_t {
				float4 vertex : POSITION;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex*_EdgeThickness);
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				return 0;
			}
				ENDCG
		}

			
		Pass
		{
			Name "Edge"
			Blend[_SrcBlend][_DstBlend]
			Cull front ZTest Less
			ZWrite off

			Stencil {
				Ref 4
				ReadMask 4
				WriteMask 4
				Comp NotEqual
				Pass Keep
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#include "UnityCG.cginc"

			half4 _EdgeColor;

			struct appdata_t {
				float4 vertex : POSITION;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				return _EdgeColor;
			}
				ENDCG
		}	
    }
}
//CustomEditor "ParticleBaseGUI"
}
