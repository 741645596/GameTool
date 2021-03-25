#ifndef PARTICLE_CORE_INCLUDED
#define PARTICLE_CORE_INCLUDED

	sampler2D _MAINTex;
	half4 _MAINTex_ST;
	half _MAINTexScrollU, _MAINTexScrollV;
	//half _MAINTilesX, _MAINTilesY, _MAINSheetSpeed;
	half _MAINHueShift;
	half4 _MAINTintColor;
	half  _MAINBrightness, _MAINCutoff;

	sampler2D _MASKTex;
	half4 _MASKTex_ST;
	half _MASKTexScrollU, _MASKTexScrollV;
	//half _MASKTilesX, _MASKTilesY, _MASKSheetSpeed;
	//half _MASKHueShift;
	half4 _MASKTintColor;
	half  _MASKBrightness, _MASKCutoff;

	sampler2D _NOISETex;
	half4 _NOISETex_ST;
	half _NOISETexScrollU, _NOISETexScrollV;
	//half _NOISETilesX, _NOISETilesY, _NOISESheetSpeed;
	//half _NOISEHueShift;
	half4 _NOISETintColor;
	half  _NOISEBrightness, _NOISECutoff;

	float4 _ClipRect;

	fixed _MAINALPHA, _MASKALPHA, _NOISEALPHA;
	fixed _MAINUVANI, _MASKUVANI, _NOISEUVANI;
	fixed _MAINUSEHUE, _MASKUSEHUE, _NOISEUSEHUE;
	fixed _MAINRGBXA, _MASKRGBXA, _NOISERGBXA;
	fixed _MAINAXGRAY, _MASKAXGRAY, _NOISEAXGRAY;
	fixed _MAINUSEDATA, _MASKUSEDATA, _NOISEUSEDATA;
	fixed _Billboard;
	//fixed _UseFog;

	half3 applyHue(half3 aColor, half aHue)
	{
		half angle = radians(aHue);
		half3 k = half3(0.57735, 0.57735, 0.57735);
		half cosAngle = cos(angle);
		return aColor * cosAngle + cross(k, aColor) * sin(angle) + k * dot(k, aColor) * (1 - cosAngle);
	}

	#if defined(_NOISEMODE_DISTORTION)
	half applyCutoff(half cutoff,half alpha,half tex,half vertexalpha) 
	{
		half minalpha = min(2.0, (1.0 - vertexalpha)) + alpha * 0.5;
		half soft = saturate(tex + 1.0 + minalpha * (-2.01));
		cutoff = cutoff * 0.5 + 0.5;
		return smoothstep(1 - cutoff, cutoff, soft);
	}
	#endif

	struct appdata_t {
		float4 vertex : POSITION;
		half4 color : COLOR;
		half4 texcoord : TEXCOORD0;
		half4 texcoord1 : TEXCOORD1;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	struct v2f {
		float4 vertex : SV_POSITION;
		half4 color : COLOR;
		half4 texcoord : TEXCOORD0;
		half4 texcoord1 : TEXCOORD1;
		float4 posWorld	: TEXCOORD2;
		float4 worldPosition : TEXCOORD3;
		UNITY_VERTEX_OUTPUT_STEREO
	};
 
	v2f vert_particle_mask (appdata_t v)
	{
		v2f o;
		UNITY_SETUP_INSTANCE_ID(v);
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
		o.worldPosition = v.vertex;
		o.vertex = UnityObjectToClipPos(o.worldPosition);
		if (_Billboard)
		{
			float2 scale = float2(length(unity_ObjectToWorld[0].xyz), length(unity_ObjectToWorld[1].xyz));
			float4 viewPos = mul(unity_MatrixMV, float4(0.0, 0.0, 0.0, 1.0)) + float4(v.vertex.xy * scale, 0.0, 0.0);
			o.vertex = mul(UNITY_MATRIX_P, viewPos);
		}
		o.color = v.color;

		half2 uv1 = v.texcoord.xy;
		half2 uv2 = v.texcoord.xy;
		half2 uv3 = v.texcoord.xy;

		uv1 += v.texcoord.zw * _MAINUSEDATA;

#ifndef _MASKMODE_NONE
		uv2 += v.texcoord1.xy * _MASKUSEDATA;
#endif

#ifndef _NOISEMODE_NONE
		uv3 += v.texcoord1.zw * _NOISEUSEDATA;
#endif

		o.texcoord.xy = v.texcoord.xy;
		o.texcoord.zw = TRANSFORM_TEX(uv1, _MAINTex);
		o.texcoord1.xy = TRANSFORM_TEX(uv2, _MASKTex);
		o.texcoord1.zw = TRANSFORM_TEX(uv3, _NOISETex);

		//uv动画
		o.texcoord.zw += _MAINUVANI * frac(_Time.yy * half2(_MAINTexScrollU, _MAINTexScrollV));
#ifndef _MASKMODE_NONE
		o.texcoord1.xy += _MASKUVANI * frac(_Time.yy * half2(_MASKTexScrollU, _MASKTexScrollV));
#endif
#ifndef _NOISEMODE_NONE
		o.texcoord1.zw += _NOISEUVANI * frac(_Time.yy * half2(_NOISETexScrollU, _NOISETexScrollV));
#endif
		o.posWorld = mul(unity_ObjectToWorld, v.vertex);

		return o;
	}

	half4 frag_particle_mask (v2f i) : SV_Target
	{
		half2 noiseUV = 0;
		half4 final = 0;
		half4 mask = 1;
		half dist = 0;

		//噪声uv，NOISEBrightness的用途符合方程y = (noise - 0.5)x _NOISEBrightness
		#if defined(_NOISEMODE_NOISE)
		noiseUV += tex2D(_NOISETex, i.texcoord1.zw).xy*_NOISEBrightness - _NOISEBrightness *0.5;
		#endif

		//main颜色采样。
		half4 mainT = tex2D(_MAINTex, i.texcoord.zw + noiseUV);

		mainT.rgb = max(_MAINALPHA, mainT.rgb);

		//假如.a作为rgb的缩放值
		mainT.rgb *= mainT.a  * _MAINRGBXA + 1 - _MAINRGBXA; // lerp(1, a, _MAINRGBXA);

		//主纹理是否需要取灰度值，并把灰度值乘到a上。该代码完全没用！
		mainT.a *= Luminance(mainT.rgb) * _MAINAXGRAY + 1 - _MAINAXGRAY; // lerp(1, Luminance(mainT.rgb), _MAINAXGRAY);


		mainT *= _MAINTintColor * _MAINBrightness;

		//暂时不清楚该代码的用途 
		if (_MAINUSEHUE)
			mainT.rgb = applyHue(mainT.rgb, _MAINHueShift);

		final += mainT;


		//mask贴图的使用
		#ifndef _MASKMODE_NONE
		half4 maskT = tex2D(_MASKTex, i.texcoord1.xy + noiseUV);

		maskT.rgb = max(_MASKALPHA, maskT.rgb);

		if(_MASKRGBXA)
			maskT.rgb *= maskT.a;

		//mask贴图的a通道乘上灰度值，完全没用的代码
		if(_MASKAXGRAY)
			maskT.a *= Luminance(maskT.rgb);

			#ifdef _MASKMODE_MASK
			final += _MASKUSEHUE * _MASKTintColor;
			mask = pow(mask*maskT*_MASKBrightness, _MASKCutoff*2);
			#endif
		#endif

		//noise
		#ifndef _NOISEMODE_NONE
		//noise纹理采样
		half4 noiseT = tex2D(_NOISETex, i.texcoord1.zw + noiseUV);

		noiseT.rgb = max(_NOISEALPHA, noiseT.rgb);

		//rgb颜色乘以a通道，提出一个疑问，为何不直接在noise的rgb上做修改，而要在a上做手脚？美术制作贴图难度加大了很多
		if(_NOISERGBXA)
			noiseT.rgb *= noiseT.a;

		//noise贴图的a通道乘上灰度值，完全没用的代码 
		if(_NOISEAXGRAY)
			noiseT.a *= Luminance(noiseT.rgb);

			//修改mask和final的颜色，应该不会用到，让美术难以理解，考虑全部不要
			#ifdef _NOISEMODE_MASK
			if (_NOISEUSEHUE)
				final += _NOISETintColor;
			mask = pow(mask*noiseT * _NOISEBrightness, _NOISECutoff*2);

			#elif _NOISEMODE_DISTORTION
			dist += applyCutoff(_NOISECutoff, _NOISEBrightness, noiseT.r, i.color.a);
			final.rgb = lerp(_NOISETintColor*final.a, final.rgb, saturate(dist*dist*dist));
			#endif
		#endif			

		final *= saturate(mask);
		//这里为何要x2.0?
		final.rgb *= 2.0f * i.color.rgb;
		final.a *= i.color.a;
		final = saturate(final);

		//_NOISEMODE_DISTORTION这个宏到底在哪里用到了？
		#if defined(_NOISEMODE_DISTORTION)
		final.a *= saturate(dist);
		final.rgb *= saturate(dist);
		#endif

#ifdef UNITY_UI_CLIP_RECT
		final.a *= UnityGet2DClipping(i.worldPosition.xy, _ClipRect);
#endif

#ifdef UNITY_UI_ALPHACLIP
		clip(final.a - 0.001);
#endif
		/*if (_UseFog) 
		{
			float fogcoord = distance(_WorldSpaceCameraPos.xyz, i.posWorld.xyz)*0.0026;
			final.rgb = final.rgb * saturate(1 - fogcoord);
		}*/
		return final;
	}

#endif //PARTICLE_CORE_INCLUDED
