Shader "Custom/RaymarchedMetaballShader"
{
    Properties
    {
        [Header(Color)]
        _MainColor ("MainColor", color) = (1,1,1,1)
        _SpecularStrength ("SpecularStrength", range(0,1) ) = 0.5
        _Gloss ("Gloss", range(0,1) ) = 0.5
        
        [Header(Shadows)]
        _ShadowStrength ("ShadowStrength", range(0,1) ) = 0.5
        _ShadowPenumbra ("ShadowPenumbra", range(0,1) ) = 0.5
        
        [Header(Shape)]
        _Size ("Size", range(0,1) ) = 0.5
        _MaxDistance ("MaxDistance", range(0,1) ) = 0.5
        _BlendSmooth ("BlendSmooth", range(0,100) ) = 32
        _Speed ("Speed", range(0,10) ) = 0.5
        
        [Header(Fresnel)]
        _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
		_FresnelBias ("Fresnel Bias", Float) = 0
		_FresnelScale ("Fresnel Scale", Float) = 1
		_FresnelPower ("Fresnel Power", Float) = 1
        
        [Header(Quality)]
		[KeywordEnum(High, Default, Low)] _Quality ("Quality", Float) = 1
    }
    SubShader
    {
        Tags 
        {
            "RenderType"="Transparent" 
            "RenderQueue"="Transparent" 
        }
        
        Blend One One
        
        ZTest LEqual
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 clipPos : SV_POSITION;
                float4 wPos : TEXCOORD0;
                float3 oViewDir : TEXCOORD1;
            };

            // Shape
            float4 _Center;
            float _Size;
            float _MaxDistance;
            float _BlendSmooth;

            // Animation
            float _Speed;
            
            // Base Color
            float4 _MainColor;
            float _SpecularStrength;
            float _Gloss;
            
            // Fresnel
            float4 _FresnelColor;
            float _FresnelBias;
            float _FresnelScale;
            float _FresnelPower;

            float _Quality;
            

            struct Ray
            {
                float3 origin;
                float3 direction;
            };

            float sdf_sphere( float3 p, float3 center, float r )
            {
                return distance(p,center) - r;
            }

            float smin( float a, float b, float c, float d, float e, float k )
            {
                float res = exp2( -k*a ) + exp2( -k*b ) + exp2( -k*c ) + exp2( -k*d ) + exp2( -k*e );
                return -log2( res )/k;
            }
            
            float map(float3 p)
            {
                
                half upDownSphere = sdf_sphere(p, float3(0,sin(_Time.y*_Speed),0) * _MaxDistance/2, _Size*1.25 );
                half mediumSpinningSphere = sdf_sphere(p, float3(sin(_Time.y*_Speed*6),sin(_Time.y*_Speed*2),sin(_Time.y*_Speed*4)) * _MaxDistance, _Size*0.75 );
                half smallSpinningSphere = sdf_sphere(p, float3(sin(_Time.y*_Speed*3),sin(_Time.y*_Speed*4),sin(_Time.y*_Speed*2)) * _MaxDistance, _Size*0.5 );
                half smallSpinningSphere2 = sdf_sphere(p, float3(-sin(_Time.y*_Speed*5),sin(_Time.y*_Speed*5)*1.5,-sin(_Time.y*_Speed*5)) * _MaxDistance, _Size*0.4 );
                half smallSpinningSphere3 = sdf_sphere(p, float3(sin(_Time.y*_Speed*4),-sin(_Time.y*_Speed*4),-sin(_Time.y*_Speed)) * _MaxDistance, _Size*0.35 );
                
                return smin
                (
                    upDownSphere,
                    mediumSpinningSphere,
                    smallSpinningSphere,
                    smallSpinningSphere2,
                    smallSpinningSphere3,
                    _BlendSmooth
                );
            }

            float3 normal (float3 p)
            {
                const float eps = 0.01;

                return normalize
                (	float3
                    (	
                        map(p + float3(eps, 0, 0)	) - map(p - float3(eps, 0, 0)),
                        map(p + float3(0, eps, 0)	) - map(p - float3(0, eps, 0)),
                        map(p + float3(0, 0, eps)	) - map(p - float3(0, 0, eps))
                    )
                );
            }
            
            fixed4 lambertLight (fixed4 color, fixed3 normal, float3 viewDir )
            {
                fixed3 lightDir = _WorldSpaceLightPos0.xyz;
                
                fixed lambert = clamp(dot(normalize(normal), lightDir), 0.75,1);

                fixed3 diffuse = lambert;
                
                fixed3 h = normalize(lightDir - viewDir);
                
                fixed specular = dot(h, normalize(normal)) * (lambert > 0);
                half specularExponent = exp2(_Gloss * 6 + 1 ); 
                specular = pow(saturate(specular), specularExponent);
                specular = smoothstep(0.1,0.2,specular);
                specular *= _SpecularStrength;
                
                fixed4 base = fixed4(color.rgb * diffuse, color.a);
                fixed4 result = base + specular;
                
                return result;
            }

            fixed4 RayMarching(Ray ray, float3 oViewDir)
            {
                half MAX_STEP = 32;
                const half STEP = 0.01;

                switch (_Quality)
                {
                    case 0:
                        MAX_STEP = 512;
                        break;
                    case 1:
                        MAX_STEP = 256;
                        break;
                    case 2:
                        MAX_STEP = 32;
                        break;
                }

                ray.origin -= _Center.xyz;
                
                for(int i = 0; i < MAX_STEP; i++)
                {
                    float distance = map(ray.origin);
                    
                    if(distance < 0)
                    {
                        fixed3 N = normal(ray.origin);
                        fixed4 lambert = lambertLight(_MainColor, N, ray.direction);
                        float fresnelMask = saturate(1-(-_FresnelBias + _FresnelScale * pow(1 + dot(oViewDir, N), _FresnelPower)));
                        fixed4 fresnel = fresnelMask * _FresnelColor;
                        return lambert + fresnel;
                    }

                    ray.origin += STEP * ray.direction;
                }
                
                return 0;
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                o.oViewDir = normalize(ObjSpaceViewDir(v.vertex));

                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {                
                Ray ray;
                ray.origin = i.wPos;
                ray.direction = normalize(ray.origin - _WorldSpaceCameraPos);

                float4 result = RayMarching(ray, i.oViewDir);

                return result;
            }
            ENDCG
        }
    }
}
