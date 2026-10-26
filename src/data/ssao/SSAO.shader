Shader "SSAO/SSAO"
{
    Properties { _MainTex ("Source", 2D) = "white" {} }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        CGINCLUDE
        #include "SSAO.cginc"
        sampler2D _MainTex, _AOTex;
        float4 _MainTex_TexelSize;
        int _SampleCount;
        float _Radius, _RangeCheck, _AOInt, _DepthBias;
        float4x4 _VMatrix, _PMatrix;
        float4 _AOCol;
        struct v2f
        {
            float4 vertex : SV_POSITION;
            float2 uv : TEXCOORD0;
            float2 cameraUV : TEXCOORD1;
        };
        v2f vert(appdata_img v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            o.cameraUV = v.texcoord;
#if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0) o.cameraUV.y = 1 - o.cameraUV.y;
#endif
            return o;
        }
        float4 frag(v2f i) : SV_Target
        {
            float2 uv = i.cameraUV;
            if (IsBackground(uv) || _Radius <= 0 || _RangeCheck <= 0) return 1;
            float eyeDepth = GetEyeDepth(uv);
            float4 position = GetWorldPos(uv);
            float3 normal = GetWorldNormal(uv);
            // A stable orthonormal basis, rotated around the normal per pixel.
            float3 axis = abs(normal.z) < 0.999 ? float3(0,0,1) : float3(0,1,0);
            float3 tangent = normalize(cross(axis, normal));
            float3 bitangent = cross(normal, tangent);
            float rotation = Hash(floor(uv * _ScreenParams.xy)) * 6.2831853;
            float occlusion = 0;
            [loop]
            for (int j = 0; j < _SampleCount; ++j)
            {
                float fraction = (j + 0.5) / _SampleCount;
                float z = fraction;
                float angle = j * 2.39996323 + rotation;
                float radial = sqrt(saturate(1 - z * z));
                float3 direction = tangent * (cos(angle) * radial)
                    + bitangent * (sin(angle) * radial) + normal * z;
                float scale = lerp(0.1, 1.0, frac((j + 0.5) * 0.754877666));
                float4 samplePosition = position + float4(direction * (_Radius * scale * scale), 0);
                float4 viewPosition = mul(_VMatrix, samplePosition);
                float sampleZ = -viewPosition.z;
                if (sampleZ <= _ProjectionParams.y) continue;
                float4 clip = mul(_PMatrix, viewPosition);
                float2 sampleUV = clip.xy / clip.w * 0.5 + 0.5;
                if (any(sampleUV < 0) || any(sampleUV > 1) || IsBackground(sampleUV)) continue;
                float sceneDepth = GetEyeDepth(sampleUV);
                float rangeWeight = smoothstep(0, 1,
                    _Radius * _RangeCheck * 0.1 / max(abs(eyeDepth - sceneDepth), 1e-5));
                occlusion += (sceneDepth < sampleZ - _DepthBias ? 1.0 : 0.0) * rangeWeight;
            }
            float visibility = 1 - saturate(occlusion * _AOInt / max(_SampleCount, 1));
            return float4(visibility, visibility, visibility, 1);
        }
        float4 frag_final(v2f i) : SV_Target
        {
            float4 source = tex2D(_MainTex, i.uv);
            float visibility = saturate(tex2D(_AOTex, i.cameraUV).r);
            // Post-process approximation: modulates the full source lighting.
            return float4(source.rgb * lerp(_AOCol.rgb, float3(1,1,1), visibility), source.a);
        }
        ENDCG
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag_final
            ENDCG
        }
    }
}
