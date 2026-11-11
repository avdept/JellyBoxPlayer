#include <flutter/runtime_effect.glsl>
#include "common/sizing.glsl"
#include "common/utils.glsl"

// JellyBox variant of warp.frag: the pointer drives a flow map (see flow.frag)
// that is sampled here and dragged through the same noise and swirl passes.

uniform sampler2D u_noiseTexture;
uniform sampler2D u_flow;

uniform vec4 u_colors[10];
uniform float u_colorsCount;
uniform float u_proportion;
uniform float u_softness;
uniform float u_shape;
uniform float u_shapeScale;
uniform float u_distortion;
uniform float u_swirl;
uniform float u_swirlIterations;

uniform float u_flowStrength;
uniform float u_flowSize;

out vec4 fragColor;

vec4 wp_colorAt(int index) {
  if (index <= 0) return u_colors[0];
  if (index == 1) return u_colors[1];
  if (index == 2) return u_colors[2];
  if (index == 3) return u_colors[3];
  if (index == 4) return u_colors[4];
  if (index == 5) return u_colors[5];
  if (index == 6) return u_colors[6];
  if (index == 7) return u_colors[7];
  if (index == 8) return u_colors[8];
  return u_colors[9];
}

vec2 rotate(vec2 uv, float th) {
  return mat2(cos(th), sin(th), -sin(th), cos(th)) * uv;
}

float randomG(vec2 p) {
  vec2 uv = floor(p) / 100. + .5;
  return texture(u_noiseTexture, fract(uv)).g;
}
float valueNoise(vec2 st) {
  vec2 i = floor(st);
  vec2 f = fract(st);
  float a = randomG(i);
  float b = randomG(i + vec2(1.0, 0.0));
  float c = randomG(i + vec2(0.0, 1.0));
  float d = randomG(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  float x1 = mix(a, b, u.x);
  float x2 = mix(c, d, u.x);
  return mix(x1, x2, u.y);
}

float warpShapeAt(vec2 uv, float t, float proportion) {
  float shape = 0.;
  if (u_shape < .5) {
    vec2 checksShape_uv = uv * (.5 + 3.5 * u_shapeScale);
    shape = .5 + .5 * sin(checksShape_uv.x) * cos(checksShape_uv.y);
    shape += .48 * sign(proportion - .5) * pow(abs(proportion - .5), .5);
  } else if (u_shape < 1.5) {
    vec2 stripesShape_uv = uv * (2. * u_shapeScale);
    float f = fract(stripesShape_uv.y);
    shape = smoothstep(.0, .55, f) * (1.0 - smoothstep(.45, 1., f));
    shape += .48 * sign(proportion - .5) * pow(abs(proportion - .5), .5);
  } else {
    float shapeScaling = 5. * (1. - u_shapeScale);
    float e0 = 0.45 - shapeScaling;
    float e1 = 0.55 + shapeScaling;
    shape = smoothstep(min(e0, e1), max(e0, e1), 1.0 - uv.y + 0.3 * (proportion - 0.5));
  }
  return shape;
}

// Flutter samples runtime-effect textures nearest-neighbour, so the flow map
// is interpolated by hand with smoothed weights to keep the field continuous.
vec2 flowTexel(vec2 texel) {
  vec4 stored = texture(u_flow, (texel + .5) / u_flowSize);
  return (stored.rg * 2. - 1.) * stored.b;
}

vec2 flowAt(vec2 screenUv) {
  vec2 p = clamp(screenUv, 0., 1.) * u_flowSize - .5;
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3. - 2. * f);
  vec2 a = flowTexel(i);
  vec2 b = flowTexel(i + vec2(1., 0.));
  vec2 c = flowTexel(i + vec2(0., 1.));
  vec2 d = flowTexel(i + vec2(1., 1.));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
  vec2 uv = ps_patternUV();
  uv *= .5;

  vec2 flow = flowAt(FlutterFragCoord().xy / u_resolution);
  uv += vec2(flow.x, -flow.y) * u_flowStrength;

  vec2 stepX = .5 * ps_patternPixelStepX();
  vec2 stepY = .5 * ps_patternPixelStepY();

  const float firstFrameOffset = 118.;
  float t = 0.0625 * (u_time + firstFrameOffset);

  float n1 = valueNoise(uv * 1. + t);
  float n2 = valueNoise(uv * 2. - t);
  float angle = n1 * TWO_PI;
  uv.x += 4. * u_distortion * n2 * cos(angle);
  uv.y += 4. * u_distortion * n2 * sin(angle);

  float swirl = u_swirl;
  for (int i = 1; i <= 20; i++) {
    if (i >= int(u_swirlIterations)) break;
    float iFloat = float(i);
    uv.x += swirl / iFloat * cos(t + iFloat * 1.5 * uv.y);
    uv.y += swirl / iFloat * cos(t + iFloat * 1. * uv.x);
  }

  float proportion = clamp(u_proportion, 0., 1.);
  float shape = warpShapeAt(uv, t, proportion);
  float shapeX = warpShapeAt(uv + stepX, t, proportion);
  float shapeY = warpShapeAt(uv + stepY, t, proportion);
  float shapeFwidth = max(ps_finiteFwidth(shape, shapeX, shapeY), ps_pixelDerivative(0.5));

  float mixer = shape * (u_colorsCount - 1.);
  vec4 gradient = wp_colorAt(0);
  gradient.rgb *= gradient.a;
  float aa = shapeFwidth;
  for (int i = 1; i < 10; i++) {
    if (i >= int(u_colorsCount)) break;
    float m = clamp(mixer - float(i - 1), 0.0, 1.0);

    float localMixerStart = floor(m);
    float softness = .5 * u_softness + shapeFwidth;
    float smoothed = smoothstep(max(0., .5 - softness - aa), min(1., .5 + softness + aa), m - localMixerStart);
    float stepped = localMixerStart + smoothed;

    m = mix(stepped, m, u_softness);

    vec4 c = wp_colorAt(i);
    c.rgb *= c.a;
    gradient = mix(gradient, c, m);
  }

  vec3 color = gradient.rgb;
  float opacity = gradient.a;

  color += 1. / 256. * (fract(sin(dot(.014 * vec2(FlutterFragCoord().x, u_resolution.y - FlutterFragCoord().y), vec2(12.9898, 78.233))) * 43758.5453123) - .5);

  fragColor = vec4(color, opacity);
}
