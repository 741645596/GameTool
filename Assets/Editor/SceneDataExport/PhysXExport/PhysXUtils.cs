using UnityEditor;
using UnityEngine.SceneManagement;
using UnityEngine;
using System.Runtime.InteropServices;
using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEditor.SceneManagement;
using OmegaEditor.Coroutine;
using OmegaEditor.Extension;
using UnityEngine.Rendering;
using ObjType = UnityPhysXExport.PhysXIDBuilder.ObjType;

namespace UnityPhysXExport
{
    public static class PhysXUtils
    {
        [StructLayout(LayoutKind.Sequential)]
        struct PxTransform
        {
            public Quaternion q;
            public Vector3 p;
        }

        enum PxGeometryType
        {
            eSPHERE,
            ePLANE,
            eCAPSULE,
            eBOX,
            eCONVEXMESH,
            eTRIANGLEMESH,
            eHEIGHTFIELD,

            eGEOMETRY_COUNT,    //!< internal use only!
            eINVALID = -1,  //!< internal use only!
        };

        enum PxShapeFlag
        {
            /**
            \brief The shape will partake in collision in the physical simulation.

            \note It is illegal to raise the eSIMULATION_SHAPE and eTRIGGER_SHAPE flags.
            In the event that one of these flags is already raised the sdk will reject any 
            attempt to raise the other.  To raise the eSIMULATION_SHAPE first ensure that 
            eTRIGGER_SHAPE is already lowered.

            \note This flag has no effect if simulation is disabled for the corresponding actor (see #PxActorFlag::eDISABLE_SIMULATION).

            @see PxSimulationEventCallback.onContact() PxScene.setSimulationEventCallback() PxShape.setFlag(), PxShape.setFlags()
            */
            eSIMULATION_SHAPE = (1 << 0),

            /**
            \brief The shape will partake in scene queries (ray casts, overlap tests, sweeps, ...).
            */
            eSCENE_QUERY_SHAPE = (1 << 1),

            /**
            \brief The shape is a trigger which can send reports whenever other shapes enter/leave its volume.

            \note Triangle meshes and heightfields can not be triggers. Shape creation will fail in these cases.

            \note Shapes marked as triggers do not collide with other objects. If an object should act both
            as a trigger shape and a collision shape then create a rigid body with two shapes, one being a 
            trigger shape and the other a collision shape. 	It is illegal to raise the eTRIGGER_SHAPE and 
            eSIMULATION_SHAPE flags on a single PxShape instance.  In the event that one of these flags is already 
            raised the sdk will reject any attempt to raise the other.  To raise the eTRIGGER_SHAPE flag first 
            ensure that eSIMULATION_SHAPE flag is already lowered.

            \note Shapes marked as triggers are allowed to participate in scene queries, provided the eSCENE_QUERY_SHAPE flag is set. 

            \note This flag has no effect if simulation is disabled for the corresponding actor (see #PxActorFlag::eDISABLE_SIMULATION).

            @see PxSimulationEventCallback.onTrigger() PxScene.setSimulationEventCallback() PxShape.setFlag(), PxShape.setFlags()
            */
            eTRIGGER_SHAPE = (1 << 2),

            /**
            \brief Enable debug renderer for this shape

            @see PxScene.getRenderBuffer() PxRenderBuffer PxVisualizationParameter
            */
            eVISUALIZATION = (1 << 3),

            /**
            \brief Sets the shape to be a particle drain.
            */
            ePARTICLE_DRAIN = (1 << 4)
        };

        [StructLayout(LayoutKind.Sequential)]
        struct PxBoxGeometry
        {
            public PxGeometryType mType;
            public Vector3 halfExtents;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct PxSphereGeometry
        {
            public PxGeometryType mType;
            public float radius;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct PxCapsuleGeometry
        {
            public PxGeometryType mType;
            public float radius;
            public float halfHeight;
        }

        [StructLayout(LayoutKind.Sequential)]
        struct PxFilterData
        {
            public Int32 word0;
            public Int32 word1;
            public Int32 word2;
            public Int32 word3;
        };

        [DllImport("PxSerialization")]
        public static extern void initPhysics();

        [DllImport("PxSerialization")]
        static extern void cleanupPhysics();

        [DllImport("PxSerialization")]
        public static extern IntPtr createCollection();

        [DllImport("PxSerialization")]
        static extern void addCollectionObject(IntPtr collection, IntPtr obj, Int64 id);

        [DllImport("PxSerialization")]
        static extern IntPtr createMaterial(float staticFriction, float dynamicFriction, float restitution);

        [DllImport("PxSerialization")]
        static extern IntPtr createShape(IntPtr geometry, IntPtr material);

        [DllImport("PxSerialization")]
        static extern void setOwnerClient(IntPtr actor, int inClient);

        [DllImport("PxSerialization")]
        static extern void setName(IntPtr actor, IntPtr name);

        [DllImport("PxSerialization")]
        static extern IntPtr createMeshShape(IntPtr points, int point_count, IntPtr triangles, int triangle_count, bool convex, IntPtr material);

        [DllImport("PxSerialization")]
        static extern IntPtr CreateHeightField(IntPtr heights, int width, int height, float thickness, float scaleX, float scaleY, float scaleZ, IntPtr material);

        [DllImport("PxSerialization")]
        static extern void attachShape(IntPtr actor, IntPtr shape);

        [DllImport("PxSerialization")]
        static extern void detachShape(IntPtr actor, IntPtr shape);

        [DllImport("PxSerialization")]
        static extern void setShapeFlag(IntPtr shape, PxShapeFlag flag, bool value);

        [DllImport("PxSerialization")]
        static extern void setLocalPose(IntPtr shape, IntPtr transform);

        [DllImport("PxSerialization")]
        static extern IntPtr createStatic(IntPtr transform, IntPtr geometry, IntPtr material);

        [DllImport("PxSerialization")]
        static extern IntPtr createDynamic(IntPtr transform, IntPtr shape, float density);

        [DllImport("PxSerialization")]
        static extern IntPtr createRigidStatic(IntPtr transform);

        [DllImport("PxSerialization")]
        static extern IntPtr createRigidDynamic(IntPtr transform, float mass, float drag, float angularDrag, bool useGravity, bool isKinematic);

        [DllImport("PxSerialization")]
        public static extern void complete(IntPtr collection, IntPtr exceptFor, bool followJoints);

        [DllImport("PxSerialization")]
        public static extern void serializeCollection(IntPtr collection, IntPtr externalRefs, IntPtr filename, Boolean toBinary);

        [DllImport("PxSerialization")]
        static extern void release(IntPtr p);

        [DllImport("PxSerialization")]
        static extern void setShapeName(IntPtr shape, IntPtr name);

        [DllImport("PxSerialization")]
        static extern void setShapeContactOffset(IntPtr shape, float offset);

        [DllImport("PxSerialization")]
        static extern void setShapeQueryFilterData(IntPtr shape, IntPtr data);

        [DllImport("PxSerialization")]
        static extern void setShapeSimulationFilterData(IntPtr shape, IntPtr data);

        static void SetShapeQueryFilterData(IntPtr shape, PxFilterData data)
        {
            IntPtr dataPtr = Marshal.AllocHGlobal(Marshal.SizeOf(data));
            Marshal.StructureToPtr(data, dataPtr, false);
            setShapeQueryFilterData(shape, dataPtr);
            Marshal.FreeHGlobal(dataPtr);
        }

        static void SetShapeQueryFilterData(IntPtr shape, Collider collider)
        {
            SetShapeQueryFilterData(shape, collider.gameObject.layer, collider.isTrigger);
        }
        
        static void SetShapeQueryFilterData(IntPtr shape, int layer, bool isTrigger)
        {
            PxFilterData data;
            data.word0 = 1 << layer;
            data.word1 = isTrigger ? 1 : 0;
            data.word2 = data.word3 = 0;
            SetShapeQueryFilterData(shape, data);
        }

        static IntPtr CreateMaterial(PhysicMaterial material)
        {
            return createMaterial(material.staticFriction, material.dynamicFriction, material.bounciness);
        }

        static IntPtr CreateRigidDynamic(Rigidbody rigidBody)
        {
            Transform transform = rigidBody.transform;
            PxTransform pxTransform;
            pxTransform.p = transform.position;
            pxTransform.q = transform.rotation;
            IntPtr transformPtr = Marshal.AllocHGlobal(Marshal.SizeOf(pxTransform));
            Marshal.StructureToPtr(pxTransform, transformPtr, false);

            IntPtr rigidDynamic = createRigidDynamic(transformPtr, rigidBody.mass, rigidBody.drag, rigidBody.angularDrag, rigidBody.useGravity, rigidBody.isKinematic);

            Marshal.FreeHGlobal(transformPtr);
            return rigidDynamic;
        }

        static IntPtr CreateRigidStatic(/*Transform transform*/)
        {
            PxTransform pxTransform;
            pxTransform.p = Vector3.zero;//transform.position;
            pxTransform.q = Quaternion.identity;//transform.rotation;
            IntPtr transformPtr = Marshal.AllocHGlobal(Marshal.SizeOf(pxTransform));
            Marshal.StructureToPtr(pxTransform, transformPtr, false);

            IntPtr rigidDynamic = createRigidStatic(transformPtr);

            Marshal.FreeHGlobal(transformPtr);
            return rigidDynamic;
        }

        static void SetLocalPose(IntPtr shape, PxTransform pxTransform)
        {
            IntPtr transformPtr = Marshal.AllocHGlobal(Marshal.SizeOf(pxTransform));
            Marshal.StructureToPtr(pxTransform, transformPtr, false);

            setLocalPose(shape, transformPtr);

            Marshal.FreeHGlobal(transformPtr);
        }


        static void SetShapeName(Collider collider, IntPtr shape)
        {
            String name = collider.name;
            setShapeName(shape, Marshal.StringToHGlobalAnsi(name));
        }

        /// <summary>
        /// 功能函数，获取 hierarchy 名字
        /// </summary>
        /// <param name="go"></param>
        /// <returns></returns>
        static string GetGameObjectNameInHierarchy(Transform go)
        {
            if (go == null) return string.Empty;
            else
            {
                return GetGameObjectNameInHierarchy(go.parent) + "/" + go.name;
            }
        }

        // PxShape with PxBoxGeometry
        static IntPtr CreateBoxCollider(BoxCollider boxCollider)
        {
            PxBoxGeometry geo;
            geo.mType = PxGeometryType.eBOX;

            geo.halfExtents.x = boxCollider.size.x * Mathf.Abs(boxCollider.transform.lossyScale.x) / 2.0f;
            geo.halfExtents.y = boxCollider.size.y * Mathf.Abs(boxCollider.transform.lossyScale.y) / 2.0f;
            geo.halfExtents.z = boxCollider.size.z * Mathf.Abs(boxCollider.transform.lossyScale.z) / 2.0f;
            if (boxCollider.size.x < 0 || boxCollider.size.y < 0 || boxCollider.size.z < 0)
            {
                Debug.LogError(string.Format("BoxCollider {0} 的大小为负数, GameObject Name: {1}，请检查", boxCollider.name, GetGameObjectNameInHierarchy(boxCollider.transform)));
            }

            IntPtr geoPtr = Marshal.AllocHGlobal(Marshal.SizeOf(geo));
            Marshal.StructureToPtr(geo, geoPtr, false);

            IntPtr shape = createShape(geoPtr, CreateMaterial(boxCollider.material));
            Marshal.FreeHGlobal(geoPtr);

            /*
             * Trigger shapes play no part in the simulation of the scene (though they can be configured to participate in scene queries). 
             * Instead, their role is to report that there has been an overlap with another shape. Contacts are not generated for the intersection,
             * and as a result contact reports are not available for trigger shapes. Further, because triggers play no part in the simulation,
             * the SDK will not allow the the eSIMULATION_SHAPE eTRIGGER_SHAPE flags to be raised simultaneously; that is, 
             * if one flag is raised then attempts to raise the other will be rejected, and an error will be passed to the error stream.
             */
            if (boxCollider.isTrigger)
            {
                setShapeFlag(shape, PxShapeFlag.eSIMULATION_SHAPE, false);
            }
            setShapeFlag(shape, PxShapeFlag.eTRIGGER_SHAPE, boxCollider.isTrigger);
            SetShapeName(boxCollider, shape);
            setShapeContactOffset(shape, boxCollider.contactOffset);
            SetShapeQueryFilterData(shape, boxCollider);

            return shape;
        }

        // PxShape with PxSphereGeometry
        static IntPtr CreateSphereCollider(SphereCollider sphereCollider)
        {
            PxSphereGeometry geo;
            geo.mType = PxGeometryType.eSPHERE;
            float max_scale = Math.Max(Math.Max(Mathf.Abs(sphereCollider.transform.localScale.x),
                Mathf.Abs(sphereCollider.transform.localScale.y)),
                Mathf.Abs(sphereCollider.transform.localScale.z));
            geo.radius = sphereCollider.radius * max_scale;

            IntPtr geoPtr = Marshal.AllocHGlobal(Marshal.SizeOf(geo));
            Marshal.StructureToPtr(geo, geoPtr, false);

            IntPtr shape = createShape(geoPtr, CreateMaterial(sphereCollider.material));
            Marshal.FreeHGlobal(geoPtr);
            if (sphereCollider.isTrigger)
            {
                setShapeFlag(shape, PxShapeFlag.eSIMULATION_SHAPE, false);
            }
            setShapeFlag(shape, PxShapeFlag.eTRIGGER_SHAPE, sphereCollider.isTrigger);
            SetShapeName(sphereCollider, shape);
            setShapeContactOffset(shape, sphereCollider.contactOffset);
            SetShapeQueryFilterData(shape, sphereCollider);
            return shape;
        }

        // PxShape with PxCapsuleGeometry
        static IntPtr CreateCapsuleCollider(CapsuleCollider capsuleCollider)
        {
            PxCapsuleGeometry geo;
            geo.mType = PxGeometryType.eCAPSULE;
            geo.radius = capsuleCollider.radius * Mathf.Max(Mathf.Abs(capsuleCollider.transform.localScale.x), Mathf.Abs(capsuleCollider.transform.localScale.z));
            geo.halfHeight = capsuleCollider.height * capsuleCollider.transform.localScale.y / 2.0f - geo.radius;
            if (geo.halfHeight <= 0)
            {
                Debug.LogWarning(string.Format("CapsuleCollider {0} 的大小为负数, GameObject Name: {1}，将设置为0.001", capsuleCollider.name, GetGameObjectNameInHierarchy(capsuleCollider.transform)));
                geo.halfHeight = 0.001f;
            }

            IntPtr geoPtr = Marshal.AllocHGlobal(Marshal.SizeOf(geo));
            Marshal.StructureToPtr(geo, geoPtr, false);

            IntPtr shape = createShape(geoPtr, CreateMaterial(capsuleCollider.material));
            Marshal.FreeHGlobal(geoPtr);
            if (capsuleCollider.isTrigger)
            {
                setShapeFlag(shape, PxShapeFlag.eSIMULATION_SHAPE, false);
            }
            setShapeFlag(shape, PxShapeFlag.eTRIGGER_SHAPE, capsuleCollider.isTrigger);
            SetShapeName(capsuleCollider, shape);
            setShapeContactOffset(shape, capsuleCollider.contactOffset);
            SetShapeQueryFilterData(shape, capsuleCollider);
            return shape;
        }

        unsafe static IntPtr CreateMeshCollider(MeshCollider meshCollider)
        {
            Mesh mesh = meshCollider.sharedMesh;
            if (mesh == null || mesh.vertices.Length == 0)
            {
                Debug.LogError(meshCollider + "上面的mesh丢失了，请检查");
                return IntPtr.Zero;
            }
            Vector3 scale = meshCollider.transform.lossyScale;
            Vector3[] meshVertices = new Vector3[mesh.vertices.Length];
            for (int i = 0; i < mesh.vertices.Length; ++i)
            {
                Vector3 vertice = mesh.vertices[i];
                vertice.x *= scale.x;
                vertice.y *= scale.y;
                vertice.z *= scale.z;
                meshVertices[i] = vertice;
            }

            IntPtr shape = IntPtr.Zero;
            fixed (Vector3* vertices = meshVertices)
            {
                fixed (int* triangles = mesh.triangles)
                {
                    //Debug.Log("triangle count: " + mesh.triangles.Length);
                    //Debug.Log("material: " + meshCollider.material);
                    shape = createMeshShape(
                        (IntPtr)vertices, 
                        mesh.vertexCount, 
                        (IntPtr)triangles, 
                        mesh.triangles.Length / 3, 
                        meshCollider.convex, 
                        CreateMaterial(meshCollider.material));
                }
            }

            if (meshCollider.isTrigger)
            {
                setShapeFlag(shape, PxShapeFlag.eSIMULATION_SHAPE, false);
            }
            setShapeFlag(shape, PxShapeFlag.eTRIGGER_SHAPE, meshCollider.isTrigger);
            SetShapeName(meshCollider, shape);
            setShapeContactOffset(shape, meshCollider.contactOffset);
            SetShapeQueryFilterData(shape, meshCollider);
            return shape;
        }
        
        unsafe static IntPtr CreateMeshCollider(Mesh mesh, int layer)
        {
            if (mesh == null || mesh.vertices.Length == 0)
            {
                Debug.LogError(mesh + "上面的mesh丢失了，请检查");
                return IntPtr.Zero;
            }

            Vector3[] meshVertices = new Vector3[mesh.vertices.Length];
            for (int i = 0; i < mesh.vertices.Length; ++i)
            {
                Vector3 vertice = mesh.vertices[i];
                meshVertices[i] = vertice;
            }

            IntPtr shape = IntPtr.Zero;
            fixed (Vector3* vertices = meshVertices)
            {
                fixed (int* triangles = mesh.triangles)
                {
                    //Debug.Log("triangle count: " + mesh.triangles.Length);
                    //Debug.Log("material: " + meshCollider.material);
                    shape = createMeshShape(
                        (IntPtr)vertices, 
                        mesh.vertexCount, 
                        (IntPtr)triangles, 
                        mesh.triangles.Length / 3, 
                        false, 
                        CreateMaterial(new PhysicMaterial()));
                }
            }

            /*if (meshCollider.isTrigger)
            {
                setShapeFlag(shape, PxShapeFlag.eSIMULATION_SHAPE, false);
            }*/
            setShapeFlag(shape, PxShapeFlag.eTRIGGER_SHAPE, false);
            //SetShapeName(meshCollider, shape);
            setShapeName(shape, Marshal.StringToHGlobalAnsi(mesh.name));
            setShapeContactOffset(shape, 0.01f);
            SetShapeQueryFilterData(shape, layer, false);
            return shape;
        }

        static IntPtr CreateHeightField(TerrainCollider terrainCollider)
        {
            int width = terrainCollider.terrainData.heightmapResolution;
            int height = terrainCollider.terrainData.heightmapResolution;
            float[,] rawHeights = terrainCollider.terrainData.GetHeights(0, 0, width, height);
            Int16[] heights = new Int16[width * height];
            for (int x = 0; x < width; ++x)
            {
                for (int y = 0; y < height; ++y)
                {
                    heights[y * width + x] = (Int16)(rawHeights[x, y] * 32767);
                }
            }

            //Debug.LogFormat("width: {0} height: {1} length: {2}", width, height, heights.Length);

            IntPtr shape = IntPtr.Zero;

            GCHandle heightsHandler = GCHandle.Alloc(heights, GCHandleType.Pinned);
            IntPtr heightsPtr = Marshal.UnsafeAddrOfPinnedArrayElement(heights, 0);
            shape = CreateHeightField(heightsPtr, width, height, -1 * terrainCollider.terrainData.thickness,
                terrainCollider.terrainData.heightmapScale.x,
                terrainCollider.terrainData.heightmapScale.y / 32767,
                terrainCollider.terrainData.heightmapScale.z,
                CreateMaterial(terrainCollider.material));

            heightsHandler.Free();
            if (shape == IntPtr.Zero)
            {
                Debug.Log("Create shape error");
            }

            if (terrainCollider.isTrigger)
            {
                setShapeFlag(shape, PxShapeFlag.eSIMULATION_SHAPE, false);
            }
            setShapeFlag(shape, PxShapeFlag.eTRIGGER_SHAPE, terrainCollider.isTrigger);
            SetShapeName(terrainCollider, shape);
            setShapeContactOffset(shape, terrainCollider.contactOffset);
            SetShapeQueryFilterData(shape, terrainCollider);

            return shape;
        }

        public static Mesh GetColliderMesh(GameObject go)
        {
            Mesh mesh = new Mesh(){name = go.name};
            VertexAttributeMask attributeMask = new VertexAttributeMask(VertexAttribute.Position);
            BoxCollider[] boxColliders = go.GetComponentsInChildren<BoxCollider>();
            foreach (var boxCollider in boxColliders)
            {
                var box = PrimitiveMesh.Cube(boxCollider.center, boxCollider.size);
                mesh.Merge(
                    box.Translated(boxCollider.transform.localToWorldMatrix), 
                    attributeMask);
            }

            SphereCollider[] sphereColliders = go.GetComponents<SphereCollider>();
            if (sphereColliders.Length != 0)
            {
                Debug.LogErrorFormat("Sphere Collider Detected:{0}", go.name);
            }

            CapsuleCollider[] capsuleColliders = go.GetComponents<CapsuleCollider>();
            if (capsuleColliders.Length != 0)
            {
                Debug.LogErrorFormat("Capsule Collider Detected:{0}", go.name);
            }
            
            TerrainCollider[] terrainColliders = go.GetComponents<TerrainCollider>();
            if (terrainColliders.Length != 0)
            {
                Debug.LogErrorFormat("Terrain Collider Detected:{0}", go.name);
            }

            MeshCollider[] meshColliders = go.GetComponentsInChildren<MeshCollider>();
            foreach (var meshCollider in meshColliders)
            {
                mesh.Merge(meshCollider.sharedMesh.Translated(meshCollider.transform.localToWorldMatrix), attributeMask);
            }
            return mesh;
        }

        static IntPtr CreatePxShape(GameObject go)
        {
            Mesh mesh = GetColliderMesh(go);
            return CreateMeshCollider(mesh, go.layer);
        }

        #region Parallel
        static void AddChilds(List<GameObject> set, GameObject go)
        {                                               //收集 子物体
            Transform tr = go.transform;
            for (int i = 0; i < tr.childCount; i++)
            {
                GameObject tmp = tr.GetChild(i).gameObject;
                if (tmp.activeInHierarchy)
                {
                    set.Add(tmp);
                    if (tmp.transform.childCount > 0)
                        AddChilds(set, tmp);
                }
            }
        }
        public static void ExportPxRigidbody(IntPtr collection, GameObject go, ObjType type = ObjType.Unknown)
        {
            IntPtr shape = CreatePxShape(go);
            Rigidbody rigidBody = go.GetComponent<Rigidbody>();

            if (shape == IntPtr.Zero && rigidBody == null)
            {
                return;
            }

            IntPtr pxRigidBody = IntPtr.Zero;
            if (rigidBody != null)
            {
                pxRigidBody = CreateRigidDynamic(rigidBody);
            }
            else
            {
                pxRigidBody = CreateRigidStatic();
            }

            setName(pxRigidBody, Marshal.StringToHGlobalAnsi(go.name));

            attachShape(pxRigidBody, shape);
            addCollectionObject(collection, pxRigidBody, PhysXIDBuilder.GenerateID(type));
        }

        public static void ExportPxRigidbody(IntPtr collection, Mesh mesh, ObjType type = ObjType.Unknown)
        {
            IntPtr shape = CreateMeshCollider(mesh, 0);
            if(shape == IntPtr.Zero)
                return;
            IntPtr pxRigidbody = IntPtr.Zero;
            pxRigidbody = CreateRigidStatic();
            setName(pxRigidbody, Marshal.StringToHGlobalAnsi(mesh.name));

            attachShape(pxRigidbody, shape);
            addCollectionObject(collection, pxRigidbody, PhysXIDBuilder.GenerateID(type));
        }
        #endregion //Parallel
    }
}
