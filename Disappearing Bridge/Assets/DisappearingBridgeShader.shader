Shader "Unlit/DisappearingBridgeShader"
{
    Properties
    {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        [PreRendererData] [HideInInspector] _Color ("Color", color) = (1,1,1,1)
        [PreRendererData] [HideInInspector] _Position ("Position", float) = 0

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderQueue"="Transparent" }
        LOD 100

        Blend One OneMinusSrcAlpha
        
        ZTest LEQual
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Color;
            float _Position;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                // o.vertex.xyz *= UNITY_ACCESS_INSTANCED_PROP(Props, _Moved);
                //
                // #if DOWN_ON
                // o.vertex.xyz += _Speed-UNITY_DEFINE_INSTANCED_PROP(Props, _Moved * _Speed);
                // #else
                // o.vertex.xyz -= _Speed-UNITY_DEFINE_INSTANCED_PROP(Props, _Moved * _Speed);
                // #endif

                o.vertex.y += _Position;
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                // fixed4 col = tex2D(_MainTex, i.uv);
                return _Color;
            }
            ENDCG
        }
    }
}
