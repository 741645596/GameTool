#ifndef MAPFUNCTION_INCLUDE
#define MAPFUNCTION_INCLUDE

#include "UnityCG.cginc"
#include "UnityUI.cginc"


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