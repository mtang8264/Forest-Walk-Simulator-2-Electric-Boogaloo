// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Toon/Specular"
{
	Properties
	{
		_AlbedoColor("Albedo Color", Color) = (1,1,1,1)
		_Texture("Texture", 2D) = "white" {}
		_AmbientLightingColor("Ambient Lighting Color", Color) = (0.4,0.4,0.4,1)
		_RimLightColor("Rim Light Color", Color) = (1,1,1,1)
		_RimAmount("Rim Amount", Range( 0 , 1)) = 0.07
		_RimThreshold("Rim Threshold", Range( 0 , 1)) = 1
		_SpecularColor("Specular Color", Color) = (1,1,1,1)
		_Glossiness("Glossiness", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityCG.cginc"
		#include "UnityShaderVariables.cginc"
		#include "Lighting.cginc"
		#pragma target 4.6
		#if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC) || defined(SHADER_API_PSSL) || (defined(SHADER_TARGET_SURFACE_ANALYSIS) && !defined(SHADER_TARGET_SURFACE_ANALYSIS_MOJOSHADER))//ASE Sampler Macros
		#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex.Sample(samplerTex,coord)
		#else//ASE Sampling Macros
		#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex2D(tex,coord)
		#endif//ASE Sampling Macros

		struct Input
		{
			float2 uv_texcoord;
			float3 worldNormal;
			float3 worldPos;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		UNITY_DECLARE_TEX2D_NOSAMPLER(_Texture);
		uniform float4 _Texture_ST;
		SamplerState sampler_Texture;
		uniform float4 _AlbedoColor;
		uniform float4 _AmbientLightingColor;
		uniform float _Glossiness;
		uniform float4 _SpecularColor;
		uniform float _RimAmount;
		uniform float _RimThreshold;
		uniform float4 _RimLightColor;

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			#ifdef UNITY_PASS_FORWARDBASE
			float ase_lightAtten = data.atten;
			if( _LightColor0.a == 0)
			ase_lightAtten = 0;
			#else
			float3 ase_lightAttenRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
			float ase_lightAtten = max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b );
			#endif
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
			half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
			float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
			float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
			ase_lightAtten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif
			float2 uv_Texture = i.uv_texcoord * _Texture_ST.xy + _Texture_ST.zw;
			float3 ase_worldNormal = i.worldNormal;
			float3 ase_worldPos = i.worldPos;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult9 = dot( ase_worldNormal , ( ase_lightAtten * ase_worldlightDir ) );
			float smoothstepResult32 = smoothstep( 0.0 , 0.025 , dotResult9);
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float3 worldSpaceViewDir44 = WorldSpaceViewDir( float4( 0,0,0,1 ) );
			float3 normalizeResult54 = normalize( worldSpaceViewDir44 );
			float3 normalizeResult50 = normalize( ( ase_worldlightDir + normalizeResult54 ) );
			float dotResult47 = dot( ase_worldNormal , normalizeResult50 );
			float smoothstepResult55 = smoothstep( 0.0 , 0.01 , pow( ( ase_lightColor.a * dotResult47 ) , ( _Glossiness * _Glossiness ) ));
			float3 worldSpaceViewDir64 = WorldSpaceViewDir( float4( 0,0,0,1 ) );
			float dotResult65 = dot( ase_worldNormal , worldSpaceViewDir64 );
			float smoothstepResult74 = smoothstep( ( _RimAmount - 0.025 ) , ( _RimAmount + 0.025 ) , ( pow( dotResult9 , _RimThreshold ) * ( 1.0 - dotResult65 ) ));
			c.rgb = ( ( SAMPLE_TEXTURE2D( _Texture, sampler_Texture, uv_Texture ) * _AlbedoColor ) * ( smoothstepResult32 + _AmbientLightingColor + ( ( smoothstepResult55 * _SpecularColor ) * ase_lightAtten ) + ( smoothstepResult74 * _RimLightColor ) ) * ase_lightColor.a ).rgb;
			c.a = 1;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows exclude_path:deferred 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.6
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.worldNormal = worldNormal;
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = IN.worldNormal;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18400
464;113;1090;811;2075.26;-664.0205;1.772403;True;False
Node;AmplifyShaderEditor.WorldSpaceViewDirHlpNode;44;-1785.798,1005.752;Inherit;False;1;0;FLOAT4;0,0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;43;-1093.422,439.7874;Inherit;True;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;54;-1558.472,987.9362;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;49;-1356.76,944.6821;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;50;-1219.011,937.5934;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LightColorNode;31;-1437.56,581.5596;Inherit;True;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.WorldNormalVector;7;-1000.704,-74.65733;Inherit;True;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LightAttenuation;40;-1128.948,197.5574;Inherit;True;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceViewDirHlpNode;64;-1820.754,1289.805;Inherit;False;1;0;FLOAT4;0,0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;46;-1030.636,936.9897;Inherit;False;Property;_Glossiness;Glossiness;7;0;Create;True;0;0;False;0;False;0;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-759.5394,338.8398;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;47;-891.0378,723.7775;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;57;-711.4038,665.8723;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;9;-698.8896,-10.50454;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;65;-1580.011,1240.031;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;66;-1386.34,1535.028;Inherit;False;Property;_RimThreshold;Rim Threshold;5;0;Create;True;0;0;False;0;False;1;0.07;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;53;-846.5982,935.2115;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;51;-568.8068,709.103;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;69;-1481.589,1684.13;Inherit;False;Property;_RimAmount;Rim Amount;4;0;Create;True;0;0;False;0;False;0.07;0.1027116;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;67;-997.3914,1240.308;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;68;-1300.689,1259.476;Inherit;True;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;52;-500.8631,835.5099;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;45;-212.763,1100.248;Inherit;False;Property;_SpecularColor;Specular Color;6;0;Create;True;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;55;-227.0867,784.1304;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.01;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;72;-1064.566,1633.071;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.025;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;70;-933.4809,1325.264;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;71;-1053.249,1750.99;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.025;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;74;-835.3915,1530.437;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;73;-818.5576,1762.912;Inherit;False;Property;_RimLightColor;Rim Light Color;3;0;Create;True;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;56;108.7234,885.7424;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;1;-419.1836,-308.0926;Inherit;True;Property;_Texture;Texture;1;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;29;-461.0496,373.4861;Inherit;False;Property;_AmbientLightingColor;Ambient Lighting Color;2;0;Create;True;0;0;False;0;False;0.4,0.4,0.4,1;0.4,0.4,0.4,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;32;-435.6333,130.9011;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.025;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;33;-333.0815,-70.87418;Inherit;False;Property;_AlbedoColor;Albedo Color;0;0;Create;True;0;0;False;0;False;1,1,1,1;0,0.1792453,0.003813751,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;75;-625.3679,1554.708;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;63;348.1779,727.5678;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;30;-125.177,205.5518;Inherit;True;4;4;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;-35.78152,-122.0743;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;10;201.1628,218.3199;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;618.3411,-77.68665;Float;False;True;-1;6;ASEMaterialInspector;0;0;CustomLighting;Toon/Specular;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;ForwardOnly;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0.02;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;True;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;54;0;44;0
WireConnection;49;0;43;0
WireConnection;49;1;54;0
WireConnection;50;0;49;0
WireConnection;41;0;40;0
WireConnection;41;1;43;0
WireConnection;47;0;7;0
WireConnection;47;1;50;0
WireConnection;57;0;31;2
WireConnection;9;0;7;0
WireConnection;9;1;41;0
WireConnection;65;0;7;0
WireConnection;65;1;64;0
WireConnection;53;0;46;0
WireConnection;53;1;46;0
WireConnection;51;0;57;0
WireConnection;51;1;47;0
WireConnection;67;0;9;0
WireConnection;67;1;66;0
WireConnection;68;1;65;0
WireConnection;52;0;51;0
WireConnection;52;1;53;0
WireConnection;55;0;52;0
WireConnection;72;0;69;0
WireConnection;70;0;67;0
WireConnection;70;1;68;0
WireConnection;71;0;69;0
WireConnection;74;0;70;0
WireConnection;74;1;72;0
WireConnection;74;2;71;0
WireConnection;56;0;55;0
WireConnection;56;1;45;0
WireConnection;32;0;9;0
WireConnection;75;0;74;0
WireConnection;75;1;73;0
WireConnection;63;0;56;0
WireConnection;63;1;40;0
WireConnection;30;0;32;0
WireConnection;30;1;29;0
WireConnection;30;2;63;0
WireConnection;30;3;75;0
WireConnection;34;0;1;0
WireConnection;34;1;33;0
WireConnection;10;0;34;0
WireConnection;10;1;30;0
WireConnection;10;2;31;2
WireConnection;0;13;10;0
ASEEND*/
//CHKSM=04C558A8E28CD28E9A442C28C72D7548C27E0105