Shader "Omega/FX/NightVisionScope"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _PlayerColor ("Player Color", Color) = (1, 0.44, 0, 0.5)
        _ScopeColor ("Scope Color", Color) = (0, 1, 0.64, 0.77)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            /*Stencil
            {
                Ref 8
                ReadMask 8
                WriteMask 8
                Comp NotEqual
            }*/
            Blend SrcAlpha OneMinusSrcAlpha, Zero One
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;

            fixed4 _ScopeColor;

            v2f_img vert (appdata_img v)
            {
                v2f_img o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag (v2f_img i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                clip(col.a - 0.001);
                col.a *= 1.2;
                col.rgb = lerp(_ScopeColor.rgb, col.rgb, col.a);
                col.a = max(col.a, _ScopeColor.a);
                return col;
            }
            ENDCG
        }

        Pass
        {
            Stencil
            {
                Ref 8
                ReadMask 8
                WriteMask 8
                Comp Equal
            }
            Blend DstAlpha OneMinusDstAlpha
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;

            fixed4 _PlayerColor;

            v2f_img vert (appdata_img v)
            {
                v2f_img o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag (v2f_img i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                clip(col.a - 0.001);
                col.a *= 1.2;
                col.rgb = lerp(_PlayerColor.rgb, col.rgb, col.a);
                return col;
            }
            ENDCG
        }
    }
}
