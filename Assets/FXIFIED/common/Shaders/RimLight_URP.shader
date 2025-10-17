Shader "FXIFIED/RimLight_URP"
{
    Properties
    {
        _ASEOutlineColor("Outline Color", Color) = (0,0,0,0)
        _ASEOutlineWidth("Outline Width", Float) = 0
        _RimColor("RimColor", Color) = (0,0,0,0)
        _RimPower("RimPower", Range(0, 10)) = 0
        [HideInInspector]_Normals("Normals", 2D) = "bump" {}
        _MainTex("MainTex", 2D) = "white" {}
        _ColorIntensity("Color Intensity", Float) = 1
        _Color("Color", Color) = (1,1,1,0)
        [HideInInspector] _texcoord("", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }
        
        LOD 100

        // Outline Pass
        Pass
        {
            Name "Outline"
            Tags { "LightMode" = "SRPDefaultUnlit" }
            
            Cull Front
            ZWrite On
            ZTest LEqual
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            
            // URP compatibility keywords
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                half4 _ASEOutlineColor;
                half _ASEOutlineWidth;
            CBUFFER_END
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                // Outline expansion
                float3 positionOS = input.positionOS.xyz + input.normalOS * _ASEOutlineWidth;
                output.positionCS = TransformObjectToHClip(positionOS);
                
                return output;
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                return half4(_ASEOutlineColor.rgb, 1.0);
            }
            ENDHLSL
        }

        // Main Pass
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            ZWrite On
            ZTest LEqual
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            
            // URP compatibility keywords - matching URP Lit shader order
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile _ _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile _ _LIGHT_COOKIES
            #pragma multi_compile _ _WRITE_RENDERING_LAYERS
            #pragma multi_compile _ _DEBUG_DISPLAY
            #pragma multi_compile _ _SURFACE_TYPE_TRANSPARENT
            #pragma multi_compile _ _ALPHATEST_ON
            #pragma multi_compile _ _ALPHAPREMULTIPLY_ON
            #pragma multi_compile _ _ALPHAMODULATE_ON
            #pragma multi_compile _ _EMISSION
            #pragma multi_compile _ _METALLICSPECGLOSSMAP
            #pragma multi_compile _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma multi_compile _ _OCCLUSIONMAP
            #pragma multi_compile _ _SPECULARHIGHLIGHTS_OFF
            #pragma multi_compile _ _ENVIRONMENTREFLECTIONS_OFF
            #pragma multi_compile _ _SPECULAR_SETUP
            #pragma multi_compile _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma multi_compile _ _RENDER_PASS_ENABLED
            #pragma multi_compile _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile _ _EDITOR_VISUALIZATION
            #pragma multi_compile _ _SPECGLOSSMAP
            #pragma multi_compile _ _ADD_PRECOMPUTED_VELOCITY
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                half4 _RimColor;
                half _RimPower;
                half4 _MainTex_ST;
                half4 _Normals_ST;
                half _ColorIntensity;
                half4 _Color;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_Normals);
            SAMPLER(sampler_Normals);
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float4 color : COLOR;
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                output.positionCS = positionInputs.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.normalWS = normalInputs.normalWS;
                output.viewDirWS = GetWorldSpaceViewDir(positionInputs.positionWS);
                output.color = input.color;
                
                return output;
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                // Sample textures
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_Normals, sampler_Normals, input.uv));
                
                // Convert normal to world space
                float3 bitangentWS = cross(input.normalWS, float3(1,0,0)) * (input.normalWS.x > 0.5 ? 1 : -1);
                float3 tangentWS = cross(bitangentWS, input.normalWS);
                float3x3 tangentToWorld = float3x3(tangentWS, bitangentWS, input.normalWS);
                half3 normalWS = normalize(mul(normalTS, tangentToWorld));
                
                // Calculate rim lighting
                half3 viewDir = normalize(input.viewDirWS);
                half NdotV = saturate(dot(normalWS, viewDir));
                half rim = pow(1.0 - NdotV, _RimPower);
                
                // Combine albedo and rim
                half3 albedo = _ColorIntensity * mainTex.rgb * _Color.rgb * input.color.rgb;
                half3 emission = rim * _RimColor.rgb;
                
                return half4(albedo + emission, 1.0);
            }
            ENDHLSL
        }
    }
    
    Fallback "Universal Render Pipeline/Lit"
}
