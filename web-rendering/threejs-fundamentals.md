---
name: threejs-fundamentals
description: Three.js scene setup, cameras, renderer, Object3D hierarchy, coordinate systems, transforms, and math utilities. Use when setting up 3D scenes, creating cameras, configuring renderers, managing object hierarchies, or working with Vector3, Matrix4, Quaternion, or colour math. Adapted from cloudai-x/threejs-skills (MIT).
license: Proprietary
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project Three.js source files and browser DevTools.
metadata:
  owner: game-delivery
  version: "1.0.0"
  language: "en-GB"
  category: "web-rendering"
  tags:
    - three-js
    - scene
    - camera
    - renderer
    - object3d
    - transforms
    - math
    - fundamentals
---

# Three.js Fundamentals

## Quick Start

```javascript
import * as THREE from 'three';

const scene    = new THREE.Scene();
const camera   = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
const renderer = new THREE.WebGLRenderer({ antialias: true });

renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
document.body.appendChild(renderer.domElement);

const geometry = new THREE.BoxGeometry(1, 1, 1);
const material = new THREE.MeshStandardMaterial({ color: 0x00ff00 });
const cube     = new THREE.Mesh(geometry, material);
scene.add(cube);

scene.add(new THREE.AmbientLight(0xffffff, 0.5));
const dirLight = new THREE.DirectionalLight(0xffffff, 1);
dirLight.position.set(5, 5, 5);
scene.add(dirLight);

camera.position.z = 5;

function animate() {
  requestAnimationFrame(animate);
  cube.rotation.x += 0.01;
  cube.rotation.y += 0.01;
  renderer.render(scene, camera);
}
animate();

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});
```

---

## Core Classes

### Scene

Container for all 3D objects, lights, and cameras.

```javascript
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x000000); // Solid colour
scene.background = texture;                   // Skybox texture
scene.background = cubeTexture;               // Cubemap
scene.environment = envMap;                   // Environment map for PBR
scene.fog = new THREE.Fog(0xffffff, 1, 100);      // Linear fog
scene.fog = new THREE.FogExp2(0xffffff, 0.02);    // Exponential fog
```

### Cameras

**PerspectiveCamera** — most common, simulates the human eye.

```javascript
// PerspectiveCamera(fov, aspect, near, far)
const camera = new THREE.PerspectiveCamera(
  75,                                    // Field of view (degrees)
  window.innerWidth / window.innerHeight, // Aspect ratio
  0.1,                                   // Near clipping plane
  1000,                                  // Far clipping plane
);

camera.position.set(0, 5, 10);
camera.lookAt(0, 0, 0);
camera.updateProjectionMatrix(); // Call after changing fov, aspect, near, or far
```

**OrthographicCamera** — no perspective distortion; good for 2D / isometric.

```javascript
const aspect       = window.innerWidth / window.innerHeight;
const frustumSize  = 10;
const camera = new THREE.OrthographicCamera(
  (frustumSize * aspect) / -2,
  (frustumSize * aspect) / 2,
  frustumSize / 2,
  frustumSize / -2,
  0.1,
  1000,
);
```

**ArrayCamera** — multiple viewports (split-screen, minimap).

```javascript
const cameras = [];
for (let i = 0; i < 4; i++) {
  const sub = new THREE.PerspectiveCamera(40, 1, 0.1, 100);
  sub.viewport = new THREE.Vector4(
    Math.floor(i % 2) * 0.5,
    Math.floor(i / 2) * 0.5,
    0.5, 0.5,
  );
  cameras.push(sub);
}
const arrayCamera = new THREE.ArrayCamera(cameras);
```

**CubeCamera** — renders environment maps for reflections.

```javascript
const cubeRenderTarget = new THREE.WebGLCubeRenderTarget(256);
const cubeCamera       = new THREE.CubeCamera(0.1, 1000, cubeRenderTarget);
scene.add(cubeCamera);

material.envMap = cubeRenderTarget.texture;

// Update in render loop (expensive — only when needed)
cubeCamera.position.copy(reflectiveMesh.position);
cubeCamera.update(renderer, scene);
```

### WebGLRenderer

```javascript
const renderer = new THREE.WebGLRenderer({
  canvas: document.querySelector('#canvas'), // Optional existing canvas
  antialias: true,
  alpha: true,
  powerPreference: 'high-performance',
  preserveDrawingBuffer: true, // Required for screenshots
});

renderer.setSize(width, height);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

// Tone mapping
renderer.toneMapping         = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.0;

// Colour space (Three.js r152+)
renderer.outputColorSpace = THREE.SRGBColorSpace;

// Shadows
renderer.shadowMap.enabled = true;
renderer.shadowMap.type    = THREE.PCFSoftShadowMap;

renderer.setClearColor(0x000000, 1);
renderer.render(scene, camera);
```

### Object3D

Base class for all 3D objects — Mesh, Group, Light, Camera all extend Object3D.

```javascript
const obj = new THREE.Object3D();

// Transform
obj.position.set(x, y, z);
obj.rotation.set(x, y, z);   // Euler angles (radians)
obj.quaternion.set(x, y, z, w);
obj.scale.set(x, y, z);

// World transforms
obj.getWorldPosition(targetVector);
obj.getWorldQuaternion(targetQuaternion);
obj.getWorldDirection(targetVector);

// Hierarchy
obj.add(child);
obj.remove(child);

// Visibility
obj.visible = false;

// Layers (selective rendering / raycasting)
obj.layers.set(1);
obj.layers.enable(2);

// Traverse entire hierarchy
obj.traverse(child => {
  if (child.isMesh) child.material.color.set(0xff0000);
});

// Matrix updates
obj.matrixAutoUpdate = true;
obj.updateMatrix();
obj.updateMatrixWorld(true); // Recursive
```

### Group

Empty container for organising objects.

```javascript
const group = new THREE.Group();
group.add(mesh1);
group.add(mesh2);
scene.add(group);

group.position.x = 5;
group.rotation.y = Math.PI / 4;
```

### Mesh

Combines geometry and material.

```javascript
const mesh = new THREE.Mesh(geometry, material);
const mesh = new THREE.Mesh(geometry, [mat1, mat2]); // Multiple materials

mesh.castShadow    = true;
mesh.receiveShadow = true;
mesh.frustumCulled = true;  // Default: skip if outside camera frustum
mesh.renderOrder   = 10;    // Higher = rendered later
```

---

## Coordinate System

Three.js uses a right-handed coordinate system:
- **+X** → right
- **+Y** → up
- **+Z** → toward viewer (out of screen)

```javascript
const axesHelper = new THREE.AxesHelper(5);
scene.add(axesHelper); // Red = X, Green = Y, Blue = Z
```

---

## Math Utilities

### Vector3

```javascript
const v = new THREE.Vector3(x, y, z);
v.set(x, y, z);
v.copy(other);
v.clone();

// In-place operations
v.add(v2);
v.sub(v2);
v.multiplyScalar(2);
v.divideScalar(2);
v.normalize();
v.negate();
v.clamp(min, max);
v.lerp(target, alpha);

// Calculations
v.length();
v.lengthSq();        // Faster than length() for comparisons
v.distanceTo(v2);
v.dot(v2);
v.cross(v2);
v.angleTo(v2);

// Transform
v.applyMatrix4(matrix);
v.applyQuaternion(q);
v.project(camera);   // World → NDC
v.unproject(camera); // NDC → world
```

### Matrix4

```javascript
const m = new THREE.Matrix4();
m.identity();
m.copy(other);

// Build transforms
m.makeTranslation(x, y, z);
m.makeRotationY(theta);
m.makeRotationFromQuaternion(q);
m.makeScale(x, y, z);

// Compose / decompose
m.compose(position, quaternion, scale);
m.decompose(position, quaternion, scale);

// Operations
m.multiply(m2);    // m = m * m2
m.premultiply(m2); // m = m2 * m
m.invert();
m.transpose();

// Camera matrices
m.makePerspective(left, right, top, bottom, near, far);
m.lookAt(eye, target, up);
```

### Quaternion

```javascript
const q = new THREE.Quaternion();
q.setFromEuler(euler);
q.setFromAxisAngle(axis, angle); // axis: normalised Vector3
q.setFromRotationMatrix(matrix);

q.multiply(q2);
q.slerp(target, t); // Spherical interpolation
q.normalize();
q.invert();
```

### Euler

```javascript
const euler = new THREE.Euler(x, y, z, 'XYZ'); // Order matters!
euler.setFromQuaternion(q);
euler.setFromRotationMatrix(m);

// Rotation orders: 'XYZ', 'YXZ', 'ZXY', 'XZY', 'YZX', 'ZYX'
```

### Color

```javascript
const colour = new THREE.Color(0xff0000);
const colour = new THREE.Color('red');
const colour = new THREE.Color('#ff0000');

colour.setHex(0x00ff00);
colour.setRGB(r, g, b); // 0–1 range
colour.setHSL(h, s, l); // 0–1 range

colour.lerp(other, alpha);
colour.multiply(other);
colour.multiplyScalar(2);
```

### MathUtils

```javascript
THREE.MathUtils.clamp(value, min, max);
THREE.MathUtils.lerp(start, end, alpha);
THREE.MathUtils.mapLinear(value, inMin, inMax, outMin, outMax);
THREE.MathUtils.degToRad(degrees);
THREE.MathUtils.radToDeg(radians);
THREE.MathUtils.randFloat(min, max);
THREE.MathUtils.randInt(min, max);
THREE.MathUtils.smoothstep(x, min, max);
THREE.MathUtils.smootherstep(x, min, max);
```

---

## Common Patterns

### Proper Cleanup

```javascript
function disposeMesh(mesh) {
  mesh.geometry.dispose();
  const mats = Array.isArray(mesh.material) ? mesh.material : [mesh.material];
  mats.forEach(m => {
    Object.values(m).forEach(v => v?.isTexture && v.dispose());
    m.dispose();
  });
  scene.remove(mesh);
}

// Full renderer cleanup
renderer.dispose();
```

### Clock for Animation

```javascript
const clock = new THREE.Clock();

function animate() {
  const delta   = clock.getDelta();      // Seconds since last frame
  const elapsed = clock.getElapsedTime(); // Total seconds

  mesh.rotation.y += 0.5 * delta;       // Consistent speed regardless of frame rate

  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}
```

### Responsive Canvas

```javascript
function onWindowResize() {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
}
window.addEventListener('resize', onWindowResize);
```

### Loading Manager

```javascript
const manager = new THREE.LoadingManager();
manager.onStart    = (url, loaded, total) => console.log('Loading started');
manager.onLoad     = ()                  => console.log('All loaded');
manager.onProgress = (url, loaded, total) => console.log(`${loaded}/${total}`);
manager.onError    = url                 => console.error(`Error: ${url}`);

const textureLoader = new THREE.TextureLoader(manager);
const gltfLoader    = new GLTFLoader(manager);
```

---

## Performance Tips

1. **Limit draw calls** — merge static geometries, use instancing, atlas textures
2. **Frustum culling** — enabled by default; ensure bounding boxes are correct
3. **LOD** — use `THREE.LOD` for distance-based mesh switching
4. **Object pooling** — reuse objects instead of creating and destroying them
5. **Avoid `getWorldPosition` in hot loops** — cache results

```javascript
// LOD
const lod = new THREE.LOD();
lod.addLevel(highDetailMesh, 0);
lod.addLevel(medDetailMesh, 50);
lod.addLevel(lowDetailMesh, 100);
scene.add(lod);

// Merge static geometry
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
const merged = mergeGeometries([geo1, geo2, geo3]);
const mesh   = new THREE.Mesh(merged, sharedMat);
```

---

## See Also

- `threejs-geometry` — geometry creation and manipulation
- `threejs-materials` — material types and properties
- `threejs-lighting` — light types and shadows
- `threejs-animation` — AnimationMixer and keyframe animation
- `three-js-best-practices` — performance rules and memory disposal
