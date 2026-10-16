@group(${bindGroup_scene}) @binding(0) var<storage, read_write> clusterSet: ClusterSet;
@group(${bindGroup_scene}) @binding(1) var<uniform> screenHeight: f32;
@group(${bindGroup_scene}) @binding(2) var<uniform> screenWidth: f32;
@group(${bindGroup_scene}) @binding(3) var<uniform> clusterRowLength: f32;
@group(${bindGroup_scene}) @binding(4) var<uniform> nearplane: f32;
@group(${bindGroup_scene}) @binding(5) var<uniform> farplane: f32;
@group(${bindGroup_scene}) @binding(6) var<uniform> camUniforms: CameraUniforms;
@group(${bindGroup_scene}) @binding(7) var<storage, read_write> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(8) var<uniform> clusterRadius: f32;

// TODO-2: implement the light clustering compute shader

// ------------------------------------
// Calculating cluster bounds:
// ------------------------------------
// For each cluster (X, Y, Z):
//     - Calculate the screen-space bounds for this cluster in 2D (XY).
//     - Calculate the depth bounds for this cluster in Z (near and far planes).
//     - Convert these screen and depth bounds into view-space coordinates.
//     - Store the computed bounding box (AABB) for the cluster.

// CHECKITOUT: this is an example of a compute shader entry point function
@compute
@workgroup_size(${moveLightsWorkgroupSize})
fn main(@builtin(global_invocation_id) globalIdx: vec3u) {
    let clusterIdx = u32(globalIdx.x);
    let intClusterRowLength = u32(clusterRowLength);

    let totalNumClusters = intClusterRowLength * intClusterRowLength;
    clusterSet.numClusters = u32(totalNumClusters);
    if (clusterIdx >= totalNumClusters) {
        return;
    }
    let clusterHeight = u32(screenHeight);
    let clusterWidth = u32(screenWidth);

    let clusterIndexX = clusterIdx % intClusterRowLength;
    let clusterIndexY = clusterIdx / intClusterRowLength;

    clusterSet.clusters[clusterIdx].minCornerXY = vec2f(f32(clusterIndexX*clusterHeight), f32(clusterIndexY*clusterWidth));
    clusterSet.clusters[clusterIdx].maxCornerXY = vec2f(f32((clusterIndexX+1)*clusterHeight), f32((clusterIndexY+1)*clusterWidth));

    let frontMax = vec4f(clusterSet.clusters[clusterIdx].maxCornerXY, 1, nearplane);
    let frontMin = vec4f(clusterSet.clusters[clusterIdx].minCornerXY, nearplane, 1);
    let backMax = vec4f(clusterSet.clusters[clusterIdx].maxCornerXY, 1, farplane);
    let backMin = vec4f(clusterSet.clusters[clusterIdx].minCornerXY, 1, farplane);

    let frontMaxPos = camUniforms.invViewProjMat * frontMax;
    let frontMinPos = camUniforms.invViewProjMat * frontMin;
    let backMaxPos = camUniforms.invViewProjMat * backMax;
    let backMinPos = camUniforms.invViewProjMat * backMin;

    clusterSet.clusters[clusterIdx].frontMax = frontMaxPos;
    clusterSet.clusters[clusterIdx].frontMin = frontMin;
    //clusterSet.clusters[clusterIdx].frontMin = frontMinPos;
    //clusterSet.clusters[clusterIdx].frontMin = vec4f(frontMinPos.x / frontMinPos.w, frontMinPos.y / frontMinPos.w, frontMinPos.z / frontMinPos.w, frontMinPos.w);
    clusterSet.clusters[clusterIdx].backMax = vec4f(backMaxPos.x / backMaxPos.w, backMaxPos.y / backMaxPos.w, backMaxPos.z / backMaxPos.w, backMaxPos.w);
    clusterSet.clusters[clusterIdx].backMin = backMinPos;

    // ------------------------------------
    // Assigning lights to clusters:
    // ------------------------------------
    // For each cluster:
    //     - Initialize a counter for the number of lights in this cluster.

    //     For each light:
    //         - Check if the light intersects with the cluster’s bounding box (AABB).
    //         - If it does, add the light to the cluster's light list.
    //         - Stop adding lights if the maximum number of lights is reached.

    //     - Store the number of lights assigned to this cluster.
    clusterSet.clusters[clusterIdx].numLights = 0;
    for (var lightIdx = 0u; lightIdx < lightSet.numLights && clusterSet.clusters[clusterIdx].numLights < 82; lightIdx++) {
        let light = lightSet.lights[lightIdx];
        let clusterCenter = (clusterSet.clusters[clusterIdx].maxCornerXY + clusterSet.clusters[clusterIdx].minCornerXY) / 2.f;
        if(distance(clusterCenter, light.screenPos) < (light.screenRadius+clusterRadius)) {
                clusterSet.clusters[clusterIdx].lights[clusterSet.clusters[clusterIdx].numLights] = light;
                clusterSet.clusters[clusterIdx].numLights ++;
                continue;
        }
    }
}
