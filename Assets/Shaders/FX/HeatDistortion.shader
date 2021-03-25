Shader "Omega/FX/HeatDistortion"
{
	Properties
	{
		_FlowMap("Flow Map (RG)", 2D) = "black" {}
		_Intensity ("Intensity", Range(0, 1)) = 1
        _Velocity ("Velocity (Direction Speed1 Speed2)", Vector) = (1,0,0,0)
		_Fade ("Fade", Float) = 3
	}
    SubShader
    {
        Tags { "Queue" = "Transparent" }

        GrabPass {}

        Pass
        {
		ZTest Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _GrabTexture;
			sampler2D _FlowMap;
			float4 _FlowMap_ST;
			float _Intensity;
			float _Fade;
            float4 _Velocity;

            struct v2f
            {
                float4 pos : SV_POSITION;
				float NoV : NORMAL;
				float2 uv : TEXCOORD0;
                float4 grabPos : TEXCOORD1;
            };

            v2f vert(appdata_base v) 
			{
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
				o.NoV = saturate(dot(v.normal, ObjSpaceViewDir(v.vertex)));
				o.uv = TRANSFORM_TEX(v.texcoord, _FlowMap);
                o.grabPos = ComputeGrabScreenPos(o.pos);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
				float2 velocity = _Velocity.xy;
				i.uv += frac(velocity * _Time.x);
				float2 flowVec = tex2D(_FlowMap, i.uv).rg;// * 2 - 1;
				float2 grabUV = i.grabPos.xy / i.grabPos.w;
				flowVec *= _Intensity * pow(i.NoV, _Fade);
				i.grabPos.xy += flowVec;

                fixed4 col = tex2Dproj(_GrabTexture, i.grabPos);
                return col;
            }
            ENDCG
        }

    }
}