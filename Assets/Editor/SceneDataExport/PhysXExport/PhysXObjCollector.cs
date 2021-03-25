using OmegaEditor.Coroutine;
using System;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityPhysXExport;
using CultureInfo = System.Globalization.CultureInfo;
using ObjType = UnityPhysXExport.PhysXIDBuilder.ObjType;
using System.Linq;
using OmegaEditor.Extension;

namespace UnityPhysXExport
{
	public class PhysXObjCollector
	{
		static Dictionary<ObjType, string> nodeRegex = new Dictionary<ObjType, string>()
		{
			[ObjType.Adorning] = "(OutDoors|OutDoors_Single|Outdoors|Outdoors_Single|Alpha|Adorning)",
			[ObjType.Building] = "(Building|Buildings)",
			[ObjType.Ground] = "(Ground|Grounds)",
			[ObjType.Rock] = "(OutDoor|OutDoors|Mountain|Mountains)",
			[ObjType.Tree] = "(Tree|Trees|Plant|Plants)"
		};
		public static Transform[] sceneTerrains
		{
			get
			{
				List<Transform> terrains = new List<Transform>();
				for (int i = 0; i < EditorSceneManager.sceneCount; ++i)
				{
					GameObject[] rootObjs = EditorSceneManager.GetSceneAt(i).GetRootGameObjects();
					foreach (var it in rootObjs)
					{
						if (
							(it.name.StartsWith("Terrain_") || it.name.StartsWith("Training")) 
							&& it.activeInHierarchy)
						{
							terrains.Add(it.transform);
						}
					}
				}
				return terrains.ToArray();
			}
		}

		public static IEnumerable<GameObject> CollectChildrenOfType(Transform terrainTsf, ObjType type = ObjType.Unknown)
		{
			string regex;
			if (!nodeRegex.TryGetValue(type, out regex))
				return Enumerable.Empty<GameObject>();
			return Enumerable.Range(0, terrainTsf.childCount)
				.Select(idx => terrainTsf.GetChild(idx).gameObject)
				.Where(go => Regex.IsMatch(go.name, regex, RegexOptions.IgnoreCase) && go.activeInHierarchy)
				.SelectMany(go => CollectChildren(go.transform));
		}

		public static IEnumerable<GameObject> CollectChildren(Transform rootTsf)
		{
			return Enumerable.Range(0, rootTsf.childCount)
				.Select(idx => rootTsf.GetChild(idx).gameObject)
				.Where(go => go.activeInHierarchy);
		}
	}
}