Shader "Snowy/DissolveShader"
{
    Properties
    {
        [MainTexture] _BaseMap ("Albedo(RGB)", 2D) = "white" {}
        [MainColor]   _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        
    	
    	[NoScaleOffset] _MetallicGlossMap ("Metallic(B) Roughness(G)", 2D) = "white" {}
        _Metallic ("Metallic", Range(0.0, 1.0)) = 1
        
        _Roughness ("Roughness", Range(0.0, 1.0)) = 0.5
    	
	    _Reflectance ("Reflectance", Range(0.0, 1.0)) = 0.5
        
    	
    	[Space(20)]
    	[Toggle(_DISSOLVE)] _Dissolve("Enable Dissolve", Float)  = 0 
    	_CutoffHeight("Cutoff Height", Float) = 0
        [HDR]_EdgeColor("Edge Color", Color) = (0, 3.262745, 23.96863, 1)
        _EdgeWidth("Edge Width", Float) = 0.05
	    _NoiseTexture("Noise Texture", 2D) = "white" {}
        _NoiseScale("Noise Scale", Float) = 50
        _NoiseStrength("Noise Strength", Float) = 1
    	
    	[Space(20)]
    	[Toggle(_MULTISCATTERING)] _EnergyConservationToggle ("Energy Conservation using Kulla-Conty method", Float) = 0
        
    	[Space(20)]
    	[Toggle(_CLEARCOAT)]  _ClearCoat ("Clear Coat", Float) = 0
    	[NoScaleOffset] _ClearCoatMap ("ClearCoat strength(R) ClearCoat roughness(B)", 2D) = "white" {}
    	_ClearCoatStrength ("ClearCoat Strength", Range(0.0, 1.0)) = 0
    	_ClearCoatRoughness ("ClearCoat Roughness", Range(0.0, 1.0)) = 0.1
        
        [Space(20)]
		[Toggle(_NORMALMAP)] _NormalMapToggle ("Use Normal Map", Float) = 0
		[NoScaleOffset][Normal] _NormalMap ("Normal Map", 2D) = "bump" {}
		_NormalScale ("Normal Scale", Float) = 1
    	
    	[Space(20)]
    	[Toggle(_DETAIL_NORMALMAP)] _DetailNormalMapToggle ("Use Detail Map", Float) = 0
	    [NoScaleOffset][Normal] _DetailNormalMap ("Detail Normal Map", 2D) = "bump" {}
    	_DetailNormalScale ("Detail Normal Scale", Float) = 1
        
	    [Space(20)]
	    [Toggle(_HEIGHTMAP)] _HeightMapToggle ("Use Parallax Mapping (Only valid if displacement map toggle is unenabled)", Float) = 0
    	[NoScaleOffset] _HeightMap ("Height Map", 2D) = "bump" {}
    	_HeightScale ("Height Scale", Range(0, 0.5)) = 1
    	
    	[Space(20)]
    	[Toggle(_DISPLACEMENTMAP)] _DisplacementMapToggle ("Use Displacement Map", Float) = 0
    	_TessellationEdgeLength ("Tessellation Edge Length", Range(5, 100)) = 50
        [NoScaleOffset] _DisplacementMap ("Displacement Map", 2D) = "black" {}
    	_DisplacementScale ("Displacement Scale", Range(0, 1)) = 0.1
    	
		[Space(20)]
		[Toggle(_OCCLUSIONMAP)] _OcclusionToggle ("Use Occlusion Map", Float) = 0
		[NoScaleOffset] _OcclusionMap ("Occlusion(R)", 2D) = "white" {}
		_OcclusionStrength ("Occlusion Strength", Range(0.0, 1.0)) = 1.0

		[Space(20)]
		[Toggle(_EMISSION)] _Emission ("Emission", Float) = 0
		[HDR] _EmissionColor ("Emission Color", Color) = (0,0,0)
		[NoScaleOffset]_EmissionMap ("Emission Map", 2D) = "black" {}
        
        [Toggle(_ALPHATEST_ON)] _AlphaTestToggle ("Alpha Clipping", Float) = 0 
        _Cutoff ("Alpha Cutoff", Float) = 0.5
        
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
        [Enum(Off, 0, On ,1)] _ZWrite("Z Write", Float) = 1 
    }
    SubShader
    {
	    HLSLINCLUDE
		#define _SHADING_MODEL_LIT
	    
        #include "Assets/ShaderLibrary/UnityInput.hlsl"
	    #include "Assets/ShaderLibrary/Surface.hlsl"
	    #include "Assets/ShaderLibrary/Config.hlsl"
        #include "Assets/Shaders/LitInput.hlsl"
	    #include "Assets/ShaderLibrary/Common.hlsl"
	    #include "Assets/ShaderLibrary/BRDF.hlsl"
	    #include "Assets/Shaders/LitInit.hlsl"
	    #include "Assets/ShaderLibrary/GI.hlsl"
	    #include "Assets/ShaderLibrary/Shadows.hlsl"
	    #include "Assets/ShaderLibrary/Lighting.hlsl"
        ENDHLSL
        
        Tags 
        {
        	"RenderType"="Obaque"
            "RenderPipeline"="UniversalPipeline"
        }
        
        Pass
        {
            Name "Lit"
            Tags { "LightMode"="UniversalForward" }
            
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull Off
            
            HLSLPROGRAM
            #pragma target 4.6
            #pragma shader_feature _DISSOLVE
            #pragma shader_feature _MULTISCATTERING
            #pragma shader_feature _CLEARCOAT
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _DETAIL_NORMALMAP
            #pragma shader_feature _HEIGHTMAP
            #pragma shader_feature _DISPLACEMENTMAP
            #pragma shader_feature _OCCLUSIONMAP
            #pragma shader_feature _EMISSION
            #pragma shader_feature _ALPHATEST_ON
            #pragma multi_compile _ _QUAD_AREA_LIGHT
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _LIGHTS_PER_OBJECT
            #pragma multi_compile_instancing

            #ifdef _DISPLACEMENTMAP
				#define _TESSELLATION 1
				#undef _HEIGHTMAP
            #else
            #undef _TESSELLATION
            #endif

            #pragma vertex MyTessellationVertexProgram
            #pragma hull MyHullProgram
            #pragma domain MyDomainProgram
            #pragma fragment LitPassFragmentDissolve

            TEXTURE2D(_NoiseTexture);
            SAMPLER(sampler_NoiseTexture);
            float _CutoffHeight;
            float4 _EdgeColor;
            float _EdgeWidth;
            float _NoiseScale;
            float _NoiseStrength;

            #include "Assets/Shaders/LitPass.hlsl"
            #include "Assets/Shaders/Tessellation.hlsl"

            float4 LitPassFragmentDissolve(Varyings input) : SV_TARGET
            {
	            UNITY_SETUP_INSTANCE_ID(input);

	            #ifdef _HEIGHTMAP
        		float3x3 tangentToWorld = float3x3(input.tangentWS.xyz, input.bitangentWS, input.normalWS);
        		float3 positionTS = TransformWorldToTangent(input.positionWS, tangentToWorld);
        		float3 cameraPosTS = TransformWorldToTangent(_WorldSpaceCameraPos, tangentToWorld);
        		float3 viewDir = normalize(cameraPosTS - positionTS);
        		input.baseUV = ParallaxMapping(GetHeight(input.baseUV), viewDir);
	            #endif

	            half4 baseMap = GetBase(input.baseUV);
	            float4 baseColor = baseMap * GetBaseColor();

            	
            	float3 emission = GetEmission(input.baseUV);;
            	Surface surface;
	            surface.baseColor =  baseColor.rgb;
            	
            	#ifdef _DISSOLVE
				float noiseValue = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture, input.baseUV).r;


	            float edge = 0;
	            Unity_Remap_float(noiseValue, float2(0, 1), float2(-1 * _NoiseStrength, _NoiseStrength), edge);
	            edge = edge + _CutoffHeight;

	            clip(edge - input.positionWS.y);
            	if (edge - input.positionWS.y < 0)
            	{
            		
            		return float4(0, 0, 1, 0);
            	}else
            	{
            		surface.emission = GetEmission(input.baseUV) + step(edge, _EdgeWidth + input.positionWS.y) * _EdgeColor;
            	}
            	#else
            	surface.emission = emission;
            	#endif
            	
	            #if defined(_ALPHATEST_ON)
				clip(baseColor.a - GetCutoff());
	            #endif

            	
            	
	            surface.alpha = baseColor.a;
	            surface.metallic = GetMetallic(input.baseUV);
	            surface.occlusion = GetOcclusion(input.detailUV);
	            surface.position = input.positionWS;
	            #if defined(_NORMALMAP)
        		float3 n = NormalTangentToWorld(
        		    GetNormalTS(input.baseUV), input.normalWS, input.tangentWS.xyz, input.tangentWS.w
        		);
	            #else
	            float3 n = normalize(input.normalWS);
	            #endif
	            surface.normal = n;
	            surface.reflectance = GetReflectance();
	            surface.perceptualRoughness = GetPerceptualRoughness(input.baseUV) + 1e-5;
	            surface.roughness = PerceptualRoughnessToRoughness(surface.perceptualRoughness);
	            #ifdef _CLEARCOAT
        		ClearCoatConfig config = GetClearCoatConfig(input.baseUV);
        		surface.clearCoat = config.strength;
        		surface.clearCoatPerceptualRoughness = clamp(config.roughness, 0.089, 1.0);
        		surface.clearCoatRoughness = surface.clearCoatPerceptualRoughness * surface.clearCoatPerceptualRoughness;
	            #endif
	            surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
				float alpha = surface.alpha;
            	
	            CustomBRDFData brdf;
	            InitializeBRDFData(surface, brdf);

	            float3 luminance = GetLighting(LIGHTMAP_UV_FRAGMENT_DATA, surface, brdf, 0);

	            luminance += surface.emission;

	            // clamping brightness to 100 to avoid undesirable oversize blooming effect
	            float4 col = float4(clamp(luminance, 0.0, 100.0), alpha);
	            
	            return col;
            }
            ENDHLSL
        }
	    
    	Pass
        {
           Name "ShadowCaster"
           Tags { "LightMode"="ShadowCaster" }

           ZWrite On
           ZTest LEqual
           HLSLPROGRAM
           #pragma shader_feature _ALPHATEST_ON
           //#pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
           #pragma multi_compile_instancing
           // Universal Pipeline Keywords
           // (v11+) This is used during shadow map generation to differentiate between directional and punctual (point/spot) light shadows, as they use different formulas to apply Normal Bias
           #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
           #pragma vertex ShadowCasterPassVertex
           #pragma fragment ShadowCasterPassFragment
           #include "Assets/Shaders/ShadowCasterPass.hlsl"
           ENDHLSL
		}
    	
    	Pass 
    	{
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ColorMask 0
			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex DepthOnlyVertex
			#pragma fragment DepthOnlyFragment
			
			#pragma shader_feature _ALPHATEST_ON

			#pragma multi_compile_instancing
			
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Assets/Shaders/DepthOnlyPass.hlsl"
			ENDHLSL
		}
    	
    	Pass 
    	{
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormals" }

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex DepthNormalsVertex
			#pragma fragment DepthNormalsFragmentDissolve

			#pragma shader_feature _DISSOLVE
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			
			#pragma multi_compile_instancing

			TEXTURE2D(_NoiseTexture);
            SAMPLER(sampler_NoiseTexture);
            float _CutoffHeight;
            float4 _EdgeColor;
            float _EdgeWidth;
            float _NoiseScale;
            float _NoiseStrength;

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Assets/Shaders/DepthNormalsPass.hlsl"
			
			half4 DepthNormalsFragmentDissolve(Varyings input) : SV_TARGET {
				#ifdef _DISSOLVE
				float noiseValue = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture, input.uv).r;


	            float edge = 0;
	            Unity_Remap_float(noiseValue, float2(0, 1), float2(-1 * _NoiseStrength, _NoiseStrength), edge);
	            edge = edge + _CutoffHeight;

	            clip(edge - input.positionWS.y);
            	if (edge - input.positionWS.y < 0)
            	{
            		return float4(0, 0, 1, 0);
            	}
	            #endif

				return DepthNormalsFragment(input);
			}
			
			// Note if we do any vertex displacement, we'll need to change the vertex function. e.g. :
			/*
			#pragma vertex DisplacedDepthOnlyVertex (instead of DepthOnlyVertex above)

			Varyings DisplacedDepthOnlyVertex(Attributes input) {
				Varyings output = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				// Example Displacement
				input.positionOS += float4(0, _SinTime.y, 0, 0);

				output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
				output.positionCS = TransformObjectToHClip(input.position.xyz);
				VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
				output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
				return output;
			}
			*/
			
			ENDHLSL
		}
    	
    	Pass
    	{
    		Name "Meta"
    		Tags { "LightMode"="Meta" }
    		
    		Cull Off
    		
    		HLSLPROGRAM
    		#pragma vertex MetaPassVertex
    		#pragma fragment MetaPassFragment
    		#include "Assets/Shaders/MetaPass.hlsl"
    		ENDHLSL
        }
    	
    }
}
