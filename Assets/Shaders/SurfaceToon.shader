Shader "GT01/SurfaceToon"
{
    Properties
    {
        _ID("Stencil ID", Int) = 1
        [Space][Space]
        _Color ("Color", Color) = (1,1,1,1)
        [Space][Space]
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _LightingRamp("Lighting Ramp", 2D) = "white" {}
        
        [Space][Space]
        _Antialiasing("Antialiasing", Range(0,10)) = 5.0
        _Glossiness("Glossiness", Range(0,5)) = 1
        _Brightness("Brightness", Range(0.1,1)) = 0.7
        
        [Space][Space]
        _OutlineSize("Outline Size", Range(0.001,0.03)) = 0.01
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
        
        [Space][Space]
        _Fresnel("Fresnel", Range(0, 1)) = 0.5

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Stencil
        {
            Ref [_ID]
            Comp always
            Pass replace
            Fail keep
            ZFail keep
        }

        CGPROGRAM

        #pragma surface surf Cel

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _BumpMap;
        sampler2D _LightingRamp;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
        };

        half _Metallic;
        fixed4 _Color;
        float _Antialiasing;
        float _Glossiness;
        float _Brightness;
        float _Fresnel;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        half4 LightingCel(SurfaceOutput surface, half3 lightDir,half3 viewDir, half atten)
        {
            float3 normal = normalize(surface.Normal);
            float3 halfVec = normalize(lightDir + viewDir);
            float3 specular = dot(normal,halfVec);
            float diffuse = dot(normal,lightDir);

            // //Look for change in color
            // float delta = fwidth(diffuse) * _Antialiasing;
            // //Smoothing the shadow lines
            // float diffuseSmooth = smoothstep(0,delta,diffuse);

            float3 diffuseSmooth = tex2D(_LightingRamp,float2(diffuse * 0.5 + 0.5, 0.5));
            specular = pow(specular * diffuseSmooth,_Glossiness * 400);
            float specularSmooth = smoothstep(0,0.01 * _Antialiasing,specular);
            
            float rim = 1 - dot (normal,viewDir);
            rim = rim * diffuse;

            float fresnelSize = 1 - _Fresnel;

            float rimSmooth = smoothstep(fresnelSize, fresnelSize * 1.1, rim);
            
            float3 col = surface.Albedo * ((diffuseSmooth + specularSmooth + rimSmooth) * _LightColor0 + unity_AmbientSky);
            return float4(col, surface.Alpha);
        }

        void surf (Input input, inout SurfaceOutput output)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, input.uv_MainTex) * _Color;
            output.Albedo = c.rgb * _Brightness;
            output.Normal = UnpackNormal(tex2D(_BumpMap, input.uv_BumpMap));

            
            output.Alpha = c.a;
        }
        ENDCG

        Pass
        {
            Cull Front
            ZWrite Off
            ZTest on

            Stencil
			{
				Ref 1
				Comp notequal
				Fail keep
				Pass replace
			}


            CGPROGRAM
            #pragma vertex vertex
            #pragma fragment fragment

            #include "UnityCG.cginc"
            
            float _OutlineSize;
            float4 _OutlineColor;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f 
            {
                float4 vertex : SV_POSITION;
            };

            v2f vertex(appdata vertex)
            {
                v2f output;
                float3 normal = normalize(vertex.normal) * _OutlineSize;
                float3 position = vertex.vertex + normal;

                output.vertex = UnityObjectToClipPos(position);

                return output;
            }

            float4 fragment(v2f input) : SV_TARGET
            {
                return _OutlineColor;
            }



            ENDCG
        }
    }
    FallBack "Diffuse"
}
