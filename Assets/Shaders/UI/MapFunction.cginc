#ifndef MAPFUNCTION_INCLUDE
#define MAPFUNCTION_INCLUDE

#include "UnityCG.cginc"
#include "UnityUI.cginc"

//float owner_smoothstep(float fmin, float fmax, float d) {
//	if (d < fmin) return 0;
//	if (d >= fmax) return 1;
//
//	float dt = (d - fmin) / ((fmax - fmin) + 0.00001);
//	return (dt * dt * (3.0 - 2.0 * dt));
//}
//
//float GetDTByX(float4 lineInfo, float2 pos, float width, float antialias) {
//	float2 point1 = lineInfo.xy;
//	float2 point2 = lineInfo.zw;
//	// 计算斜率k  
//	float k = (point1.x - point2.x) / (point1.y - point2.y);
//	// 求b  
//	float b = point1.x - k * point1.y;
//	// 点到直线的距离：d=|A·a+B·b+C|/√(A²+B²)  
//	// d = |kx-y+b|/√(k²+1²)  
//	float d = abs(k * pos.y - pos.x + b) / sqrt(k * k + 1);
//	// 公式smoothstep：将d限制在0到antialias之间，再通过公式计算插值  
//	// 返回为0表示是在线上  
//	// 返回为[0-1]表示是平滑区域  
//	// 返回为1表示不在线上  
//	//float t = 0;
//	//if (d != 0)
//	//t = smoothstep(width / 2.0, width / 2.0 + antialias, d);
//	//else
//	//	t = width / 2.0;
//
//	//float t = d < width ? 0 : 1;
//	return owner_smoothstep(width / 2.0f, width / 2.0f + antialias, d);
//}
//
//float GetDTByY(float4 lineInfo, float2 pos, float width, float antialias) {
//	float2 point1 = lineInfo.xy;
//	float2 point2 = lineInfo.zw;
//	// 计算斜率k  
//	float k = (point1.y - point2.y) / (point1.x - point2.x);
//	// 求b  
//	float b = point1.y - k * point1.x;
//	// 点到直线的距离：d=|A·a+B·b+C|/√(A²+B²)  
//	// d = |kx-y+b|/√(k²+1²)  
//	float d = abs(k * pos.x - pos.y + b) / sqrt(k * k + 1);
//	// 公式smoothstep：将d限制在0到antialias之间，再通过公式计算插值  
//	// 返回为0表示是在线上  
//	// 返回为[0-1]表示是平滑区域  
//	// 返回为1表示不在线上  
//
//	//float t = d < width ? 0 : 1;
//	return owner_smoothstep(width / 2.0f, width / 2.0f + antialias, d);
//}
//
//float4 DrawLine(float4 lineInfo, float fragLength, float2 pos, float width, float3 color, float antialias) : COLOR
//{
//	float2 point1 = lineInfo.xy;
//	float2 point2 = lineInfo.zw;
//	//// 计算斜率k  
//	//float k = (point1.y - point2.y) / (point1.x - point2.x);
//	//// 求b  
//	//float b = point1.y - k * point1.x;
//	//// 点到直线的距离：d=|A·a+B·b+C|/√(A²+B²)  
//	//// d = |kx-y+b|/√(k²+1²)  
//	//float d = abs(k * pos.x - pos.y + b) / sqrt(k * k + 1);
//	//// 公式smoothstep：将d限制在0到antialias之间，再通过公式计算插值  
//	//// 返回为0表示是在线上  
//	//// 返回为[0-1]表示是平滑区域  
//	//// 返回为1表示不在线上  
//	////float t = 0;
//	////if (d != 0)
//	//	//t = smoothstep(width / 2.0, width / 2.0 + antialias, d);
//	////else
//	////	t = width / 2.0;
//
//	////float t = d < width ? 0 : 1;
//	//float t = smoothstep(width / 2.0f, width / 2.0f + antialias, d);
//	float t = 0;
//	float tX = GetDTByX(lineInfo, pos, width, antialias);
//	float tY = GetDTByY(lineInfo, pos, width, antialias);
//
//	t = min(tX, tY);
//
//
//	float4 limit_v = float4(min(point1.x, point2.x), max(point1.x, point2.x), min(point1.y, point2.y), max(point1.y, point2.y));
//	limit_v.x -= width * 0.5f;
//	limit_v.y += width * 0.5f;
//	limit_v.z -= width * 0.5f;
//	limit_v.w += width * 0.5f;
//
//	if (!(((pos.x > limit_v.x && pos.x < limit_v.y) &&
//		(pos.y > limit_v.z && pos.y < limit_v.w)))) {
//		t = 1;
//	}
//
//	if (t < 1) {
//		float point_dis = distance(float4(point1, 0, 0), float4(point2, 0, 0));
//		point_dis = point_dis / (point_dis / (fragLength));
//
//		float v1_2_v_dis = distance(float4(point1, 0, 0), float4(pos, 0, 0));
//		v1_2_v_dis = floor(v1_2_v_dis / point_dis);
//		v1_2_v_dis = v1_2_v_dis / 2 - floor(v1_2_v_dis / 2);
//		//v1_2_v_dis = floor(v1_2_v_dis / point_dis) % 2;
//		if (v1_2_v_dis > 0) {
//			t = 1;
//		}
//	}
//
//	return fixed4(color, 1.0 - t);
//}

/*float4 DrawRound(float2 uv, float lineSize, fixed4 col,
	float4 targetRound, fixed4 targetRoundCol, float4 moveRound, fixed4 moveRoundCol) : COLOR
{
	float4 uv_v = float4(uv.xy, 0, 0);

	if (targetRound.w > 0 && targetRound.z > 0)
	{
		float4 center = float4(targetRound.xy, 0, 0);
		float dis = distance(uv_v, center);

		if (dis > (targetRound.z - lineSize * .3) && dis < (targetRound.z + lineSize * .3)) {
			return targetRoundCol;
		}
	}

	if (moveRound.w > 0)
	{
		float4 center = float4(moveRound.xy, 0, 0);
		float dis = distance(uv_v, center);

		if (dis >= moveRound.z) {
			return moveRoundCol;
		}
	}

	return col;
}*/

float4 DrawRound(float2 uv, float lineSize, fixed4 col,
	float4 targetRound, fixed4 targetRoundCol, float4 moveRound, fixed4 moveRoundCol) : COLOR
{
	fixed isTargetRound = 1 - step(min(targetRound.z, targetRound.w), 0); // targetRound.w > 0 && targetRound.z > 0
	float dis = distance(uv.xy, targetRound.xy);
	isTargetRound *= 1 - step(lineSize * 0.3, abs(dis - targetRound.z)); // dis > (targetRound.z - lineSize * .3) && dis < (targetRound.z + lineSize * .3)
	fixed isMoveRound  = 1 - step(moveRound.w, 0); // moveRound.w > 0
	dis = distance(uv.xy, moveRound.xy);
	isMoveRound *= step(moveRound.z, dis); // dis >= moveRound.z

	return lerp(
		lerp(col, moveRoundCol, isMoveRound),
		targetRoundCol,
		isTargetRound);
}

#endif