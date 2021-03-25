using System.Runtime.InteropServices;
using System.IO;
using System.Collections.Generic;
//using BattleField.Utility;
using BATTLE_ID = System.Int64;

[StructLayout(LayoutKind.Sequential)]
public struct PointValue
{
    public float x;
    public float y;
    public float z;

    public PointValue(float x, float y, float z)
    {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    //public PointValue(Vector3 point)
    //{
    //    x = point.x;
    //    y = point.y;
    //    z = point.z;
    //}

    // for reuse
    //public Vector3 Vector
    //{
    //    get
    //    {
    //        return new Vector3(x, y, z);
    //    }
    //    set
    //    {
    //        x = value.x;
    //        y = value.y;
    //        z = value.z;
    //    }
    //}

    //public static implicit operator Vector3(PointValue point)
    //{
    //    return new Vector3(point.x, point.y, point.z);
    //}

    //public static implicit operator PointValue(Vector3 point)
    //{
    //    return new PointValue(point.x, point.y, point.z);
    //}

#if UNITY_2017_1_OR_NEWER
    public static implicit operator PointValue(UnityEngine.Vector3 point)
    {
        return new PointValue(point.x, point.y, point.z);
    }
#endif
}

[StructLayout(LayoutKind.Sequential)]
public struct AgentCrowdData
{
    public PointValue Position;
    public PointValue AvoidanceVelocity;
    public float SpeedScale;
    public int State;
}
[StructLayout(LayoutKind.Sequential)]
public class AgentRunTimeInfo
{
    //< The current agent position. [(x, y, z)]
    public PointValue CurrentPosition;
    //< A temporary value used to accumulate agent displacement during iterative collision resolution. [(x, y, z)]
    public PointValue Displacement;
    //< The desired velocity of the agent. Based on the current path, calculated from scratch each frame. [(x, y, z)]
    public PointValue DesierVelocity;
    //< The desired velocity adjusted by obstacle avoidance, calculated from scratch each frame. [(x, y, z)]
    public PointValue AfterAdjustAvoidance;
    //< The actual velocity of the agent. The change from nvel -> vel is constrained by max acceleration. [(x, y, z)]
    public PointValue ActualVelocity;
};

public enum CrowAgentState
{
    CrowAgentStateInvalid,
    CrowAgentStateWalking,
    CrowAgentStateWalkingOffmesh
}

[StructLayout(LayoutKind.Sequential)]
public class CrowdParameter
{
    //< Agent radius. [Limit: >= 0]
    public float Radius;
    //< Agent height. [Limit: > 0]
    public float Height;
    //< Maximum allowed acceleration. [Limit: >= 0]
    public float MaxAcceleration;
    //< Maximum allowed speed. [Limit: >= 0]
    public float MaxSpeed;
    // Defines how close a collision element must be before it is considered for steering behaviors. [Limits: > 0]
    public float NeighborQueryRange;
    // How aggresive the agent manager should be at avoiding collisions with this agent. [Limit: >= 0]
    // PS:A higher value will result in agents trying to stay farther away from each other at the
    // cost of more difficult steering in tight spaces.
    public float NeighborSeparationWeight;
    // The index of the avoidance configuration to use for the agent. 
	// [Limits: 0 <= value <= #DT_CROWD_MAX_OBSTAVOIDANCE_PARAMS]
    public byte ObstacleAvoidanceType;
    //if != 0 enable localavoidance, else disable
    public int EnableLocalAvoidance;
    public CrowdParameter(float radius, float height, float maxAcceleration, float maxSpeed, float neighborQueryRange, float neighborSeparationWeight,
        byte obstacleAvoidanceType, int enableLocalAvoidance)
    {
        Radius = radius;
        Height = height;
        MaxAcceleration = maxAcceleration;
        MaxSpeed = maxSpeed;
        NeighborQueryRange = neighborQueryRange;
        NeighborSeparationWeight = neighborSeparationWeight;
        EnableLocalAvoidance = enableLocalAvoidance;
        ObstacleAvoidanceType = obstacleAvoidanceType;
    }
}
[StructLayout(LayoutKind.Sequential)]
public class ObstacleAvoidanceParams
{
    // the velocity bias describes how the sampling patterns is offset from the(0,0)
    // based on the desired velocity. This allows to tighten the sampling area and cull a lot of samples.
    // If you take a look at the picture in the adaptive RVO you'll notice how the grid is slightly
    // towards the desired velocity. Range [0..1]
    // The RVO works so that each sample is given a value, and the best value is used. The weights are used to
    // fine tune the behavior. The setup is very brittle, slight change in a parameter can make the agents to
    // oscillate or run in circles. It was huge pain in the ass to find a set that works ok. You've been warned :)
    public float VelBias = 0.5f;
    //	how much deviation from desired velocity is penalized,the more penalty applied to this,
    //	the more "goal oriented" the avoidance is, at the cost of getting more easily stuck at local minimas
    public float WeightDesVel = 2.0f;
    //	how much deviation from current velocity us penalized, the more penalty applied to this, the more
    //	stubborn the agent is. This basically is a low pass filter, and very important part of making things work.
    public float WeightCurVel = 0.75f;
    //	in order to avoid reciprocal dance, the agenst prefer to pass from right (or left, forgot), this weight
    //	applies penalty to velocities which try to take over from wrong side
    public float WeightSide = 0.75f;
    //	how much penalty is added based on time to impact. Too much penalty and the agents are shy,
    //	too little and they avoid too late.
    public float WeightToi = 2.5f;
    //	time horizon, this affects how early the agents start to avoid each other. Too long horizon and the
    //	agents are scared of going through tight spots, and too small and they avoid too late (closely related
    public float HorizTime = 2.5f;
    //  影響採樣品質的相關參數，AdaptiveDepth要注意不能設大，造成效能問題，建議這邊參數不要亂改…
    //  相關範例如下：
    // Low (11)
	//params.adaptiveDivs = 5;
	//params.adaptiveRings = 2;
	//params.adaptiveDepth = 1;
	//m_pCrowd->setObstacleAvoidanceParams(0, &params);
	// Medium (22)
	//params.adaptiveDivs = 5; 
	//params.adaptiveRings = 2;
	//params.adaptiveDepth = 2;
	//m_pCrowd->setObstacleAvoidanceParams(1, &params);
	// Good (45)
	//params.adaptiveDivs = 7;
	//params.adaptiveRings = 2;
	//params.adaptiveDepth = 3;
	//m_pCrowd->setObstacleAvoidanceParams(2, &params);
	// High (66)
	//params.adaptiveDivs = 7;
	//params.adaptiveRings = 3;
	//params.adaptiveDepth = 3;
	//m_pCrowd->setObstacleAvoidanceParams(3, &params);
    public byte GridSize = 33;
    public byte AdaptiveDivs = 7;
    public byte AdaptiveRings = 3;
    public byte AdaptiveDepth = 3;
    public ObstacleAvoidanceParams(float velBias, float weightDesVel, float weightCurVel, float weightSide, float weightToi, float horizTime,
        byte gridSize, byte adaptiveDivs, byte adaptiveRings, byte adaptiveDepth)
    {
        VelBias = velBias;
        WeightDesVel = weightDesVel;
        WeightCurVel = weightCurVel;
        WeightSide = weightSide;
        WeightToi = weightToi;
        HorizTime = horizTime;
        GridSize = gridSize;
        AdaptiveDivs = adaptiveDivs;
        AdaptiveRings = adaptiveRings;
        AdaptiveDepth = adaptiveDepth;
    }
    public ObstacleAvoidanceParams() { }
}

//public interface INAVMeshSystem
//{
    //void AfterBuildNAVFromMemoryData(BATTLE_ID sceneID);
//}
public static class NAVMeshSystem
{
    private static object s_syncRoot = new object(); // for recastnavigation sync

    private const uint _maxPathPoints = 256;
    
    private static float[] _tempPathInfos = new float[_maxPathPoints * 3];

    //public static void SetInterface(INAVMeshSystem theInterface) { _navMeshSystemInterface = theInterface; }
    //private static INAVMeshSystem _navMeshSystemInterface = null;    

    public delegate void AfterBuildNAVFromMemoryDataCB(BATTLE_ID sceneID);
    public static AfterBuildNAVFromMemoryDataCB AfterBuildNAVFromMemoryData { get; set; }

    //use for unity TextAsset.bytes
    public static bool BuildNAVFromMemoryData(BATTLE_ID sceneID, byte[] data)
    {
        lock (s_syncRoot)
        {
            if (BuildNAVMesh(sceneID, data, (uint)data.Length) != 0)
            {
                //if (_navMeshSystemInterface != null)
                //_navMeshSystemInterface.AfterBuildNAVFromMemoryData(sceneID);
                if (AfterBuildNAVFromMemoryData != null)
                    AfterBuildNAVFromMemoryData((uint)sceneID);
                return true;
            }
            return false;
            //return BuildNAVMesh(sceneID, data, (uint)data.Length) != 0;
        }
    }

    public static void ReuseNAVFromMemoryData(BATTLE_ID sceneID)
    {
        lock (s_syncRoot)
        {
            if (AfterBuildNAVFromMemoryData != null)
                AfterBuildNAVFromMemoryData((uint)sceneID);
        }
    }

    public static bool RemoveNAVMeshData(BATTLE_ID sceneID)
    {
        lock (s_syncRoot)
        {
            return RemoveNAVMesh(sceneID) != 0;
        }
    }

    //use for server simulate
    public static bool BuildNAVFromFile(BATTLE_ID sceneID, string filePathName)
    {
        FileStream fileStream = new FileStream(filePathName, FileMode.Open, FileAccess.Read);
        // Create a byte array of file stream length
        byte[] datas = new byte[fileStream.Length];
        //Read block of bytes from stream into the byte array
        fileStream.Read(datas, 0, System.Convert.ToInt32(fileStream.Length));
        //Close the File Stream
        fileStream.Close();
        fileStream.Dispose();
        lock (s_syncRoot)
        {
            return BuildNAVFromMemoryData(sceneID, datas);
        }
    }

    public static bool GetNAVPath(BATTLE_ID sceneID, PointValue startPoint,
        PointValue endPoint, LinkedList<PointValue> pathPoints)
    {
        pathPoints.Clear();
        uint vertexCount;
        lock (s_syncRoot)
        {
            System.Array.Clear(_tempPathInfos, 0, _tempPathInfos.Length);
            vertexCount = GetNAVMeshPath(sceneID, _tempPathInfos, _maxPathPoints,
                ref startPoint, ref endPoint) / 3;

            if (vertexCount <= 0)
                return false;
            int posIndex = 0;
            for (int index = 0; index < vertexCount; ++index)
            {
                pathPoints.AddLast(new PointValue(_tempPathInfos[posIndex],
                    _tempPathInfos[posIndex + 1], _tempPathInfos[posIndex + 2]));

                posIndex += 3;
            }
        }
        return true;
    }

    public static bool SetCrowdAgentTargetPosition(BATTLE_ID sceneID, int index, PointValue destPoint)
    {
        lock (s_syncRoot)
        {
            if (SetCrowdAgentTargetPosition(sceneID, index, ref destPoint) != 0)
            {
                return true;
            }
        }
        return false;
    }
#if UNITY_IPHONE && !UNITY_EDITOR
    //navigation mesh reference function
    [DllImport("__Internal")]
    private static extern int BuildNAVMesh(BATTLE_ID sceneID, byte[] data, uint length);
    [DllImport("__Internal")]
    public static extern void ConvertNAVMesh(BATTLE_ID sceneID, float[] vertexBuffer,
        uint numVertex, int[] triangleBuffer, uint numTriangle);
    [DllImport("__Internal")]
    public static extern uint BuildNAVMeshDebugInfo(BATTLE_ID sceneID, float[] DebugInfo,
        uint uiMaxTriangleCount);
    [DllImport("__Internal")]
    private static extern int RemoveNAVMesh(BATTLE_ID sceneID);
    [DllImport("__Internal")]
    public static extern void SetupBuildConfig(string configString);
    [DllImport("__Internal")]
    private static extern uint GetNAVMeshPath(BATTLE_ID sceneID,
        float[] pPathInfo, uint uiMaxPathCount, ref PointValue pStartPoint, ref PointValue pEndPoint);
    [DllImport("__Internal")]
    public static extern int SaveNAVMeshFile(BATTLE_ID sceneID, string filePathName);
    [DllImport("__Internal")]
    public static extern int FindDistanceToWall(BATTLE_ID sceneID, ref PointValue position, float testRadius,
        float[] outDistance, ref PointValue outHitPoint, ref PointValue outHitNormal);
    [DllImport("__Internal")]
    public static extern int GetDestPolyHeight(BATTLE_ID sceneID, ref PointValue position, float[] outHeight);
    [DllImport("__Internal")]
    public static extern int CheckIsValidPoly(BATTLE_ID sceneID, ref PointValue position, float Extend);
    //agent crowd reference function
    [DllImport("__Internal")]
    public static extern int AddCrowdAgent(BATTLE_ID sceneID, System.IntPtr agentData,
        CrowdParameter agentParameter);
    [DllImport("__Internal")]
    public static extern int ClearALLCrowdAgents(BATTLE_ID sceneID);
    [DllImport("__Internal")]
    public static extern int RemoveCrowdAgent(BATTLE_ID sceneIDe, int index);
    [DllImport("__Internal")]
    public static extern int Update(BATTLE_ID sceneID, float deltaTime);
    [DllImport("__Internal")]
    public static extern int PostUpdate(BATTLE_ID sceneID, float deltaTime);
    [DllImport("__Internal")]
    private static extern int SetCrowdAgentTargetPosition(BATTLE_ID sceneID, int index, ref PointValue outFixPosition);
    [DllImport("__Internal")]
    public static extern int ChangeCrowdAgentSpeedInfo(BATTLE_ID sceneID, int index, float maxSpeed,
        float maxAcceleration);
    [DllImport("__Internal")]
    public static extern int ChangeCrowdAgentLocalAvoidanceFlag(BATTLE_ID sceneID, int index, int iEnable);
    [DllImport("__Internal")]
    public static extern int SetupAvoidanceParams(byte index, ObstacleAvoidanceParams obstacleAvoidanceParams);
    [DllImport("__Internal")]
    public static extern int GetAgentRunTimeInfo(BATTLE_ID sceneID, int index, AgentRunTimeInfo agentRunTimeInfo);
    [DllImport("__Internal")]
    //DT_CROWDAGENT_MAX_NEIGHBOURS = 6
    public static extern uint GetNeighbors(BATTLE_ID sceneID, int index, int maxbufferCount, int[] outAgentIDs);
    //obstalce reference function
    [DllImport("__Internal")]
    public static extern int AddCylinderObstacle(BATTLE_ID sceneID, ref PointValue positon, float fRadius, float fHeight);
    [DllImport("__Internal")]
    public static extern int AddAABBObstacle(BATTLE_ID sceneID, ref PointValue minVector, ref PointValue maxVector);
    [DllImport("__Internal")]
    public static extern int RemoveObstacle(BATTLE_ID sceneID, uint obstacleID);
#else
    //切記，要在unity下把so的設定設好，platform要改成anroid，不能用all platform，否則會
    //call不到函式庫
    //navigation mesh reference function
    [DllImport("Recastnavigation")]
    private static extern int BuildNAVMesh(BATTLE_ID sceneID, byte[] data, uint length);
    [DllImport("Recastnavigation")]
    public static extern void ConvertNAVMesh(BATTLE_ID sceneID, float[] vertexBuffer,
        uint numVertex, int[] triangleBuffer, uint numTriangle);
    [DllImport("Recastnavigation")]
    public static extern uint BuildNAVMeshDebugInfo(BATTLE_ID sceneID, float[] DebugInfo,
        uint uiMaxTriangleCount);
    [DllImport("Recastnavigation")]
    private static extern int RemoveNAVMesh(BATTLE_ID sceneID);
    [DllImport("Recastnavigation")]
    public static extern void SetupBuildConfig(string configString);
    [DllImport("Recastnavigation")]
    private static extern uint GetNAVMeshPath(BATTLE_ID sceneID,
        float[] pPathInfo, uint uiMaxPathCount, ref PointValue pStartPoint, ref PointValue pEndPoint);    
    [DllImport("Recastnavigation")]
    public static extern int SaveNAVMeshFile(BATTLE_ID sceneID, string filePathName);
    [DllImport("Recastnavigation")]
    public static extern int FindDistanceToWall(BATTLE_ID sceneID, ref PointValue position, float testRadius,
        float[] outDistance, ref PointValue outHitPoint, ref PointValue outHitNormal);
    [DllImport("Recastnavigation")]
    public static extern int GetDestPolyHeight(BATTLE_ID sceneID, ref PointValue position, float[] outHeight);
    [DllImport("Recastnavigation")]
    public static extern int CheckIsValidPoly(BATTLE_ID sceneID, ref PointValue position, float Extend);
    //agent crowd reference function
    [DllImport("Recastnavigation")]
    public static extern int AddCrowdAgent(BATTLE_ID sceneID, System.IntPtr agentData,
        CrowdParameter agentParameter);
    [DllImport("Recastnavigation")]
    public static extern int ClearALLCrowdAgents(BATTLE_ID sceneID);
    [DllImport("Recastnavigation")]
    public static extern int RemoveCrowdAgent(BATTLE_ID sceneIDe, int index);
    [DllImport("Recastnavigation")]
    public static extern int Update(BATTLE_ID sceneID, float deltaTime);
    [DllImport("Recastnavigation")]
    public static extern int PostUpdate(BATTLE_ID sceneID, float deltaTime);
    [DllImport("Recastnavigation")]
    private static extern int SetCrowdAgentTargetPosition(BATTLE_ID sceneID, int index, ref PointValue outFixPosition);
    [DllImport("Recastnavigation")]
    public static extern int ChangeCrowdAgentSpeedInfo(BATTLE_ID sceneID, int index, float maxSpeed,
        float maxAcceleration);
    [DllImport("Recastnavigation")]
    public static extern int ChangeCrowdAgentLocalAvoidanceFlag(BATTLE_ID sceneID, int index, int iEnable);
    [DllImport("Recastnavigation")]
    public static extern int SetupAvoidanceParams(byte index, ObstacleAvoidanceParams obstacleAvoidanceParams);
    [DllImport("Recastnavigation")]
    public static extern int GetAgentRunTimeInfo(BATTLE_ID sceneID, int index, AgentRunTimeInfo agentRunTimeInfo);
    [DllImport("Recastnavigation")]
    //DT_CROWDAGENT_MAX_NEIGHBOURS = 6
    public static extern uint GetNeighbors(BATTLE_ID sceneID, int index, int maxbufferCount, int[] outAgentIDs);
    //obstalce reference function
    [DllImport("Recastnavigation")]
    public static extern int AddCylinderObstacle(BATTLE_ID sceneID, ref PointValue positon, float fRadius, float fHeight);
    [DllImport("Recastnavigation")]
    public static extern int AddAABBObstacle(BATTLE_ID sceneID, ref PointValue minVector, ref PointValue maxVector);
    [DllImport("Recastnavigation")]
    public static extern int RemoveObstacle(BATTLE_ID sceneID, uint obstacleID);
#endif
}