//
//  Shader.metal
//  t20210712
//
//  Created by 有本淳吾 on 2021/07/14.
//

#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

constexpr sampler samplerBilinear(coord::normalized,
                                 address::repeat,
                                 filter::linear,
                                 mip_filter::nearest);


[[visible]]
void simpleSurface(realitykit::surface_parameters params)
{
//    auto surface = params.surface();
//    half3 oceanBlue = half3(0, 0.412, 0.58);
//    surface.set_base_color(
//                           oceanBlue
//                           );
    float tim = params.uniforms().time();
    
    float2 uv = params.geometry().uv0();
    uv.y += (int(tim * 500) % 100) * 0.01;

    uv.y = 1.0 - uv.y;

    auto surface = params.surface();
    auto tex = params.textures();

    surface.set_base_color(tex.custom().sample(samplerBilinear, uv).b);
    surface.set_roughness(1.0);
}

