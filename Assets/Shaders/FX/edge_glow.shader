// Shader created with Shader Forge v1.38 
// Shader Forge (c) Neat Corporation / Joachim Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge
/*SF_DATA;ver:1.38;sub:START;pass:START;ps:flbk:Particles/Alpha Blended,iptp:0,cusa:False,bamd:0,cgin:,lico:0,lgpr:1,limd:0,spmd:1,trmd:0,grmd:0,uamb:True,mssp:True,bkdf:False,hqlp:False,rprd:False,enco:False,rmgx:True,imps:True,rpth:0,vtps:0,hqsc:True,nrmq:1,nrsp:0,vomd:0,spxs:False,tesm:0,olmd:1,culm:2,bsrc:0,bdst:0,dpts:2,wrdp:False,dith:0,atcv:False,rfrpo:True,rfrpn:Refraction,coma:15,ufog:False,aust:True,igpj:True,qofs:0,qpre:3,rntp:2,fgom:False,fgoc:False,fgod:False,fgor:False,fgmd:0,fgcr:0.5,fgcg:0.5,fgcb:0.5,fgca:1,fgde:0.01,fgrn:0,fgrf:300,stcl:False,atwp:False,stva:128,stmr:255,stmw:255,stcp:6,stps:0,stfa:0,stfz:0,ofsf:0,ofsu:0,f2p0:True,fnsp:True,fnfb:False,fsmp:False;n:type:ShaderForge.SFN_Final,id:3138,x:33258,y:32666,varname:node_3138,prsc:2|emission-7876-OUT;n:type:ShaderForge.SFN_Color,id:7241,x:32598,y:32467,ptovrint:False,ptlb:Color,ptin:_Color,varname:node_7241,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0.07843138,c2:0.3921569,c3:0.7843137,c4:1;n:type:ShaderForge.SFN_Fresnel,id:4604,x:32329,y:32839,varname:node_4604,prsc:2|EXP-9512-OUT;n:type:ShaderForge.SFN_Slider,id:6526,x:32172,y:33044,ptovrint:False,ptlb:power,ptin:_power,varname:node_6526,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:0.5125054,max:1;n:type:ShaderForge.SFN_Multiply,id:7876,x:32912,y:32657,varname:node_7876,prsc:2|A-7241-RGB,B-5482-OUT;n:type:ShaderForge.SFN_Power,id:428,x:32549,y:32839,varname:node_428,prsc:2|VAL-4604-OUT,EXP-6526-OUT;n:type:ShaderForge.SFN_ValueProperty,id:8265,x:32537,y:33124,ptovrint:False,ptlb:liangdu,ptin:_liangdu,varname:node_8265,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,v1:1;n:type:ShaderForge.SFN_Multiply,id:5482,x:32714,y:32954,varname:node_5482,prsc:2|A-428-OUT,B-8265-OUT;n:type:ShaderForge.SFN_Slider,id:9512,x:31974,y:32855,ptovrint:False,ptlb:fanwei,ptin:_fanwei,varname:node_9512,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:1.934588,max:10;proporder:7241-6526-8265-9512;pass:END;sub:END;*/

Shader "Omega/FX/edge_glow" {
    Properties {
        _Color ("Color", Color) = (0.07843138,0.3921569,0.7843137,1)
        _power ("power", Range(0, 1)) = 0.5125054
        _liangdu ("liangdu", Float ) = 1
        _fanwei ("fanwei", Range(0, 10)) = 1.934588
		[HideInInspector]_MainTex ("MainTex", 2D) = "black" {}
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Float) = 2
		[Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)]_DestFactor("Dest Blend", Float) = 1
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        LOD 200
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
			Blend [_SrcFactor] [_DestFactor]
			Cull [_CullMode]
            //Cull Off
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //#define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            //#pragma multi_compile_fwdbase
            #pragma only_renderers d3d9 d3d11 glcore gles gles3 metal 
            #pragma target 2.0
            uniform float4 _Color;
            uniform float _power;
            uniform float _liangdu;
            uniform float _fanwei;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                half4 color : COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float4 posWorld : TEXCOORD0;
                float3 normalDir : TEXCOORD1;
                half4 color : COLOR;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos( v.vertex );
                o.color = v.color;
                return o;
            }
            float4 frag(VertexOutput i) : SV_Target {

                //float faceSign = ( facing >= 0 ? 1 : -1 );
                i.normalDir = normalize(i.normalDir);
                //i.normalDir *= faceSign;
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = i.normalDir;
////// Lighting:
////// Emissive:
                float emissive = pow(pow(1.0-abs(dot(normalDirection, viewDirection)),_fanwei),_power)*_liangdu;
                float3 finalColor = emissive * _Color.rgb *i.color.rgb;
                return fixed4(finalColor,i.color.a * _Color.a * emissive);
            }
            ENDCG
        }
    }
    //FallBack "Particles/Alpha Blended"
    //CustomEditor "ShaderForgeMaterialInspector"
}
