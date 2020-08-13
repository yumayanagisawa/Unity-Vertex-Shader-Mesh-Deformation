Shader "Custom/Noise"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _Frequency("Wave Freqency", Range(1, 8)) = 2
        _Size("Wave Size", Range(0, 5)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        //#pragma surface surf Standard vertex:vert
        #pragma surface surf Standard nolightmap addshadow vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float _Frequency, _Size;

        // classic perlin noise
        float3 mod289(float3 x)
        {
            return x - floor(x * (1.0 / 289.0)) * 289.0;
        }
        float4 mod289(float4 x)
        {
            return x - floor(x * (1.0 / 289.0)) * 289.0;
        }
        float4 permute(float4 x)
        {
            return mod289(((x * 34.0) + 1.0) * x);
        }
        float4 taylorInvSqrt(float4 r)
        {
            return 1.79284291400159 - 0.85373472095314 * r;
        }
        float3 fade(float3 t) {
            return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
        }
        float cnoise(float3 P)
        {
            float3 Pi0 = floor(P);
            float3 Pi1 = Pi0 + float3(1.0, 1.0, 1.0);
            Pi0 = mod289(Pi0);
            Pi1 = mod289(Pi1);
            float3 Pf0 = frac(P);
            float3 Pf1 = Pf0 - float3(1.0, 1.0, 1.0);
            float4 ix = float4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
            float4 iy = float4(Pi0.yy, Pi1.yy);
            float4 iz0 = Pi0.zzzz;
            float4 iz1 = Pi1.zzzz;
            float4 ixy = permute(permute(ix) + iy);
            float4 ixy0 = permute(ixy + iz0);
            float4 ixy1 = permute(ixy + iz1);
            float4 gx0 = ixy0 * (1.0 / 7.0);
            float4 gy0 = frac(floor(gx0) * (1.0 / 7.0)) - 0.5;
            gx0 = frac(gx0);
            float4 gz0 = float4(0.5, 0.5, 0.5, 0.5) - abs(gx0) - abs(gy0);
            float4 sz0 = step(gz0, float4(0.0, 0.0, 0.0, 0.0));
            gx0 -= sz0 * (step(0.0, gx0) - 0.5);
            gy0 -= sz0 * (step(0.0, gy0) - 0.5);
            float4 gx1 = ixy1 * (1.0 / 7.0);
            float4 gy1 = frac(floor(gx1) * (1.0 / 7.0)) - 0.5;
            gx1 = frac(gx1);
            float4 gz1 = float4(0.5, 0.5, 0.5, 0.5) - abs(gx1) - abs(gy1);
            float4 sz1 = step(gz1, float4(0.0, 0.0, 0.0, 0.0));
            gx1 -= sz1 * (step(0.0, gx1) - 0.5);
            gy1 -= sz1 * (step(0.0, gy1) - 0.5);
            float3 g000 = float3(gx0.x, gy0.x, gz0.x);
            float3 g100 = float3(gx0.y, gy0.y, gz0.y);
            float3 g010 = float3(gx0.z, gy0.z, gz0.z);
            float3 g110 = float3(gx0.w, gy0.w, gz0.w);
            float3 g001 = float3(gx1.x, gy1.x, gz1.x);
            float3 g101 = float3(gx1.y, gy1.y, gz1.y);
            float3 g011 = float3(gx1.z, gy1.z, gz1.z);
            float3 g111 = float3(gx1.w, gy1.w, gz1.w);
            float4 norm0 = taylorInvSqrt(float4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
            g000 *= norm0.x;
            g010 *= norm0.y;
            g100 *= norm0.z;
            g110 *= norm0.w;
            float4 norm1 = taylorInvSqrt(float4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
            g001 *= norm1.x;
            g011 *= norm1.y;
            g101 *= norm1.z;
            g111 *= norm1.w;
            float n000 = dot(g000, Pf0);
            float n100 = dot(g100, float3(Pf1.x, Pf0.yz));
            float n010 = dot(g010, float3(Pf0.x, Pf1.y, Pf0.z));
            float n110 = dot(g110, float3(Pf1.xy, Pf0.z));
            float n001 = dot(g001, float3(Pf0.xy, Pf1.z));
            float n101 = dot(g101, float3(Pf1.x, Pf0.y, Pf1.z));
            float n011 = dot(g011, float3(Pf0.x, Pf1.yz));
            float n111 = dot(g111, Pf1);
            float3 fade_xyz = fade(Pf0);
            float4 n_z = lerp(float4(n000, n100, n010, n110), float4(n001, n101, n011, n111), fade_xyz.z);
            float2 n_yz = lerp(n_z.xy, n_z.zw, fade_xyz.y);
            float n_xyz = lerp(n_yz.x, n_yz.y, fade_xyz.x);
            return 2.2 * n_xyz;
        }
        
        float ApplyNoise(float3 p) {
            //float3 displacement = _Size * cnoise(1.3 * (sin(_Time.y * .5) + 2.) * p + _Time.y);
            float displacement = _Size * cnoise(_Frequency * p + _Time.y);
            return displacement;
        }


        void vert(inout appdata_full v) {

            float3 v0 = v.vertex.xyz;
            float3 bitangent = cross(v.normal, v.tangent.xyz);
            float3 v1 = v0 + (v.tangent.xyz * 0.01);
            float3 v2 = v0 + (bitangent * 0.01);

            float ns0 = ApplyNoise(v0);
            v0.xyz += ((ns0 + 1) / 2) * v.normal;

            float ns1 = ApplyNoise(v1);
            v1.xyz += ((ns1 + 1) / 2) * v.normal;

            float ns2 = ApplyNoise(v2);
            v2.xyz += ((ns2 + 1) / 2) * v.normal;

            float3 vn = cross(v2 - v0, v1 - v0);

            v.normal = normalize(-vn);
            v.vertex.xyz = v0 * .5;

        }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
