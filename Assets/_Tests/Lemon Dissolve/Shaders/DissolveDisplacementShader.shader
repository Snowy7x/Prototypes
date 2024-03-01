Shader "Snowy/DisintegrateShader"
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
    	_FlowMap("Flow (RG)", 2D) = "black" {}
        _DissolveTexture("Dissolve Texutre", 2D) = "white" {}
        [HDR]_EdgeColor("Dissolve Color Border", Color) = (1, 1, 1, 1) 
        _DissolveBorder("Dissolve Border", float) =  0.05
    	_Exapnd("Expand", float) = 1
        _Weight("Weight", float) = 0
        _Direction("Direction", Vector) = (0, 0, 0, 0)
        [HDR]_DisintegrationColor("Disintegration Color", Color) = (1, 1, 1, 1)

        _Shape("Shape Texutre", 2D) = "white" {} 
        _R("Radius", float) = .1
    	
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
    
    HLSLINCLUDE

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

    #if defined(LIGHTMAP_ON)
    #define LIGHTMAP_UV_ATTRIBUTE float2 lightMapUV : TEXCOORD1;
    #define LIGHTMAP_UV_VARYINGS float2 lightMapUV : VAR_LIGHTMAP_UV;
    #define TRANSFER_LIGHTMAP_DATA(input, output) output.lightMapUV = input.lightMapUV * \
        unity_LightmapST.xy + unity_LightmapST.zw;
    #define LIGHTMAP_UV_FRAGMENT_DATA input.lightMapUV
#else
    #define LIGHTMAP_UV_ATTRIBUTE 
    #define LIGHTMAP_UV_VARYINGS 
    #define TRANSFER_LIGHTMAP_DATA(input, output) 
    #define LIGHTMAP_UV_FRAGMENT_DATA 0.0
#endif

    
    
    struct v2g
{
    float4 positionCS  : SV_POSITION;
    float2 baseUV      : TEXCOORD0;
    float2 detailUV    : TEXCOORD1;
    float3 positionWS  : TEXCOORD2;
    float3 normalWS    : TEXCOORD3;
    float4 tangentWS   : TEXCOORD4;
    float3 bitangentWS : TEXCOORD5;
    LIGHTMAP_UV_VARYINGS
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

        struct g2f
{
    float4 positionCS  : SV_POSITION;
    float2 baseUV      : TEXCOORD0;
    float2 detailUV    : TEXCOORD1;
    float3 positionWS  : TEXCOORD2;
    float3 normalWS    : TEXCOORD3;
    float4 tangentWS   : TEXCOORD4;
    float3 bitangentWS : TEXCOORD5;
    float4 Color : COLOR;
    LIGHTMAP_UV_VARYINGS
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

    float4 _AmbientColor;
    sampler2D _BumpMap;
    float _BumpStr;

    sampler2D _FlowMap;
    float4 _FlowMap_ST;
    sampler2D _DissolveTexture;
    float4 _EdgeColor;
    float _DissolveBorder;


    float _Exapnd;
    float _Weight;
    float4 _Direction;
    float4 _DisintegrationColor;
    sampler2D _Shape;
    float _R;

    float random(float2 uv)
    {
	    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453123);
    }

    float remap(float value, float from1, float to1, float from2, float to2)
    {
	    return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
    }

    float randomMapped(float2 uv, float from, float to)
    {
	    return remap(random(uv), 0, 1, from, to);
    }

    float4 remapFlowTexture(float4 tex)
    {
	    return float4(
		    remap(tex.x, 0, 1, -1, 1),
		    remap(tex.y, 0, 1, -1, 1),
		    0,
		    remap(tex.w, 0, 1, -1, 1)
		    );
    }

    float2 MultiplyUV (float4x4 mat, float2 inUV) {
    	float4 temp = float4 (inUV.x, inUV.y, 0, 0);
    	temp = mul (mat, temp);
    	return temp.xy;
	}
	#define UNITY_MATRIX_TEXTURE0 float4x4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
    

    [maxvertexcount(7)]
    void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
    {
	    float2 avgUV = (IN[0].baseUV + IN[1].baseUV + IN[2].baseUV) / 3;
	    float3 avgPos = (TransformWorldToObject(IN[0].positionWS) + TransformWorldToObject(IN[1].positionWS) + TransformWorldToObject(IN[2].positionWS)) / 3;
	    float3 avgNormal = (TransformWorldToObjectNormal(IN[0].normalWS) + TransformWorldToObjectNormal(IN[1].normalWS) + TransformWorldToObjectNormal(IN[2].normalWS)) / 3;
	    float4 avgTangent = (float4(TransformWorldToObjectDir(IN[0].tangentWS), IN[0].tangentWS.w) + float4(TransformWorldToObjectDir(IN[0].tangentWS), IN[0].tangentWS.w) + float4(TransformWorldToObjectDir(IN[0].tangentWS), IN[0].tangentWS.w)) / 3;

	    float dissolve_value = tex2Dlod(_DissolveTexture, float4(avgUV, 0, 0)).r;

    	float3 worldPos = TransformObjectToWorld(avgPos);
    	
	    float t = clamp((worldPos.y - _Weight * 2) - dissolve_value, 0, 1);

	    float2 flowUV = TRANSFORM_TEX(mul(unity_ObjectToWorld, avgPos).xz, _FlowMap);
	    float4 flowVector = remapFlowTexture(tex2Dlod(_FlowMap, float4(flowUV, 0, 0)));

	    float3 pseudoRandomPos = (avgPos) + _Direction;
	    pseudoRandomPos += (flowVector.xyz * _Exapnd);

	    float3 p = lerp(avgPos, pseudoRandomPos, t);
	    float radius = lerp(_R, 0, t);

	    if (t > 0)
	    {
		    float3 right = UNITY_MATRIX_IT_MV[0].xyz;
		    float3 up = UNITY_MATRIX_IT_MV[1].xyz;

		    float halfS = 0.5f * radius;

		    float4 v[4];
		    v[0] = float4(p + halfS * right - halfS * up, 1.0f);
		    v[1] = float4(p + halfS * right + halfS * up, 1.0f);
		    v[2] = float4(p - halfS * right - halfS * up, 1.0f);
		    v[3] = float4(p - halfS * right + halfS * up, 1.0f);


		    g2f vert;
	    	VertexPositionInputs positionInputs = GetVertexPositionInputs(v[0]);
    		vert.positionCS = positionInputs.positionCS;
    		vert.baseUV = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(1.0f, 0.0f));
    		vert.detailUV = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(1.0f, 0.0f));
    		vert.positionWS = positionInputs.positionWS;
	    	vert.Color = float4(1, 1, 1, 1);
		
    		VertexNormalInputs normalInputs = GetVertexNormalInputs(avgNormal.xyz, avgTangent);
    		vert.normalWS = normalInputs.normalWS;
    		vert.tangentWS = float4(normalInputs.tangentWS, avgTangent.w);
    		vert.bitangentWS = normalInputs.bitangentWS;
		    triStream.Append(vert);

	    	positionInputs = GetVertexPositionInputs(v[1]);
    		vert.positionCS = positionInputs.positionCS;
    		vert.baseUV = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(1.0f, 1.0f));
    		vert.detailUV = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(1.0f, 1.0f));
    		vert.positionWS = positionInputs.positionWS;
	    	vert.Color = float4(1, 1, 1, 1);

    		normalInputs = GetVertexNormalInputs(avgNormal.xyz, avgTangent);
    		vert.normalWS = normalInputs.normalWS;
    		vert.tangentWS = float4(normalInputs.tangentWS, avgTangent.w);
    		vert.bitangentWS = normalInputs.bitangentWS;
		    triStream.Append(vert);

	    	positionInputs = GetVertexPositionInputs(v[2]);
    		vert.positionCS = positionInputs.positionCS;
    		vert.baseUV = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(0.0f, 0.0f));
    		vert.detailUV = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(0.0f, 0.0f));
    		vert.positionWS = positionInputs.positionWS;
	    	vert.Color = float4(1, 1, 1, 1);

    		normalInputs = GetVertexNormalInputs(avgNormal.xyz, avgTangent);
    		vert.normalWS = normalInputs.normalWS;
    		vert.tangentWS = float4(normalInputs.tangentWS, avgTangent.w);
    		vert.bitangentWS = normalInputs.bitangentWS;
		    triStream.Append(vert);

	    	positionInputs = GetVertexPositionInputs(v[3]);
    		vert.positionCS = positionInputs.positionCS;
    		vert.baseUV = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(0.0f, 1.0f));
    		vert.detailUV = MultiplyUV(UNITY_MATRIX_TEXTURE0, float2(0.0f, 1.0f));
    		vert.positionWS = positionInputs.positionWS;
	    	vert.Color = float4(1, 1, 1, 1);

    		normalInputs = GetVertexNormalInputs(avgNormal.xyz, avgTangent);
    		vert.normalWS = normalInputs.normalWS;
    		vert.tangentWS = float4(normalInputs.tangentWS, avgTangent.w);
    		vert.bitangentWS = normalInputs.bitangentWS;
		    triStream.Append(vert);

		    triStream.RestartStrip();
	    }

	    for (int j = 0; j < 3; j++)
	    {
	    	g2f o = (g2f)0;
	    	o.positionCS = IN[j].positionCS;
	    	o.baseUV = IN[j].baseUV;
	    	o.detailUV = IN[j].detailUV;
	    	o.positionWS = IN[j].positionWS;
	    	o.normalWS = IN[j].normalWS;
	    	o.tangentWS = IN[j].tangentWS;
	    	o.bitangentWS = IN[j].bitangentWS;
	    	o.Color = float4(0, 0, 0, 0);
	    	
		    triStream.Append(o);
	    }

	    triStream.RestartStrip();
    }
    ENDHLSL
    
    SubShader
    {
	    HLSLINCLUDE
		#define _SHADING_MODEL_LIT
		
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
            #pragma multi_compile_fwdbase

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
            #pragma geometry geom

            #include "Assets/Shaders/LitPass.hlsl"
            #include "Assets/Shaders/Tessellation.hlsl"

            float4 LitPassFragmentDissolve(g2f input) : SV_TARGET
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
            	surface.emission = emission;
                 #if defined(_NORMALMAP)
        		float3 n = NormalTangentToWorld(
        		    GetNormalTS(input.baseUV), input.normalWS, input.tangentWS.xyz, input.tangentWS.w
        		);
	            #else
	            float3 n = normalize(input.normalWS);
	            #endif
	            surface.normal = n;

            	#ifdef _DISSOLVE
				float dissolve = tex2D(_DissolveTexture, input.baseUV).r;
				if(input.Color.w == 0){
                    clip(dissolve - (input.positionWS.y - _Weight * 2));
					surface.emission = emission + step(dissolve - (input.positionWS.y - _Weight * 2), _DissolveBorder) * _EdgeColor;
                }else{
                	surface.emission = _DisintegrationColor;
                    float4 shape = tex2D(_Shape, input.baseUV);
                    if (shape.a < .5) {
						discard;
					}

                    surface.baseColor = shape.rgb * GetBaseColor();
                    surface.normal = normalize(input.normalWS);
                }
            	
            	#endif
            	
            	
	            #if defined(_ALPHATEST_ON)
				clip(baseColor.a - GetCutoff());
	            #endif

            	
            	
	            surface.alpha = baseColor.a;
	            surface.metallic = GetMetallic(input.baseUV);
	            surface.occlusion = GetOcclusion(input.detailUV);
	            surface.position = input.positionWS;
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
           #pragma fragment ShadowCasterPassFragmentDissolve
           #pragma geometry geom
           
           #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
           #include "Assets/Shaders/ShadowCasterPass.hlsl"

           void ShadowCasterPassFragmentDissolve(Varyings input) {
           		#ifdef _DISSOLVE
				float dissolve = tex2D(_DissolveTexture, input.baseUV).r;

                if(input.Color.w == 0){
                    clip(dissolve - (input.positionWS.y - _Weight * 2));
                }else{
                    float s = tex2D(_Shape, input.baseUV).r;
                    if(s < .5) {
                        discard;
                    }
                }
	            #endif

				ShadowCasterPassFragment(input);
           }
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
			#pragma vertex DepthNormalsVertexDisssolve
			#pragma geometry geom
			#pragma fragment DepthNormalsFragmentDissolve

			#pragma shader_feature _DISSOLVE
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			
			#pragma multi_compile_instancing

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Assets/Shaders/DepthNormalsPass.hlsl"

			v2g DepthNormalsVertexDisssolve(Attributes input)
			{
    			v2g output = (v2g)0;
    			UNITY_SETUP_INSTANCE_ID(input);
    			UNITY_TRANSFER_INSTANCE_ID(input, output);
    			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
			
    			output.baseUV         = TRANSFORM_TEX(input.texcoord, _BaseMap);
    			output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    			output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
			
    			
    			VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
    			output.normalWS = normalize(normalInput.normalWS);
			
    			return output;
			}

			
			half4 DepthNormalsFragmentDissolve(g2f input) : SV_TARGET {
				#ifdef _DISSOLVE
				float dissolve = tex2D(_DissolveTexture, input.baseUV).r;

                if(input.Color.w == 0){
                    clip(dissolve - (input.positionWS.y - _Weight * 2));
                }else{
                    float s = tex2D(_Shape, input.baseUV).r;
                    if(s < .5) {
                        discard;
                    }
                }
	            #endif

				Varyings varyings;
				varyings.positionWS = input.positionWS;
				varyings.positionCS = input.positionCS;
				varyings.normalWS = input.normalWS;
				varyings.uv = input.baseUV;
				
				
				return DepthNormalsFragment(varyings);
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
