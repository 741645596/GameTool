Shader "Omega/FX/Distortion"
{
    Properties
    {
        _MainTex ("Albedo (RGBA)", 2D) = "white" {}
		_FlowMap("Flow Map (RG)", 2D) = "black" {}
		_Flow ("Distortion", Range(0, 0.1)) = 0.001
        _Velocity ("Velocity (Direction Speed1 Speed2)", Vector) = (1,0,0,0)
        _Alpha ("Alpha", Range(0, 20)) = 1.0
        _Fadeout ("Fadeout (Top,Buttom,Left,Right)", Vector) = (1,0,1,1)
        _WaveDuration ("Wave Duration", Vector) = (1,1,1,1)
        _Wave ("Wave", Vector) = (1,1,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off ZTest On
        
        LOD 100

        Pass
        {
            CGPROGRAM

            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _FlowMap;
			float4 _FlowMap_ST;
			float _Flow;
            float _Alpha;
            float4 _Velocity;
            float4 _Fadeout;
            float4 _WaveDuration;
            // x: Fade In
            // y: Max
            // z: Fade Out
            // w: Min
            float4 _Wave;
            // x: Max Alpha
            // y: Min Alpha
            // z: Time Offset
            // w: Not Used

            fixed4 frag (v2f_img i) : SV_Target
            {
				float2 flowVec = tex2D(_FlowMap, TRANSFORM_TEX(i.uv, _FlowMap)).rg;

				float4 uv = TRANSFORM_TEX(i.uv, _MainTex).xyxy;

                float4 velocity = normalize(_Velocity.xy).xyxy * _Velocity.zzww;
				uv += frac(velocity * _Time.x);
				
				uv -= frac(flowVec.xyxy * _Time.x * _Flow);
				
                fixed4 col1 = tex2D(_MainTex, uv.xy);
                fixed4 col2 = tex2D(_MainTex, uv.zw);
                fixed4 col = lerp(col1, col2, 1 - col1.a);
                float4 fade = pow(float4(1 - i.uv.y, i.uv.y, i.uv.x, 1 - i.uv.x), _Fadeout);
                col.a *= _Alpha * fade.x * fade.y * fade.z * fade.w;
                float2 halfDuration = float2(_WaveDuration.x + _WaveDuration.y, _WaveDuration.z + _WaveDuration.w);
                float t = (_Time.y + _Wave.z) % (halfDuration.x + halfDuration.y);
                float region = step(t, halfDuration.x);
                float wave = saturate(t / _WaveDuration.x) * region;
                wave += (1 - saturate((t - halfDuration.x) / _WaveDuration.z)) * (1 - region);
                col.a *= lerp(_Wave.x, _Wave.y, wave);
                return col;
            }
            ENDCG
        }
    }
}
