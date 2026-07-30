---
name: threejs-materials
description: Three.js material types — 9 materials from MeshBasicMaterial to MeshPhysicalMaterial, PBR advanced properties (clearcoat, transmission, iridescence, sheen), MeshToonMaterial, MeshNormalMaterial, MeshDepthMaterial, LineBasicMaterial, PointsMaterial, performance hierarchy, blending modes, and transparency. Use when choosing or configuring materials, implementing PBR surfaces, toon shading, transparency, or optimising material count. Adapted from CloudAI-X/threejs-skills (MIT).
license: MIT
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project Three.js source files and shader inspector.
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
    - materials
    - pbr
    - mesh-standard-material
    - mesh-physical-material
    - toon-shading
    - transparency
    - shader-material
    - clearcoat
    - transmission
  intents:
    - material-selection
    - pbr-configuration
    - toon-shading
    - transparency-setup
    - material-cost-review
  output_types:
    - code-example
    - api-reference
    - material-recommendation
---

# Three.js Materials

## Quick Start

```javascript
import * as THREE from 'three';

// PBR material — the default choice for game assets
const material = new THREE.MeshStandardMaterial({
  color: 0xffffff,
  roughness: 0.5,
  metalness: 0.0,
});

const mesh = new THREE.Mesh(new THREE.BoxGeometry(1, 1, 1), material);
scene.add(mesh);
```

---

## Material Hierarchy — Choose by Cost

From cheapest to most expensive:

| Material | Lighting | Shadows | Best For |
|---|---|---|---|
| `MeshBasicMaterial` | None | No | UI, wireframes, skyboxes, emissive-only |
| `MeshLambertMaterial` | Flat/Gouraud | Yes | Low-poly stylised, background props |
| `MeshPhongMaterial` | Blinn-Phong | Yes | Shiny plastics, legacy assets |
| `MeshStandardMaterial` | PBR | Yes | **Default — game characters, props** |
| `MeshPhysicalMaterial` | PBR + extras | Yes | Glass, car paint, skin, cloth |
| `ShaderMaterial` | Custom | Custom | Custom effects |

---

## MeshBasicMaterial

Flat colour or texture, unaffected by lights.

```javascript
const mat = new THREE.MeshBasicMaterial({
  color: 0xff0000,
  map: texture,          // Replaces color
  wireframe: false,
  transparent: false,
  opacity: 1.0,
  side: THREE.FrontSide, // THREE.BackSide, THREE.DoubleSide
  alphaTest: 0.5,        // Discard pixels below this alpha
  depthWrite: true,
  depthTest: true,
});
```

---

## MeshLambertMaterial

Diffuse-only lighting. Fast but no specular highlights.

```javascript
const mat = new THREE.MeshLambertMaterial({
  color: 0x44aa88,
  map: texture,
  emissive: new THREE.Color(0x000000),
  emissiveIntensity: 1.0,
});
```

Good choice for foliage, rock, soil — surfaces that aren't shiny.

---

## MeshPhongMaterial

Blinn-Phong shading with specular highlights.

```javascript
const mat = new THREE.MeshPhongMaterial({
  color: 0xffffff,
  specular: new THREE.Color(0x111111), // Specular highlight colour
  shininess: 30,                       // 0 = matte, 1000 = mirror-like
  map: diffuseTexture,
  normalMap: normalTexture,
  bumpMap: bumpTexture,
  bumpScale: 1.0,
  emissive: new THREE.Color(0x000000),
});
```

---

## MeshStandardMaterial — Default Choice

Physically based rendering (PBR) — metalness/roughness workflow.

```javascript
const mat = new THREE.MeshStandardMaterial({
  // Colour
  color: 0xffffff,
  map: albedoTexture,

  // PBR
  roughness: 0.5,          // 0 = mirror, 1 = matte
  roughnessMap: roughnessTex,
  metalness: 0.0,          // 0 = dielectric, 1 = metal
  metalnessMap: metalnessTex,

  // Surface normals
  normalMap: normalTex,
  normalScale: new THREE.Vector2(1, 1),

  // Ambient occlusion (requires uv2 channel)
  aoMap: aoTex,
  aoMapIntensity: 1.0,

  // Emissive
  emissive: new THREE.Color(0x000000),
  emissiveMap: emissiveTex,
  emissiveIntensity: 1.0,

  // Environment
  envMap: envMapTexture,
  envMapIntensity: 1.0,

  // Transparency
  transparent: false,
  opacity: 1.0,
  alphaMap: alphaTex,
  alphaTest: 0,

  // Shadow
  side: THREE.FrontSide,
});
```

---

## MeshPhysicalMaterial — Advanced PBR

Extends `MeshStandardMaterial` with real-world effects. Use sparingly — higher shader complexity.

```javascript
const mat = new THREE.MeshPhysicalMaterial({
  // Inherits all MeshStandardMaterial properties, plus:

  // Clearcoat — lacquer/paint over-layer (car paint, varnished wood)
  clearcoat: 1.0,                        // 0–1 clearcoat intensity
  clearcoatRoughness: 0.1,
  clearcoatMap: clearcoatTex,
  clearcoatRoughnessMap: clearcoatRoughTex,
  clearcoatNormalMap: clearcoatNormalTex,

  // Transmission — glass/liquid (replaces opacity for physically correct glass)
  transmission: 1.0,     // 1.0 = fully transmissive
  transmissionMap: transmissionTex,
  thickness: 0.5,        // Volume thickness (for refraction depth)
  ior: 1.5,              // Index of refraction (glass ≈ 1.5, water ≈ 1.33)
  attenuationDistance: Infinity,
  attenuationColor: new THREE.Color(0xffffff),

  // Iridescence — oil-slick/soap-bubble effect
  iridescence: 1.0,
  iridescenceIOR: 1.3,
  iridescenceThicknessRange: [100, 400], // nm

  // Sheen — cloth/fabric
  sheen: 1.0,
  sheenRoughness: 0.5,
  sheenColor: new THREE.Color(0xffffff),
  sheenColorMap: sheenColorTex,

  // Anisotropy — brushed metal
  anisotropy: 0.5,
  anisotropyRotation: 0,
  anisotropyMap: anisotropyTex,
});
```

### Glass Example

```javascript
const glassMat = new THREE.MeshPhysicalMaterial({
  transmission: 1.0,
  thickness: 0.5,
  roughness: 0.05,
  ior: 1.5,
  transparent: true,
  side: THREE.DoubleSide,
});
```

---

## MeshToonMaterial — Cel Shading

Stepped lighting for cartoon/anime look. Uses a gradient map to define light steps.

```javascript
// Two-tone gradient (sharp shadow, mid, highlight)
const gradientCanvas  = document.createElement('canvas');
gradientCanvas.width  = 3;
gradientCanvas.height = 1;
const ctx = gradientCanvas.getContext('2d');
ctx.fillStyle = '#000000'; ctx.fillRect(0, 0, 1, 1); // Shadow
ctx.fillStyle = '#888888'; ctx.fillRect(1, 0, 1, 1); // Mid
ctx.fillStyle = '#ffffff'; ctx.fillRect(2, 0, 1, 1); // Lit
const gradMap = new THREE.CanvasTexture(gradientCanvas);
gradMap.minFilter = gradMap.magFilter = THREE.NearestFilter; // Hard steps

const toonMat = new THREE.MeshToonMaterial({
  color: 0x44aaff,
  gradientMap: gradMap,
  map: texture,
});
```

---

## MeshNormalMaterial

Visualises surface normals as RGB. Development/debugging only.

```javascript
const normalMat = new THREE.MeshNormalMaterial({
  flatShading: false,
  wireframe: false,
});
```

---

## MeshDepthMaterial

Renders depth as greyscale. Used for custom post-processing effects.

```javascript
const depthMat = new THREE.MeshDepthMaterial({
  depthPacking: THREE.RGBADepthPacking, // More precision for post-processing
});
```

---

## LineBasicMaterial / LineDashedMaterial

```javascript
const lineMat = new THREE.LineBasicMaterial({
  color: 0x00ff00,
  linewidth: 1, // Note: linewidth > 1 not supported on WebGL
});

const dashedMat = new THREE.LineDashedMaterial({
  color: 0xffffff,
  dashSize: 0.1,
  gapSize: 0.05,
  scale: 1,
});

// LineDashed requires computing line distances
lineGeometry.computeLineDistances();
```

---

## PointsMaterial

```javascript
const pointsMat = new THREE.PointsMaterial({
  size: 0.02,
  sizeAttenuation: true,  // Points shrink with distance
  color: 0xffffff,
  map: particleTexture,
  alphaTest: 0.5,
  transparent: true,
  vertexColors: false,    // Use per-vertex colour attribute
  blending: THREE.AdditiveBlending, // Good for particles/sparks
});
```

---

## Transparency

Three.js has two transparency systems:

```javascript
// Alpha blend — correct order-dependent transparency
mat.transparent = true;
mat.opacity     = 0.5;

// Alpha test — discard below threshold (no sorting needed, cheaper)
mat.alphaTest = 0.5; // Foliage, fences, decals

// Render order (for sorting transparent objects)
mesh.renderOrder = 1; // Higher = rendered later (on top)
```

### Blending Modes

```javascript
mat.blending = THREE.NormalBlending;    // Default
mat.blending = THREE.AdditiveBlending;  // Glow, fire, particles
mat.blending = THREE.MultiplyBlending;  // Multiply colour
mat.blending = THREE.SubtractiveBlending;
mat.depthWrite = false; // Disable for additive blending to avoid z-fighting
```

---

## Shared Properties (All Materials)

```javascript
material.side          = THREE.FrontSide; // FrontSide, BackSide, DoubleSide
material.visible       = true;
material.depthTest     = true;
material.depthWrite    = true;
material.wireframe     = false;
material.fog           = true;  // Affected by scene fog
material.vertexColors  = false; // Use geometry colour attribute
material.flatShading   = false; // Flat vs smooth interpolation
material.needsUpdate   = false; // Set true after changing properties post-compile

// Clipping planes
material.clippingPlanes = [new THREE.Plane(new THREE.Vector3(0, -1, 0), 1)];
material.clipIntersection = false;
material.clipShadows      = false;
```

---

## Multiple Materials on One Mesh

Assign different materials to geometry groups.

```javascript
const mesh = new THREE.Mesh(geometry, [mat1, mat2, mat3]);

// Assign geometry faces to a group/material index
geometry.addGroup(0, 3, 0);  // Triangles 0–2 use mat1
geometry.addGroup(3, 3, 1);  // Triangles 3–5 use mat2
```

---

## Material Disposal

```javascript
function disposeMaterial(material) {
  const slots = [
    'map', 'normalMap', 'roughnessMap', 'metalnessMap',
    'aoMap', 'emissiveMap', 'alphaMap', 'envMap',
    'displacementMap', 'lightMap', 'clearcoatMap',
    'transmissionMap', 'sheenColorMap',
  ];
  slots.forEach(slot => material[slot]?.dispose());
  material.dispose();
}
```

---

## Performance Tips

1. **Start with `MeshStandardMaterial`** — only upgrade to Physical when a specific feature is needed
2. **Use `MeshBasicMaterial`** for skyboxes, UI planes, invisible colliders
3. **Share material instances** — one material per visual variant, not one per mesh
4. **Avoid `DoubleSide`** — nearly doubles fragment shader invocations; model closed geometry instead
5. **`alphaTest` over `transparent: true`** for foliage/fences — avoids sorting cost
6. **Disable `fog: false`** on materials that will never be in fog (performance micro-optimisation for large scenes)

```javascript
// Material instancing — DO NOT do this
const mats = meshes.map(() => new THREE.MeshStandardMaterial({ color: 0xff0000 })); // Bad

// Share instead
const sharedMat = new THREE.MeshStandardMaterial({ color: 0xff0000 });
const mats = meshes.map(() => sharedMat); // Good
```

---

## See Also

- `threejs-textures` — loading and configuring texture maps
- `threejs-shaders` — ShaderMaterial and custom GLSL
- `threejs-lighting` — how lights interact with PBR materials
- `three-js-best-practices` — material instancing and draw-call budget
