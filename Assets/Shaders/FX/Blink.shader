Shader "Omega/FX/Blink"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Frame ("Frame", Vector) = (0, 4, 0.2, 3)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Frame;
            //x: Current Frame Idx
            //y: Frame Count
            //z: Blink Duration
            //w: Blink Interval

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.y = v.uv.y;
                o.uv.x = (v.uv.x + floor(_Frame.x)) / _Frame.y;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float halfInterval = _Frame.w * 0.5;
                float halfDuration = _Frame.z * 0.5;
                float t = halfInterval - abs(_Time.y % _Frame.w - halfInterval);
                float scale = saturate(t / halfDuration);
                scale = max(scale, 0.001);
                i.uv.y = (i.uv.y - 0.5) / scale +0.5;
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
