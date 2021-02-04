//
//  shaders.metal
//  FloateingSights4var2
//
//  Created by takasiki on H30/07/24.
//  Copyright © 平成30年 takasiki. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

struct MyNodeBuffer {
    float4x4 modelViewTransform;
    float4x4 modelViewProjectionTransform;
};

struct MyVertexInput {
    float3 position [[attribute(SCNVertexSemanticPosition)]];
    float2 texCoords [[attribute(SCNVertexSemanticTexcoord0)]];
    float3 normal    [[ attribute(SCNVertexSemanticNormal) ]];
};

struct SimpleVertex
{
    float4 position [[position]];
    float2 vUv;
    float3 eyePosition;
    float3 normal;
    float noise;
    float time;
};

constexpr constant uint MAX_LIGHTS = 4;
struct LightDesc {
    uint num_lights;
    float4 light_position[MAX_LIGHTS];
    float4 light_color[MAX_LIGHTS];
    float4 light_attenuation_factors[MAX_LIGHTS];
};

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
    return mod289(((x*34.0)+1.0)*x);
}

float4 taylorInvSqrt(float4 r)
{
    return 1.79284291400159 - 0.85373472095314 * r;
}

float3 fade(float3 t) {
    return t*t*t*(t*(t*6.0-15.0)+10.0);
}

// Classic Perlin noise
float cnoise(float3 P)
{
    float3 Pi0 = floor(P); // Integer part for indexing
    float3 Pi1 = Pi0 + float3(1.0); // Integer part + 1
    Pi0 = mod289(Pi0);
    Pi1 = mod289(Pi1);
    float3 Pf0 = fract(P); // Fractional part for interpolation
    float3 Pf1 = Pf0 - float3(1.0); // Fractional part - 1.0
    float4 ix = float4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
    float4 iy = float4(Pi0.yy, Pi1.yy);
    float4 iz0 = Pi0.zzzz;
    float4 iz1 = Pi1.zzzz;
    
    float4 ixy = permute(permute(ix) + iy);
    float4 ixy0 = permute(ixy + iz0);
    float4 ixy1 = permute(ixy + iz1);
    
    float4 gx0 = ixy0 * (1.0 / 7.0);
    float4 gy0 = fract(floor(gx0) * (1.0 / 7.0)) - 0.5;
    gx0 = fract(gx0);
    float4 gz0 = float4(0.5) - abs(gx0) - abs(gy0);
    float4 sz0 = step(gz0, float4(0.0));
    gx0 -= sz0 * (step(0.0, gx0) - 0.5);
    gy0 -= sz0 * (step(0.0, gy0) - 0.5);
    
    float4 gx1 = ixy1 * (1.0 / 7.0);
    float4 gy1 = fract(floor(gx1) * (1.0 / 7.0)) - 0.5;
    gx1 = fract(gx1);
    float4 gz1 = float4(0.5) - abs(gx1) - abs(gy1);
    float4 sz1 = step(gz1, float4(0.0));
    gx1 -= sz1 * (step(0.0, gx1) - 0.5);
    gy1 -= sz1 * (step(0.0, gy1) - 0.5);
    
    float3 g000 = float3(gx0.x,gy0.x,gz0.x);
    float3 g100 = float3(gx0.y,gy0.y,gz0.y);
    float3 g010 = float3(gx0.z,gy0.z,gz0.z);
    float3 g110 = float3(gx0.w,gy0.w,gz0.w);
    float3 g001 = float3(gx1.x,gy1.x,gz1.x);
    float3 g101 = float3(gx1.y,gy1.y,gz1.y);
    float3 g011 = float3(gx1.z,gy1.z,gz1.z);
    float3 g111 = float3(gx1.w,gy1.w,gz1.w);
    
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
    float4 n_z = mix(float4(n000, n100, n010, n110), float4(n001, n101, n011, n111), fade_xyz.z);
    float2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
    float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
    return 2.2 * n_xyz;
}

// Classic Perlin noise, periodic variant
float pnoise(float3 P, float3 rep)
{
    float3 Pi0 = fmod(floor(P), rep); // Integer part, modulo period
    float3 Pi1 = fmod(Pi0 + float3(1.0), rep); // Integer part + 1, mod period
    Pi0 = mod289(Pi0);
    Pi1 = mod289(Pi1);
    float3 Pf0 = fract(P); // Fractional part for interpolation
    float3 Pf1 = Pf0 - float3(1.0); // Fractional part - 1.0
    float4 ix = float4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
    float4 iy = float4(Pi0.yy, Pi1.yy);
    float4 iz0 = Pi0.zzzz;
    float4 iz1 = Pi1.zzzz;
    
    float4 ixy = permute(permute(ix) + iy);
    float4 ixy0 = permute(ixy + iz0);
    float4 ixy1 = permute(ixy + iz1);
    
    float4 gx0 = ixy0 * (1.0 / 7.0);
    float4 gy0 = fract(floor(gx0) * (1.0 / 7.0)) - 0.5;
    gx0 = fract(gx0);
    float4 gz0 = float4(0.5) - abs(gx0) - abs(gy0);
    float4 sz0 = step(gz0, float4(0.0));
    gx0 -= sz0 * (step(0.0, gx0) - 0.5);
    gy0 -= sz0 * (step(0.0, gy0) - 0.5);
    
    float4 gx1 = ixy1 * (1.0 / 7.0);
    float4 gy1 = fract(floor(gx1) * (1.0 / 7.0)) - 0.5;
    gx1 = fract(gx1);
    float4 gz1 = float4(0.5) - abs(gx1) - abs(gy1);
    float4 sz1 = step(gz1, float4(0.0));
    gx1 -= sz1 * (step(0.0, gx1) - 0.5);
    gy1 -= sz1 * (step(0.0, gy1) - 0.5);
    
    float3 g000 = float3(gx0.x,gy0.x,gz0.x);
    float3 g100 = float3(gx0.y,gy0.y,gz0.y);
    float3 g010 = float3(gx0.z,gy0.z,gz0.z);
    float3 g110 = float3(gx0.w,gy0.w,gz0.w);
    float3 g001 = float3(gx1.x,gy1.x,gz1.x);
    float3 g101 = float3(gx1.y,gy1.y,gz1.y);
    float3 g011 = float3(gx1.z,gy1.z,gz1.z);
    float3 g111 = float3(gx1.w,gy1.w,gz1.w);
    
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
    float4 n_z = mix(float4(n000, n100, n010, n110), float4(n001, n101, n011, n111), fade_xyz.z);
    float2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
    float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
    return 2.2 * n_xyz;
}

float turbulence( float3 p ) {
    
    float w = 100.0;
    float t = -.5;
    
    for (float f = 1.0 ; f <= 10.0 ; f++ ){
        float power = pow( 2.0, f );
        t += abs( pnoise( float3( power * p ), float3( 10.0, 10.0, 10.0 ) ) / power );
    }
    return t;
}

vertex SimpleVertex myVertex(MyVertexInput in [[stage_in]],
                             constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                             constant MyNodeBuffer& scn_node [[buffer(1)]],
                             constant float4x4& mvp_matrix [[buffer(2)]],
                             constant float &random [[buffer(3)]])
{
    float time = scn_frame.time*0.3;
    
    SimpleVertex vert;
    vert.time = time;
    vert.vUv = in.texCoords;
    float ran = random;
    
    // add time to the noise parameters so it's animated
    float noise = 3.0 *  -0.10 * turbulence( 0.5 * in.normal + time );
    float b = 0.9 * pnoise( 0.05 * in.position + float3( 2.0 * time ), float3( 100.0 ) );
    float displacement = - noise + b;
    
    float3 newPosition = in.position + in.normal * displacement;
    //gl_Position = projectionMatrix * modelViewMatrix * float4( newPosition, 1.0 );
    vert.position = scn_frame.projectionTransform * scn_node.modelViewTransform * float4( newPosition, 1.0 );
    vert.eyePosition = (scn_node.modelViewTransform * float4( newPosition, 1.0 )).xyz;
    vert.noise = noise;
    
    return vert;
}

float random( float4 pos, float3 scale, float seed ){
    return fract( sin( dot( pos.xyz + seed, scale ) ) * 43758.5453 + seed ) ;
}

fragment half4 myFragment(SimpleVertex in [[stage_in]],
                          texture2d<float, access::sample> diffuseTexture [[texture(0)]],
                          texture2d<float, access::sample> noiseTexture [[texture(1)]])
{
    //constexpr sampler sampler2d(coord::normalized, filter::linear, address::repeat);
    // get a random offset
    //float r = 0.01 * random( in.position, float3( 12.9898, 78.233, 151.7182 ), 0.0 );
    
    //tを100で割ると変化が
    float time = (in.time+2.0)*-1;//timeをマイナスに
    float4 fragColor = float4(1,1,1,1);
    float2 uv;
    //uv移動
    uv = (in.vUv.xy + in.vUv.xy - fragColor.xy) / fragColor.y*2.;
    //時間、uvの長さ、uvのx,yから成る角度、循環する時間、層の数、uvの長さ*層の数Nの整数部分
    float t = pow(time,1.3), r = length(uv), a = atan2(uv.y,uv.x), N = sin(t), so = t/25, i = floor(r*so);
    //kabenのi乗 花弁の数を増やす
    float kaben = 12;//時間で増やす
    a *= floor(pow(kaben,i/so));
    //aを使って回転を制御sinで回転させて、cosにrをかけて揺らす(nobashiはどのくらい伸ばすか)
    float nobashi = 10.0;
    a += 10.0*sin(t)-nobashi*r*cos(t);
    //角度aから形を生成 /NでNの数だけ層を増やせる
    r +=  (0.5+0.5*cos(a)) / so;
    //rの整数部分を取り出す（整数部分で塗りつぶせる）/soで層ごとに分解　＊soで層の数分縮小させる（絵的にも値的にも）
    r = floor(so*r)/so;
    //(1.-r)値の反転
    fragColor = (1.-r) * float4(1.6,.6,.7,1);
    
    float3 normal = float3(in.normal);
    //拡散光と鏡面反射項の和としての指向性光の寄与を計算する
    // Calculate the contribution of the directional light as a sum of diffuse and specular terms
//    float3 directionalContribution = float3(0);
//    {
//        // Light falls off based on how closely aligned the surface normal is to the light direction
//        float nDotL = saturate(dot(normal, -sharedUniforms.directionalLightDirection));
//
//        // The diffuse term is then the product of the light color, the surface material
//        // reflectance, and the falloff
//        float3 diffuseTerm = sharedUniforms.directionalLightColor * nDotL;
//
//        // Apply specular lighting...
//        // 1) Calculate the halfway vector between the light direction and the direction they eye is looking
//        float3 halfwayVector = normalize(-sharedUniforms.directionalLightDirection - float3(in.eyePosition));
//
//        // 2) Calculate the reflection angle between our reflection vector and the eye's direction
//        float reflectionAngle = saturate(dot(normal, halfwayVector));
//
//        // 3) Calculate the specular intensity by multiplying our reflection angle with our object's shininess
//        float specularIntensity = saturate(powr(reflectionAngle, sharedUniforms.materialShininess));
//
//        // 4) Obtain the specular term by multiplying the intensity by our light's color
//        float3 specularTerm = sharedUniforms.directionalLightColor * specularIntensity;
//
//        // Calculate total contribution from this light is the sum of the diffuse and specular values
//        directionalContribution = diffuseTerm + specularTerm;
//    }
    
    // The ambient contribution, which is an approximation for global, indirect lighting, is
    // the product of the ambient light intensity multiplied by the material's reflectance
    //float3 ambientContribution = sharedUniforms.ambientLightColor;
    
    // Now that we have the contributions our light sources in the scene, we sum them together
    // to get the fragment's lighting value
    //float3 lightContributions = ambientContribution + directionalContribution + 0.3;
    
    // light
    float3 light = float3(0.1,1.0,0.3);
    float d = pow(max(0.25,dot(in.normal.xyz, light))*2.75, 1.4);
    
    fragColor.rgb = fragColor.rgb*d*0.15; //* lightContributions;
    return half4(fragColor);
}
fragment half4 sixFragment(SimpleVertex in [[stage_in]],
                          texture2d<float, access::sample> diffuseTexture [[texture(0)]],
                          texture2d<float, access::sample> noiseTexture [[texture(1)]])
{
    //constexpr sampler sampler2d(coord::normalized, filter::linear, address::repeat);
    // get a random offset
    //float r = 0.01 * random( in.position, float3( 12.9898, 78.233, 151.7182 ), 0.0 );
    
    //tを100で割ると変化が
    float time = in.time;
    float4 fragColor = float4(1,1,1,1);
    float so = 2.0;
    float2 uv;
    //uv移動
    uv = (in.vUv.xy + in.vUv.xy - fragColor.xy) / fragColor.y*2.;
    //時間、uvの長さ、uvのx,yから成る角度、循環する時間、uvの長さ*層の数の最大数
    float t = time, r = length(uv), a = atan2(uv.y,uv.x), N = sin(t), i = floor(r*so);
    //kabenの最も長い値を個数乗 花弁の数を増やす
    float kaben = pow(t,4);//時間で増やす
    a *= floor(pow(kaben,i/6.));
    //aを使って回転を制御sinで回転させて、cosにrをかけて揺らす(nobashiはどのくらい伸ばすか)
    float nobashi = 1.0;
    a += 10.0*sin(t)-nobashi*r*cos(t);
    //角度aから花弁を生成 /soで層まで花弁を伸ばすようにする（見切れさせない）
    r +=  (0.5*cos(a)) / so;
    //rの最大数で値を確定（最大の数で塗りつぶせる）/10で最大値の確定を分解10で１０層　＊soで層の数分縮小させる（絵的にも値的にも）
    r = floor(so*r)/so;
    //(1.-r)値の反転
    fragColor = (1.-r) * float4(.6,1.1,.7,1);
    
    float3 normal = float3(in.normal);
    
    // light
    float3 light = float3(0.1,1.0,0.3);
    float d = pow(max(0.25,dot(normal.xyz, light))*2.75, 1.4);
    
    fragColor.rgb = fragColor.rgb*d*0.15; //* lightContributions;
    return half4(fragColor);
}

fragment half4 sevenFragment(SimpleVertex in [[stage_in]],
                           texture2d<float, access::sample> diffuseTexture [[texture(0)]],
                           texture2d<float, access::sample> noiseTexture [[texture(1)]])
{
    //constexpr sampler sampler2d(coord::normalized, filter::linear, address::repeat);
    // get a random offset
    //float r = 0.01 * random( in.position, float3( 12.9898, 78.233, 151.7182 ), 0.0 );
    
    //tを100で割ると変化が
    float time = in.time;
    float4 fragColor = float4(1,1,1,1);
    float so = 2.0;
    float2 uv;
    //uv移動
    uv = (in.vUv.xy + in.vUv.xy - fragColor.xy) / fragColor.y*2.;
    //時間、uvの長さ、uvのx,yから成る角度、循環する時間、uvの長さ*層の数Nの最大数
    float t = time, r = length(uv), a = atan2(uv.y,uv.x), N = sin(t), i = floor(r*so);
    //kabenの最も長い値を個数乗 花弁の数を増やす
    float kaben = t;//pow(t,4);//時間で増やす
    a *= kaben;
    //aを使って回転を制御sinで回転させて、cosにrをかけて揺らす(nobashiはどのくらい伸ばすか)
    float nobashi = 1.0;
    a += 10.0*sin(t)-nobashi*r*cos(t);
    //角度aから形を生成 /NでNの数だけ層を増やせる 実数はどのくらい伸ばすか
    r +=  (0.7*cos(a)) / so;
    //rの最大数で値を確定（最大の数で塗りつぶせる）/10で最大値の確定を分解10で１０層　＊soで層の数分縮小させる（絵的にも値的にも）
    r = floor(so*r)/so;
    //(1.-r)値の反転
    fragColor = (1.-r) * float4(1.6,1.1,.7,1);
    
    float3 normal = float3(in.normal);
    
    // light
    float3 light = float3(0.1,1.0,0.3);
    float d = pow(max(0.25,dot(normal.xyz, light))*2.75, 1.4);
    
    fragColor.rgb = fragColor.rgb*d*0.2; //* lightContributions;
    return half4(fragColor);
}

fragment half4 eightFragment(SimpleVertex in [[stage_in]],
                             texture2d<float, access::sample> diffuseTexture [[texture(0)]],
                             texture2d<float, access::sample> noiseTexture [[texture(1)]])
{
    //constexpr sampler sampler2d(coord::normalized, filter::linear, address::repeat);
    // get a random offset
    //float r = 0.01 * random( in.position, float3( 12.9898, 78.233, 151.7182 ), 0.0 );
    
    //tを100で割ると変化が
    float time = in.time;
    float4 fragColor = float4(1,1,1,1);
    float so = 2.0;
    float2 uv;
    //uv移動
    uv = (in.vUv.xy + in.vUv.xy - fragColor.xy) / fragColor.y*2.;
    //時間、uvの長さ、uvのx,yから成る角度、循環する時間、uvの長さ*層の数Nの最大数
    float t = time, r = length(uv), a = atan2(uv.y,uv.x), N = sin(t), i = floor(r*so);
    //kabenの最も長い値を個数乗 花弁の数を増やす
    float kaben = 10;//pow(t,4);//時間で増やす
    a *= kaben;
    //aを使って回転を制御sinで回転させて、cosにrをかけて揺らす(yurashiはどのくらいさらに揺らすか)
    float yurashi = 1.0;
    a += 10.0*sin(t)-yurashi*r*cos(t);
    //角度aから形を生成 /NでNの数だけ層を増やせる nobashiは花弁同士の
    float nobashi = 0.7;
    r +=  (nobashi*tan(a)) / so;
    //rの最大数で値を確定（最大の数で塗りつぶせる）/10で最大値の確定を分解10で１０層　＊soで層の数分縮小させる（絵的にも値的にも）
    r = floor(so*r)/so;
    //(1.-r)値の反転
    fragColor = (1.-r) * float4(.6,1.1,1.7,1);
    
    float3 normal = float3(in.normal);
    
    // light
    float3 light = float3(0.1,1.0,0.3);
    float d = pow(max(0.25,dot(normal.xyz, light))*2.75, 1.4);
    
    fragColor.rgb = fragColor.rgb*d*0.15; //* lightContributions;
    return half4(fragColor);
}

fragment half4 nineFragment(SimpleVertex in [[stage_in]],
                             texture2d<float, access::sample> diffuseTexture [[texture(0)]],
                             texture2d<float, access::sample> noiseTexture [[texture(1)]])
{
    //constexpr sampler sampler2d(coord::normalized, filter::linear, address::repeat);
    // get a random offset
    //float r = 0.01 * random( in.position, float3( 12.9898, 78.233, 151.7182 ), 0.0 );
    
    //tを100で割ると変化が
    float time = in.time;
    float4 fragColor = float4(1,1,1,1);
    float so = 10.0;
    float2 uv;
    //uv移動
    uv = (in.vUv.xy + in.vUv.xy - fragColor.xy) / fragColor.y*2.;
    //時間、uvの長さ、uvのx,yから成る角度、循環する時間、uvの長さ*層の数Nの最大数
    float t = time, r = length(uv), a = atan2(uv.y,uv.x), N = sin(t), i = floor(r*so);
    //kabenの最も長い値を個数乗 花弁の数を増やす
    float kaben = 5;//pow(t,4);//時間で増やす
    a *= floor(pow(kaben,i/6.));
    //aを使って回転を制御sinで回転させて、cosにrをかけて揺らす(nobashiはどのくらい伸ばすか)
    float nobashi = 1.0;
    a += 10.0*sin(t)-nobashi*r*cos(t);
    //角度aから形を生成 /NでNの数だけ層を増やせる
    r +=  (0.5*cos(a)) / so;
    //rの最大数で値を確定（最大の数で塗りつぶせる）/10で最大値の確定を分解10で１０層　＊soで層の数分縮小させる（絵的にも値的にも）
    r = floor(so*r)/-abs(N)*0.5;
    //(1.-r)値の反転
    fragColor = (1.-r) * float4(1.6,.1,1.7,0.1);
    
    float3 normal = float3(in.normal);
    
    // light
    float3 light = float3(0.1,1.0,0.3);
    float d = pow(max(0.25,dot(normal.xyz, light))*2.75, 1.4);
    
    fragColor.rgb = fragColor.rgb*d*0.09; //* lightContributions;
    return half4(fragColor);
}
