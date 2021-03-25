using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace UnityPhysXExport
{
    /*public class ScenePhysXExportWnd : EditorWindow 
    {
        //[MenuItem("Window/PhysXExport/OpenWindow")]
        public static void OpenPhsyXExportWnd()
        {
            ScenePhysXExportWnd creator = (ScenePhysXExportWnd)EditorWindow.GetWindow(typeof(ScenePhysXExportWnd));
            creator.titleContent = new GUIContent("PhysXExport");
            creator.Show();
        }

        private Vector2 vs;
        void OnGUI()
        {
            List<string> scenePaths = new List<string>();
            foreach (UnityEditor.EditorBuildSettingsScene scene in UnityEditor.EditorBuildSettings.scenes)
            {
                if (scene.enabled)
                {
                    string scenePath = scene.path;
                    scenePaths.Add(scenePath);
                }
            }
            GUILayout.Space(20);
            EditorGUILayout.BeginHorizontal();
            GUILayout.Space(20);
            if(GUILayout.Button("Export All",GUILayout.Width(500)))
            {
                string outputPath = string.Empty;
                if (PlayerPrefs.HasKey("ScenePhysXExportPath") && !string.IsNullOrEmpty(PlayerPrefs.GetString("ScenePhysXExportPath")))
                {
                    outputPath = PlayerPrefs.GetString("ScenePhysXExportPath");
                }
                else
                {
                    outputPath = EditorUtility.SaveFolderPanel("Select Folder To Save", outputPath, "");
                    PlayerPrefs.SetString("ScenePhysXExportPath", outputPath);
                }
                for (int i=0;i<scenePaths.Count;i++)
                {
                    PhysXUtils.Export(scenePaths[i], outputPath);
                }
            }
            EditorGUILayout.EndHorizontal();
            GUILayout.Space(20);

            vs = EditorGUILayout.BeginScrollView(vs);
            for (int i = 0; i < scenePaths.Count; i++)
            {
                EditorGUILayout.BeginHorizontal();
                GUILayout.Space(20);
                if (GUILayout.Button("Export"))
                {
                    string outputPath = string.Empty;
                    if (PlayerPrefs.HasKey("ScenePhysXExportPath") && !string.IsNullOrEmpty(PlayerPrefs.GetString("ScenePhysXExportPath")))
                    {
                        outputPath = PlayerPrefs.GetString ("ScenePhysXExportPath");
                    }
                    else
                    {
                        outputPath = EditorUtility.SaveFolderPanel("Select Folder To Save", outputPath, "");
                        PlayerPrefs.SetString("ScenePhysXExportPath", outputPath);
                    }
                }
                EditorGUILayout.LabelField(i.ToString(), GUILayout.Width(60));
                EditorGUILayout.LabelField(scenePaths[i].Replace("Assets/", "").Replace(".unity", ""), GUILayout.Width(500));
                EditorGUILayout.EndHorizontal();
                GUILayout.Space(3);
            }
            EditorGUILayout.EndScrollView();
            GUILayout.Space(20);
        }
    }*/
}