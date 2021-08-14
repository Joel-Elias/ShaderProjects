#region
using UnityEngine;
#endregion

[RequireComponent( typeof( MeshRenderer ) )]
public class RaymarchedMetaballController : MonoBehaviour {

    [SerializeField] private MeshRenderer rend;

    private void Awake() {
        rend.material = new Material( rend.material );
    }

    private void Update() {
        rend.material.SetVector( "_Center", transform.position );
    }

}