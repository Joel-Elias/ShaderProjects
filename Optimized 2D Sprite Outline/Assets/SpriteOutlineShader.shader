Shader "Custom/SpriteOutlineShader"
{
    Properties
    {
        [Header(Outline)][Space]
        [Toggle] _UseOutline ("UseOutline", float ) = 0
        [KeywordEnum(Ultra, High, Normal, Low)] _OutlineQuality("Outline Quality", Float) = 0
        [Toggle] _FillBackground ("FillBackground", float ) = 0
        _OutlineColor ("OutlineColor", Color ) = (1,1,1,1)
        _OutlineWidth ("OutlineWidth", range(0,10)) = 2
        _OutlineSharpness ("OutlineSharpness", range(0.01,1)) = 0.15
        
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]
        
        Pass
        {
            Name "Default"

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            
            #include "UnityCG.cginc"

            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP
            
            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;
            
            int _UseOutline;
            int _OutlineQuality;
            half _FillBackground;
            fixed4 _OutlineColor;
            half _OutlineWidth;
            half _OutlineSharpness;

            v2f vert (appdata_t v)
            {
                v2f OUT;
                
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.vertex *= 1.5;

                OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                OUT.color = v.color * _Color;

                return OUT;
            }

            half GetCombinedAlpha(fixed2 uv)
            {
                half result = 0;
                int quality;
                
                switch (_OutlineQuality)
                {
                    case 0:
                        quality = 360;
                        break;
                    case 1:
                        quality = 180;
                        break;
                    case 2:
                        quality = 90;
                        break;
                    case 3:
                        quality = 45;
                        break;
                    default:
                        quality = 45;
                        break;
                }
                
                for (int i = 0; i < quality; i++)
                {
                    half width = _OutlineWidth * 0.01;
                    fixed2 sUV = uv + fixed2(cos(i), sin(i)) * width;
                    result = max(result, tex2D(_MainTex,sUV).a);
                }
                return result;
            }

            fixed4 GetOutline(v2f i)
            {
                fixed4 main = tex2D(_MainTex, i.texcoord);
                
                half combinedMask = GetCombinedAlpha(i.texcoord);
                
                fixed3 rgb;
                half a;

                half sharpness = clamp(_OutlineSharpness,0,.99);
                
                half smoothMain = smoothstep(sharpness, 1, main.a);
                half smoohtMask = smoothstep(sharpness, 1, combinedMask);
                
                half outlineMask = smoohtMask - smoothMain;
                half reverseOutline = 1-outlineMask;

                main *= i.color;

                if(!_FillBackground)
                {
                    rgb = lerp(_OutlineColor.rgb, main.rgb, reverseOutline);
                    a = lerp(outlineMask*_OutlineColor.a, main.a, reverseOutline * i.color.a * combinedMask);
                }
                else
                {
                    rgb = lerp(_OutlineColor.rgb, main.rgb*i.color.a, reverseOutline * i.color.a);
                    a = lerp(combinedMask*_OutlineColor.a, main.a,  reverseOutline * i.color.a);
                }

                fixed4 result = fixed4(rgb, a);; 
                
                return result;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.texcoord) + _TextureSampleAdd;

                #ifdef UNITY_UI_ALPHACLIP
                clip (col.a - 0.001);
                #endif
                
                if(_UseOutline)
                {
                    return GetOutline(i);
                }
                
                return col * i.color;
            }
            ENDCG
        }

    }
}
