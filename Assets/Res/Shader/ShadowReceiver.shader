// Upgrade NOTE: replaced '_World2Shadow' with 'unity_WorldToShadow[0]'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

///////////////////////////////////////////
// author     : chen yong
// create time: 2017/7/5
// modify time: 
// description: 
///////////////////////////////////////////

Shader "Custom/ShadowMapping/Receiver" {
	SubShader{
		Tags { "RenderType" = "Opaque" }
		LOD 300

		Pass {
			Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 shadowCoord : TEXCOORD0;
			};

			uniform float4x4 _gWorldToShadow;
			uniform sampler2D _gShadowMapTexture;
			/*{TextureName}_TexelSize - a float4 property contains texture size information :
			x contains 1.0 / width
			y contains 1.0 / height
			z contains width
			w contains height*/
			uniform float4 _gShadowMapTexture_TexelSize;
			uniform float _gShadowStrength;

			v2f vert(appdata_full v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.shadowCoord = mul(_gWorldToShadow, worldPos);

				return o;
			}

			//3x3的PCF Soft Shadow
			float PCFSample(float depth, float2 uv)
			{
				float shadow = 0.0;
				for (int x = -1; x <= 1; ++x)
				{
					for (int y = -1; y <= 1; ++y)
					{
						float4 col = tex2D(_gShadowMapTexture, uv + float2(x, y) * _gShadowMapTexture_TexelSize.xy);
						float sampleDepth = DecodeFloatRGBA(col);
						shadow += sampleDepth < depth ? _gShadowStrength : 1;//接受物体片元的深度与深度图的值比较，大于则表示被挡住灯光，显示为阴影，否则显示自己的颜色（这里显示白色）
					}
				}
				return shadow /= 9;
			}

			fixed4 frag(v2f i) : COLOR0
			{
				// shadow
				i.shadowCoord.xy = i.shadowCoord.xy / i.shadowCoord.w;
				float2 uv = i.shadowCoord.xy;
				uv = uv * 0.5 + 0.5; //(-1, 1)-->(0, 1)

				float depth = i.shadowCoord.z / i.shadowCoord.w;
			#if defined (SHADER_TARGET_GLSL)
				depth = depth * 0.5 + 0.5; //(-1, 1)-->(0, 1)
			#elif defined (UNITY_REVERSED_Z)
				depth = 1 - depth;       //(1, 0)-->(0, 1)
			#endif

				return PCFSample(depth, uv);
				// sample depth texture
				/*float4 col = tex2D(_gShadowMapTexture, uv);
				float sampleDepth = DecodeFloatRGBA(col);
				float shadow = sampleDepth < depth ? _gShadowStrength : 1;//接受物体片元的深度与深度图的值比较，大于则表示被挡住灯光，显示为阴影，否则显示自己的颜色（这里显示白色）
				return shadow;*/
			}

			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest  
			ENDCG
		}
	}
}
