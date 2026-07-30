---
name: three-js-best-practices
description: Three.js performance and implementation best-practice reference. Use when writing, reviewing, or optimising a Three.js application — covers memory disposal, render loop, draw calls, instancing, glTF asset loading, materials, lighting, shaders (GLSL and TSL), WebGPU, WebXR, mobile, and post-processing. Adapted from emalorenzo/three-agent-skills (MIT).
license: MIT
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project Three.js source files, Chrome DevTools Performance captures, and Spector.js GPU captures.
disable-model-invocation: true
metadata:
  owner: game-delivery
  version: "2.0.0"
  language: "en-GB"
  category: "web-rendering"
  upstream_references:
    - "https://github.com/emalorenzo/three-agent-skills (MIT — see NOTICE.md)"
  tags:
    - three-js
    - webgl
    - webgpu
    - performance
    - shaders
    - tsl
    - gltf
    - memory
    - instancing
    - webxr
    - mobile
  intents:
    - code-review
    - performance-optimisation
    - memory-audit
    - draw-call-reduction
    - shader-review
    - webgpu-migration
    - mobile-optimisation
  output_types:
    - rule-citation
    - review-findings
    - optimisation-plan
    - code-correction
---

# Three.js Best Practices

Reference guide for Three.js r170+. Rules are grouped by impact category. Within each category, critical rules are marked **CRITICAL**.

---

## 1. Memory and Disposal

**CRITICAL — Three.js does not automatically garbage-collect GPU resources.** Removing a mesh from the scene does not free its GPU memory. Always call `.dispose()` explicitly.

### Dispose geometry and material on removal

```javascript
// BAD — GPU buffer leaks
scene.remove(mesh);
mesh = null;

// GOOD — explicit GPU cleanup
function disposeMesh(mesh) {
  scene.remove(mesh);
  mesh.geometry.dispose();
  if (Array.isArray(mesh.material)) {
    mesh.material.forEach(m => disposeMaterial(m));
  } else {
    disposeMaterial(mesh.material);
  }
}

function disposeMaterial(material) {
  material.dispose();
  for (const key of Object.keys(material)) {
    const value = material[key];
    if (value && typeof value.dispose === 'function') {
      value.dispose(); // textures
    }
  }
}
```

### Recursive disposal for complex objects

```javascript
function disposeObject(object) {
  object.traverse(child => {
    if (child.isMesh) {
      child.geometry.dispose();
      const mats = Array.isArray(child.material) ? child.material : [child.material];
      mats.forEach(m => {
        m.dispose();
        Object.values(m).forEach(v => v?.isTexture && v.dispose());
      });
    }
  });
}
```

### Monitor GPU memory

```javascript
// Log current GPU memory usage
console.log('Geometries:', renderer.info.memory.geometries);
console.log('Textures:', renderer.info.memory.textures);
console.log('Draw calls:', renderer.info.render.calls);
```

---

## 2. Render Loop

**CRITICAL — Use `renderer.setAnimationLoop()` instead of `requestAnimationFrame` when targeting WebXR.** For standard projects either works, but `setAnimationLoop` is safer.

```javascript
// GOOD
renderer.setAnimationLoop((timestamp, frame) => {
  // frame is the XRFrame when in XR session
  update(timestamp);
  renderer.render(scene, camera);
});

// Stop cleanly
renderer.setAnimationLoop(null);
```

### Delta time for frame-rate-independent animation

**CRITICAL — Always use delta time. Fixed increments run at different speeds on different devices.**

```javascript
const clock = new THREE.Clock();

renderer.setAnimationLoop(() => {
  const delta = clock.getDelta();        // seconds since last frame
  const elapsed = clock.getElapsedTime(); // total seconds

  mesh.rotation.y += 1.0 * delta;        // 1 radian/second regardless of fps
  renderer.render(scene, camera);
});
```

---

## 3. Draw Calls and Instancing

**Target: fewer than 100 draw calls per frame on mobile. Each `THREE.Mesh` is one draw call.**

Monitor: `renderer.info.render.calls`

### InstancedMesh for identical objects

```javascript
// BAD — 10,000 draw calls
for (let i = 0; i < 10000; i++) {
  const mesh = new THREE.Mesh(geometry, material);
  scene.add(mesh);
}

// GOOD — 1 draw call
const instancedMesh = new THREE.InstancedMesh(geometry, material, 10000);
const dummy = new THREE.Object3D();
const color = new THREE.Color();

for (let i = 0; i < 10000; i++) {
  dummy.position.random().multiplyScalar(100);
  dummy.rotation.set(Math.random() * Math.PI, Math.random() * Math.PI, 0);
  dummy.updateMatrix();
  instancedMesh.setMatrixAt(i, dummy.matrix);
  color.setHSL(Math.random(), 0.8, 0.5);
  instancedMesh.setColorAt(i, color);
}

instancedMesh.instanceMatrix.needsUpdate = true;
if (instancedMesh.instanceColor) instancedMesh.instanceColor.needsUpdate = true;
scene.add(instancedMesh);
```

When to use `InstancedMesh`: > 50 objects with the same geometry.
When NOT to use: objects need different geometries or different materials.

### BatchedMesh for varied geometry sharing one material

```javascript
import { BatchedMesh } from 'three';

const batchedMesh = new BatchedMesh(maxObjects, maxVertices, maxIndices, material);
const geometryId = batchedMesh.addGeometry(myGeometry);
const instanceId = batchedMesh.addInstance(geometryId);
batchedMesh.setMatrixAt(instanceId, matrix);
scene.add(batchedMesh);
```

### Merge static geometry

```javascript
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const merged = mergeGeometries([geo1, geo2, geo3]);
const mesh = new THREE.Mesh(merged, sharedMaterial);
scene.add(mesh);
```

Use for geometry that never changes position. Do not merge objects that need individual transforms at runtime.

### Share material instances

```javascript
// BAD — N materials, N GPU state switches
objects.forEach(o => o.material = new THREE.MeshStandardMaterial({ color: 0xff0000 }));

// GOOD — 1 material shared
const sharedMat = new THREE.MeshStandardMaterial({ color: 0xff0000 });
objects.forEach(o => o.material = sharedMat);
```

---

## 4. Asset Loading (glTF / GLB)

### Preferred loader configuration

```javascript
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { DRACOLoader } from 'three/addons/loaders/DRACOLoader.js';
import { KTX2Loader } from 'three/addons/loaders/KTX2Loader.js';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';

const dracoLoader = new DRACOLoader();
dracoLoader.setDecoderPath('/draco/'); // host locally — not from CDN

const ktx2Loader = new KTX2Loader();
ktx2Loader.setTranscoderPath('/basis/');
ktx2Loader.detectSupport(renderer);

const loader = new GLTFLoader();
loader.setDRACOLoader(dracoLoader);
loader.setKTX2Loader(ktx2Loader);
loader.setMeshoptDecoder(MeshoptDecoder);
```

### Compression format selection

| Format | Geometry reduction | Texture reduction | Animation | Notes |
|---|---|---|---|---|
| Draco | 70–90% | — | None | Best geometry compression |
| Meshopt | 60–80% | — | Yes | Supports morph targets and animation |
| KTX2/Basis | — | 75–85% GPU memory | — | GPU-native; best texture format |
| WebP | — | 25–35% file size | — | CPU decoded; worse than KTX2 for GPU |

Prefer GLB over GLTF. Keeps assets in a single file.

### Optimise with glTF-Transform CLI

```bash
npx @gltf-transform/cli optimize input.glb output.glb \
  --draco \
  --texture-compress webp \
  --texture-size 1024
```

### Preload critical assets

```javascript
// Start loading before the scene is visible
const loader = new THREE.TextureLoader();
const texture = loader.load('/assets/diffuse.ktx2');

// Or with LoadingManager
const manager = new THREE.LoadingManager();
manager.onProgress = (url, loaded, total) => {
  updateProgressUI(loaded / total);
};
```

---

## 5. Materials and Textures

### Material cost hierarchy (ascending GPU cost)

`MeshBasicMaterial` → `MeshLambertMaterial` → `MeshPhongMaterial` → `MeshStandardMaterial` → `MeshPhysicalMaterial`

On mobile: avoid `MeshPhongMaterial` — on iOS it can drop from 60 to 15 fps. Prefer `MeshLambertMaterial` or `MeshBasicMaterial`.

### Texture size targets

| Platform | Diffuse | Normal | Mobile max |
|---|---|---|---|
| Mobile | 512×512 | 512×512 | 1024×1024 |
| Desktop mid | 1024×1024 | 1024×1024 | — |
| Desktop high | 2048×2048 | 2048×2048 | — |

Always use power-of-2 dimensions. Non-power-of-2 textures disable mipmapping.

### Combine textures to reduce sampler calls

```glsl
// BAD — 4 texture lookups
float ao        = texture2D(aoMap, uv).r;
float roughness = texture2D(roughMap, uv).r;
float metalness = texture2D(metalMap, uv).r;
float emissive  = texture2D(emissiveMap, uv).r;

// GOOD — 1 texture lookup (RGBA packing)
vec4 packed = texture2D(packedMap, uv);
float ao        = packed.r;
float roughness = packed.g;
float metalness = packed.b;
float emissive  = packed.a;
```

---

## 6. Lighting and Shadows

### Limit active lights

**Target: 3 or fewer active lights.** Each additional light increases shader complexity. Beyond 3, bake lighting.

### Avoid PointLight shadows

PointLight shadows require 6 shadow map renders (one per cube face):

```
Shadow draw calls = object count × 6 × point light count
```

100 objects + 2 point lights = 1,200 shadow draw calls. Use `DirectionalLight` or `SpotLight` for shadows.

### Size shadow maps for platform

| Platform | Shadow map size |
|---|---|
| Mobile | 512 |
| Desktop | 1024–2048 |
| Quality critical | 4096 |

```javascript
directionalLight.shadow.mapSize.setScalar(2048);
```

### Fit shadow camera frustum tightly

```javascript
const light = new THREE.DirectionalLight(0xffffff, 1);
light.castShadow = true;
light.shadow.camera.left = -20;
light.shadow.camera.right = 20;
light.shadow.camera.top = 20;
light.shadow.camera.bottom = -20;
light.shadow.camera.near = 0.5;
light.shadow.camera.far = 100;
```

### Disable shadow auto-update for static scenes

```javascript
renderer.shadowMap.autoUpdate = false;
// Call once after scene is ready
renderer.shadowMap.needsUpdate = true;
// Re-enable only when lights move
```

### Cascaded Shadow Maps for large outdoor scenes

```javascript
import { CSM } from 'three/addons/csm/CSM.js';

const csm = new CSM({
  maxFar: camera.far,
  cascades: 4,           // desktop: 4, mobile: 2
  shadowMapSize: 2048,
  lightDirection: new THREE.Vector3(-1, -1, -1).normalize(),
  camera,
  parent: scene,
});

// In render loop
csm.update();
```

### Use environment maps instead of multiple ambient lights

```javascript
import { RGBELoader } from 'three/addons/loaders/RGBELoader.js';

const pmrem = new THREE.PMREMGenerator(renderer);
new RGBELoader().load('/hdri/environment.hdr', texture => {
  scene.environment = pmrem.fromEquirectangular(texture).texture;
  texture.dispose();
  pmrem.dispose();
});
```

---

## 7. Object Pooling

**Use object pooling to eliminate garbage collection pauses during gameplay.** Critical for bullets, particles, enemies, and any frequently spawned/destroyed objects.

```javascript
class ObjectPool {
  constructor(factory, initialSize = 50) {
    this.pool = [];
    this.active = new Set();
    this.factory = factory;
    for (let i = 0; i < initialSize; i++) this.pool.push(factory());
  }

  get() {
    const obj = this.pool.pop() ?? this.factory();
    this.active.add(obj);
    obj.visible = true;
    return obj;
  }

  release(obj) {
    this.active.delete(obj);
    obj.visible = false;
    // Reset state here before returning
    this.pool.push(obj);
  }
}

// Pre-warm during loading (never during gameplay)
const bulletPool = new ObjectPool(() => {
  const mesh = new THREE.Mesh(bulletGeo, sharedMat); // shared geometry and material
  scene.add(mesh);
  mesh.visible = false;
  return mesh;
}, 200);
```

---

## 8. Debugging Tools

| Tool | Purpose | How to add |
|---|---|---|
| `stats-gl` | FPS / MS / GPU overlay | `npm install stats-gl` |
| `lil-gui` | Runtime parameter tweaking | `npm install lil-gui` |
| Spector.js | Frame GPU capture | Chrome extension |
| `renderer.info` | Draw calls and memory at runtime | Built-in |
| Chrome DevTools Performance | CPU and GPU timeline | Built-in |

```javascript
import Stats from 'stats-gl';
const stats = new Stats();
document.body.appendChild(stats.dom);

renderer.setAnimationLoop(() => {
  stats.begin();
  renderer.render(scene, camera);
  stats.end();
});
```

---


## Further reference

Detail split out of this file. Each is self-contained; read one only when its trigger applies.

- [`references/shaders.md`](./references/shaders.md) — Shaders — GLSL and TSL. Read when writing, reviewing or optimising custom shader code, or migrating GLSL to TSL.
- [`references/platform-targets.md`](./references/platform-targets.md) — Platform targets — WebGPU, WebXR and mobile. Read when targeting the WebGPU renderer, building for VR/AR headsets, or tuning for mobile browsers.
- [`references/post-processing.md`](./references/post-processing.md) — Post-processing. Read when adding bloom, depth of field, ambient occlusion, outlines or any screen-space effect.

## Quick-reference checklist

- [ ] All removed geometries, materials, and textures are disposed
- [ ] Delta time used in all animation loops
- [ ] `renderer.setAnimationLoop()` used (required for WebXR)
- [ ] Draw calls < 100 on mobile target (check `renderer.info.render.calls`)
- [ ] `InstancedMesh` used for > 50 identical objects
- [ ] Pixel ratio capped (1.5 mobile, 2 desktop)
- [ ] Textures are power-of-two and sized for target platform
- [ ] Shadow map sized for platform (512 mobile, 2048 desktop)
- [ ] Post-processing effects merged into fewest passes possible
- [ ] glTF assets use Draco/Meshopt compression + KTX2 textures
- [ ] Decoders (Draco, KTX2) hosted locally, not from CDN
