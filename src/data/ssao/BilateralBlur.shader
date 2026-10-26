Shader "SSAO/BilateralBlur"
{
    Properties { _MainTex ("Source", 2D) = "white" {} }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        CGINCLUDE
        #include "SSAO.cginc"
        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        float _BlurRadius, _BilaterFilterFactor, _DepthSigma, _UseGuidance;
        struct v2f
        {
            float4 vertex : SV_POSITION;
            float2 uv : TEXCOORD0;
            float2 delta : TEXCOORD1;
        };
        v2f vert_h(appdata_img v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            o.delta = abs(_MainTex_TexelSize.xy) * float2(_BlurRadius, 0);
            return o;
        }
        v2f vert_v(appdata_img v)
        {
            v2f o = vert_h(v);
            o.delta = abs(_MainTex_TexelSize.xy) * float2(0, _BlurRadius);
            return o;
        }
        float4 frag(v2f i) : SV_Target
        {
            float3 normal = 0;
            float depth = 0;
            if (_UseGuidance > 0.5)
            {
                if (IsBackground(i.uv)) return 1;
                normal = GetWorldNormal(i.uv);
                depth = GetEyeDepth(i.uv);
            }
            float total = 0.37004405286;
            float result = tex2D(_MainTex, i.uv).r * total;
            [unroll]
            for (int offset = -3; offset <= 3; ++offset)
            {
                if (offset == 0) continue;
                float2 uv = i.uv + offset * i.delta;
                if (any(uv < 0) || any(uv > 1)) continue;
                float spatial = abs(offset) == 1 ? 0.31718061674
                    : (abs(offset) == 2 ? 0.19823788546 : 0.11453744493);
                float weight = spatial;
                // Gaussian uses only spatial weights, including across silhouettes.
                if (_UseGuidance > 0.5)
                {
                    if (IsBackground(uv)) continue;
                    float normalWeight = smoothstep(_BilaterFilterFactor, 1.0, dot(normal, GetWorldNormal(uv)));
                    float difference = (GetEyeDepth(uv) - depth) / _DepthSigma;
                    weight *= normalWeight * exp(-0.5 * difference * difference);
                }
                result += tex2D(_MainTex, uv).r * weight;
                total += weight;
            }
            float visibility = result / total;
            return float4(visibility, visibility, visibility, 1);
        }
        ENDCG
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_h
            #pragma fragment frag
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_v
            #pragma fragment frag
            ENDCG
        }
    }
}
