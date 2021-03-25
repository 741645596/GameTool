Shader "Omega/Actors/WeaponDrop"
{

	Properties{
		_Diffuse("Diffuse", Color) = (1,1,1,1)
		_OutlineCol("OutlineCol", Color) = (1,0,0,1)
        _RimPower("Rim Power", Range(0.001,100)) = 3.0
		_MainTex("Base 2D", 2D) = "white"{}

        [Toggle]_IgnoreXray("Ignore Xray", Int) = 1
	}
 
	SubShader
		{
            Pass
            {
				Tags{ "RenderType" = "Opaque"  "Queue"="AlphaTest-10"}
                ZTest Less

                Stencil
			    {
				    WriteMask 1
				    Ref [_IgnoreXray]
				    Comp Always
				    Pass Replace
			    }

				CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag	
                //#pragma multi_compile_instancing
                #pragma instancing_options lodfade
                #include "UnityCG.cginc"

                UNITY_INSTANCING_BUFFER_START(prop)
                    UNITY_DEFINE_INSTANCED_PROP(float4, _OutlineCol)
                UNITY_INSTANCING_BUFFER_END(prop)
                fixed4 _Diffuse;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                float _RimPower;

                struct input {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float4 texcoord : TEXCOORD0;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float2 uv : TEXCOORD0;
                    half4 color : COLOR;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };
    
                v2f vert(input v)
                {
                    v2f o;
                    UNITY_INITIALIZE_OUTPUT(v2f, o);
                    UNITY_SETUP_INSTANCE_ID(v);
                    UNITY_TRANSFER_INSTANCE_ID(v, o);
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                    
                    //rim
                    fixed3 norDir = (mul(fixed4(v.normal, 0), unity_WorldToObject)).xyz;
                    fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
                    fixed rimDir = 1 - saturate(dot(norDir, viewDir));
                    rimDir =  pow(rimDir, 1 / _RimPower);
                    fixed3 rimColor = rimDir * UNITY_ACCESS_INSTANCED_PROP(prop, _OutlineCol);
                    o.color.rgb = rimColor.rgb;
                    return o;
                }
    
                fixed4 frag(v2f i) : SV_Target
                {
                    fixed4 color = tex2D(_MainTex, i.uv)*_Diffuse;
                    color += i.color;        
                    return color;
			    }
				ENDCG
			}
		}

FallBack "Legacy Shaders/Override/Diffuse"
}
