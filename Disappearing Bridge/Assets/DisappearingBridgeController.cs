#region
using System.Collections.Generic;
using UnityEngine;
#endregion

public class DisappearingBridgeController : MonoBehaviour {

    [SerializeField] private Transform target;
    [SerializeField] private Vector3 targetOffset;
    [SerializeField] private List<MeshRenderer> renderers;
    [Space]
    [SerializeField] private Color colorA;
    [SerializeField] private Color colorB;

    private MaterialPropertyBlock _properties;

    private void Awake() {
        _properties = new MaterialPropertyBlock();
    }

    private void Update() {
        foreach ( var renderer in renderers ) {
            renderer.GetPropertyBlock( _properties );

            var offset = renderer.transform.position - (target.position + targetOffset);

            var t = offset.magnitude;

            _properties.SetFloat( "_Position", t );
            _properties.SetColor( "_Color", Color.Lerp( colorA, colorB, t ) );

            renderer.SetPropertyBlock( _properties );
        }
    }

}