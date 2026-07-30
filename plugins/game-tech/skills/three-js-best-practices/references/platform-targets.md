# Platform targets — WebGPU, WebXR and mobile

Split out of [`three-js-best-practices`](../SKILL.md) to keep that file inside the 500-line convention.

**Read this when** targeting the WebGPU renderer, building for VR/AR headsets, or tuning for mobile browsers.

## WebGPU Renderer

WebGPU offers GPU compute shaders and improved performance for draw-call-heavy scenes. Falls back to WebGL 2 automatically.

### Setup

```javascript
import WebGPURenderer from 'three/addons/renderers/webgpu/WebGPURenderer.js';

const renderer = new WebGPURenderer({ antialias: true });
await renderer.init(); // required — await before first render
document.body.appendChild(renderer.domElement);
```

### When to migrate to WebGPU

- Scene > 100 draw calls and CPU bound
- Particle systems > 50,000 particles
- Compute-intensive effects (physics, fluid sim)
- Already using TSL shaders

Typical speedup: 2–10× in applicable scenarios.

### GPU compute shaders

```javascript
import { compute, instanceIndex, storage, float } from 'three/nodes';

const buffer = new THREE.StorageBufferAttribute(COUNT, 4);
const storageNode = storage(buffer, 'vec4', COUNT);

const computeNode = compute(fn(storageNode), COUNT, [64]);
renderer.computeAsync(computeNode);
```

---

## WebXR

### Minimal VR setup

```javascript
renderer.xr.enabled = true;

// In HTML — requires user gesture
const button = VRButton.createButton(renderer);
document.body.appendChild(button);

// CRITICAL — use setAnimationLoop, not RAF
renderer.setAnimationLoop((timestamp, frame) => {
  renderer.render(scene, camera);
});
```

### Reference space selection

| Space | Use when |
|---|---|
| `local` | AR, or seated VR |
| `local-floor` | Room-scale VR (Quest, Vive) |
| `unbounded` | Large outdoor AR |

```javascript
renderer.xr.setReferenceSpaceType('local-floor');
```

### Controller input

```javascript
const controller = renderer.xr.getController(0);
controller.addEventListener('selectstart', onSelectStart);
controller.addEventListener('selectend', onSelectEnd);
scene.add(controller);

import { XRControllerModelFactory } from 'three/addons/webxr/XRControllerModelFactory.js';
const factory = new XRControllerModelFactory();
const grip = renderer.xr.getControllerGrip(0);
grip.add(factory.createControllerModel(grip));
scene.add(grip);
```

### Comfort targets

- Frame rate: 72 fps minimum, 90 fps preferred
- Never use continuous artificial locomotion without a comfort option (teleport)
- Keep UI elements 1–3 metres from the camera
- Avoid rendering to full resolution on every frame — use foveation where supported

---

## Mobile Optimisation

### Device detection and pixel ratio cap

```javascript
const isMobile = /Android|iPhone|iPad/i.test(navigator.userAgent);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, isMobile ? 1.5 : 2));
```

### Mobile quality profile

```javascript
if (isMobile) {
  renderer.shadowMap.enabled = false;        // disable dynamic shadows
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5));
  scene.traverse(obj => {
    if (obj.isMesh && obj.material.isMeshStandardMaterial) {
      obj.material = new THREE.MeshLambertMaterial({
        map: obj.material.map,
        color: obj.material.color,
      });
    }
  });
}
```

### iOS-specific limits

- Maximum texture size: 4096×4096 on most devices, 2048×2048 on older ones
- Maximum textures per draw call: 8
- No WebGPU in Safari < 26 (September 2025)
- No `WEBGL_compressed_texture_s3tc` — use PVRTC or KTX2 with ETC transcoder

---
