---
name: threejs-postprocessing
description: Three.js post-processing with EffectComposer — RenderPass, UnrealBloomPass, SSAOPass, BokehPass, FilmPass, OutlinePass, FXAA/SMAA anti-aliasing, custom ShaderPass, multi-pass composition, selective bloom, resize handling, and performance. Use when adding bloom, depth-of-field, ambient occlusion, outlines, colour grading, or any screen-space effect to a Three.js scene. Adapted from CloudAI-X/threejs-skills (MIT).
license: MIT
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project Three.js source files and Chrome DevTools GPU profiling.
disable-model-invocation: true
metadata:
  owner: game-delivery
  version: "2.0.0"
  language: "en-GB"
  category: "web-rendering"
  upstream_references:
    - "https://github.com/CloudAI-X/threejs-skills (MIT — see NOTICE.md)"
  tags:
    - three-js
    - post-processing
    - effect-composer
    - bloom
    - ssao
    - depth-of-field
    - anti-aliasing
    - outline
    - shader-pass
    - screen-space-effects
  intents:
    - effect-composition
    - bloom-setup
    - ambient-occlusion
    - depth-of-field
    - outline-effect
    - antialiasing-selection
    - custom-pass-authoring
  output_types:
    - code-example
    - api-reference
    - pass-chain-plan
---

# Three.js Post-Processing

## Quick Start

```javascript
import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass }     from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';

const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
composer.addPass(new UnrealBloomPass(
  new THREE.Vector2(window.innerWidth, window.innerHeight),
  0.5,  // strength
  0.4,  // radius
  0.85, // threshold
));

// Replace renderer.render with composer.render in the loop
function animate() {
  requestAnimationFrame(animate);
  composer.render();
}
```

---

## EffectComposer Setup

```javascript
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass }     from 'three/addons/postprocessing/RenderPass.js';

// Use a render target for HDR (floating-point) precision
const renderTarget = new THREE.WebGLRenderTarget(
  window.innerWidth,
  window.innerHeight,
  {
    type: THREE.HalfFloatType, // Required for HDR bloom
    format: THREE.RGBAFormat,
    colorSpace: THREE.SRGBColorSpace,
    samples: 4, // MSAA
  }
);

const composer = new EffectComposer(renderer, renderTarget);
composer.addPass(new RenderPass(scene, camera));

// Handle resize
function onResize() {
  composer.setSize(window.innerWidth, window.innerHeight);
  composer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
}
window.addEventListener('resize', onResize);
```

---

## Pass Reference

### RenderPass — Required First Pass

```javascript
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';

const renderPass = new RenderPass(scene, camera);
renderPass.clearColor    = new THREE.Color(0x000000);
renderPass.clearAlpha    = 1;
composer.addPass(renderPass);
```

### UnrealBloomPass — Glow / Bloom

```javascript
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';

const bloom = new UnrealBloomPass(
  new THREE.Vector2(window.innerWidth, window.innerHeight),
  1.5,  // strength (0 = no bloom, 3+ = very heavy)
  0.4,  // radius (spread)
  0.85, // threshold (luminance below this = no bloom)
);

bloom.enabled = true;
composer.addPass(bloom);

// Update in response to UI changes
bloom.strength  = 1.0;
bloom.radius    = 0.5;
bloom.threshold = 0.8;
```

### SSAOPass — Screen-Space Ambient Occlusion

```javascript
import { SSAOPass } from 'three/addons/postprocessing/SSAOPass.js';

const ssao = new SSAOPass(scene, camera, window.innerWidth, window.innerHeight);
ssao.kernelRadius = 16;
ssao.minDistance  = 0.005;
ssao.maxDistance  = 0.1;
composer.addPass(ssao);
```

### BokehPass — Depth of Field

```javascript
import { BokehPass } from 'three/addons/postprocessing/BokehPass.js';

const bokeh = new BokehPass(scene, camera, {
  focus:    500.0,  // Focus distance
  aperture: 0.025,  // Aperture (smaller = sharper)
  maxblur:  0.01,   // Maximum blur radius
});
composer.addPass(bokeh);

// Update focus point dynamically
bokeh.uniforms['focus'].value   = focusDistance;
bokeh.uniforms['aperture'].value = apertureValue;
```

### FilmPass — Film Grain and Scanlines

```javascript
import { FilmPass } from 'three/addons/postprocessing/FilmPass.js';

const film = new FilmPass(
  0.35, // noise intensity
  0.0,  // scanline intensity (0 to disable)
  648,  // scanline count
  false // greyscale
);
composer.addPass(film);
```

### DotScreenPass — Pop-Art Halftone

```javascript
import { DotScreenPass } from 'three/addons/postprocessing/DotScreenPass.js';

const dotScreen = new DotScreenPass(
  new THREE.Vector2(0, 0), // centre
  0.5,  // angle
  0.8,  // scale
);
composer.addPass(dotScreen);
```

### GlitchPass — Digital Glitch

```javascript
import { GlitchPass } from 'three/addons/postprocessing/GlitchPass.js';

const glitch = new GlitchPass();
glitch.goWild = false; // true = constant glitch
composer.addPass(glitch);
```

### OutlinePass — Object Outlines

```javascript
import { OutlinePass } from 'three/addons/postprocessing/OutlinePass.js';

const outline = new OutlinePass(
  new THREE.Vector2(window.innerWidth, window.innerHeight),
  scene,
  camera,
);

outline.edgeStrength = 3.0;
outline.edgeGlow     = 0.5;
outline.edgeThickness = 1.0;
outline.visibleEdgeColor.set('#ffffff');
outline.hiddenEdgeColor.set('#190a05');
composer.addPass(outline);

// Add/remove objects to be outlined
outline.selectedObjects = [mesh1, mesh2];
outline.selectedObjects = [];
```

---

## Anti-Aliasing

MSAA built into the renderer is the simplest; post-process AA is needed when using a custom render target.

### FXAA — Fast Approximate AA

```javascript
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js';
import { FXAAShader }  from 'three/addons/shaders/FXAAShader.js';

const fxaa = new ShaderPass(FXAAShader);
fxaa.material.uniforms['resolution'].value.x = 1 / (window.innerWidth  * renderer.getPixelRatio());
fxaa.material.uniforms['resolution'].value.y = 1 / (window.innerHeight * renderer.getPixelRatio());
composer.addPass(fxaa);

// Update on resize
function onResize() {
  fxaa.material.uniforms['resolution'].value.x = 1 / (window.innerWidth  * renderer.getPixelRatio());
  fxaa.material.uniforms['resolution'].value.y = 1 / (window.innerHeight * renderer.getPixelRatio());
}
```

### SMAA — Sub-pixel Morphological AA (Higher Quality)

```javascript
import { SMAAPass } from 'three/addons/postprocessing/SMAAPass.js';

const smaa = new SMAAPass(
  window.innerWidth  * renderer.getPixelRatio(),
  window.innerHeight * renderer.getPixelRatio(),
);
composer.addPass(smaa);
```

### TAA — Temporal AA (Reduces Shimmer)

```javascript
import { TAARenderPass } from 'three/addons/postprocessing/TAARenderPass.js';

const taa = new TAARenderPass(scene, camera);
taa.sampleLevel = 2; // 0–5; higher = slower but better quality

// Replace RenderPass with TAARenderPass
composer.addPass(taa);
```

---

## Custom ShaderPass

```javascript
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js';

const vignetteShader = {
  uniforms: {
    tDiffuse:  { value: null }, // Previous pass output — always required
    uStrength: { value: 0.5 },
    uOffset:   { value: 1.2 },
  },
  vertexShader: `
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: `
    uniform sampler2D tDiffuse;
    uniform float uStrength;
    uniform float uOffset;
    varying vec2 vUv;

    void main() {
      vec4 colour = texture2D(tDiffuse, vUv);
      vec2 uv = (vUv - 0.5) * 2.0;
      float vignette = 1.0 - dot(uv, uv) * uStrength;
      vignette = clamp(vignette, 0.0, 1.0);
      gl_FragColor = vec4(colour.rgb * vignette, colour.a);
    }
  `,
};

const vignettePass = new ShaderPass(vignetteShader);
vignettePass.uniforms['uStrength'].value = 0.7;
composer.addPass(vignettePass);
```

---

## Selective Bloom (Objects Only)

Bloom only selected objects without affecting the full scene.

```javascript
// 1. Render scene normally first (no bloom)
// 2. Temporarily replace non-blooming materials with black
// 3. Render bloom pass on the masked scene
// 4. Composite together with a ShaderPass

const BLOOM_LAYER = 1;
const bloomLayer = new THREE.Layers();
bloomLayer.set(BLOOM_LAYER);

// Mark objects to bloom
emissiveMesh.layers.enable(BLOOM_LAYER);

// Darken non-bloom objects before the bloom composer renders
const darkMaterial = new THREE.MeshBasicMaterial({ color: 0x000000 });
const materialMap  = new Map();

function darkenNonBloomed(obj) {
  if (obj.isMesh && !bloomLayer.test(obj.layers)) {
    materialMap.set(obj.uuid, obj.material);
    obj.material = darkMaterial;
  }
}

function restoreMaterials(obj) {
  if (materialMap.has(obj.uuid)) {
    obj.material = materialMap.get(obj.uuid);
    materialMap.delete(obj.uuid);
  }
}

function render() {
  scene.traverse(darkenNonBloomed);
  bloomComposer.render();
  scene.traverse(restoreMaterials);
  finalComposer.render();
}
```

---

## Colour Grading — LUT Pass

Apply a 3D look-up table for colour grading.

```javascript
import { LUTPass }   from 'three/addons/postprocessing/LUTPass.js';
import { LUTCubeLoader } from 'three/addons/loaders/LUTCubeLoader.js';

new LUTCubeLoader().load('lut/warm.cube', result => {
  const lutPass = new LUTPass();
  lutPass.lut       = result.texture3D;
  lutPass.intensity = 1.0;
  composer.addPass(lutPass);
});
```

---

## Resize Handling

```javascript
function onWindowResize() {
  const w = window.innerWidth;
  const h = window.innerHeight;

  camera.aspect = w / h;
  camera.updateProjectionMatrix();

  renderer.setSize(w, h);
  composer.setSize(w, h);

  // Update any size-dependent uniforms
  if (fxaaPass) {
    fxaaPass.material.uniforms['resolution'].value.set(
      1 / (w * renderer.getPixelRatio()),
      1 / (h * renderer.getPixelRatio()),
    );
  }
}
window.addEventListener('resize', onWindowResize);
```

---

## Performance Tips

1. **Fewer passes = better** — each pass is a full-screen render; keep total passes under 5
2. **HalfFloatType render target** — required for HDR bloom; higher precision than UnsignedByteType
3. **FXAA over MSAA for post-processing pipelines** — MSAA doesn't apply after render-to-target
4. **Disable passes when not visible** — `pass.enabled = false` skips execution entirely
5. **Reduce resolution for expensive passes** — halve the render target size for SSAO/DoF
6. **Profile with Spector.js** — inspect each pass's GPU cost individually

```javascript
// Disable bloom entirely on mobile
if (isMobile) {
  bloomPass.enabled = false;
}

// Downscale expensive pass
const halfResTarget = new THREE.WebGLRenderTarget(
  window.innerWidth / 2,
  window.innerHeight / 2,
);
```

---

## See Also

- `threejs-shaders` — writing custom fragment shaders for ShaderPass
- `threejs-fundamentals` — renderer setup and pixel ratio
- `threejs-materials` — MeshPhysicalMaterial transmission as alternative to DoF
- `three-js-best-practices` — GPU budget and mobile scaling rules
