Shader "Hidden/ConvertSplatmap"
{
    Properties
    {
        _SplatAlpha0("Splat Alpha0", 2D) = "black" {}
        _SplatAlpha1("Splat Alpha1", 2D) = "black" {}
        _SplatAlpha2("Splat Alpha2", 2D) = "black" {}
        _SplatAlpha3("Splat Alpha3", 2D) = "black" {}
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            v2f_img vert (appdata_img v)
            {
                v2f_img o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            sampler2D _SplatAlpha0;
            sampler2D _SplatAlpha1;
            sampler2D _SplatAlpha2;
            sampler2D _SplatAlpha3;
            float4x4 _SplatIdx;

            fixed4 frag (v2f_img i) : SV_Target
            {
                float fg = 0;
                float bg = 0;
                int fgidx = 0;
                int bgidx = 0;
                float4x4 splat;
                splat[0] = tex2D(_SplatAlpha0, i.uv);
                splat[1] = tex2D(_SplatAlpha1, i.uv);
                splat[2] = tex2D(_SplatAlpha2, i.uv);
                splat[3] = tex2D(_SplatAlpha3, i.uv);
                for(int y = 0; y < 4; ++y)
                {
                    for(int x = 0; x < 4; ++x)
                    {
                        float val = splat[x][y];
                        int idx = _SplatIdx[x][y];
                        if(val > fg)
                        {
                            if(val > bg)
                            {
                                bg = fg;
                                bgidx = fgidx;
                            }
                            fg = val;
                            fgidx = idx;
                        }
                    }
                }
                float mix = saturate(fg / (fg + bg));
                if(bgidx > fgidx)
                {
                    mix = 1 - mix;
                    int tmpidx = fgidx;
                    fgidx = bgidx;
                    bgidx = tmpidx;
                }
                return fixed4((float2(bgidx, fgidx) + 0.5) / 16, mix, 1);
            }
            ENDCG
        }
    }
}
