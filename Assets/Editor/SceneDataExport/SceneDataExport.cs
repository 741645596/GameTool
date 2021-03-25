#if !UNITY_EDITOR_OSX
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Xml.Serialization;
using UnityEditor;
using UnityEditorInternal;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;
using UnityEngine;
using OmegaEditor.Coroutine;
using OmegaEditor.RecastNavigation;
using UnityPhysXExport;

namespace OmegaEditor
{
    public class SceneDataExport : EditorWindow
    {
        const string confPath = "Assets/Editor/SceneDataExport/SceneList.xml";
        static XmlSerializer serializer = new XmlSerializer(typeof(List<string>));
        [XmlElement("Scene")]
        static List<string> sceneList;
        static ReorderableList list;

        [MenuItem("Tools/场景工具/场景信息导出/设置")]
        static void OpenWindow()
        {
            GetWindow<SceneDataExport>().Show();
        }

        [MenuItem("Tools/场景工具/场景信息导出/导出")]
        static void StartExport()
        {
            EditorCoroutine.StartCoroutine(ExportRoutine());
        }

        private static IEnumerator ExportRoutine()
        {
            List<Scene> scenes = new List<Scene>(sceneList.Count);
            foreach(var scenePath in sceneList)
            {
                Scene scene = EditorSceneManager.GetSceneByPath(scenePath);
                if(!scene.isLoaded)
                {
                    scenes.Add(EditorSceneManager.OpenScene(scenePath, OpenSceneMode.Additive));
                }
            }
            CustomAsyncOperation operation = PhysXExport.ExportPhysXData();
            while (!operation.isDone)
                yield return null;
            RecastBuilder.RebuildRecastNAV();
            yield return null;
        }

        static SceneDataExport()
        {
            sceneList = new List<string>();
            if (File.Exists(confPath))
            {
                StreamReader sr = File.OpenText(confPath);
                sceneList = serializer.Deserialize(sr) as List<string>;
                sr.Close();
                sr.Dispose();
            }
        }

        public static IEnumerable<Scene> GetScenes()
        {
            foreach (var it in sceneList)
            {
                Scene scene = SceneManager.GetSceneByPath(it);
                if (scene != null)
                    yield return scene;
            }
        }

        private void OnEnable()
        {
            list = new ReorderableList(sceneList, typeof(string));
            list.drawElementCallback += DrawElement;
            list.onAddCallback += AddElement;
        }

        private void OnGUI()
        {
            list.DoLayoutList();
        }

        private void OnDisable()
        {
            FileStream fs = File.Open(confPath, FileMode.Create);
            StreamWriter sw = new StreamWriter(fs, Encoding.UTF8);
            XmlSerializerNamespaces ns = new XmlSerializerNamespaces();
            ns.Add("", "");
            serializer.Serialize(sw, sceneList, ns);
            sw.Flush();
            fs.Flush();
            sw.Close();
            fs.Close();
            sw.Dispose();
            fs.Dispose();
        }

        void DrawElement(Rect rect, int index, bool isActive, bool isFocused)
        {
            sceneList[index] = EditorGUI.TextField(rect, sceneList[index]);
        }

        void AddElement(ReorderableList list)
        {
            foreach(var scene in Selection.GetFiltered<SceneAsset>(SelectionMode.TopLevel | SelectionMode.Assets))
            {
                sceneList.Add(AssetDatabase.GetAssetPath(scene));
            }
        }
    }
}
#endif