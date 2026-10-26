Shader "SSAO/NormalCompare"
{
    Properties { _MainTex ("Source", 2D) = "white" {} }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        CGINCLUDE
        #include "SSAO.cginc"
        float4 _MainTex_TexelSize;
        struct v2f { float4 vertex : SV_POSITION; float2 uv : TEXCOORD0; };
        v2f vert(appdata_img v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
#if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0) o.uv.y = 1 - o.uv.y;
#endif
            return o;
        }
        float4 forwardNormal(v2f i) : SV_Target
        {
            float3 normalVS = DecodeViewNormalStereo(tex2D(_CameraDepthNormalsTexture, DepthUV(i.uv)));
            float3 normalWS = normalize(mul((float3x3)_NormalToWorld, normalVS));
            return float4(normalWS * 0.5 + 0.5, 1);
        }
        float4 deferredNormal(v2f i) : SV_Target
        {
            float3 normalWS = tex2D(_CameraGBufferTexture2, DepthUV(i.uv)).xyz * 2 - 1;
            normalWS *= rsqrt(max(dot(normalWS, normalWS), 1e-8));
            return float4(normalWS * 0.5 + 0.5, 1);
        }
        ENDCG
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment forwardNormal
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment deferredNormal
            ENDCG
        }
    }
}
