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
    float2 uv;
};

vertex VertexOut vertexPassthrough(
                                   uint vertexID [[vertex_id]],
                                   constant float4 *vertices [[buffer(0)]])
{
    VertexOut out;
    
    float4 vertexGiven = vertices[vertexID];
    out.position = float4(vertexGiven.xy, 0.0, 1.0);
    out.uv = vertexGiven.zw;
    
    return out;
}

// MARK: - Ambient Gradent Shader
fragment float4 ambientGradient(VertexOut in [[stage_in]],
                                constant float &time [[buffer(0)]],
                                constant float3 &tint [[buffer(1)]],
                                constant float &blurProgress [[buffer(2)]]) {
    float2 uv = in.uv;
    
    float angle = time * 0.5;
    float2 dir = float2(cos(angle), sin(angle));
    
    float fade = dot(uv - 0.5, dir) * 1.5;
    float brightness = smoothstep(0.0, 1.0, 0.5 + 0.5 * fade);
    
    float3 finalColor = tint * brightness * 0.25;
    
    float easedProgress = pow(blurProgress, 8.0);
    // Lerp between black and the final color based on blurProgress
    float3 color = mix(float3(0.0), finalColor, easedProgress);
    
    return float4(color, 1.0);
}

// MARK: - Spotlight Shader
fragment float4 spotlight(VertexOut in [[stage_in]],
                             constant float &time [[buffer(0)]],
                             constant float3 &tint [[buffer(1)]]) {
    
    float2 uv = in.uv * 2.0 - 1.0;
    
    float2 c1 = float2(sin(time * 0.4), cos(time * 0.5)) * 0.3;
    float2 c2 = float2(cos(time * 0.3), sin(time * 0.4)) * 0.25;
    
    float r1 = 0.25 / length(uv - c1);
    float r2 = 0.25 / length(uv - c2);
    
    float intensity = r1 + r2;
    
    float glow = smoothstep(1.0, 2.0, intensity);
    
    float3 base = tint * 0.15;
    float3 blend = tint * (0.5 + 0.5 * sin(time * 0.6));
    float3 color = mix(base, blend, glow);
    
    return float4(color, 1.0);
}

// MARK: - Unused Shader
fragment float4 blurFragment(VertexOut in [[stage_in]],
                             constant float &time [[buffer(0)]],
                             constant float3 &tint [[buffer(1)]]) {
    return float4(tint, 1.0);
}
