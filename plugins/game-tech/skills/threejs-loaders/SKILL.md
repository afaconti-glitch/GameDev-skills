---
name: threejs-loaders
description: Three.js asset loading — GLTFLoader with DRACO/KTX2/Meshopt compression, OBJLoader+MTLLoader, FBXLoader, STLLoader, PLYLoader, RGBELoader for HDR, LoadingManager with progress/error tracking, async/Promise patterns, asset caching, and error handling. Use when loading 3D models, HDR environments, or managing multi-asset loading pipelines. Adapted from CloudAI-X/threejs-skills (MIT).
license: MIT
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project Three.js source files and asset pipeline configuration.
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
    - loaders
    - gltf
    - glb
    - draco
    - ktx2
    - fbx
    - obj
    - hdr
    - loading-manager
    - async
    - asset-pipeline
  intents:
    - model-loading
    - compression-setup
    - hdr-loading
    - load-progress-tracking
    - asset-caching
    - error-handling
  output_types:
    - code-example
    - api-reference
    - loading-pipeline-plan
---

# Three.js Loaders

## Quick Start

```javascript
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

const loader = new GLTFLoader();

loader.load(
  'model.glb',
  gltf => {
    scene.add(gltf.scene);
  },
  xhr => console.log(`${(xhr.loaded / xhr.total * 100).toFixed(0)}% loaded`),
  err => console.error('Load error:', err),
);
```

---

## LoadingManager

Tracks progress across multiple loaders simultaneously.

```javascript
const manager = new THREE.LoadingManager();

manager.onStart    = (url, loaded, total) => console.log(`Loading started: ${url}`);
manager.onLoad     = ()                   => console.log('All assets loaded');
manager.onProgress = (url, loaded, total) => {
  const pct = Math.round(loaded / total * 100);
  updateProgressBar(pct);
};
manager.onError    = url => console.error(`Failed: ${url}`);

// Pass manager to all loaders
const gltfLoader    = new GLTFLoader(manager);
const textureLoader = new THREE.TextureLoader(manager);
const audioLoader   = new THREE.AudioLoader(manager);
```

---

## GLTFLoader — Primary Format

`.glb` (binary) is the preferred production format — single file, faster load.

### Basic Usage

```javascript
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

const loader = new GLTFLoader();
loader.load('model.glb', gltf => {
  const model = gltf.scene;

  // Traverse and configure meshes
  model.traverse(child => {
    if (child.isMesh) {
      child.castShadow    = true;
      child.receiveShadow = true;
    }
  });

  scene.add(model);

  // Animations (if present)
  if (gltf.animations.length > 0) {
    const mixer = new THREE.AnimationMixer(model);
    const action = mixer.clipAction(gltf.animations[0]);
    action.play();
  }
});
```

### Async/Await Pattern

```javascript
function loadGLTF(url) {
  return new Promise((resolve, reject) => {
    new GLTFLoader().load(url, resolve, undefined, reject);
  });
}

async function init() {
  const [character, environment] = await Promise.all([
    loadGLTF('character.glb'),
    loadGLTF('environment.glb'),
  ]);

  scene.add(character.scene);
  scene.add(environment.scene);
}

init().catch(console.error);
```

### DRACO Compression

Reduces geometry file size by 60–90%. Requires the Draco decoder wasm files.

```javascript
import { GLTFLoader }   from 'three/addons/loaders/GLTFLoader.js';
import { DRACOLoader }  from 'three/addons/loaders/DRACOLoader.js';

const dracoLoader = new DRACOLoader();
dracoLoader.setDecoderPath('/libs/draco/'); // Path to draco_decoder.wasm + .js

const loader = new GLTFLoader();
loader.setDRACOLoader(dracoLoader);

loader.load('compressed-model.glb', gltf => {
  scene.add(gltf.scene);
  dracoLoader.dispose(); // Free after loading
});
```

Copy decoder files from `three/addons/libs/draco/` to your public directory.

### KTX2 Texture Compression (Basis Universal)

Compressed textures in GLTF — reduces VRAM by 4–8×.

```javascript
import { GLTFLoader }  from 'three/addons/loaders/GLTFLoader.js';
import { KTX2Loader }  from 'three/addons/loaders/KTX2Loader.js';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';

const ktx2Loader = new KTX2Loader();
ktx2Loader.setTranscoderPath('/libs/basis/');
ktx2Loader.detectSupport(renderer); // Detects GPU compressed format support

const loader = new GLTFLoader();
loader.setKTX2Loader(ktx2Loader);
loader.setMeshoptDecoder(MeshoptDecoder); // Optional — for Meshopt geometry compression

loader.load('model-ktx2.glb', gltf => {
  scene.add(gltf.scene);
});
```

### GLTF Data Access

```javascript
loader.load('model.glb', gltf => {
  // Full hierarchy
  console.log(gltf.scene);         // THREE.Group
  console.log(gltf.scenes);        // All scenes in the file

  // Animations
  console.log(gltf.animations);    // THREE.AnimationClip[]

  // Camera from GLTF (optional)
  console.log(gltf.cameras);       // THREE.Camera[]

  // Named objects
  const player = gltf.scene.getObjectByName('Player');

  // Materials
  gltf.scene.traverse(child => {
    if (child.isMesh) {
      console.log(child.material.name);
    }
  });
});
```

---

## OBJLoader + MTLLoader

```javascript
import { OBJLoader } from 'three/addons/loaders/OBJLoader.js';
import { MTLLoader } from 'three/addons/loaders/MTLLoader.js';

const mtlLoader = new MTLLoader();
mtlLoader.setPath('/assets/models/');
mtlLoader.load('model.mtl', materials => {
  materials.preload();

  const objLoader = new OBJLoader();
  objLoader.setMaterials(materials);
  objLoader.setPath('/assets/models/');
  objLoader.load('model.obj', object => {
    scene.add(object);
  });
});
```

Prefer GLTF over OBJ for new assets — GLTF supports PBR materials, animations, and compression.

---

## FBXLoader

```javascript
import { FBXLoader } from 'three/addons/loaders/FBXLoader.js';

const loader = new FBXLoader();
loader.load('character.fbx', object => {
  object.scale.setScalar(0.01); // FBX often uses cm units; convert to metres

  if (object.animations.length > 0) {
    const mixer = new THREE.AnimationMixer(object);
    mixer.clipAction(object.animations[0]).play();
  }

  scene.add(object);
});
```

FBX does not support compressed textures. Use GLTF for production when possible.

---

## STLLoader

ASCII and binary STL support. Produces geometry only — no materials.

```javascript
import { STLLoader } from 'three/addons/loaders/STLLoader.js';

const loader = new STLLoader();
loader.load('part.stl', geometry => {
  geometry.computeVertexNormals(); // STL normals are per-face

  const mesh = new THREE.Mesh(
    geometry,
    new THREE.MeshStandardMaterial({ color: 0xaaaaaa }),
  );
  scene.add(mesh);
});
```

---

## PLYLoader

Point clouds and mesh data with per-vertex colour.

```javascript
import { PLYLoader } from 'three/addons/loaders/PLYLoader.js';

const loader = new PLYLoader();
loader.load('scan.ply', geometry => {
  geometry.computeVertexNormals();

  // As mesh
  const mesh = new THREE.Mesh(
    geometry,
    new THREE.MeshStandardMaterial({ vertexColors: true }),
  );

  // As point cloud
  const points = new THREE.Points(
    geometry,
    new THREE.PointsMaterial({ size: 0.01, vertexColors: true }),
  );

  scene.add(mesh);
});
```

---

## RGBELoader — HDR Environment Maps

```javascript
import { RGBELoader }       from 'three/addons/loaders/RGBELoader.js';
import { PMREMGenerator }   from 'three';

const pmremGenerator = new PMREMGenerator(renderer);
pmremGenerator.compileEquirectangularShader();

new RGBELoader().load('studio.hdr', texture => {
  const envMap = pmremGenerator.fromEquirectangular(texture).texture;

  scene.environment = envMap;
  scene.background  = envMap;

  texture.dispose();
  pmremGenerator.dispose();
});
```

---

## Asset Caching

Prevent duplicate network requests for shared assets.

```javascript
const cache = new Map();

async function loadGLTFCached(url) {
  if (cache.has(url)) return cache.get(url);

  const promise = new Promise((resolve, reject) => {
    new GLTFLoader().load(url, resolve, undefined, reject);
  });

  cache.set(url, promise);
  return promise;
}

// Usage — second call returns the cached promise immediately
const [hero, enemy] = await Promise.all([
  loadGLTFCached('hero.glb'),
  loadGLTFCached('enemy.glb'),
]);

// Shared base model — clone for separate instances
async function spawnCharacter(url, position) {
  const gltf = await loadGLTFCached(url);
  const clone = gltf.scene.clone(true); // deep clone
  clone.position.copy(position);
  scene.add(clone);
  return clone;
}
```

---

## Error Handling

```javascript
async function loadWithRetry(url, retries = 3) {
  for (let attempt = 0; attempt < retries; attempt++) {
    try {
      return await loadGLTF(url);
    } catch (err) {
      if (attempt === retries - 1) throw err;
      console.warn(`Retry ${attempt + 1} for ${url}`);
      await new Promise(r => setTimeout(r, 1000 * (attempt + 1))); // Backoff
    }
  }
}

// Graceful fallback — substitute placeholder on failure
async function loadOrFallback(url) {
  try {
    return await loadGLTF(url);
  } catch {
    console.warn(`Failed to load ${url} — using placeholder`);
    return createPlaceholderMesh();
  }
}

function createPlaceholderMesh() {
  const geo = new THREE.BoxGeometry(1, 1, 1);
  const mat = new THREE.MeshStandardMaterial({ color: 0xff00ff, wireframe: true });
  return { scene: new THREE.Mesh(geo, mat), animations: [] };
}
```

---

## Preloading All Assets Before Play

```javascript
const assetManifest = [
  { type: 'gltf',    url: 'character.glb' },
  { type: 'gltf',    url: 'environment.glb' },
  { type: 'texture', url: 'ui-atlas.png' },
  { type: 'hdr',     url: 'sky.hdr' },
];

async function preloadAll(manifest, onProgress) {
  const results = {};
  let loaded = 0;

  await Promise.all(manifest.map(async ({ type, url }) => {
    if (type === 'gltf')    results[url] = await loadGLTF(url);
    if (type === 'texture') results[url] = await loadTexture(url);
    if (type === 'hdr')     results[url] = await loadHDR(url);

    loaded++;
    onProgress(loaded / manifest.length);
  }));

  return results;
}

const assets = await preloadAll(assetManifest, pct => {
  progressBar.style.width = `${pct * 100}%`;
});
```

---

## Performance Tips

1. **Use `.glb` over `.gltf`** — single binary file, no separate texture requests
2. **DRACO-compress geometry** — 60–90% size reduction, CPU cost only on first load
3. **KTX2-compress textures** — 4–8× VRAM reduction vs PNG/JPG
4. **Cache loader instances** — create one `GLTFLoader` per loader type, not per load call
5. **Use `LoadingManager`** — track all assets together, show a real progress bar
6. **Clone, don't re-load** — for multiple instances of the same model, `gltf.scene.clone(true)`

```javascript
// Reuse loader instance — DO NOT create per call
const gltfLoader = new GLTFLoader(); // Create once

// All subsequent loads reuse the same loader
loader.load('a.glb', ...);
loader.load('b.glb', ...);
loader.load('c.glb', ...);
```

---

## See Also

- `threejs-animation` — using `gltf.animations` with AnimationMixer
- `threejs-textures` — texture loading and colour space configuration
- `threejs-lighting` — RGBELoader for HDR environment maps
- `three-js-best-practices` — asset compression pipeline rules
