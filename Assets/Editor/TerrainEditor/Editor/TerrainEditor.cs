using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEngine.SceneManagement;
using UnityEditor.SceneManagement;

namespace OmegaEditor.TerrainEditor
{
    public class TerrainEditor : EditorWindow
    {
        protected static TerrainEditorTarget target = new TerrainEditorTarget();

        protected Material painterMat;
        protected static CustomRenderTexture m_renderTarget;
        public CustomRenderTexture renderTarget
        {
            get => m_renderTarget;
            set
            {
                if (value == m_renderTarget)
                    return;
                if (value != null)
                {
                    if(m_renderTarget != null)
                    {
                        m_renderTarget.Release();
                        Object.DestroyImmediate(m_renderTarget);
                    }
                    m_renderTarget = value;
                    m_renderTarget.doubleBuffered = true;
                    m_renderTarget.material = painterMat;
                }
            }
        }

        #region Material_Properties
        private static Vector2Int m_size = new Vector2Int(4, 4);
        protected Vector2Int size
        {
            get => m_size;
            set
            {
                m_size.x = Mathf.Max(value.x, 1);
                m_size.y = Mathf.Max(value.y, 1);
            }
        }
        protected int row => size.x;
        protected int col => size.y;
        #endregion //Material_Properties

        #region Brush_Properties
        protected static AnimationCurve m_brushCurve;
        protected AnimationCurve brushCurve
        {
            get => m_brushCurve;
            set
            {
                m_brushCurve = value;
                if (m_brushCurve != null)
                    brush.Update(m_brushCurve);
                painterMat.SetTexture("_Brush", brush);
            }
        }
        private static RampMap m_brush;
        protected RampMap brush
        {
            get
            {
                if (m_brush == null)
                    m_brush = new RampMap(brushCurve, 512);
                return m_brush;
            }
        }
        protected static float brushSize = 0.2f;
        protected static float density = 1.0f;
        static protected Texture2D m_atlasPanelTex;
        protected Texture atlasPanelTex
        {
            get 
            {
                if(!m_atlasPanelTex)
                {
                    if(target == null)
                        Debug.Log("Null Target");
                    if(target.material == null)
                        Debug.Log("Null Material");
                    m_atlasPanelTex = target.material.GetTexture("_MainTex") as Texture2D;
                }
                return m_atlasPanelTex;
            }
        }
        #endregion //Brush_Properties

        private float EncodeIndex(int index)
        {
            int r = index / size.x;
            int c = index % size.y;
            r = row - r - 1;
            int idx = r * col + c;
            return (idx + 0.5f) / (row * col);
        }

        public static Shader terrainShader
        {
            get;
            protected set;
        }
        public static Shader brushShader
        {
            get;
            protected set;
        }

        public static Shader painterShader
        {
            get;
            protected set;
        }

        #region Editor_Properties
        bool showDebugInfo = false;
        Vector2 scrollPos;
        Vector2 cursorBuffer = Vector2.zero;
        int m_selected;
        int selected
        {
            get => m_selected;
            set
            {
                if (m_selected == value)
                    return;
                prevSelected = m_selected;
                m_selected = value;
            }
        }
        int prevSelected;
        bool m_hardBrush = false;
        bool hardBrush
        {
            get => m_hardBrush;
            set
            {
                if (m_hardBrush == value)
                    return;
                m_hardBrush = value;
                painterMat.SetFloat("_Mode", m_hardBrush ? 1 : 0);
            }
        }
        #endregion //Editor_Properties

        protected void OnEnable()
        {
            terrainShader = Shader.Find("Omega/Env/Terrain_NormalSpec_Array");
            brushShader = Shader.Find("Hidden/Brush");
            painterShader = Shader.Find("CustomRenderTexture/TerrainPainter");

            painterMat = new Material(painterShader);
            if (brushCurve == null)
                brushCurve = new AnimationCurve();
            if (renderTarget != null)
                renderTarget.material = painterMat;
            //SceneView.onSceneGUIDelegate += OnSceneGUI;
            SceneView.duringSceneGui += OnSceneGUI;
            if (target.gameObject != null)
            {
                BeginEdit();
            }
            target.onTargetChanged += BeginEdit;
            EditorSceneManager.sceneOpened += OnSceneOpened;
        }

        protected void OnDisable()
        {
            //SceneView.onSceneGUIDelegate -= OnSceneGUI;
            SceneView.duringSceneGui -= OnSceneGUI;
            if (renderTarget != null)
            {
                SaveOrDiscard();
            }
            EndEdit();
            EditorSceneManager.sceneOpened -= OnSceneOpened;
        }

        protected void OnSceneGUI(SceneView scene)
        {
            if (renderTarget == null)
                return;
            Event e = Event.current;
            if (e.alt)
                return;
            HandleUtility.AddDefaultControl(GUIUtility.GetControlID(FocusType.Passive));
            Vector2 mousePos = Event.current.mousePosition;
            Ray ray = HandleUtility.GUIPointToWorldRay(mousePos);
            RaycastHit[] hitInfo = Physics.RaycastAll(ray);
            foreach (var hit in hitInfo)
            {
                if (hit.collider != target.collider)
                    continue;
                
                if (e.isMouse && e.button == 0 &&
                    (e.type == EventType.MouseDown || e.type == EventType.MouseDrag))
                {
                    UpdateRT(hit.textureCoord);
                }
                else
                {
                    cursorBuffer = hit.textureCoord;
                }
                UpdateBrushMat(hit.textureCoord);
                scene.Repaint();
            }
            HandleUtility.GUIPointToWorldRay(Event.current.mousePosition);
        }

        protected void UpdateRT(Vector2 cursor)
        {
            painterMat.SetVector("_Prev_Cursor", cursorBuffer);
            cursorBuffer = cursor;
            painterMat.SetVector("_Current_Cursor", cursorBuffer);

            painterMat.SetFloat("_Scale", brushSize);
            painterMat.SetFloat("_Density", density);
            float idx = EncodeIndex(selected);
            float prevIdx = EncodeIndex(prevSelected);
            painterMat.SetFloat("_Idx", idx);
            painterMat.SetFloat("_IdxFG", idx);
            painterMat.SetFloat("_IdxBG", prevIdx);
            renderTarget.Update();
            this.Repaint();
        }

        protected void UpdateBrushMat(Vector2 cursor)
        {
            target.brush     = brush;
            target.cursor    = cursor;
            target.brushSize = brushSize;
            target.density   = density;
        }

        public void SaveOrDiscard()
        {
            bool save = EditorUtility.DisplayDialog("Warning", "Save texture?", "Save", "Discard");
            if (save)
            {
                string assetPath = Save();
                target.srcSplat = AssetDatabase.LoadAssetAtPath<Texture2D>(assetPath);
            }
        }

        public string Save()
        {
            int width = renderTarget.width;
            int height = renderTarget.height;

            Texture2D tex = new Texture2D(width, height, TextureFormat.RGBA32, false);

            Graphics.SetRenderTarget(renderTarget);
            tex.ReadPixels(new Rect(0, 0, width, height), 0, 0);
            tex.Apply();

            byte[] bytes = tex.EncodeToTGA();

            DestroyImmediate(tex);

            string assetPath;
            if (target.srcSplat == null)
            {
                assetPath = EditorUtility.SaveFilePanel(
                    "Save Custom Render Texture",
                    "Assets",
                    "Splat_" + target.material.name,
                    "tga");
            }
            else
            {
                assetPath = AssetDatabase.GetAssetPath(target.srcSplat);
                assetPath = Application.dataPath + assetPath.Replace("Assets", "");
            }
            if (!string.IsNullOrEmpty(assetPath))
            {
                using (FileStream fs = File.Create(assetPath))
                {
                    fs.Write(bytes, 0, bytes.Length);
                    fs.Flush();
                    fs.Close();
                }
                AssetDatabase.Refresh();
            }
            assetPath = "Assets" + assetPath.Replace(Application.dataPath, "");
            TextureImporter importSettings = AssetImporter.GetAtPath(assetPath) as TextureImporter;
            importSettings.filterMode = FilterMode.Bilinear;
            importSettings.mipmapEnabled = false;
            importSettings.textureCompression = TextureImporterCompression.Uncompressed;
            importSettings.SaveAndReimport();
            return assetPath;
        }

        protected void BeginEdit()
        {
            int width = target.srcSplat.width;
            int height = target.srcSplat.height; 
            renderTarget = new CustomRenderTexture(
                width,
                height,
                RenderTextureFormat.ARGB32)
            {
                dimension = TextureDimension.Tex2D,
                wrapMode = TextureWrapMode.Clamp,
                filterMode = FilterMode.Bilinear,
                initializationMode = CustomRenderTextureUpdateMode.OnDemand,
                initializationSource = CustomRenderTextureInitializationSource.TextureAndColor,
                initializationTexture = target.srcSplat,
                initializationColor = target.srcSplat == null ? Color.black : Color.white,
                updateMode = CustomRenderTextureUpdateMode.OnDemand,
                doubleBuffered = true,
            };
            renderTarget.Initialize();
            MeshCollider collider = target.gameObject.AddComponent<MeshCollider>();
            collider.sharedMesh = target.gameObject.GetComponent<MeshFilter>().sharedMesh;
            target.collider = collider;
            target.material.shader = brushShader;
            target.splat = renderTarget;
        }

        protected void EndEdit()
        {
            target.collider = null;
            target.shader = terrainShader;
            target.splat = target.srcSplat;
        }

        protected void OnSceneOpened(Scene scene, OpenSceneMode mode)
        {
            m_brush = new RampMap(brushCurve, 512);
            painterMat = new Material(painterShader);
        }

        [MenuItem("Tools/Terrain Editer")]
        public static void Entry()
        {
            GetWindow<TerrainEditor>("Terrain Editor").Show(true);
        }

        protected void OnGUI()
        {
            scrollPos = EditorGUILayout.BeginScrollView(scrollPos);

            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button("Save"))
            {
                Save();
            }

            if (GUILayout.Button("Discard"))
            {
                if (renderTarget != null)
                    renderTarget.Initialize();
            }

            EditorGUILayout.EndHorizontal();

            target.gameObject = EditorGUILayout.ObjectField(target.gameObject, typeof(GameObject), true) as GameObject;

            //renderTarget = EditorGUILayout.ObjectField(renderTarget, typeof(CustomRenderTexture), true) as CustomRenderTexture;
            //target.material = EditorGUILayout.ObjectField(targetMat, typeof(Material), false) as Material;
            //targetCollider = EditorGUILayout.ObjectField(targetCollider, typeof(Collider), true) as Collider;

            EditorGUILayout.BeginHorizontal();
            BrushSettingLayout();
            AtlasSettingLayout();
            EditorGUILayout.EndHorizontal();
            AtlasSelectionLayout();
            DebugInfoLayout();

            EditorGUILayout.EndScrollView();
        }

        protected void BrushSettingLayout()
        {
            float width = position.width / 2f;
            EditorGUILayout.BeginVertical();

            EditorGUILayout.LabelField("Brush");

            EditorGUILayout.BeginHorizontal(GUILayout.Width(width));

            Rect rectRampMap = GUILayoutUtility.GetRect(50, 50);
            brushCurve = EditorGUI.CurveField(rectRampMap, brushCurve);
            GUI.DrawTexture(rectRampMap, brush, ScaleMode.StretchToFill);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.LabelField("Size");
            brushSize = EditorGUILayout.Slider(brushSize, 0, 0.2f, GUILayout.Width(width));

            EditorGUILayout.LabelField("Density");
            density = EditorGUILayout.Slider(density, 0, 1, GUILayout.Width(width));

            hardBrush = EditorGUILayout.Toggle("HardBrush", hardBrush);

            EditorGUILayout.EndVertical();
        }

        protected void AtlasSettingLayout()
        {
            EditorGUILayout.BeginVertical();

            EditorGUILayout.LabelField("Atlas");

            EditorGUILayout.BeginHorizontal();

            EditorGUILayout.BeginVertical(GUILayout.Width(50));
            EditorGUILayout.LabelField("Albedo", GUILayout.Width(50));
            target.albedo = EditorGUILayout.ObjectField(
                target.albedo, typeof(Texture2DArray), false,
                GUILayout.Width(50),
                GUILayout.Height(50)) as Texture2DArray;
            EditorGUILayout.EndVertical();

            EditorGUILayout.BeginVertical(GUILayout.Width(50));
            EditorGUILayout.LabelField("Bump", GUILayout.Width(50));
            target.bump = EditorGUILayout.ObjectField(
                target.bump, typeof(Texture2DArray), false,
                GUILayout.Width(50),
                GUILayout.Height(50)) as Texture2DArray;
            EditorGUILayout.EndVertical();

            EditorGUILayout.EndHorizontal();

            //size = EditorGUILayout.Vector2IntField("Count", size);

            EditorGUILayout.EndVertical();
        }

        protected void AtlasSelectionLayout()
        {
            Rect rect = GUILayoutUtility.GetRect(position.width, position.width);
            GUI.Box(rect, atlasPanelTex);
            GUI.color = new Color(1, 1, 1, 0.2f);
            selected = GUI.SelectionGrid(rect, selected, new string[row * col], col);
            GUI.color = Color.white;
        }

        protected void DebugInfoLayout()
        {
            showDebugInfo = EditorGUILayout.Foldout(showDebugInfo, "DebugInfo");
            if (showDebugInfo && renderTarget != null)
            {
                Rect rect = GUILayoutUtility.GetRect(position.width, position.width);
                Graphics.DrawTexture(rect, renderTarget);
            }
            EditorGUILayout.ObjectField(atlasPanelTex, typeof(Texture2D), false);
        }
    }
}