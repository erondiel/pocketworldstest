Shader "PropHunt/GodrayUnlit"
{
    Properties
    {
        _Color("Tint", Color) = (1,1,1,1)
        _Intensity("Intensity", Range(0,5)) = 1
        _Softness("Edge Softness", Range(0.5,5)) = 1
        _BeamWidth("Beam Width", Range(0.01,0.5)) = 0.12
        _BeamCount("Beam Count", Range(1,10)) = 1
        _BeamSpacing("Beam Spacing", Range(0,0.5)) = 0.1
        _LengthFade("Length Fade", Range(0,4)) = 1.5
        _TipFade("Tip Fade", Range(0,2)) = 0.5
        _BaseFade("Base Fade", Range(0,2)) = 0.5
        _UOffset("U Offset", Range(-1,1)) = 0
        _VOffset("V Offset", Range(-1,1)) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
        }

        Blend One One
        Cull Off
        ZWrite Off

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float4 _Color;
            float _Intensity;
            float _Softness;
            float _BeamWidth;
            float _BeamCount;
            float _BeamSpacing;
            float _LengthFade;
            float _TipFade;
            float _BaseFade;
            float _UOffset;
            float _VOffset;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_INSTANCING_BUFFER_END(Props)

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float3 posWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(posWS);
                output.uv = input.uv;

                return output;
            }

            #define MAX_BEAMS 10

            float WidthMask(float x, float width, float count, float beamSpacing, float softness)
            {
                int beamCount = (int)floor(count + 0.5f);
                beamCount = max(beamCount, 1);

                float halfWidth = max(width, 0.001f);
                float spacing = max(beamSpacing, 0.0f);

                float centeredX = x - 0.5f;
                float totalSpan = spacing * (beamCount - 1);
                float centerOffset = totalSpan * 0.5f;

                float minDist = 10.0f;
                [unroll]
                for (int i = 0; i < MAX_BEAMS; ++i)
                {
                    if (i >= beamCount) break;
                    float center = (i * spacing) - centerOffset;
                    float dist = abs(centeredX - center);
                    minDist = min(minDist, dist);
                }

                float mask = saturate(1.0f - (minDist / halfWidth));
                return pow(mask, max(softness, 0.001f));
            }

            float LengthMask(float y, float lengthFade, float tipFade)
            {
                // y=0 at bottom, y=1 at top of plane (beam tip)
                float startFade = saturate(y * lengthFade);
                float tip = saturate(1.0f - (1.0f - y) * tipFade);
                // Opposite-side fade (towards the tip end)
                float baseEdge = saturate(1.0f - y * _BaseFade);
                return startFade * tip * baseEdge;
            }

            float4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 uv = input.uv + float2(_UOffset, _VOffset);

                // Beam masks: width across X, length along Y
                float widthMask = WidthMask(uv.x, _BeamWidth, _BeamCount, _BeamSpacing, _Softness);
                float lengthMask = LengthMask(uv.y, _LengthFade, _TipFade);

                float intensity = saturate(widthMask * lengthMask) * _Intensity;

                float3 rgb = _Color.rgb * intensity;
                float alpha = saturate(intensity * _Color.a);
                return float4(rgb, alpha);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
