Shader "Omega/Env/skydome"
{
    Properties
    {
		_MainTex("Texture", 2D) = "white" {}
		_TintColor("Color", Color) = (1,1,1,1)
        uG("G", float) = -0.991
    }
    SubShader
    {
		Tags { "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" }
        LOD 100

        Pass
        {
			Tags { "RenderType" = "Background" }
			Cull off
			zwrite off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

        #include "atmosphere.cginc"		
            ENDCG
        }
		
    }
}
