#region
using UnityEngine;
#endregion

public class TargetMover : MonoBehaviour {

    [SerializeField] private float speed;

    private void Update() {
        var pos = transform.position;
        pos.x = Mathf.Lerp( -5.5f, 1.5f, Mathf.Sin( Time.time * speed ) * 0.5f + 0.5f );
        transform.position = pos;
    }

}