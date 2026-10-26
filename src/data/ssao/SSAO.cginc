#ifndef SSAO_CGINC
#define SSAO_CGINC
#include "UnityCG.cginc"
UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
sampler2D _CameraDepthNormalsTexture;
sampler2D _CameraGBufferTexture2;
float4 _CameraDepthTexture_TexelSize;
float4x4 _VPMatrix_invers;
float4x4 _NormalToWorld;
float _UseGBuffer;

// Work in camera clip UVs; texture storage can be flipped on D3D.
float2 DepthUV(float2 uv)
{
#if UNITY_UV_STARTS_AT_TOP
    if (_CameraDepthTexture_TexelSize.y < 0) uv.y = 1 - uv.y;
#endif
    return uv;
}
float GetRawDepth(float2 uv)
{
    return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, DepthUV(uv));
}
bool IsBackground(float2 uv)
{
#if defined(UNITY_REVERSED_Z)
    return GetRawDepth(uv) <= 0.000001;
#else
    return GetRawDepth(uv) >= 0.999999;
#endif
}
float4 GetWorldPos(float2 uv)
{
    float depth = GetRawDepth(uv);
#if !defined(UNITY_REVERSED_Z)
    depth = lerp(UNITY_NEAR_CLIP_VALUE, 1.0, depth);
#endif
    float4 position = mul(_VPMatrix_invers, float4(uv * 2 - 1, depth, 1));
    return position / position.w;
}
float GetEyeDepth(float2 uv)
{
    float depth = GetRawDepth(uv);
    if (unity_OrthoParams.w > 0.5)
    {
#if defined(UNITY_REVERSED_Z)
        depth = 1 - depth;
#endif
        return lerp(_ProjectionParams.y, _ProjectionParams.z, depth);
    }
    return LinearEyeDepth(depth);
}
float3 GetWorldNormal(float2 uv)
{
    uv = DepthUV(uv);
    float3 normal;
    if (_UseGBuffer > 0.5)
        normal = tex2D(_CameraGBufferTexture2, uv).xyz * 2 - 1;
    else
        normal = mul((float3x3)_NormalToWorld,
            DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, uv)));
    return normal * rsqrt(max(dot(normal, normal), 1e-8));
}
float Hash(float2 p)
{
    return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}
#endif
