// TODO-3: implement the Clustered Deferred fullscreen fragment shader

// Similar to the Forward+ fragment shader, but with vertex information coming from the G-buffer instead.

@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read> clusterSet: ClusterSet;
@group(${bindGroup_scene}) @binding(3) var<uniform> camUniforms: CameraUniforms;
@group(${bindGroup_scene}) @binding(4) var<uniform> screenHeight: f32;
@group(${bindGroup_scene}) @binding(5) var<uniform> screenWidth: f32;
@group(${bindGroup_scene}) @binding(6) var<uniform> clusterRowLength: f32;

@group(1) @binding(0) var normalDepth: texture_2d<f32>;
@group(1) @binding(1) var normalDepthSampler: sampler;
@group(1) @binding(2) var color: texture_2d<f32>;
@group(1) @binding(3) var colorSampler: sampler;

struct FragmentInput
{
    @builtin(position) fragPos: vec4f,
    @location(0) pos: vec3f,
    @location(1) nor: vec3f,
    @location(2) uv: vec2f
}

struct FragmentOutput
{
    @location(0) color: vec4f,
    @location(1) nor: vec4f
}

@fragment
fn main(in: FragmentInput) -> FragmentOutput
{
    var out: FragmentOutput;


    //calculate diffuse color
    //let uv = vec2f(0.5*(in.pos.x+1), 0.5*(-in.pos.y+1));
    // let uv = vec2f(in.fragPos.x / screenWidth, in.fragPos.y / screenHeight);
    // let diffuseColor = textureSample(normalDepth, normalDepthSampler, uv);
    //out.color = vec4f(diffuseColor.xyz, 1);
    //out.color = vec4f(1,1, 0, 1);

    //out.color = vec4f(in.fragPos.xyz/1000, 1);
    let fragposUV = vec2f(in.fragPos.x / (8*screenWidth), in.fragPos.y / (8*screenHeight));
    //out.color = vec4f(fragposUV, 0, 1);
    let normal = textureSample(normalDepth, normalDepthSampler, fragposUV);
    let diffuseColor = textureSample(color, colorSampler, fragposUV);
    out.color = vec4f(diffuseColor.xyz, 1);

    //out.color = vec4f(diffuseColor.w, diffuseColor.w, diffuseColor.w, 1);

    var totalLightContrib = vec3f(0, 0, 0);
    for (var lightIdx = 0u; lightIdx < lightSet.numLights; lightIdx++) {
        let light = lightSet.lights[lightIdx];
        totalLightContrib += calculateLightContrib(light, in.pos, normalize(in.nor));
    }

    var finalColor = diffuseColor.rgb * totalLightContrib;
    //out.color = vec4f(finalColor.xyz, 1);
    
    return out;
}