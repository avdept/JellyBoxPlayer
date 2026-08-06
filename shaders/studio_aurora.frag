#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uPhase;
uniform sampler2D uArt;

out vec4 fragColor;

vec2 rotate(vec2 p, float a) {
  float c = cos(a);
  float s = sin(a);
  return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

vec3 sampleArt(vec2 uv) {
  return texture(uArt, clamp(uv, 0.0, 1.0)).rgb;
}

float ditherNoise(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  float t = uPhase * 6.28318530718;
  float maxDim = max(uSize.x, uSize.y);

  float zoom = 1.15 + 0.05 * sin(t);
  vec2 baseUv = 0.5 + (frag - 0.5 * uSize) / (maxDim * zoom);
  vec3 color = sampleArt(baseUv);

  vec2 pivotA = vec2(0.85, 0.20) * uSize;
  vec2 dA = rotate(frag - pivotA, t) / (maxDim * 1.7);
  float featherA = 1.0 - smoothstep(0.275, 0.5, length(dA));
  color = mix(color, sampleArt(0.5 + dA), 0.55 * featherA);

  vec2 pivotB = vec2(0.20, 0.85) * uSize;
  vec2 dB = rotate(frag - pivotB, -2.0 * t) / (maxDim * 2.0);
  float featherB = 1.0 - smoothstep(0.275, 0.5, length(dB));
  color = mix(color, sampleArt(0.5 + dB), 0.45 * featherB);

  color *= 0.55;
  color += (ditherNoise(frag) - 0.5) * (2.0 / 255.0);

  fragColor = vec4(color, 1.0);
}
