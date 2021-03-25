using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class TestPathFinding : MonoBehaviour
{
    [SerializeField]
    private TextAsset _targetNAVFile = null;
    [SerializeField]
    private Transform _targetTransform = null;
    private Transform _transform = null;
    private LinkedList<PointValue> _pathPoints = new LinkedList<PointValue>();
    // Use this for initialization
    private LineRenderer _lineRenderer = null;
    private void Start ()
    {
        _transform = gameObject.transform;
        if (_targetNAVFile)
        {
            NAVMeshSystem.BuildNAVFromMemoryData(0, _targetNAVFile.bytes);
        }
        GameObject go = new GameObject();
        go.hideFlags = HideFlags.HideAndDontSave;
        _lineRenderer = go.AddComponent<LineRenderer>();
        _lineRenderer.enabled = true;
        //_lineRenderer.enabled = false;
        //_lineRenderer = gameObject.GetComponent<LineRenderer>();
        if (_lineRenderer)
        {
            _lineRenderer.startWidth = 3.0f;
            _lineRenderer.endWidth = 3.0f;
        }        
    }
    private void OnDestroy()
    {
        if (_lineRenderer)
            GameObject.Destroy(_lineRenderer.gameObject);
    }

    // Update is called once per frame
    private void Update ()
    {
        //if (!Input.GetMouseButtonUp(0))
        //    return;
        //Camera testCamera = Camera.main;
        //if (!testCamera)
        //    return;
        //Ray ray = testCamera.ScreenPointToRay(Input.mousePosition);        
        //RaycastHit hit;
        //if (Physics.Raycast(ray, out hit, Mathf.Infinity))
        //{
        //    Vector3 position = _transform.position;
        //    PointValue startPoint = new PointValue(position.x, position.y, position.z);
        //    position = hit.point;
        //    PointValue endPoint = new PointValue(position.x, position.y, position.z);
        //    NAVMeshSystem.GetNAVPath(0, startPoint, endPoint, _pathPoints);
        //}

        if (_targetTransform)
        {
            Vector3 position = _transform.position;
            PointValue startPoint = new PointValue(position.x, position.y, position.z);
            //PointValue startPoint = new PointValue(position.x, 0.0f, position.z);
            position = _targetTransform.position;
            PointValue endPoint = new PointValue(position.x, position.y, position.z);
            //PointValue endPoint = new PointValue(position.x, 0.0f, position.z);
            if (!NAVMeshSystem.GetNAVPath(0, startPoint, endPoint, _pathPoints))
            {
                int akilar = 10;
                int count = _pathPoints.Count;
                akilar = 10;
            }
            else
            {
                int akilar = 10;
            }


            //    position = hit.point;
            //    PointValue endPoint = new PointValue(position.x, position.y, position.z);
            //    NAVMeshSystem.GetNAVPath(0, startPoint, endPoint, _pathPoints);

            var element = _pathPoints.GetEnumerator();
            while (element.MoveNext())
            {
                PointValue pointValue = element.Current;
                //Debug.LogFormat("Point:{0},{1},{2}", pointValue.x, pointValue.y, pointValue.z);
            }
            element.Dispose();
        }
        DrawPaths();
    }
    private void DrawPaths()
    {
        if ((!_transform) || (!_lineRenderer))
            return;
        _lineRenderer.positionCount = _pathPoints.Count + 1;
        _lineRenderer.enabled = _lineRenderer.positionCount > 1;

        if (!_lineRenderer.enabled)
            return;

        var element = _pathPoints.GetEnumerator();
        int index = 0;

        Vector3 to = _transform.position;
        to.y = 2.0f;
        _lineRenderer.SetPosition(index, to);
        PointValue currentPoint = new PointValue(0.0f, 0.0f, 0.0f);
        
        index = 1;
        while (element.MoveNext())
        {
            currentPoint = element.Current;
            to.x = currentPoint.x;
            to.y = currentPoint.y + 5.0f;
            to.z = currentPoint.z;
            _lineRenderer.SetPosition(index, to);
            ++index;
        }
        element.Dispose();
    }
}