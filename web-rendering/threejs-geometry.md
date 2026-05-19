---
name: threejs-geometry
description: Three.js geometry — BufferGeometry, 15+ built-in shapes, custom vertex/index data, InstancedMesh for many identical objects, geometry merging, EdgesGeometry, point clouds, morph targets, and InstancedBufferGeometry. Use when creating or modifying 3D geometry, optimising repeated objects, or building procedural meshes. Adapted from cloudai-x/threejs-skills (MIT).
license: Proprietary
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project Three.js source files and renderer.info draw-call monitoring.
metadata:
  owner: game-delivery
  version: "1.0.0"
  language: "en-GB"
  category: "web-rendering"
  tags:
    - three-js
    - geometry
    - buffer-geometry
    - instancing
    - instanced-mesh
    - procedural
    - point-cloud
    - morph-targets
---

# Three.js Geometry

## Quick Start

```javascript
import * as THREE from 'three';

// Built-in geometry
const geometry = new THREE.BoxGeometry(1, 1, 1);
const material = new THREE.MeshStandardMaterial({ color: 0x44aa88 });
const mesh     = new THREE.Mesh(geometry, material);
scene.add(mesh);

// Custom geometry
const custom = new THREE.BufferGeometry();
const vertices = new Float32Array([
   0,  1, 0,   // top
  -1, -1, 0,   // bottom-left
   1, -1, 0,   // bottom-right
]);
custom.setAttribute('position', new THREE.BufferAttribute(vertices, 3));
scene.add(new THREE.Mesh(custom, material));
```

---

## Built-in Geometry Types

### Primitives

```javascript
// Box
new THREE.BoxGeometry(width, height, depth, widthSeg, heightSeg, depthSeg);
new THREE.BoxGeometry(1, 1, 1);           // Unit cube

// Sphere
new THREE.SphereGeometry(radius, widthSeg, heightSeg, phiStart, phiLength, thetaStart, thetaLength);
new THREE.SphereGeometry(0.5, 32, 32);    // Good quality for web

// Plane
new THREE.PlaneGeometry(width, height, widthSeg, heightSeg);
new THREE.PlaneGeometry(10, 10, 64, 64);  // Subdivided for displacement

// Cylinder / Cone
new THREE.CylinderGeometry(radiusTop, radiusBottom, height, radialSeg, heightSeg, openEnded);
new THREE.CylinderGeometry(0.5, 0.5, 2, 32); // Standard cylinder
new THREE.CylinderGeometry(0, 0.5, 1, 32);   // Cone (top radius = 0)

// Torus (donut)
new THREE.TorusGeometry(radius, tube, radialSeg, tubularSeg, arc);
new THREE.TorusGeometry(1, 0.4, 16, 100);

// Torus Knot
new THREE.TorusKnotGeometry(radius, tube, tubularSeg, radialSeg, p, q);
new THREE.TorusKnotGeometry(1, 0.3, 128, 16, 2, 3);

// Circle
new THREE.CircleGeometry(radius, segments, thetaStart, thetaLength);
new THREE.CircleGeometry(0.5, 32);

// Ring
new THREE.RingGeometry(innerRadius, outerRadius, thetaSeg, phiSeg, thetaStart, thetaLength);
new THREE.RingGeometry(0.3, 0.5, 32);

// Capsule (Three.js r147+)
new THREE.CapsuleGeometry(radius, length, capSeg, radialSeg);
new THREE.CapsuleGeometry(0.5, 1, 8, 16);

// Icosahedron / Octahedron / Tetrahedron / Dodecahedron
new THREE.IcosahedronGeometry(radius, detail);
new THREE.OctahedronGeometry(radius, detail);
```

### Path-Based Shapes

```javascript
// Lathe — revolve a 2D profile around Y axis
const points = [];
for (let i = 0; i < 10; i++) {
  points.push(new THREE.Vector2(Math.sin(i * 0.2) + 0.5, i * 0.2 - 1));
}
new THREE.LatheGeometry(points, 32);

// Extrude — extrude a 2D shape along a path
const shape = new THREE.Shape();
shape.moveTo(0, 0);
shape.lineTo(1, 0);
shape.lineTo(1, 1);
shape.lineTo(0, 1);
shape.lineTo(0, 0);

const extrudeSettings = {
  depth: 0.5,
  bevelEnabled: true,
  bevelThickness: 0.1,
  bevelSize: 0.1,
  bevelSegments: 3,
};
new THREE.ExtrudeGeometry(shape, extrudeSettings);

// Tube — mesh around a 3D curve
const path = new THREE.CatmullRomCurve3([
  new THREE.Vector3(-1, 0, 0),
  new THREE.Vector3(0, 1, 0),
  new THREE.Vector3(1, 0, 0),
]);
new THREE.TubeGeometry(path, 64, 0.1, 8, false);
```

---

## BufferGeometry

The foundation class for all geometry in Three.js — stores data as typed arrays on the GPU.

### Custom Geometry

```javascript
const geometry = new THREE.BufferGeometry();

// Vertices (required)
const positions = new Float32Array([
  0, 0, 0,   // v0
  1, 0, 0,   // v1
  0, 1, 0,   // v2
  1, 1, 0,   // v3
]);
geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

// Normals
const normals = new Float32Array([
  0, 0, 1,
  0, 0, 1,
  0, 0, 1,
  0, 0, 1,
]);
geometry.setAttribute('normal', new THREE.BufferAttribute(normals, 3));

// UV coordinates
const uvs = new Float32Array([
  0, 0,
  1, 0,
  0, 1,
  1, 1,
]);
geometry.setAttribute('uv', new THREE.BufferAttribute(uvs, 2));

// Indices (face definition — reduces vertex count for shared verts)
const indices = new Uint16Array([0, 1, 2, 1, 3, 2]);
geometry.setIndex(new THREE.BufferAttribute(indices, 1));

// Colours (per-vertex)
const colours = new Float32Array([
  1, 0, 0,   // red
  0, 1, 0,   // green
  0, 0, 1,   // blue
  1, 1, 0,   // yellow
]);
geometry.setAttribute('color', new THREE.BufferAttribute(colours, 3));
// On material: vertexColors: true

// Compute auto normals if not provided
geometry.computeVertexNormals();
```

### Runtime Modification

```javascript
const positions = geometry.attributes.position;

// Modify in place
for (let i = 0; i < positions.count; i++) {
  const y = Math.sin(positions.getX(i) * 2 + time) * 0.5;
  positions.setY(i, y);
}
positions.needsUpdate = true; // Tell GPU to re-upload

// Recompute bounds after modification
geometry.computeBoundingBox();
geometry.computeBoundingSphere();
```

### Bounding Volumes

```javascript
geometry.computeBoundingBox();
geometry.computeBoundingSphere();

const box = geometry.boundingBox;    // THREE.Box3
const sphere = geometry.boundingSphere; // THREE.Sphere

// Check if point is inside bounding box
const inside = box.containsPoint(new THREE.Vector3(0.5, 0.5, 0));
```

---

## InstancedMesh — Many Identical Objects

**Critical for performance.** One draw call for thousands of identical meshes.

```javascript
const count    = 10000;
const geometry = new THREE.BoxGeometry(0.1, 0.1, 0.1);
const material = new THREE.MeshStandardMaterial({ color: 0xff0000 });

const instancedMesh = new THREE.InstancedMesh(geometry, material, count);
instancedMesh.castShadow    = true;
instancedMesh.receiveShadow = true;

const dummy = new THREE.Object3D();
const colour = new THREE.Color();

for (let i = 0; i < count; i++) {
  dummy.position.random().multiplyScalar(20);
  dummy.rotation.set(
    Math.random() * Math.PI,
    Math.random() * Math.PI,
    0,
  );
  dummy.scale.setScalar(0.5 + Math.random() * 0.5);
  dummy.updateMatrix();
  instancedMesh.setMatrixAt(i, dummy.matrix);

  colour.setHSL(Math.random(), 0.8, 0.5);
  instancedMesh.setColorAt(i, colour);
}

instancedMesh.instanceMatrix.needsUpdate = true;
if (instancedMesh.instanceColor) instancedMesh.instanceColor.needsUpdate = true;
scene.add(instancedMesh);

// Update a single instance
function moveInstance(index, position) {
  dummy.position.copy(position);
  dummy.updateMatrix();
  instancedMesh.setMatrixAt(index, dummy.matrix);
  instancedMesh.instanceMatrix.needsUpdate = true;
}
```

### Raycasting on InstancedMesh

```javascript
const raycaster = new THREE.Raycaster();

function onClick(event) {
  const mouse = new THREE.Vector2(
    (event.clientX / window.innerWidth) * 2 - 1,
    -(event.clientY / window.innerHeight) * 2 + 1,
  );
  raycaster.setFromCamera(mouse, camera);

  const intersects = raycaster.intersectObject(instancedMesh);
  if (intersects.length > 0) {
    const id = intersects[0].instanceId;
    instancedMesh.getMatrixAt(id, dummy.matrix);
    console.log('Clicked instance:', id);
  }
}
```

---

## Geometry Merging

Combine static meshes into one — eliminates individual draw calls.

```javascript
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

// All geometries must share the same attributes (position, normal, uv)
const geos = objects.map(o => {
  const geo = o.geometry.clone();
  geo.applyMatrix4(o.matrixWorld); // Bake world transform into vertices
  return geo;
});

const merged = mergeGeometries(geos, false); // false = single group
const mesh   = new THREE.Mesh(merged, sharedMaterial);
scene.add(mesh);

// With multiple material groups
const mergedMulti = mergeGeometries(geos, true); // true = keep groups
const meshMulti   = new THREE.Mesh(mergedMulti, [mat1, mat2]);
```

Only merge static geometry. Merged meshes cannot be transformed individually.

---

## Wireframes, Edges, and Points

```javascript
// Wireframe material
const wireMat = new THREE.MeshBasicMaterial({ wireframe: true, color: 0x00ff00 });
const wireMesh = new THREE.Mesh(geometry, wireMat);

// Edge lines (only outer / sharp edges)
const edges     = new THREE.EdgesGeometry(geometry, 30); // 30° threshold
const edgeMesh  = new THREE.LineSegments(edges, new THREE.LineBasicMaterial({ color: 0xffffff }));

// Wireframe utility (all triangles)
const wireGeo   = new THREE.WireframeGeometry(geometry);
const wireLine  = new THREE.LineSegments(wireGeo, new THREE.LineBasicMaterial({ color: 0x888888 }));

// Point cloud
const pointMat  = new THREE.PointsMaterial({ size: 0.02, color: 0xffffff, sizeAttenuation: true });
const pointMesh = new THREE.Points(geometry, pointMat);
```

---

## Morph Targets

Blend between alternative vertex positions for animation.

```javascript
const baseGeometry = new THREE.SphereGeometry(1, 32, 32);

// Create morphed version (squash)
const morphGeo = baseGeometry.clone();
const morphPos = morphGeo.attributes.position;
for (let i = 0; i < morphPos.count; i++) {
  morphPos.setY(i, morphPos.getY(i) * 0.5); // Flatten Y
  morphPos.setX(i, morphPos.getX(i) * 1.5); // Widen X
}

// Attach to base geometry
baseGeometry.morphAttributes.position = [morphPos];

const mesh = new THREE.Mesh(baseGeometry, new THREE.MeshStandardMaterial({ morphTargets: true }));
scene.add(mesh);

// Blend in animation loop
function animate() {
  mesh.morphTargetInfluences[0] = Math.sin(clock.getElapsedTime()) * 0.5 + 0.5;
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}
```

---

## InstancedBufferGeometry — Custom Per-Instance Attributes

For instanced particles or objects needing per-instance shader data beyond transform and colour.

```javascript
const count    = 50000;
const geometry = new THREE.PlaneGeometry(0.05, 0.05);

// Per-instance random seed for shader variation
const seeds  = new Float32Array(count);
const speeds = new Float32Array(count);
for (let i = 0; i < count; i++) {
  seeds[i]  = Math.random();
  speeds[i] = 0.5 + Math.random() * 1.5;
}

geometry.setAttribute('aSeed',  new THREE.InstancedBufferAttribute(seeds, 1));
geometry.setAttribute('aSpeed', new THREE.InstancedBufferAttribute(speeds, 1));

const material = new THREE.ShaderMaterial({
  uniforms: { uTime: { value: 0 } },
  vertexShader: `
    attribute float aSeed;
    attribute float aSpeed;
    uniform float uTime;
    varying float vSeed;

    void main() {
      vSeed = aSeed;
      vec3 pos = position;
      pos.y += mod(aSeed + uTime * aSpeed, 10.0) - 5.0;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    }
  `,
  fragmentShader: `
    varying float vSeed;
    void main() { gl_FragColor = vec4(vSeed, 0.5, 1.0 - vSeed, 1.0); }
  `,
});

const mesh = new THREE.InstancedMesh(geometry, material, count);
// Set transforms...
scene.add(mesh);
```

---

## Performance Tips

1. **InstancedMesh over individual meshes** — 100+ identical objects = use instancing
2. **Merge static geometry** — buildings, terrain props that never move
3. **Right segment count** — 32 segments for spheres; 64×64 for subdivided planes; avoid excess
4. **Index your geometry** — shared vertices via index array = smaller GPU buffer
5. **Non-indexed geometry** for flat-shaded low-poly — avoids vertex duplication issues
6. **Dispose on removal** — `geometry.dispose()` frees GPU memory

```javascript
// Performance check
console.log('Draw calls:', renderer.info.render.calls);
console.log('Triangles:', renderer.info.render.triangles);
console.log('Geometries:', renderer.info.memory.geometries);
```

---

## See Also

- `threejs-fundamentals` — scene setup and Object3D transforms
- `threejs-materials` — materials for geometry
- `three-js-best-practices` — draw-call budget and instancing rules
- `threejs-animation` — morph target animation with AnimationMixer
