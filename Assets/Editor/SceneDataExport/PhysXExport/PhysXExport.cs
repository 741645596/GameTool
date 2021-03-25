using System.Collections;
using System.IO;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
using System;
using UnityEditor.SceneManagement;
using System.Runtime.InteropServices;
using OmegaEditor.Coroutine;
using OmegaEditor.Extension;
using ObjType = UnityPhysXExport.PhysXIDBuilder.ObjType;

namespace UnityPhysXExport
{
	public class PhysXExport
	{
		const string outputPath = "PhysXData/";

		static PhysXExport()
		{
			if (!Directory.Exists(outputPath))
			{
				Directory.CreateDirectory(outputPath);
			}
		}

		[MenuItem("Tools/场景工具/cmd: 导出场景物理数据")]
		public static CustomAsyncOperation ExportPhysXData()
		{
			string path = outputPath + "world01";
			if (Directory.Exists(path))
			{
				Directory.Delete(path, true);
			}
			Directory.CreateDirectory(path);
			Action<float> setProgress;
			Action<string> setMessage;
			CustomAsyncOperation operation = new CustomAsyncOperation(out setProgress, out setMessage);
			EditorProgressBar.DisplayProgressBar(operation, "PhysX Export");
			EditorCoroutine.StartCoroutine(ExportCurrentSceneRoutine(path, setProgress, setMessage));
			return operation;
		}

		[MenuItem("Tools/场景工具/cmd: 导出选中物理数据")]
		public static void ExportSelectedPhysXData()
		{
			foreach(var go in Selection.gameObjects)
			{
				ExportPhysXData(go);
			}
			Debug.Log("Complete");
		}

		public static void ExportPhysXData(GameObject go)
		{
			IntPtr collection = IntPtr.Zero;
			try
			{
				PhysXIDBuilder.Init();
				PhysXUtils.initPhysics();
				collection = PhysXUtils.createCollection();
				if(collection == IntPtr.Zero)
				{
					throw new Exception("Init Failed");
				}
			}
			catch(Exception e)
			{
				Debug.LogError(e.Message);
			}

			PhysXUtils.ExportPxRigidbody(collection, go);
			foreach(var it in PhysXObjCollector.CollectChildren(go.transform))
			{
				PhysXUtils.ExportPxRigidbody(collection, it);
			}

			try
			{
				PhysXUtils.complete(collection, IntPtr.Zero, false);
				string filename = outputPath + "/" + go.name.ToLower() + ".xml";
				Debug.Log(filename);
				PhysXUtils.serializeCollection(collection, IntPtr.Zero, Marshal.StringToHGlobalAnsi(filename), false);//bool: Is Binary
			}
			catch(Exception e)
			{
				Debug.LogError(e.Message);
			}
		}

		static IntPtr BeginExport()
		{
			IntPtr collection = IntPtr.Zero;
			PhysXUtils.initPhysics();
			collection = PhysXUtils.createCollection();
			if(collection == IntPtr.Zero)
			{
				throw new Exception("Initialization Failed");
			}
			return collection;
		}

		static void EndExport(IntPtr collection, string path, bool isBinary = false)
		{
			PhysXUtils.complete(collection, IntPtr.Zero, false);
			PhysXUtils.serializeCollection(collection, IntPtr.Zero, Marshal.StringToHGlobalAnsi(path), isBinary);
		}
	
		static IEnumerator ExportCurrentSceneRoutine(string path, Action<float> setProgress, Action<string> setMessage, bool isBinary = false)
		{
			

			setMessage("Start export");
			yield return null;
			Transform[] terrains = PhysXObjCollector.sceneTerrains;

			PhysXIDBuilder.Init();

			IntPtr collection;
			
			#region export water
			collection = BeginExport();

			GameObject sea = GameObject.CreatePrimitive(PrimitiveType.Cube);
			//sea.transform.position = new Vector3(2048f, 30f, 2048f);
			sea.transform.position = new Vector3(2048f, 2f, 2048f);
			sea.transform.localScale = new Vector3(4096f, 0.01f, 4096f);
			PhysXUtils.ExportPxRigidbody(collection, sea, ObjType.Sea);
			GameObject.DestroyImmediate(sea);

			EndExport(collection, path + "/Sea.xml", isBinary);
			#endregion

			#region Terrain Gounds
			/*collection = BeginExport();
			//GameObject terrainCollision = GameObject.Find("TerrainCollision_world01");
			GameObject terrainCollision = GameObject.Find("TerrainCollision_world02");
			foreach (var it in PhysXObjCollector.CollectChildren(terrainCollision.transform))
			{
				PhysXUtils.ExportPxRigidbody(collection, it, ObjType.Ground);
			}
			EndExport(collection, path + "/Ground.xml", isBinary);*/
			#endregion

			#region export terrains
			for (int i = 0; i < terrains.Length; ++i)
			{
				collection = BeginExport();
				MeshBuilder ground   = new MeshBuilder() { name = "Ground" };
				MeshBuilder building = new MeshBuilder() { name = "Building" };
				MeshBuilder adorning = new MeshBuilder() { name = "Adorning" };
				MeshBuilder rock     = new MeshBuilder() { name = "Rock" };
				MeshBuilder tree     = new MeshBuilder() { name = "Tree" };
				Transform terrain = terrains[i];
				string terrainID = terrain.gameObject.name;

				setMessage("Collecting " + terrain.gameObject.name);
				yield return null;
				
				setMessage("Collecting adorning in " + terrain.gameObject.name);
				yield return null;
				foreach (var it in PhysXObjCollector.CollectChildrenOfType(terrains[i], ObjType.Adorning))
				{
					if(!it.name.Contains("rock") && !it.name.Contains("stone"))
					{
						//PhysXUtils.ExportPxRigidbody(collection, it, ObjType.Adorning);
						adorning.Append(PhysXUtils.GetColliderMesh(it.gameObject));
					}
				}

				setProgress((i + 0.2f) / (terrains.Length + 1));
				setMessage("Collecting building in " + terrain.gameObject.name);
				yield return null;
				foreach (var it in PhysXObjCollector.CollectChildrenOfType(terrains[i], ObjType.Building))
				{
					//Debug.Log(it.name);
					//PhysXUtils.ExportPxRigidbody(collection, it, ObjType.Building);
					building.Append(PhysXUtils.GetColliderMesh(it.gameObject));
				}
				setProgress((i + 0.4f) / (terrains.Length + 1));
				setMessage("Collecting ground in " + terrain.gameObject.name);
				yield return null;
				if(terrain.gameObject.scene.name.Contains("Island"))//.name.EndsWith("Z0") || terrain.name.EndsWith("Z15"))
				{
					foreach (var it in PhysXObjCollector.CollectChildrenOfType(terrains[i], ObjType.Ground))
					{
						//Debug.Log(it.name);
						//PhysXUtils.ExportPxRigidbody(collection, it, ObjType.Ground);
						ground.Append(PhysXUtils.GetColliderMesh(it.gameObject));
					}
				}
				setProgress((i + 0.6f) / (terrains.Length + 1));
				setMessage("Collecting rock in " + terrain.gameObject.name);
				yield return null;
				foreach (var it in PhysXObjCollector.CollectChildrenOfType(terrains[i], ObjType.Rock))
				{
					if (it.name.Contains("rock") || it.name.Contains("stone") || it.name.Contains("mountain"))
					{
						//Debug.Log("rock" + it.name);
						//PhysXUtils.ExportPxRigidbody(collection, it, ObjType.Rock);
						rock.Append(PhysXUtils.GetColliderMesh(it.gameObject));
					}
				}
				setProgress((i + 0.8f) / (terrains.Length + 1));
				setMessage("Collecting tree in " + terrain.gameObject.name);
				yield return null;
				foreach (var it in PhysXObjCollector.CollectChildrenOfType(terrains[i], ObjType.Tree))
				{
					//Debug.Log(it.name);
					//PhysXUtils.ExportPxRigidbody(collection, it, ObjType.Tree);
					tree.Append(PhysXUtils.GetColliderMesh(it.gameObject));
				}
				setProgress((i + 1.0f) / (terrains.Length + 1));
				setMessage("Serializing binary : " + terrain.gameObject.name);
				yield return null;
				PhysXUtils.ExportPxRigidbody(collection, adorning, ObjType.Adorning);
				PhysXUtils.ExportPxRigidbody(collection, building, ObjType.Building);
				PhysXUtils.ExportPxRigidbody(collection, ground, ObjType.Ground);
				PhysXUtils.ExportPxRigidbody(collection, rock, ObjType.Rock);
				PhysXUtils.ExportPxRigidbody(collection, tree, ObjType.Tree);

				yield return null;

				string filename = path + "/" + terrain.gameObject.name.Replace("Terrain_", "").ToLower() + ".xml";
				EndExport(collection, filename, isBinary);
				yield return null;
			}
			#endregion
			setMessage("Finished");
			setProgress(1.0f);
			yield return null;
			EditorUtility.ClearProgressBar();
		}
	}
}