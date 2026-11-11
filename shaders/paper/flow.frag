#include <flutter/runtime_effect.glsl>

// JellyBox flow map pass, after the ogl Flowmap extra (oframe/ogl, MIT).
// Each tick the previous map is advected by itself and faded, then the
// pointer stroke stamps its velocity in. Red/green hold the direction
// mapped to 0..1, blue holds the speed, so an RGBA8 target is enough.

uniform vec2 u_resolution;
uniform float u_aspect;
uniform vec2 u_from;
uniform vec2 u_to;
uniform vec2 u_velocity;
uniform float u_alpha;
uniform float u_falloff;
uniform float u_dissipation;
uniform float u_advection;

uniform sampler2D u_previous;

out vec4 fragColor;

vec2 decode(vec4 stored) {
  return (stored.rg * 2. - 1.) * stored.b;
}

vec2 flowTexel(vec2 texel) {
  return decode(texture(u_previous, (texel + .5) / u_resolution));
}

vec2 flowAt(vec2 uv) {
  vec2 p = clamp(uv, 0., 1.) * u_resolution - .5;
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 a = flowTexel(i);
  vec2 b = flowTexel(i + vec2(1., 0.));
  vec2 c = flowTexel(i + vec2(0., 1.));
  vec2 d = flowTexel(i + vec2(1., 1.));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float segmentDistance(vec2 p, vec2 a, vec2 b) {
  vec2 ab = b - a;
  float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-6), 0., 1.);
  return length(p - (a + ab * t));
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_resolution;

  vec2 here = decode(texture(u_previous, uv));
  vec2 upstream = uv - here * u_advection * vec2(1. / u_aspect, 1.);
  vec2 flow = flowAt(upstream);

  float speed = max(0., length(flow) * u_dissipation - 1.5 / 255.);
  flow = speed > 0. ? normalize(flow) * speed : vec2(0.);

  vec2 p = vec2(uv.x * u_aspect, uv.y);
  vec2 a = vec2(u_from.x * u_aspect, u_from.y);
  vec2 b = vec2(u_to.x * u_aspect, u_to.y);
  float stamp = u_alpha * smoothstep(u_falloff, 0., segmentDistance(p, a, b));
  flow = mix(flow, u_velocity, stamp);

  speed = min(length(flow), 1.);
  vec2 dir = speed > 1e-4 ? flow / length(flow) : vec2(0.);
  fragColor = vec4(dir * .5 + .5, speed, 1.);
}
