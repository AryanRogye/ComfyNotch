//
//  File.metal
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/17/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    float2 positions[6] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2(-1.0,  1.0),
        float2( 1.0, -1.0),
        float2( 1.0,  1.0)
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = (positions[vertexID] + 1.0) * 0.5;
    return out;
}

// 🔥 Full screen glow shader
fragment float4 fragment_fullGlow(VertexOut in [[stage_in]],
                                  constant float &time [[buffer(0)]],
                                  constant float3 &baseColor [[buffer(1)]]) {
    float brightness = 0.5 + 0.5 * sin(time);
    return float4(baseColor * brightness, 1.0);
}

// 0 = time   1 = float4(baseColor.rgb, pulseStrength)
fragment float4 fragment_borderGlow(VertexOut in [[stage_in]],
                                    constant float  &time       [[buffer(0)]],
                                    constant float4 &pulseInfo  [[buffer(1)]])
{
    float3 baseColor     = pulseInfo.rgb;   // album‑art hue
    float  pulseStrength = pulseInfo.a;     // fades from 1 → 0 in Swift

    // ===== border math =====================================================
    float border = 0.04;          // 4 % of panel
    float radius = 0.20;          // 20 % rounded corner (matches 20 pt)
    float2 uv    = in.texCoord;

    // distance from nearest edge
    float edgeDist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));

    // smoothstep gives us a soft fall‑off
    float glowMask = 1.0 - smoothstep(border - 0.015, border + 0.015, edgeDist);

    // rounded‑corner mask (fade out inside the quarter‑circle)
    float2 corner = clamp(uv, float2(radius, radius), float2(1.0 - radius, 1.0 - radius));
    float cornerDist = distance(uv, corner);
    float cornerMask = smoothstep(radius - border, radius, cornerDist);

    glowMask *= cornerMask;       // combine

    // ===== animated pulse ==================================================
    float wave = (sin(time * 4.0) + 1.0) * 0.5;   // fast ripple
    float brightness = glowMask * (0.3 + 0.7 * wave) * pulseStrength;

    return float4(baseColor * brightness, brightness); // premultiplied glow α
}
