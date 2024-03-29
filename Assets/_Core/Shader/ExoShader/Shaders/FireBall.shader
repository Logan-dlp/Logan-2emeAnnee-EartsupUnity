Shader "ExoShader/FireBall"
{
    // The properties block of the Unity shader. In this example this block is empty
    // because the output color is predefined in the fragment shader code.
    Properties
    { 
        [MainTexture] _MainTex("Main Texture", 2D) = "white" {}
        [HDR] _FireColor1("Fire Color 1", Color) = (1, 0, 0, 1)
        [HDR] _FireColor2("Fire Color 2", Color) = (1, 1, 0, 1)
        [HDR] _RimColor("Rim Color", Color) = (1, 1, 0, 1)
        _FresnelPower("Fresnel Power", Range(0, 10)) = 2.13
    }

    // The SubShader block containing the Shader code.
    SubShader
    {
        // SubShader Tags define when and under which conditions a SubShader block or
        // a pass is executed.
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            // The HLSL code block. Unity SRP uses the HLSL language.
            HLSLPROGRAM
            // This line defines the name of the vertex shader.
            #pragma vertex vert
            // This line defines the name of the fragment shader.
            #pragma fragment frag

            // The Core.hlsl file contains definitions of frequently used HLSL
            // macros and functions, and also contains #include references to other
            // HLSL files (for example, Common.hlsl, SpaceTransforms.hlsl, etc.).
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // The structure definition defines which variables it contains.
            // This example uses the Attributes structure as an input structure in
            // the vertex shader.
            struct Attributes
            {
                // The positionOS variable contains the vertex positions in object
                // space.
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                half3 normal        : NORMAL;
            };

            struct Varyings
            {
                // The positions in this struct must have the SV_POSITION semantic.
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : WS_POSITION;
                float2 uv           : TEXCOORD0;
                half3 normal        : NORMAL;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                half4 _MainTex_ST;
                half4 _FireColor1;
                half4 _FireColor2;
                half4 _RimColor;
                float _FresnelPower;
            CBUFFER_END

            // The vertex shader definition with properties defined in the Varyings
            // structure. The type of the vert function must match the type (struct)
            // that it returns.
            Varyings vert(Attributes IN)
            {
                // Declaring the output object (OUT) with the Varyings struct.
                Varyings OUT;
                // The TransformObjectToHClip function transforms vertex positions
                // from object space to homogenous clip space.
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // Returning the output.

                OUT.positionWS = TransformObjectToWorld(IN.positionOS);

                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                OUT.normal = IN.normal;
                
                return OUT;
            }

            // The fragment shader definition.
            half4 frag(Varyings IN) : SV_Target
            {
                half4 textureColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + float2(0, 1) * _Time.x);
                textureColor = lerp(_FireColor1, _FireColor2, textureColor);

                float3 viewDirection = GetCameraPositionWS() - IN.positionWS;
                float fresnel = pow(saturate(dot(normalize(IN.normal), normalize(viewDirection))), _FresnelPower);
                half4 fresnelColor = _RimColor + (1 - fresnel);
                
                return fresnelColor * textureColor;
            }
            ENDHLSL
        }
    }
}