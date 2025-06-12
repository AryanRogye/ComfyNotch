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

// MARK: - Ripple Effect
fragment float4 rippleEffect(VertexOut in [[stage_in]],
                             constant float &time [[buffer(0)]],
                             constant float3 &tint [[buffer(1)]],
                             constant float &blurProgress [[buffer(2)]]) {
    float2 uv = in.uv;
    float2 center = float2(0.5, 0.5);
    
    float dist = distance(uv, center);
    float ripple = sin(dist * 20.0 - time * 8.0) * 0.5 + 0.5;
    ripple *= exp(-dist * 3.0); // fade out ripple
    
    float3 finalColor = tint * ripple * 0.8;
    float easedProgress = smoothstep(0.0, 1.0, blurProgress);
    float3 color = mix(float3(0.0), finalColor, easedProgress);
    
    return float4(color, 1.0);
}

// MARK: - Plasma Wave
fragment float4 plasmaWave(VertexOut in [[stage_in]],
                           constant float &time [[buffer(0)]],
                           constant float3 &tint [[buffer(1)]],
                           constant float &blurProgress [[buffer(2)]]) {
    float2 uv = in.uv * 2.0 - 1.0;
    
    float plasma = sin(uv.x * 10.0 + time) +
    sin(uv.y * 8.0 + time * 1.2) +
    sin((uv.x + uv.y) * 6.0 + time * 0.8) +
    sin(length(uv) * 12.0 + time * 1.5);
    
    plasma = (plasma + 4.0) / 8.0; // normalize to [0,1]
    
    float3 finalColor = tint * plasma * 0.6;
    float easedProgress = pow(blurProgress, 4.0);
    float3 color = mix(float3(0.0), finalColor, easedProgress);
    
    return float4(color, 1.0);
}

// MARK: - Vortex Spiral
fragment float4 vortexSpiral(VertexOut in [[stage_in]],
                             constant float &time [[buffer(0)]],
                             constant float3 &tint [[buffer(1)]],
                             constant float &blurProgress [[buffer(2)]]) {
    float2 uv = in.uv * 2.0 - 1.0;
    
    float angle = atan2(uv.y, uv.x);
    float radius = length(uv);
    
    float spiral = sin(angle * 6.0 + radius * 8.0 - time * 4.0) * 0.5 + 0.5;
    spiral *= (1.0 - smoothstep(0.0, 1.0, radius)); // fade at edges
    
    float3 finalColor = tint * spiral * 0.7;
    float easedProgress = pow(blurProgress, 3.0);
    float3 color = mix(float3(0.0), finalColor, easedProgress);
    
    return float4(color, 1.0);
}

// MARK: - Breathing Glow
fragment float4 breathingGlow(VertexOut in [[stage_in]],
                              constant float &time [[buffer(0)]],
                              constant float3 &tint [[buffer(1)]],
                              constant float &blurProgress [[buffer(2)]]) {
    float2 uv = in.uv;
    float2 center = float2(0.5, 0.5);
    
    float dist = distance(uv, center);
    float breath = sin(time * 2.0) * 0.3 + 0.7; // breathing effect
    
    float glow = 1.0 / (1.0 + dist * 8.0 * breath);
    glow = pow(glow, 2.0);
    
    float3 finalColor = tint * glow * 0.5;
    float easedProgress = smoothstep(0.0, 1.0, blurProgress);
    float3 color = mix(float3(0.0), finalColor, easedProgress);
    
    return float4(color, 1.0);
}

// MARK: - Electric Grid
fragment float4 electricGrid(VertexOut in [[stage_in]],
                             constant float &time [[buffer(0)]],
                             constant float3 &tint [[buffer(1)]],
                             constant float &blurProgress [[buffer(2)]]) {
    float2 uv = in.uv * 10.0;
    
    float2 grid = abs(fract(uv) - 0.5);
    float line = min(grid.x, grid.y);
    
    float electric = sin(time * 6.0 + uv.x + uv.y) * 0.5 + 0.5;
    float intensity = (1.0 - smoothstep(0.0, 0.1, line)) * electric;
    
    float3 finalColor = tint * intensity * 0.8;
    float easedProgress = pow(blurProgress, 5.0);
    float3 color = mix(float3(0.0), finalColor, easedProgress);
    
    return float4(color, 1.0);
}

// MARK: - Noise Clouds
fragment float4 noiseClouds(VertexOut in [[stage_in]],
                            constant float &time [[buffer(0)]],
                            constant float3 &tint [[buffer(1)]],
                            constant float &blurProgress [[buffer(2)]]) {
    float2 uv = in.uv * 4.0;
    
    // Simple noise approximation using sin waves
    float noise = sin(uv.x + time * 0.5) * sin(uv.y + time * 0.3) +
    sin(uv.x * 2.0 + time * 0.8) * sin(uv.y * 1.5 + time * 0.6) * 0.5 +
    sin(uv.x * 4.0 + time * 1.2) * sin(uv.y * 3.0 + time * 0.9) * 0.25;
    
    noise = (noise + 1.75) / 3.5; // normalize
    noise = smoothstep(0.3, 0.7, noise);
    
    float3 finalColor = tint * noise * 0.4;
    float easedProgress = pow(blurProgress, 6.0);
    float3 color = mix(float3(0.0), finalColor, easedProgress);
    
    return float4(color, 1.0);
}

// MARK: - Pulsing Dots
fragment float4 pulsingDots(VertexOut in [[stage_in]],
                            constant float &time [[buffer(0)]],
                            constant float3 &tint [[buffer(1)]],
                            constant float &blurProgress [[buffer(2)]]) {
    float2 uv = in.uv * 8.0;
    float2 grid = fract(uv) - 0.5;
    
    float dist = length(grid);
    float pulse = sin(time * 4.0 + floor(uv.x) + floor(uv.y)) * 0.5 + 0.5;
    
    float dot = 1.0 - smoothstep(0.1 * pulse, 0.2 * pulse, dist);
    
    float3 finalColor = tint * dot * 0.9;
    float easedProgress = pow(blurProgress, 2.0);
    float3 color = mix(float3(0.0), finalColor, easedProgress);
    
    return float4(color, 1.0);
}

// MARK: - Wave Interference
fragment float4 waveInterference(VertexOut in [[stage_in]],
                                 constant float &time [[buffer(0)]],
                                 constant float3 &tint [[buffer(1)]],
                                 constant float &blurProgress [[buffer(2)]]) {
    float2 uv = in.uv * 2.0 - 1.0;
    
    float2 source1 = float2(sin(time * 0.7), cos(time * 0.8)) * 0.3;
    float2 source2 = float2(cos(time * 0.9), sin(time * 0.6)) * 0.4;
    
    float wave1 = sin(length(uv - source1) * 15.0 - time * 6.0);
    float wave2 = sin(length(uv - source2) * 12.0 - time * 5.0);
    
    float interference = (wave1 + wave2) * 0.5;
    interference = interference * 0.5 + 0.5; // normalize
    
    float3 finalColor = tint * interference * 0.6;
    float easedProgress = smoothstep(0.0, 1.0, blurProgress);
    float3 color = mix(float3(0.0), finalColor, easedProgress);
    
    return float4(color, 1.0);
}

// MARK: - Hexagon Pattern
fragment float4 hexagonPattern(VertexOut in [[stage_in]],
                               constant float &time [[buffer(0)]],
                               constant float3 &tint [[buffer(1)]],
                               constant float &blurProgress [[buffer(2)]]) {
    float2 uv = in.uv * 6.0;
    
    // Hexagon grid approximation
    float2 h = float2(uv.x + uv.y * 0.57735, uv.y * 1.1547);
    float2 f = fract(h) - 0.5;
    float2 a = abs(f);
    
    float hex = max(a.x * 1.732 + a.y, a.y * 2.0) - 1.0;
    hex = 1.0 - smoothstep(0.0, 0.1, hex);
    
    float pulse = sin(time * 3.0 + floor(h.x) + floor(h.y)) * 0.5 + 0.5;
    
    float3 finalColor = tint * hex * pulse * 0.7;
    float easedProgress = pow(blurProgress, 4.0);
    float3 color = mix(float3(0.0), finalColor, easedProgress);
    
    return float4(color, 1.0);
}

// MARK: - Flowing Lines
fragment float4 flowingLines(VertexOut in [[stage_in]],
                             constant float &time [[buffer(0)]],
                             constant float3 &tint [[buffer(1)]],
                             constant float &blurProgress [[buffer(2)]]) {
    float2 uv = in.uv;
    
    float flow = sin(uv.y * 8.0 + time * 2.0) * 0.1;
    float lines = sin((uv.x + flow) * 20.0 + time * 4.0);
    
    lines = pow(abs(lines), 0.5);
    lines *= sin(uv.y * 3.0 + time) * 0.3 + 0.7; // vary intensity
    
    float3 finalColor = tint * lines * 0.5;
    float easedProgress = pow(blurProgress, 3.0);
    float3 color = mix(float3(0.0), finalColor, easedProgress);
    
    return float4(color, 1.0);
}
