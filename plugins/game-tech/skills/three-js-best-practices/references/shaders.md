# Shaders — GLSL and TSL

Split out of [`three-js-best-practices`](../SKILL.md) to keep that file inside the 500-line convention.

**Read this when** writing, reviewing or optimising custom shader code, or migrating GLSL to TSL.

## Shaders (GLSL)

### Precision on mobile

**`mediump` is ~2× faster than `highp` on mobile.** Use the lowest precision that gives acceptable results.

```glsl
// BAD on mobile — all highp
precision highp float;
varying highp vec3 vNormal;
varying highp vec2 vUv;

// GOOD — lower precision where acceptable
precision mediump float;
varying mediump vec3 vNormal;
varying highp vec2 vUv; // keep highp for UV to avoid texture swimming
```

### Avoid branching in shaders

```glsl
// BAD — GPU divergence
if (value > threshold) {
  colour = colourA;
} else {
  colour = colourB;
}

// GOOD — branchless
colour = mix(colourB, colourA, step(threshold, value));
```

### Pack varyings

```glsl
// BAD — 5 varyings
varying vec3 vNormal;
varying vec2 vUv;
varying vec3 vPosition;
varying float vFresnel;
varying float vAO;

// GOOD — 2 varyings
varying vec4 vData0; // xyz: normal, w: fresnel
varying vec4 vData1; // xy: uv, z: ao, w: spare
```

### Custom shader material pattern

```javascript
const material = new THREE.ShaderMaterial({
  uniforms: {
    uTime: { value: 0 },
    uTexture: { value: texture },
  },
  vertexShader: `
    uniform float uTime;
    varying vec2 vUv;
    void main() {
      vUv = uv;
      vec3 pos = position;
      pos.y += sin(pos.x + uTime) * 0.1;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    }
  `,
  fragmentShader: `
    uniform sampler2D uTexture;
    varying vec2 vUv;
    void main() {
      gl_FragColor = texture2D(uTexture, vUv);
    }
  `,
});

// Update in render loop
material.uniforms.uTime.value = clock.getElapsedTime();
```

---

## Three.js Shading Language (TSL)

TSL is the modern, cross-platform shader authoring API for Three.js. It compiles to both GLSL (WebGL) and WGSL (WebGPU) automatically. Prefer TSL for new projects targeting WebGPU compatibility.

### Basic TSL node material

```javascript
import {
  MeshStandardNodeMaterial,
  texture,
  uniform,
  uv,
  time,
  sin,
  vec3,
} from 'three/nodes';

const mat = new MeshStandardNodeMaterial();

const uColour = uniform(new THREE.Color(0x0088ff));
const t = texture(myTexture, uv());

mat.colorNode = t.mul(uColour);
mat.roughnessNode = uniform(0.4);
```

### Animated TSL shader

```javascript
import { positionLocal, normalLocal, mix, color } from 'three/nodes';

const wave = sin(positionLocal.x.add(time)).mul(0.1);
mat.positionNode = positionLocal.add(vec3(0, wave, 0));
```

### TSL post-processing

```javascript
import { pass, bloom, fxaa } from 'three/addons/tsl/display/PostProcessing.js';

const postProcessing = new THREE.PostProcessing(renderer);
const scenePass = pass(scene, camera);
const bloomPass = bloom(scenePass.getTextureNode('output'), 0.5, 0.2);

postProcessing.outputNode = fxaa(bloomPass);

// In render loop — use renderAsync for WebGPU
await postProcessing.renderAsync();
```

---
