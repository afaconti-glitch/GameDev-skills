---
name: threejs-lighting
description: Three.js lighting — 6 light types (Ambient, Directional, Point, Spot, Hemisphere, RectArea), shadow configuration, PCSS/PCFSoft shadow maps, environment map lighting via HDR and PMREMGenerator, 3-point studio setup, LightProbe, and performance rules. Use when setting up scene lighting, configuring shadows, loading HDR environments, or optimising light count for mobile. Adapted from CloudAI-X/threejs-skills (MIT).
license: MIT
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project Three.js source files and renderer shadow/light count profiling.
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
    - lighting
    - shadows
    - environment-maps
    - hdr
    - pmrem
    - ambient-light
    - directional-light
    - point-light
    - spot-light
    - hemisphere-light
    - rect-area-light
  intents:
    - light-selection
    - shadow-configuration
    - environment-lighting
    - studio-setup
    - light-budget
  output_types:
    - code-example
    - api-reference
    - lighting-plan
---

# Three.js Lighting

## Quick Start

```javascript
import * as THREE from 'three';

const scene = new THREE.Scene();

// Ambient fill
const ambient = new THREE.AmbientLight(0xffffff, 0.4);
scene.add(ambient);

// Primary directional light with shadows
const sun = new THREE.DirectionalLight(0xffffff, 1.0);
sun.position.set(5, 10, 5);
sun.castShadow = true;
scene.add(sun);

// Enable shadows on renderer
renderer.shadowMap.enabled = true;
renderer.shadowMap.type    = THREE.PCFSoftShadowMap;

// Enable on geometry
mesh.castShadow    = true;
mesh.receiveShadow = true;
```

---

## Light Types

### AmbientLight — Uniform Fill

No position, no shadows. Adds flat, directionless light to every surface equally.

```javascript
const ambient = new THREE.AmbientLight(
  0xffffff, // colour
  0.4,      // intensity
);
scene.add(ambient);
```

Use as a low-intensity fill to prevent pure-black shadows. Never as the sole light source.

### HemisphereLight — Sky/Ground Gradient

Simulates outdoor bounce light from sky above and ground below.

```javascript
const hemi = new THREE.HemisphereLight(
  0x87ceeb, // sky colour (above)
  0x4a4a2a, // ground colour (below)
  0.6,      // intensity
);
scene.add(hemi);
```

Good outdoor ambient substitute — more natural than AmbientLight. No shadows.

### DirectionalLight — Sun

Parallel rays from infinity. Best for outdoor sun/moon. Supports shadows.

```javascript
const dirLight = new THREE.DirectionalLight(0xfff5e0, 1.2);
dirLight.position.set(10, 20, 10); // Direction is from position toward 0,0,0
dirLight.target.position.set(0, 0, 0);
scene.add(dirLight);
scene.add(dirLight.target);

// Shadows
dirLight.castShadow           = true;
dirLight.shadow.mapSize.width  = 2048;
dirLight.shadow.mapSize.height = 2048;
dirLight.shadow.camera.near    = 0.5;
dirLight.shadow.camera.far     = 100;
dirLight.shadow.camera.left    = -20;
dirLight.shadow.camera.right   = 20;
dirLight.shadow.camera.top     = 20;
dirLight.shadow.camera.bottom  = -20;
dirLight.shadow.bias           = -0.001; // Prevents shadow acne
dirLight.shadow.normalBias     = 0.02;   // Fixes shadow gap on curved surfaces
```

Visualise the shadow frustum during development:

```javascript
import { CameraHelper } from 'three';
const shadowHelper = new CameraHelper(dirLight.shadow.camera);
scene.add(shadowHelper);
```

### PointLight — Omni Light (Bulb)

Radiates in all directions from a single point. Supports shadows (expensive — 6 shadow maps).

```javascript
const point = new THREE.PointLight(
  0xff8844, // colour
  2.0,      // intensity
  15,       // distance (0 = infinite)
  2,        // decay (physically correct = 2)
);
point.position.set(0, 3, 0);
scene.add(point);

// Shadows (costs 6× shadow maps)
point.castShadow           = true;
point.shadow.mapSize.width  = 512;
point.shadow.mapSize.height = 512;
point.shadow.camera.near   = 0.1;
point.shadow.camera.far    = 15;
```

### SpotLight — Cone of Light

Directional cone. Supports shadows with a single shadow map.

```javascript
const spot = new THREE.SpotLight(
  0xffffff, // colour
  2.0,      // intensity
  30,       // distance
  Math.PI / 6, // angle (cone half-angle)
  0.3,         // penumbra (0 = hard edge, 1 = soft)
  2,           // decay
);
spot.position.set(0, 8, 0);
spot.target.position.set(0, 0, 0);
scene.add(spot);
scene.add(spot.target);

// Shadows
spot.castShadow           = true;
spot.shadow.mapSize.width  = 1024;
spot.shadow.mapSize.height = 1024;
spot.shadow.camera.near   = 1;
spot.shadow.camera.far    = 30;
spot.shadow.focus         = 1; // Focuses shadow camera to fit spot cone
```

### RectAreaLight — Area Light (Softbox)

Rectangular emitter for studio/interior looks. No real-time shadows — bake or use PointLight fallback.

```javascript
import { RectAreaLightHelper } from 'three/addons/helpers/RectAreaLightHelper.js';
import { RectAreaLightUniformsLib } from 'three/addons/lights/RectAreaLightUniformsLib.js';

// Required once at startup
RectAreaLightUniformsLib.init();

const rectLight = new THREE.RectAreaLight(
  0xffffff, // colour
  5,        // intensity
  4,        // width
  4,        // height
);
rectLight.position.set(0, 5, 0);
rectLight.lookAt(0, 0, 0);
scene.add(rectLight);

// Debug helper (development only)
scene.add(new RectAreaLightHelper(rectLight));
```

Only works with `MeshStandardMaterial` and `MeshPhysicalMaterial`.

---

## Shadow Configuration

### Shadow Map Types

```javascript
renderer.shadowMap.enabled = true;
renderer.shadowMap.type    = THREE.PCFSoftShadowMap; // Recommended default

// Options:
// THREE.BasicShadowMap        — fastest, no filtering
// THREE.PCFShadowMap          — percentage closer filtering
// THREE.PCFSoftShadowMap      — soft PCF (best quality/cost balance)
// THREE.VSMShadowMap          — variance shadow maps (blurry, fast)
```

### Tuning Shadow Quality

```javascript
// Increase resolution
light.shadow.mapSize.set(2048, 2048); // Powers of 2: 512, 1024, 2048, 4096

// Prevent shadow acne (self-shadowing artefacts)
light.shadow.bias       = -0.001;  // Negative for DirectionalLight
light.shadow.normalBias = 0.02;    // Positive for rounded surfaces

// Fit shadow camera tightly around scene (improves precision)
light.shadow.camera.left   = -10;
light.shadow.camera.right  = 10;
light.shadow.camera.top    = 10;
light.shadow.camera.bottom = -10;
light.shadow.camera.updateProjectionMatrix();
```

### Selective Shadows

```javascript
// Opt objects in/out
mesh.castShadow    = true;  // Casts shadow onto others
mesh.receiveShadow = true;  // Receives shadows from others

// Ground plane only needs to receive
groundPlane.castShadow    = false;
groundPlane.receiveShadow = true;
```

---

## Environment Map Lighting

### Equirectangular HDR (Recommended)

```javascript
import { RGBELoader } from 'three/addons/loaders/RGBELoader.js';
import { PMREMGenerator } from 'three';

const pmrem = new PMREMGenerator(renderer);
pmrem.compileEquirectangularShader();

new RGBELoader().load('studio.hdr', hdrTexture => {
  const envMap = pmrem.fromEquirectangular(hdrTexture).texture;

  scene.environment = envMap; // PBR lighting for all MeshStandardMaterial
  scene.background  = envMap; // Visible skybox

  hdrTexture.dispose();
  pmrem.dispose();
});
```

### Cube Texture (Legacy)

```javascript
const cubeLoader = new THREE.CubeTextureLoader();
const envMap = cubeLoader.load([
  'px.jpg', 'nx.jpg',
  'py.jpg', 'ny.jpg',
  'pz.jpg', 'nz.jpg',
]);
scene.environment = envMap;
scene.background  = envMap;
```

### Apply Per-Material

```javascript
// Apply env map to a specific material only
material.envMap          = envMap;
material.envMapIntensity = 1.5; // Scale reflection intensity
```

---

## 3-Point Studio Setup

Classic lighting rig for character/product renders.

```javascript
function createStudioLighting(scene) {
  // Key light — primary, directional, 45° above and to the right
  const keyLight = new THREE.DirectionalLight(0xfff5e0, 1.5);
  keyLight.position.set(3, 4, 3);
  keyLight.castShadow = true;
  keyLight.shadow.mapSize.set(1024, 1024);
  scene.add(keyLight);

  // Fill light — opposite side, softer, no shadows
  const fillLight = new THREE.DirectionalLight(0xe0f0ff, 0.4);
  fillLight.position.set(-3, 2, 2);
  scene.add(fillLight);

  // Back light (rim) — behind subject, separates from background
  const rimLight = new THREE.DirectionalLight(0xffffff, 0.6);
  rimLight.position.set(0, 3, -4);
  scene.add(rimLight);

  // Ambient fill for shadows
  const ambient = new THREE.AmbientLight(0xffffff, 0.2);
  scene.add(ambient);
}
```

---

## LightProbe — Baked Ambient from Environment

Captures low-frequency ambient light from a cube render at runtime.

```javascript
import { LightProbeGenerator } from 'three/addons/lights/LightProbeGenerator.js';

const cubeRenderTarget = new THREE.WebGLCubeRenderTarget(256);
const cubeCamera = new THREE.CubeCamera(0.1, 1000, cubeRenderTarget);
scene.add(cubeCamera);

// Render once, then generate probe
cubeCamera.update(renderer, scene);
const lightProbe = LightProbeGenerator.fromCubeRenderTarget(renderer, cubeRenderTarget);
scene.add(lightProbe);
```

Better quality than `AmbientLight` for scenes with a skybox — captures actual sky colour.

---

## Light Helpers (Development)

```javascript
import { DirectionalLightHelper } from 'three';
import { PointLightHelper }       from 'three';
import { SpotLightHelper }        from 'three';
import { HemisphereLightHelper }  from 'three';
import { RectAreaLightHelper }    from 'three/addons/helpers/RectAreaLightHelper.js';

scene.add(new DirectionalLightHelper(dirLight, 2));
scene.add(new PointLightHelper(pointLight, 0.5));
scene.add(new SpotLightHelper(spotLight));
scene.add(new HemisphereLightHelper(hemiLight, 1));

// Update SpotLight helper when target moves
spotHelper.update();
```

---

## Performance Tips

1. **Limit shadow-casting lights** — each adds a render pass. 1–2 maximum on mobile
2. **Use HemisphereLight instead of AmbientLight outdoors** — more realistic for the same cost
3. **Disable castShadow on small/distant objects** — only the floor and large props need shadows
4. **Tight shadow camera frustum** — shadow precision is proportional to frustum size; fit it to visible area
5. **Shadow map pooling** — Three.js reuses shadow map textures; don't create lights dynamically
6. **Use environment maps for static PBR lighting** — `scene.environment` + no dynamic lights is fastest

```javascript
// Check total lights at startup
console.log('Lights:', renderer.info.programs);
// Or inspect directly
const lightCount = scene.children.filter(c => c.isLight).length;
```

---

## See Also

- `threejs-fundamentals` — scene setup and renderer configuration
- `threejs-materials` — PBR material properties that interact with lighting
- `threejs-textures` — HDR and environment map texture loading
- `three-js-best-practices` — shadow map budget and light count limits
