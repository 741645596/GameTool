// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Omega/FX/SafeObject" 
{
	Properties
	{
		_MainTex("Main Tex", 2D) = "white" {}
		_MainTexAlpha("Texture Alpha", Range(0, 1)) = 1

		_ObjectScale("Object scale", FLOAT) = 1		
		_RimColor("RimColor", Color) = (1,1,1,1)
		_RimPower("RimPower", Range(0.000001, 8)) = 0.1
		_RimStrength("RimStrength",Range(0, 100)) = 2

		_AtmoColor("Atmosphere Color", Color) = (0, 0.4, 1.0, 1)    //光晕颜色
		_Size("Size", Float) = 0.1 //光晕范围
		_OutLightPow("Falloff",Range(0.000001, 3)) = 0.1 //光晕平方参数
		_OutLightStrength("Transparency", Range(0, 100)) = 2 //光晕强度

		[Header(Fade Out Effect Params)][Space]
		[Toggle]_FadeOutEnable("Fade Out Enable", Float) = 0
		_MinHeight("MinLimit(Fade Begin)", Float) = 25
		_MaxHeight("MaxLimit(Fade End)", Float) = 40
		_MinDistance("MinDistance(Fade Begin)", Float) = 25
		_MaxDistance("MaxDistance(Fade End)", Float) = 100
		_FadScale("Fade Tex Scale", Float) = 1

		[Header(Player world Position(for test))][Space]
		_PlayerPos("player world position", Vector) = (0, 0, 0, 0)

		[Header(Blurring Effect Params)][Space]
		[Toggle]_Blurring("Blur Enable", Float) = 0
		_BlurRadius("Blur Radius", Float) = 1.4
		_BlurDir("Blur Dir", Vector) = (0, 1, 0, 0)

		[Header(Texture Effect Param)][Space]
		[Toggle]_TextureEffectEnable("Texture effect enable", Float) = 0
		_SrcTexture("source texture(rgba.tga)", 2D) = "white"{}
		_MaskTexture("mask texture(rgba.tga)", 2D) = "white"{}		

		[Header(TE r Pass Effect(UV move))][Space]
		[Toggle]_Te_R_EffectEnable("texture effect on r-pass enable", Float) = 0
		//[KeywordEnum(NONE, BOTH, UP_DOWN, LEFT_FIGHT)]_MoveType_R("effect move type(R)", Float) = 0
		[Toggle]_MoveType_R_UP_DOWN("effect move type(R)UP_DOWN", Float) = 0
		[Toggle]_MoveType_R_LEFT_RIGHT("effect move type(R)LEFT_RIGHT", Float) = 0
		_TE_R_Color("r-Color", Color) = (0, 0, 0, 0)
		_Color_Power_R("color power(R)", Float) = 1
		_SrcTexUVParam_R("source texture uv param(R)", Vector) = (1, 1, 0, 0)
		_MaskTexUVParam_R("mask texture uv param(R)", Vector) = (1, 1, 0, 0)
		_UpdateDownMoveSpeed_R("up-down move speed(R)", Float) = 1
		_LeftRightMoveSpeed_R("left-right move speed(R)", Float) = 1

		[Header(TE g Pass Effect(UV move))][Space]
		[Toggle]_Te_G_EffectEnable("texture effect on g-pass enable", Float) = 0
		//[KeywordEnum(NONE, BOTH, UP_DOWN, LEFT_FIGHT)]_MoveType_G("effect move type(G)", Float) = 0			
		[Toggle]_MoveType_G_UP_DOWN("effect move type(G)UP_DOWN", Float) = 0
		[Toggle]_MoveType_G_LEFT_RIGHT("effect move type(G)LEFT_RIGHT", Float) = 0
		_TE_G_Color("g-Color", Color) = (0, 0, 0, 0)
		_Color_Power_G("color power(G)", Float) = 1
		_SrcTexUVParam_G("source texture uv param(G)", Vector) = (1, 1, 0, 0)
		_MaskTexUVParam_G("mask texture uv param(G)", Vector) = (1, 1, 0, 0)
		_UpdateDownMoveSpeed_G("up-down move speed(G)", Float) = 1
		_LeftRightMoveSpeed_G("left-right move speed(G)", Float) = 1

		[Header(TE b Pass Effect(twinkle))][Space]
		[Toggle]_Te_B_EffectEnable("texture effect on b-pass enable", Float) = 0
		_TE_B_Color("b-Color", Color) = (0, 0, 0, 0)
		_Twinkle_Color_Power_B("twinkle power(B)", Float) = 1
		_SrcTexUVParam_B("source texture uv param(B)", Vector) = (1, 1, 0, 0)
		_MaskTexUVParam_B("mask texture uv param(B)", Vector) = (1, 1, 0, 0)
		_TwinkleSpeed_B("twinkle speed(B)", Float) = 1

		[Header(TE a Pass Effect(twinkle))][Space]
		[Toggle]_Te_A_EffectEnable("texture effect on b-pass enable", Float) = 0
		_TE_A_Color("a-Color", Color) = (0, 0, 0, 0)
		_Twinkle_Color_Power_A("twinkle power(A)", Float) = 1
		_SrcTexUVParam_A("source texture uv param(A)", Vector) = (1, 1, 0, 0)
		_MaskTexUVParam_A("mask texture uv param(A)", Vector) = (1, 1, 0, 0)
		_TwinkleSpeed_A("twinkle speed(A)", Float) = 1
	}
	
	SubShader
	{
		//////////////////////////////////////////////////////////////////////////////
		Pass
		{
			Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
			ZWrite Off
			Cull Off
			Blend SrcAlpha OneMinusSrcAlpha
			Fog{ Color(0,0,0,0) }

			CGPROGRAM
			//引入头文件
			#include "Lighting.cginc"

			//定义Properties中的变量
			sampler2D _MainTex;
			//使用了TRANSFROM_TEX宏就需要定义XXX_ST
			float4 _MainTex_ST;
			fixed4 _RimColor;
			float _RimPower;
			float _RimStrength;
			uniform float _ObjectScale;

			//<- TEXTURE EFFECT
			sampler2D _SrcTexture;
			//float4 _SrcTexture_ST;
			sampler2D _MaskTexture;
			//float4 _MaskTexture_ST;

			fixed4 _TE_R_Color;
			float _Color_Power_R;
			float4 _SrcTexUVParam_R;
			float4 _MaskTexUVParam_R;
			float _UpdateDownMoveSpeed_R;
			float _LeftRightMoveSpeed_R;

			fixed4 _TE_G_Color;
			float _Color_Power_G;
			float4 _SrcTexUVParam_G;
			float4 _MaskTexUVParam_G;
			float _UpdateDownMoveSpeed_G;
			float _LeftRightMoveSpeed_G;

			fixed4 _TE_B_Color;
			float _Twinkle_Color_Power_B;
			float4 _SrcTexUVParam_B;
			float4 _MaskTexUVParam_B;
			float _TwinkleSpeed_B;

			fixed4 _TE_A_Color;
			float _Twinkle_Color_Power_A;
			float4 _SrcTexUVParam_A;
			float4 _MaskTexUVParam_A;
			float _TwinkleSpeed_A;

			float _Blurring;
			float _TextureEffectEnable;
			float _FadeOutEnable;
			float _Te_R_EffectEnable;
			float _MoveType_R_UP_DOWN;
			float _MoveType_R_LEFT_RIGHT;
			float _Te_G_EffectEnable;
			float _MoveType_G_UP_DOWN;
			float _MoveType_G_LEFT_RIGHT;
			float _Te_B_EffectEnable;
			float _Te_A_EffectEnable;

			uniform float _MinHeight;
			uniform float _MaxHeight;
			uniform float _MinDistance;
			uniform float _MaxDistance;
			uniform float _FadScale;
			uniform float4 _PlayerPos;
			uniform float _MainTexAlpha;

			//定义结构体：vertex shader阶段输出的内容
			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float2 uv : TEXCOORD1;
				//在vertex shader中计算观察方向传递给fragment shader
				float3 worldViewDir : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				float2 baseUV : TEXCOORD4;
			};

			float2 tranformTargetUV(float2 srcUV, float4 param) 
			{
				return (srcUV.xy * param.xy + param.zw) * (_ObjectScale);
			}

			//定义顶点shader,参数直接使用appdata_base（包含position, noramal, texcoord）
			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldViewDir = normalize(_WorldSpaceCameraPos.xyz - o.worldPos);
				o.baseUV = v.texcoord;
				return o;
			}

			//定义片元shader
			fixed4 frag(v2f i) : SV_Target
			{
				float2 uvOffset = i.uv * (_ObjectScale - 1);//lerp(float2(0, 0), i.uv * (_ObjectScale - 1), _ObjectScale);
				fixed4 color = tex2D(_MainTex, i.uv + uvOffset);

				//计算视线方向与法线方向的夹角，夹角越大，dot值越接近0，说明视线方向越偏离该点，也就是平视，该点越接近边缘
				float rim = max(0, 1 - abs(dot(i.worldNormal, normalize(i.worldViewDir))) * _RimStrength);
				//计算rimLight
				fixed4 rimColor = _RimColor * pow(rim, 1 / _RimPower);
				//输出颜色+边缘光颜色
				color.rgb += rimColor.rgb;

				//if (_TextureEffectEnable > 0)
				{
					float2 srcUV;
					fixed4 srcColor;
					float2 maskUV;
					fixed4 maskColor;
					float sinAin;

					//if (_Te_G_EffectEnable > 0)
					{
						float2 moveOffsetUV = 0;
						//if (_MoveType_G_UP_DOWN > 0) 
						{
							moveOffsetUV.y = frac(_UpdateDownMoveSpeed_G * _Time.w);
						}
						/*if (_MoveType_G_LEFT_RIGHT > 0) 
						{
							moveOffsetUV.x = frac(_LeftRightMoveSpeed_G * _Time.w);
						}*/
						srcUV = tranformTargetUV(i.baseUV, _SrcTexUVParam_G);
						fixed src = tex2D(_SrcTexture, srcUV + moveOffsetUV).g;
						maskUV = tranformTargetUV(i.baseUV, _MaskTexUVParam_G);
						fixed mask = tex2D(_MaskTexture, maskUV).g;

						color.rgba += _TE_G_Color.rgba * src * mask * _Color_Power_G;
					}

					//if (_Te_A_EffectEnable > 0)
					{
						srcUV = tranformTargetUV(i.baseUV, _SrcTexUVParam_A);
						srcColor = tex2D(_SrcTexture, srcUV);
						maskUV = tranformTargetUV(i.baseUV, _MaskTexUVParam_A);

						sinAin = abs(sin(_Time.w * _TwinkleSpeed_A));

						color.rgba += _TE_A_Color.rgba * srcColor.a * _Twinkle_Color_Power_A * sinAin;
					}
				}

				color.a *= 1 - smoothstep(_MinDistance, _MaxDistance, distance(i.worldPos.xz, _PlayerPos.xz));
				color.a *= _MainTexAlpha;

				//if (_FadeOutEnable > 0) 
				{
					color.a *= 1 - smoothstep(_MinHeight + _FadScale, _MaxHeight + _PlayerPos.y + _FadScale, i.worldPos.y);
				}

				return color;
			}

			#pragma vertex vert
			#pragma fragment frag	

			ENDCG
		}
		
		//////////////////////////////////////////////////////////////////////////////		
	}
}