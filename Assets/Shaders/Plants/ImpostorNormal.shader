Shader "Omega/Env/ImpostorNormal"
{
	Properties
	{
		[NoScaleOffset] _Albedo("Albedo & Alpha", 2D) = "white" {}
		[NoScaleOffset]_Normals("Normals & Depth", 2D) = "white" {}
		_SpecularColor("Specular Color", Color) = (.5,.5,.5,1)
		_Shininess("Shininess", Range(0.01, 1)) = 0.5
		_AI_Frames("Frames", Float) = 16
		_AI_ImpostorSize("Impostor Size", Float) = 1
		_AI_Offset("Offset", Vector) = (0,0,0,0)
		[HideInInspector]_DepthSize("DepthSize", Float) = 1
		[Toggle(_HEMI_ON)] _Hemi("Hemi", Float) = 0
		_ClipMask("Clip", Range(0.01 , 1)) = 0.5
	}

	SubShader
	{
		CGINCLUDE
		#pragma target 3.0
		ENDCG

		Tags { "RenderType" = "Opaque" "Queue" = "Geometry-100" "DisableBatching" = "True" }
		Cull Back

		Pass
		{
			ZWrite On
			Name "ForwardBase"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma multi_compile _ _HEMI_ON
			#pragma multi_compile _ _WORLD_GRID_CULL
			// compile directives
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma multi_compile_fog
			//#pragma multi_compile_fwdbase
			#pragma multi_compile_instancing
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"
			#ifndef UNITY_PASS_FORWARDBASE
				#define UNITY_PASS_FORWARDBASE
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityStandardUtils.cginc"
			#include "../Fog/FogCore.cginc"

			float _AI_Frames;
			float _AI_ImpostorSize;

			uniform sampler2D _Albedo;
			uniform sampler2D _Normals;
			uniform float _ClipMask;
			uniform float _DepthSize;
			uniform float4 _AI_Offset;

			float4 _TintColor;
			float4 _SpecularColor;
			float _Shininess;

			float4 _GridRegion;
			half _CullWorldLOD;

			struct v2f_surf {
				UNITY_POSITION(pos);
				float3 worldPos : TEXCOORD3;
				float4 uvsFrame1 : TEXCOORD5;
				float4 uvsFrame2 : TEXCOORD6;
				float4 uvsFrame3 : TEXCOORD7;
				float4 octaFrame : TEXCOORD8;
				float4 viewPos : TEXCOORD9;
				//UNITY_FOG_COORDS(4)
				half fogCoord	: TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			float2 VectortoOctahedron(float3 N)
			{
				N /= dot(1.0, abs(N));
				if (N.z <= 0)
				{
					N.xy = (1 - abs(N.yx)) * (N.xy >= 0 ? 1.0 : -1.0);
				}
				return N.xy;
			}

			float2 VectortoHemiOctahedron(float3 N)
			{
				N.xy /= dot(1.0, abs(N));
				return float2(N.x + N.y, N.x - N.y);
			}

			float3 OctahedronToVector(float2 Oct)
			{
				float3 N = float3(Oct, 1.0 - dot(1.0, abs(Oct)));
				if (N.z < 0)
				{
					N.xy = (1 - abs(N.yx)) * (N.xy >= 0 ? 1.0 : -1.0);
				}
				return normalize(N);
			}

			float3 HemiOctahedronToVector(float2 Oct)
			{
				Oct = float2(Oct.x + Oct.y, Oct.x - Oct.y) * 0.5;
				float3 N = float3(Oct, 1 - dot(1.0, abs(Oct)));
				return normalize(N);
			}

			inline void OctaImpostorVertex(inout appdata_full v, inout float4 uvsFrame1, inout float4 uvsFrame2, inout float4 uvsFrame3, inout float4 octaFrame, inout float4 viewPos)
			{
				// Inputs
				float framesXY = _AI_Frames;
				float parallax = -1;
				float prevFrame = framesXY - 1;
				float2 fractions = 1.0 / float2(framesXY, prevFrame);
				float fractionsFrame = fractions.x;
				float fractionsPrevFrame = fractions.y;
				float UVscale = _AI_ImpostorSize;

				// Basic data
				v.vertex.xyz += _AI_Offset.xyz;
				float3 worldOrigin = float3(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w);
				float3 worldCameraPos = _WorldSpaceCameraPos;

				float3 objectCameraDirection = normalize(mul((float3x3)unity_WorldToObject, worldCameraPos - worldOrigin) - _AI_Offset.xyz);
				float3 objectCameraPosition = mul(unity_WorldToObject, float4(worldCameraPos, 1)).xyz - _AI_Offset.xyz; //ray origin

				// Create orthogonal vectors to define the billboard
				float3 upVector = float3(0, 1, 0);
				float3 objectHorizontalVector = normalize(cross(objectCameraDirection, upVector));
				float3 objectVerticalVector = cross(objectHorizontalVector, objectCameraDirection);

				// Billboard
				float2 uvExpansion = (v.texcoord.xy - 0.5f) * framesXY * fractionsFrame * UVscale;
				float3 billboard = objectHorizontalVector * uvExpansion.x + objectVerticalVector * uvExpansion.y + _AI_Offset.xyz;

				float3 localDir = billboard - objectCameraPosition - _AI_Offset.xyz;

				// Octahedron Frame
	#ifdef _HEMI_ON
				objectCameraDirection.y = max(0.001, objectCameraDirection.y);
				float2 frameOcta = VectortoHemiOctahedron(objectCameraDirection.xzy) * 0.5 + 0.5;
	#else
				float2 frameOcta = VectortoOctahedron(objectCameraDirection.xzy) * 0.5 + 0.5;
	#endif

				// Setup for octahedron
				float2 prevOctaFrame = frameOcta * prevFrame;
				float2 baseOctaFrame = floor(prevOctaFrame);
				float2 fractionOctaFrame = (baseOctaFrame * fractionsFrame);

				// Octa 1
				float2 octaFrame1 = (baseOctaFrame * fractionsPrevFrame) * 2.0 - 1.0;
	#ifdef _HEMI_ON
				float3 octa1WorldY = HemiOctahedronToVector(octaFrame1).xzy;
	#else
				float3 octa1WorldY = OctahedronToVector(octaFrame1).xzy;
	#endif
				float3 octa1WorldX = normalize(cross(upVector, octa1WorldY) + float3(-0.001, 0, 0));
				float3 octa1WorldZ = cross(octa1WorldX, octa1WorldY);

				float dotY1 = dot(octa1WorldY, localDir);
				float3 octa1LocalY = normalize(float3(dot(octa1WorldX, localDir), dotY1, dot(octa1WorldZ, localDir)));

				float lineInter1 = dot(octa1WorldY, -objectCameraPosition) / dotY1; //minus??
				float3 intersectPos1 = (lineInter1 * localDir + objectCameraPosition); // should subtract offset??

				float dotframeX1 = dot(octa1WorldX, -intersectPos1);
				float dotframeZ1 = dot(octa1WorldZ, -intersectPos1);

				float2 uvFrame1 = float2(dotframeX1, dotframeZ1);

				if (lineInter1 <= 0.0)
					uvFrame1 = 0;

				float2 uvParallax1 = octa1LocalY.xz * fractionsFrame * parallax;
				uvFrame1 = ((uvFrame1 / UVscale) + 0.5) * fractionsFrame + fractionOctaFrame;
				uvsFrame1 = float4(uvParallax1, uvFrame1);

				// Octa 2
				float2 fractPrevOctaFrame = frac(prevOctaFrame);
				float2 cornerDifference = lerp(float2(0, 1), float2(1, 0), saturate(ceil((fractPrevOctaFrame.x - fractPrevOctaFrame.y))));
				float2 octaFrame2 = ((baseOctaFrame + cornerDifference) * fractionsPrevFrame) * 2.0 - 1.0;
	#ifdef _HEMI_ON
				float3 octa2WorldY = HemiOctahedronToVector(octaFrame2).xzy;
	#else
				float3 octa2WorldY = OctahedronToVector(octaFrame2).xzy;
	#endif
				float3 octa2WorldX = normalize(cross(upVector, octa2WorldY) + float3(-0.001, 0, 0));
				float3 octa2WorldZ = cross(octa2WorldX, octa2WorldY);

				float dotY2 = dot(octa2WorldY, localDir);
				float3 octa2LocalY = normalize(float3(dot(octa2WorldX, localDir), dotY2, dot(octa2WorldZ, localDir)));

				float lineInter2 = dot(octa2WorldY, -objectCameraPosition) / dotY2; //minus??
				float3 intersectPos2 = (lineInter2 * localDir + objectCameraPosition);

				float dotframeX2 = dot(octa2WorldX, -intersectPos2);
				float dotframeZ2 = dot(octa2WorldZ, -intersectPos2);

				float2 uvFrame2 = float2(dotframeX2, dotframeZ2);

				if (lineInter2 <= 0.0)
					uvFrame2 = 0;

				float2 uvParallax2 = octa2LocalY.xz * fractionsFrame * parallax;
				uvFrame2 = ((uvFrame2 / UVscale) + 0.5) * fractionsFrame + ((cornerDifference * fractionsFrame) + fractionOctaFrame);
				uvsFrame2 = float4(uvParallax2, uvFrame2);


				// Octa 3
				float2 octaFrame3 = ((baseOctaFrame + 1) * fractionsPrevFrame) * 2.0 - 1.0;
	#ifdef _HEMI_ON
				float3 octa3WorldY = HemiOctahedronToVector(octaFrame3).xzy;
	#else
				float3 octa3WorldY = OctahedronToVector(octaFrame3).xzy;
	#endif
				float3 octa3WorldX = normalize(cross(upVector, octa3WorldY) + float3(-0.001, 0, 0));
				float3 octa3WorldZ = cross(octa3WorldX, octa3WorldY);

				float dotY3 = dot(octa3WorldY, localDir);
				float3 octa3LocalY = normalize(float3(dot(octa3WorldX, localDir), dotY3, dot(octa3WorldZ, localDir)));

				float lineInter3 = dot(octa3WorldY, -objectCameraPosition) / dotY3; //minus??
				float3 intersectPos3 = (lineInter3 * localDir + objectCameraPosition);

				float dotframeX3 = dot(octa3WorldX, -intersectPos3);
				float dotframeZ3 = dot(octa3WorldZ, -intersectPos3);

				float2 uvFrame3 = float2(dotframeX3, dotframeZ3);

				if (lineInter3 <= 0.0)
					uvFrame3 = 0;

				float2 uvParallax3 = octa3LocalY.xz * fractionsFrame * parallax;
				uvFrame3 = ((uvFrame3 / UVscale) + 0.5) * fractionsFrame + (fractionOctaFrame + fractionsFrame);
				uvsFrame3 = float4(uvParallax3, uvFrame3);

				// maybe remove this?
				octaFrame = 0;
				octaFrame.xy = prevOctaFrame;

				// view pos
				viewPos = 0;
				viewPos.xyz = UnityObjectToViewPos(billboard);
				v.vertex.xyz = billboard;
				v.normal.xyz = objectCameraDirection;
			}


			v2f_surf vert_surf(appdata_full v)
			{
				UNITY_SETUP_INSTANCE_ID(v);
				v2f_surf o;
				UNITY_INITIALIZE_OUTPUT(v2f_surf,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);

				OctaImpostorVertex(v, o.uvsFrame1, o.uvsFrame2, o.uvsFrame3, o.octaFrame, o.viewPos);

				o.pos = UnityObjectToClipPos(v.vertex);
				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.worldPos = posWorld.xyz;
				o.fogCoord = GetFogCoord(o.pos, posWorld);
				//UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}

			fixed4 frag_surf(v2f_surf IN, out float outDepth : SV_Depth) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
#ifdef _WORLD_GRID_CULL
				fixed ci = _GridRegion.x - IN.worldPos.x;
				ci = max(ci, IN.worldPos.x - _GridRegion.y);
				ci = max(ci, _GridRegion.z - IN.worldPos.z);
				ci = max(ci, IN.worldPos.z - _GridRegion.w);
				ci *= _CullWorldLOD;
				clip(ci + 0.01);
#endif

				float depthBias = -1.0;
				float textureBias = -1.0;

				// Octa1
				float4 parallaxSample1 = tex2Dbias(_Normals, float4(IN.uvsFrame1.zw, 0, depthBias));
				float2 parallax1 = ((0.5 - parallaxSample1.a) * IN.uvsFrame1.xy) + IN.uvsFrame1.zw;
				float4 albedo1 = tex2Dbias(_Albedo, float4(parallax1, 0, textureBias));
				float4 normals1 = tex2Dbias(_Normals, float4(parallax1, 0, textureBias));

				// Octa2
				float4 parallaxSample2 = tex2Dbias(_Normals, float4(IN.uvsFrame2.zw, 0, depthBias));
				float2 parallax2 = ((0.5 - parallaxSample2.a) * IN.uvsFrame2.xy) + IN.uvsFrame2.zw;
				float4 albedo2 = tex2Dbias(_Albedo, float4(parallax2, 0, textureBias));
				float4 normals2 = tex2Dbias(_Normals, float4(parallax2, 0, textureBias));

				// Octa3
				float4 parallaxSample3 = tex2Dbias(_Normals, float4(IN.uvsFrame3.zw, 0, depthBias));
				float2 parallax3 = ((0.5 - parallaxSample3.a) * IN.uvsFrame3.xy) + IN.uvsFrame3.zw;
				float4 albedo3 = tex2Dbias(_Albedo, float4(parallax3, 0, textureBias));
				float4 normals3 = tex2Dbias(_Normals, float4(parallax3, 0, textureBias));

				// Weights
				float2 fraction = frac(IN.octaFrame.xy);
				float2 invFraction = 1 - fraction;
				float3 weights;
				weights.x = min(invFraction.x, invFraction.y);
				weights.y = abs(fraction.x - fraction.y);
				weights.z = min(fraction.x, fraction.y);

				// Blends
				float4 blendedAlbedo = albedo1 * weights.x + albedo2 * weights.y + albedo3 * weights.z;
				float4 blendedNormal = normals1 * weights.x + normals2 * weights.y + normals3 * weights.z;

				float3 localNormal = blendedNormal.rgb * 2.0 - 1.0;
				float3 worldNormal = normalize(mul(unity_ObjectToWorld, float4(localNormal, 0)).xyz);

				float3 viewPos = IN.viewPos.xyz;
				viewPos.z += ((parallaxSample1.a * weights.x + parallaxSample2.a * weights.y + parallaxSample3.a * weights.z) * 2.0 - 1.0) * 0.5 * _DepthSize * length(unity_ObjectToWorld[2].xyz);

				float3 worldPos = mul(UNITY_MATRIX_I_V, float4(viewPos.xyz, 1)).xyz;
				float4 clipPos = mul(UNITY_MATRIX_P, float4(viewPos, 1));

				clipPos.xyz /= clipPos.w;
				if (UNITY_NEAR_CLIP_VALUE < 0)
					clipPos = clipPos * 0.5 + 0.5;

				outDepth = clipPos.z;

				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				half diff = saturate(dot(worldNormal, _WorldSpaceLightPos0.xyz));
				//float3 reflectDir = reflect(-_WorldSpaceLightPos0.xyz, worldNormal);
				//float NoH = max(dot(worldViewDir, reflectDir), 0.0);
				//half spec = pow(NoH, 48 * _Shininess);

				fixed4 c = 0;
				fixed3 lightColor = _LightColor0.rgb * diff + UNITY_LIGHTMODEL_AMBIENT.rgb;

				c.rgb = blendedAlbedo.rgb * lightColor; // +spec * _SpecularColor.rgb;
				c.a = blendedAlbedo.a - _ClipMask;
				clip(c.a);

				//c.rgb = ApplyFog(c.rgb, IN.fogCoord);
				c.rgb = ApplySunFog(c.rgb, IN.fogCoord, worldViewDir);
				//UNITY_APPLY_FOG(IN.fogCoord, c);
				return c;
			}

			ENDCG
		}
	}
				//FallBack "Legacy Shaders/Override/Diffuse"
}
