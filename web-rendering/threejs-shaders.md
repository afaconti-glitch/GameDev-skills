---
name: threejs-shaders
description: Three.js custom shader authoring — ShaderMaterial, RawShaderMaterial, uniform types, GLSL patterns (vertex displacement, Fresnel, rim lighting, dissolve, noise), and extending built-in materials via onBeforeCompile. Use when writing custom visual effects, extending existing materials, or optimising GPU shader code. Adapted from cloudai-x/threejs-skills (MIT).
license: Proprietary
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project GLSL source files and Chrome DevTools / Spector.js captures.
metadata:
  owner: game-delivery
  version: "1.0.0"
  language: "en-GB"
  category: "web-rendering"
  tags:
    - three-js
    - shaders
    - glsl
    - shadermaterial
    - uniforms
    - vertex-shader
    - fragment-shader
    - visual-effects
---

# Three.js Shaders

## Quick Start

```javascript
import * as THREE from 'three';

const material = new THREE.ShaderMaterial({
  uniforms: {
    uTime:    { value: 0 },
    uColour:  { value: new THREE.Color(0x00aaff) },
  },
  vertexShader: `
    uniform float uTime;
    varying vec2 vUv;

    void main() {
      vUv = uv;
      vec3 pos = position;
      pos.y += sin(pos.x * 3.0 + uTime) * 0.1;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    }
  `,
  fragmentShader: `
    uniform vec3 uColour;
    varying vec2 vUv;

    void main() {
      gl_FragColor = vec4(uColour * vUv.y, 1.0);
    }
  `,
});

// Update uniform in render loop
const clock = new THREE.Clock();
function animate() {
  material.uniforms.uTime.value = clock.getElapsedTime();
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}
```

---

## ShaderMaterial vs RawShaderMaterial

| Feature | ShaderMaterial | RawShaderMaterial |
|---|---|---|
| Built-in uniforms | ✅ (projectionMatrix, modelViewMatrix, etc.) | ❌ — must declare all |
| Precision declaration | Auto | Must add manually |
| Best for | Most custom shaders | Full control / porting external GLSL |
| Chunk injection | Via `#include` | Not available |

```javascript
// RawShaderMaterial — must declare everything
const rawMat = new THREE.RawShaderMaterial({
  uniforms: { uTime: { value: 0 } },
  vertexShader: `
    precision mediump float;

    uniform float uTime;
    uniform mat4 projectionMatrix;
    uniform mat4 modelViewMatrix;

    attribute vec3 position;
    attribute vec2 uv;

    varying vec2 vUv;

    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: `
    precision mediump float;
    varying vec2 vUv;

    void main() {
      gl_FragColor = vec4(vUv, 0.0, 1.0);
    }
  `,
});
```

---

## Uniform Types

```javascript
const uniforms = {
  // Scalars
  uFloat:   { value: 1.0 },
  uInt:     { value: 42 },
  uBool:    { value: true },

  // Vectors
  uVec2:    { value: new THREE.Vector2(1, 0) },
  uVec3:    { value: new THREE.Vector3(0, 1, 0) },
  uVec4:    { value: new THREE.Vector4(1, 0, 0, 1) },
  uColour:  { value: new THREE.Color(0xff0000) },

  // Matrices
  uMat3:    { value: new THREE.Matrix3() },
  uMat4:    { value: new THREE.Matrix4() },

  // Textures
  uMap:     { value: texture },
  uCubeMap: { value: cubeTexture },

  // Arrays
  uFloatArr: { value: [0.1, 0.2, 0.3] },
  uVec3Arr:  { value: [new THREE.Vector3(), new THREE.Vector3()] },
};

// Update in render loop — always mutate .value, never replace the uniform object
material.uniforms.uTime.value  = clock.getElapsedTime();
material.uniforms.uColour.value.setHSL(t, 1, 0.5);
```

---

## Built-in ShaderMaterial Uniforms

Available without declaring when using `ShaderMaterial`:

```glsl
// Matrices
uniform mat4 modelMatrix;          // Object → world
uniform mat4 viewMatrix;           // World → camera
uniform mat4 projectionMatrix;     // Camera → clip
uniform mat4 modelViewMatrix;      // Object → camera (modelMatrix * viewMatrix)
uniform mat3 normalMatrix;         // Normal transform

// Camera
uniform vec3 cameraPosition;

// Attributes (available in vertex shader)
attribute vec3 position;
attribute vec3 normal;
attribute vec2 uv;
attribute vec4 tangent;
```

---

## Shader Patterns

### 1. Texture Sampling

```glsl
// Vertex
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

// Fragment
uniform sampler2D uMap;
varying vec2 vUv;
void main() {
  vec4 colour = texture2D(uMap, vUv);
  gl_FragColor = colour;
}
```

### 2. Vertex Displacement

```glsl
// Vertex
uniform float uTime;
uniform float uAmplitude;
uniform float uFrequency;
varying vec2 vUv;

void main() {
  vUv = uv;
  vec3 pos = position;
  pos.y += sin(pos.x * uFrequency + uTime) * uAmplitude;
  pos.y += cos(pos.z * uFrequency * 0.7 + uTime * 1.3) * uAmplitude * 0.5;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}
```

### 3. Fresnel Effect

```glsl
// Vertex
varying vec3 vNormal;
varying vec3 vViewDir;

void main() {
  vNormal  = normalize(normalMatrix * normal);
  vViewDir = normalize(cameraPosition - (modelMatrix * vec4(position, 1.0)).xyz);
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

// Fragment
uniform vec3 uBaseColour;
uniform vec3 uFresnelColour;
uniform float uFresnelPower;
varying vec3 vNormal;
varying vec3 vViewDir;

void main() {
  float fresnel = pow(1.0 - abs(dot(vNormal, vViewDir)), uFresnelPower);
  vec3 colour   = mix(uBaseColour, uFresnelColour, fresnel);
  gl_FragColor  = vec4(colour, 1.0);
}
```

### 4. Rim Lighting

```glsl
// Fragment
uniform vec3 uRimColour;
uniform float uRimWidth;
varying vec3 vNormal;
varying vec3 vViewDir;

void main() {
  float rim    = 1.0 - max(dot(normalize(vNormal), normalize(vViewDir)), 0.0);
  rim          = smoothstep(1.0 - uRimWidth, 1.0, rim);
  vec3 colour  = vec3(0.2) + uRimColour * rim;
  gl_FragColor = vec4(colour, 1.0);
}
```

### 5. Noise-Based Dissolve

```glsl
// Fragment
uniform sampler2D uNoiseMap;
uniform float uThreshold;   // 0 = fully visible, 1 = fully dissolved
varying vec2 vUv;

void main() {
  float noise = texture2D(uNoiseMap, vUv).r;
  if (noise < uThreshold) discard;

  // Soft edge
  float edge = smoothstep(uThreshold, uThreshold + 0.05, noise);
  vec3 edgeColour = mix(vec3(1.0, 0.3, 0.0), vec3(1.0), edge);
  gl_FragColor    = vec4(edgeColour, 1.0);
}
```

### 6. Procedural Noise in GLSL

```glsl
// Simple value noise
float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float valueNoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f); // Smooth step

  return mix(
    mix(hash(i + vec2(0,0)), hash(i + vec2(1,0)), u.x),
    mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), u.x),
    u.y
  );
}

void main() {
  float n = valueNoise(vUv * 8.0 + uTime * 0.5);
  gl_FragColor = vec4(vec3(n), 1.0);
}
```

---

## Extending Built-in Materials (onBeforeCompile)

Modify Three.js standard materials without writing a full shader from scratch.

```javascript
const material = new THREE.MeshStandardMaterial({ color: 0xffffff });

material.onBeforeCompile = shader => {
  // Inject custom uniforms
  shader.uniforms.uTime = { value: 0 };
  materialRef.userData.shader = shader; // Save reference for updates

  // Inject into vertex shader
  shader.vertexShader = shader.vertexShader
    .replace(
      '#include <begin_vertex>',
      `
      #include <begin_vertex>
      transformed.y += sin(transformed.x * 3.0 + uTime) * 0.1;
      `,
    );

  // Inject into fragment shader
  shader.fragmentShader = shader.fragmentShader
    .replace(
      'uniform vec3 diffuse;',
      `
      uniform vec3 diffuse;
      uniform float uTime;
      `,
    );
};

// Store ref and update
let savedShader;
material.onBeforeCompile = shader => {
  savedShader = shader;
  shader.uniforms.uTime = { value: 0 };
};

function animate() {
  if (savedShader) savedShader.uniforms.uTime.value = clock.getElapsedTime();
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}
```

---

## Instanced Rendering with Custom Shaders

```javascript
const count    = 10000;
const geometry = new THREE.BoxGeometry(0.1, 0.1, 0.1);
const material = new THREE.ShaderMaterial({
  uniforms: { uTime: { value: 0 } },
  vertexShader: `
    attribute vec3 instanceOffset;
    attribute vec3 instanceColour;
    uniform float uTime;
    varying vec3 vColour;

    void main() {
      vColour = instanceColour;
      vec3 pos = position + instanceOffset;
      pos.y += sin(pos.x + uTime) * 0.2;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    }
  `,
  fragmentShader: `
    varying vec3 vColour;
    void main() { gl_FragColor = vec4(vColour, 1.0); }
  `,
});

// Add per-instance attributes
const offsets = new Float32Array(count * 3);
const colours = new Float32Array(count * 3);
for (let i = 0; i < count; i++) {
  offsets.set([Math.random() * 20 - 10, 0, Math.random() * 20 - 10], i * 3);
  colours.set([Math.random(), Math.random(), Math.random()], i * 3);
}
geometry.setAttribute('instanceOffset', new THREE.InstancedBufferAttribute(offsets, 3));
geometry.setAttribute('instanceColour', new THREE.InstancedBufferAttribute(colours, 3));

const mesh = new THREE.InstancedMesh(geometry, material, count);
scene.add(mesh);
```

---

## Performance Tips

1. **Avoid branching** — replace `if/else` with `mix()` and `step()`
2. **Lower precision on mobile** — `mediump float` is ~2× faster than `highp float`
3. **Pack varyings** — use `vec4` rather than 4 separate floats to reduce interpolator count
4. **Minimise texture samples** — pack RGBA channels instead of separate textures
5. **Move calculations to vertex shader** — interpolated results are cheaper than per-fragment re-computation
6. **Precompute on CPU** — constants and static values belong in uniforms, not recalculated each fragment

```glsl
// BAD — branching causes GPU divergence
if (value > 0.5) colour = colourA;
else             colour = colourB;

// GOOD — branchless
colour = mix(colourB, colourA, step(0.5, value));

// BAD — 4 texture lookups
float r = texture2D(mapR, uv).r;
float g = texture2D(mapG, uv).r;
float b = texture2D(mapB, uv).r;
float a = texture2D(mapA, uv).r;

// GOOD — 1 packed texture lookup
vec4 packed = texture2D(packedMap, uv);
```

---

## See Also

- `three-js-best-practices` — shader mobile optimisation rules
- `threejs-materials` — built-in material types and PBR properties
- `threejs-textures` — texture loading and UV mapping
- `threejs-fundamentals` — ShaderMaterial uniform update patterns
