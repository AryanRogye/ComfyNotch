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
    out.position = vertices[vertexID];
    out.uv = out.position.xy * 0.5 + 0.5; // convert to [0,1] for fragment
    return out;
}

fragment float4 blobFragment(VertexOut in [[stage_in]],
                             constant float &time [[buffer(0)]]) {
    float2 uv = in.uv * 2.0 - 1.0;

    float2 center1 = float2(sin(time * 0.8), cos(time * 1.2)) * 0.3;
    float2 center2 = float2(cos(time * 0.5), sin(time * 0.6)) * 0.4;

    float r1 = 0.3 / length(uv - center1);
    float r2 = 0.3 / length(uv - center2);

    float intensity = r1 + r2;

    float4 color = mix(float4(0.2, 0.4, 1.0, 1.0), float4(1.0, 0.5, 0.8, 1.0), sin(time) * 0.5 + 0.5);
    return color * smoothstep(1.5, 2.5, intensity);
}
