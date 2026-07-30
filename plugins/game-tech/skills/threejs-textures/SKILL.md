---
name: threejs-textures
description: Three.js texture loading and management — TextureLoader, colour spaces (SRGBColorSpace), wrapping modes, filtering, mipmaps, UV mapping, texture atlases, PBR texture sets (map/normalMap/roughnessMap/metalnessMap/aoMap/emissiveMap/displacementMap), video textures, canvas textures, DataTexture for procedural content, KTX2 compressed textures, and memory disposal. Use when loading or creating textures, configuring UV mapping, or managing texture memory. Adapted from CloudAI-X/threejs-skills (MIT).
license: MIT
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project Three.js source files and texture asset pipeline.
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
    - textures
    - texture-loading
    - uv-mapping
    - pbr
    - normal-map
    - colour-space
    - video-texture
    - canvas-texture
    - ktx2
    - memory-management
  intents:
    - texture-loading
    - colour-space-selection
    - uv-configuration
    - pbr-texture-set
    - texture-compression
    - memory-disposal
  output_types:
    - code-example
    - api-reference
    - texture-budget
---

# Three.js Textures

## Quick Start

```javascript
import * as THREE from 'three';

const loader  = new THREE.TextureLoader();
const texture = loader.load('diffuse.jpg');

// Colour textures must be in sRGB space
texture.colorSpace = THREE.SRGBColorSpace;

const material = new THREE.MeshStandardMaterial({ map: texture });
const mesh     = new THREE.Mesh(new THREE.BoxGeometry(1, 1, 1), material);
scene.add(mesh);
```

---

## TextureLoader

### Basic Loading

```javascript
const loader = new THREE.TextureLoader();

// Callback-based
loader.load(
  'texture.jpg',
  texture => { material.map = texture; material.needsUpdate = true; },
  undefined,  // onProgress (not supported for single textures)
  err => console.error('Load error:', err),
);

// Promise-based (cleaner)
async function loadTexture(url) {
  return new Promise((resolve, reject) => {
    loader.load(url, resolve, undefined, reject);
  });
}

const texture = await loadTexture('texture.jpg');
```

### Loading Multiple Textures

```javascript
import { LoadingManager } from 'three';

const manager = new LoadingManager(
  ()             => console.log('All textures loaded'),
  (url, n, total) => console.log(`${n}/${total} — ${url}`),
  url            => console.error(`Error: ${url}`),
);

const loader = new THREE.TextureLoader(manager);

const [diffuse, normal, roughness] = await Promise.all([
  loadTexture('diffuse.jpg'),
  loadTexture('normal.jpg'),
  loadTexture('roughness.jpg'),
]);
```

---

## Colour Space

**Critical: colour textures must be tagged SRGBColorSpace; data textures must be LinearSRGBColorSpace.**

```javascript
// Colour textures (albedo/diffuse, emissive) — perceived colour, gamma-encoded
texture.colorSpace = THREE.SRGBColorSpace;

// Non-colour data textures — linear, no gamma
normalMap.colorSpace     = THREE.LinearSRGBColorSpace; // Default; can omit
roughnessMap.colorSpace  = THREE.LinearSRGBColorSpace;
metalnessMap.colorSpace  = THREE.LinearSRGBColorSpace;
aoMap.colorSpace         = THREE.LinearSRGBColorSpace;
displacementMap.colorSpace = THREE.LinearSRGBColorSpace;

// Renderer must match
renderer.outputColorSpace = THREE.SRGBColorSpace; // Required for correct output
```

Incorrect colour space causes washed-out or overly-dark materials.

---

## Wrapping Modes

```javascript
texture.wrapS = THREE.RepeatWrapping;   // Horizontal
texture.wrapT = THREE.RepeatWrapping;   // Vertical

// Options
texture.wrapS = THREE.ClampToEdgeWrapping;   // Clamp to border (default)
texture.wrapS = THREE.RepeatWrapping;        // Tile
texture.wrapS = THREE.MirroredRepeatWrapping; // Mirror-tile

// Tiling and offset
texture.repeat.set(4, 4);    // Tile 4× in each direction
texture.offset.set(0.5, 0);  // Shift UV by 0.5 on X
texture.center.set(0.5, 0.5); // Rotation pivot (0.5,0.5 = centre)
texture.rotation = Math.PI / 4; // Rotate texture 45°
```

---

## Filtering and Mipmaps

```javascript
// Minification filter (texture smaller than screen pixels)
texture.minFilter = THREE.LinearMipmapLinearFilter; // Default — trilinear, best quality
texture.minFilter = THREE.NearestFilter;             // Pixelated (retro look)
texture.minFilter = THREE.LinearFilter;              // No mipmaps (canvas/video)

// Magnification filter (texture larger than screen pixels)
texture.magFilter = THREE.LinearFilter;  // Default — bilinear
texture.magFilter = THREE.NearestFilter; // Pixelated

// Anisotropic filtering (reduces blurring at oblique angles)
const maxAniso  = renderer.capabilities.getMaxAnisotropy();
texture.anisotropy = maxAniso; // Use maximum for quality

// Disable mipmaps for UI / non-repeated textures
texture.generateMipmaps = false;
texture.minFilter = THREE.LinearFilter;
```

---

## UV Mapping

### Accessing UV Channels

```javascript
// Primary UVs (uv)
geometry.setAttribute('uv', new THREE.BufferAttribute(uvArray, 2));

// Secondary UV channel (uv2) for lightmaps and AO maps
geometry.setAttribute('uv2', new THREE.BufferAttribute(uv2Array, 2));

// Built-in geometries have UVs pre-generated
const geo = new THREE.BoxGeometry(1, 1, 1);
console.log(geo.attributes.uv); // Available immediately
```

### UV Transform on Material

```javascript
// Fine-tune UV transform per texture slot
material.map.repeat.set(2, 2);
material.map.offset.set(0, 0);

// UV channel selection (Three.js r152+)
material.aoMap.channel = 1; // Use uv2 for AO
```

---

## PBR Texture Set (MeshStandardMaterial)

```javascript
const material = new THREE.MeshStandardMaterial({
  // Colour (albedo)
  map: albedoTexture,                    // sRGB

  // Surface normals
  normalMap: normalTexture,              // Linear; RGB encodes XY surface normals
  normalScale: new THREE.Vector2(1, 1),  // Intensity multiplier

  // Surface roughness
  roughnessMap: roughnessTexture,        // Linear; R channel
  roughness: 1.0,                        // Multiplied by map value

  // Metalness
  metalnessMap: metalnessTexture,        // Linear; B channel
  metalness: 1.0,

  // Ambient occlusion (requires uv2)
  aoMap: aoTexture,                      // Linear; R channel
  aoMapIntensity: 1.0,

  // Emissive
  emissiveMap: emissiveTexture,          // sRGB
  emissive: new THREE.Color(0xffffff),   // Multiplied by map
  emissiveIntensity: 1.0,

  // Height displacement
  displacementMap: heightTexture,        // Linear; R channel
  displacementScale: 0.1,
  displacementBias: 0,

  // Environment reflections
  envMap: envMapTexture,
  envMapIntensity: 1.0,
});
```

### Packed ORM Texture (Optimised)

Pack Occlusion (R), Roughness (G), Metalness (B) into one texture to save memory and sampling cost.

```javascript
const ormTexture = loader.load('orm.png');
ormTexture.colorSpace = THREE.LinearSRGBColorSpace;

const material = new THREE.MeshStandardMaterial({
  aoMap: ormTexture,            // Uses R channel
  roughnessMap: ormTexture,     // Uses G channel
  metalnessMap: ormTexture,     // Uses B channel
});
```

---

## Video Texture

Stream video frames as a texture. Update must be called in the render loop.

```javascript
const video = document.createElement('video');
video.src     = 'video.mp4';
video.loop    = true;
video.muted   = true; // Required for autoplay in browsers
video.play();

const videoTexture = new THREE.VideoTexture(video);
videoTexture.colorSpace = THREE.SRGBColorSpace;

const material = new THREE.MeshBasicMaterial({ map: videoTexture });

function animate() {
  // VideoTexture updates automatically when video.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}
```

---

## Canvas Texture

Use a `<canvas>` element as a texture — useful for dynamic text, HUD elements.

```javascript
const canvas  = document.createElement('canvas');
canvas.width  = 512;
canvas.height = 256;

const ctx = canvas.getContext('2d');
ctx.fillStyle = '#000000';
ctx.fillRect(0, 0, canvas.width, canvas.height);
ctx.fillStyle = '#ffffff';
ctx.font = '48px Arial';
ctx.fillText('Hello Three.js', 50, 150);

const canvasTexture = new THREE.CanvasTexture(canvas);

// Update after drawing to canvas
function updateLabel(text) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.fillText(text, 50, 150);
  canvasTexture.needsUpdate = true; // Signal Three.js to re-upload
}
```

---

## DataTexture — Procedural Textures

Create textures entirely in JavaScript without image assets.

```javascript
const width  = 256;
const height = 256;
const data   = new Uint8Array(width * height * 4); // RGBA

for (let y = 0; y < height; y++) {
  for (let x = 0; x < width; x++) {
    const i = (y * width + x) * 4;
    const value = Math.floor(Math.random() * 255);

    data[i]     = value; // R
    data[i + 1] = value; // G
    data[i + 2] = value; // B
    data[i + 3] = 255;   // A
  }
}

const dataTexture = new THREE.DataTexture(data, width, height, THREE.RGBAFormat);
dataTexture.needsUpdate = true;
dataTexture.colorSpace  = THREE.SRGBColorSpace;
```

### Checkerboard Pattern

```javascript
function createCheckerTexture(size = 128, squareSize = 16) {
  const data = new Uint8Array(size * size * 4);

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const i = (y * size + x) * 4;
      const isWhite = (Math.floor(x / squareSize) + Math.floor(y / squareSize)) % 2 === 0;
      const v = isWhite ? 255 : 50;
      data[i] = data[i + 1] = data[i + 2] = v;
      data[i + 3] = 255;
    }
  }

  const tex = new THREE.DataTexture(data, size, size, THREE.RGBAFormat);
  tex.needsUpdate = true;
  return tex;
}
```

---

## KTX2 Compressed Textures

GPU-compressed textures reduce VRAM and upload time. Requires a transcoder.

```javascript
import { KTX2Loader } from 'three/addons/loaders/KTX2Loader.js';

const ktx2Loader = new KTX2Loader();
ktx2Loader.setTranscoderPath('/libs/basis/'); // basis_transcoder.wasm
ktx2Loader.detectSupport(renderer);

ktx2Loader.load('texture.ktx2', texture => {
  texture.colorSpace = THREE.SRGBColorSpace;
  material.map = texture;
  material.needsUpdate = true;
});
```

Prefer KTX2 for production — reduces VRAM by 4–8× vs PNG/JPG.

---

## Texture Atlas

Pack multiple textures into one to reduce draw calls.

```javascript
// Atlas with 4 textures in a 2×2 grid
const atlasTexture = loader.load('atlas.png');
atlasTexture.colorSpace = THREE.SRGBColorSpace;

// Per-object UV offset and repeat to select a region
function setAtlasRegion(mesh, col, row, gridSize = 2) {
  const uvScale  = 1 / gridSize;
  mesh.material.map.repeat.set(uvScale, uvScale);
  mesh.material.map.offset.set(col * uvScale, row * uvScale);
}

setAtlasRegion(tree,   0, 0); // Top-left region
setAtlasRegion(rock,   1, 0); // Top-right region
setAtlasRegion(bush,   0, 1); // Bottom-left region
```

---

## Memory Management

```javascript
// Dispose when no longer needed
texture.dispose();

// Dispose all textures of a material
function disposeMaterial(material) {
  const textureSlots = [
    'map', 'normalMap', 'roughnessMap', 'metalnessMap',
    'aoMap', 'emissiveMap', 'displacementMap', 'envMap',
    'alphaMap', 'lightMap',
  ];
  textureSlots.forEach(slot => {
    if (material[slot]) material[slot].dispose();
  });
  material.dispose();
}

// Check VRAM usage
console.log('Textures in memory:', renderer.info.memory.textures);
```

---

## Performance Tips

1. **Always set `colorSpace`** — missing this causes incorrect colour rendering
2. **Use KTX2/Basis compressed textures in production** — 4–8× VRAM saving
3. **Power-of-2 dimensions** — non-POT textures cannot generate mipmaps and repeat poorly
4. **Disable `generateMipmaps`** for UI/video/canvas textures — they don't need it
5. **Share textures between materials** — same texture object = single GPU upload
6. **Atlas small textures** — fewer texture binds = fewer draw calls
7. **Set `anisotropy` to `renderer.capabilities.getMaxAnisotropy()`** for floor/terrain

```javascript
// Shared texture across multiple materials
const sharedTex = loader.load('shared.jpg');
const mat1 = new THREE.MeshStandardMaterial({ map: sharedTex });
const mat2 = new THREE.MeshStandardMaterial({ map: sharedTex }); // Same GPU texture
```

---

## See Also

- `threejs-materials` — material types that use texture slots
- `threejs-lighting` — HDR environment map loading
- `threejs-loaders` — GLTFLoader, RGBELoader, KTX2Loader
- `three-js-best-practices` — texture compression and VRAM budget
