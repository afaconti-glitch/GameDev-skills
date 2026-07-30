---
name: threejs-interaction
description: Three.js user interaction — camera controls (OrbitControls, FirstPersonControls, PointerLockControls, FlyControls, MapControls), raycasting for click and hover detection, TransformControls, DragControls, SelectionBox, keyboard input, and touch handling. Use when implementing player input, object picking, camera movement, or any user-driven 3D interaction. Adapted from CloudAI-X/threejs-skills (MIT).
license: MIT
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project Three.js source files. Requires three/addons controls from the same Three.js version.
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
    - interaction
    - raycasting
    - camera-controls
    - orbit-controls
    - pointer-lock
    - input
    - game-input
  intents:
    - camera-controls
    - raycasting
    - object-picking
    - transform-gizmos
    - keyboard-input
    - touch-input
  output_types:
    - code-example
    - api-reference
    - input-scheme
---

# Three.js Interaction

## Quick Start

```javascript
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true; // Smooth inertia
controls.dampingFactor = 0.05;

function animate() {
  requestAnimationFrame(animate);
  controls.update(); // Required when enableDamping is true
  renderer.render(scene, camera);
}
```

---

## Camera Controls

### OrbitControls — Rotate Around a Target

Best for: editors, product viewers, model inspection.

```javascript
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const controls = new OrbitControls(camera, renderer.domElement);

// Damping (smooth feel)
controls.enableDamping  = true;
controls.dampingFactor  = 0.05;

// Limits
controls.minDistance    = 1;
controls.maxDistance    = 50;
controls.minPolarAngle  = 0;                // Vertical: 0 = straight up
controls.maxPolarAngle  = Math.PI * 0.9;   // Don't go past floor
controls.minAzimuthAngle = -Math.PI / 4;   // Horizontal left limit
controls.maxAzimuthAngle =  Math.PI / 4;   // Horizontal right limit

// Disable specific interactions
controls.enablePan  = false;
controls.enableZoom = false;
controls.enableRotate = false;

// Pan speed / zoom speed
controls.panSpeed    = 1.0;
controls.zoomSpeed   = 1.0;
controls.rotateSpeed = 1.0;

// Target (the point the camera orbits around)
controls.target.set(0, 1, 0);
controls.update();

// Must call in render loop when damping is enabled
function animate() {
  controls.update();
  renderer.render(scene, camera);
}
```

### PointerLockControls — First-Person Game Controls

Best for: FPS games, immersive first-person experiences.

```javascript
import { PointerLockControls } from 'three/addons/controls/PointerLockControls.js';

const controls = new PointerLockControls(camera, document.body);

// Lock pointer on click (requires user gesture)
document.addEventListener('click', () => controls.lock());

controls.addEventListener('lock',   () => console.log('Pointer locked'));
controls.addEventListener('unlock', () => console.log('Pointer unlocked'));

// WASD movement
const keys = {};
document.addEventListener('keydown', e => keys[e.code] = true);
document.addEventListener('keyup',   e => keys[e.code] = false);

const velocity  = new THREE.Vector3();
const direction = new THREE.Vector3();
const moveSpeed = 10;

function animate() {
  const delta = clock.getDelta();

  direction.z = Number(keys['KeyW']) - Number(keys['KeyS']);
  direction.x = Number(keys['KeyD']) - Number(keys['KeyA']);
  direction.normalize();

  if (keys['KeyW'] || keys['KeyS']) velocity.z -= direction.z * moveSpeed * delta;
  if (keys['KeyA'] || keys['KeyD']) velocity.x -= direction.x * moveSpeed * delta;

  // Friction
  velocity.x -= velocity.x * 10 * delta;
  velocity.z -= velocity.z * 10 * delta;

  controls.moveRight(-velocity.x * delta);
  controls.moveForward(-velocity.z * delta);

  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}
```

### FlyControls — Free-Flying Camera

Best for: fly-through, level design views.

```javascript
import { FlyControls } from 'three/addons/controls/FlyControls.js';

const controls = new FlyControls(camera, renderer.domElement);
controls.movementSpeed = 10;
controls.rollSpeed     = Math.PI / 12;
controls.autoForward   = false;
controls.dragToLook    = true;

// Must pass delta to update
function animate() {
  controls.update(clock.getDelta());
  renderer.render(scene, camera);
}
```

### MapControls — Top-Down Map View

Best for: strategy games, overhead editors.

```javascript
import { MapControls } from 'three/addons/controls/MapControls.js';

const controls = new MapControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.screenSpacePanning = false; // Pan keeps camera at same height
controls.minDistance  = 5;
controls.maxDistance  = 100;
controls.maxPolarAngle = Math.PI / 2; // No looking under the map
```

### FirstPersonControls — Mouse-Look Camera

Best for: walkthroughs, cut-scenes.

```javascript
import { FirstPersonControls } from 'three/addons/controls/FirstPersonControls.js';

const controls = new FirstPersonControls(camera, renderer.domElement);
controls.movementSpeed  = 5;
controls.lookSpeed      = 0.1;
controls.lookVertical   = true;
controls.constrainVertical = true;
controls.verticalMin    = 1.0;
controls.verticalMax    = 2.0;

function animate() {
  controls.update(clock.getDelta());
  renderer.render(scene, camera);
}
```

---

## Raycasting

Convert screen coordinates to 3D ray and test for intersections.

### Basic Click Detection

```javascript
const raycaster = new THREE.Raycaster();
const mouse     = new THREE.Vector2();

function onClick(event) {
  // Normalise mouse to -1..1
  mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
  mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

  raycaster.setFromCamera(mouse, camera);

  // Test against specific objects
  const intersects = raycaster.intersectObjects(scene.children, true); // true = recursive

  if (intersects.length > 0) {
    const hit = intersects[0]; // Nearest intersection
    console.log('Hit:', hit.object.name);
    console.log('Point:', hit.point);        // World position
    console.log('Distance:', hit.distance);  // Distance from camera
    console.log('Face:', hit.face);          // Hit face normal
    console.log('UV:', hit.uv);              // Hit UV coordinate
  }
}

renderer.domElement.addEventListener('click', onClick);
```

### Hover / Highlight

```javascript
let hovered = null;

function onMouseMove(event) {
  mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
  mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

  raycaster.setFromCamera(mouse, camera);
  const intersects = raycaster.intersectObjects(interactiveObjects);

  if (intersects.length > 0) {
    const obj = intersects[0].object;
    if (hovered !== obj) {
      if (hovered) hovered.material.emissive.set(0x000000);
      hovered = obj;
      hovered.material.emissive.set(0x444444);
    }
  } else {
    if (hovered) hovered.material.emissive.set(0x000000);
    hovered = null;
  }
}

// Throttle to avoid raycasting every frame
let lastMove = 0;
renderer.domElement.addEventListener('mousemove', event => {
  if (Date.now() - lastMove > 16) { // ~60fps
    onMouseMove(event);
    lastMove = Date.now();
  }
});
```

### Limit Raycast to Specific Layers

```javascript
// Only test objects on layer 1
raycaster.layers.set(1);

interactiveObject.layers.enable(1);
nonInteractiveObject.layers.disable(1); // On layer 0 (default)
```

### Invisible Collision Meshes

```javascript
// Use a simpler mesh for raycasting, hide the visual mesh's detail
const collider = new THREE.Mesh(
  new THREE.BoxGeometry(1, 1, 1), // Simple shape
  new THREE.MeshBasicMaterial({ visible: false }),
);
collider.userData.isCollider = true;
scene.add(collider);

const intersects = raycaster.intersectObjects([collider]);
```

---

## TransformControls — Move/Rotate/Scale Gizmo

```javascript
import { TransformControls } from 'three/addons/controls/TransformControls.js';

const transformControls = new TransformControls(camera, renderer.domElement);
scene.add(transformControls);

// Attach to a selected object
transformControls.attach(selectedObject);

// Switch mode
transformControls.setMode('translate'); // 'translate', 'rotate', 'scale'

// Snapping
transformControls.setTranslationSnap(0.5); // Snap to 0.5-unit grid
transformControls.setRotationSnap(THREE.MathUtils.degToRad(15));
transformControls.setScaleSnap(0.1);

// Coordinate space
transformControls.setSpace('world'); // 'world' or 'local'

// Detach when done
transformControls.detach();

// Prevent OrbitControls from interfering while using TransformControls
transformControls.addEventListener('dragging-changed', event => {
  orbitControls.enabled = !event.value;
});

// Listen for changes
transformControls.addEventListener('objectChange', () => {
  console.log('Position:', selectedObject.position);
});
```

---

## DragControls — Direct Object Dragging

```javascript
import { DragControls } from 'three/addons/controls/DragControls.js';

const dragControls = new DragControls(draggableObjects, camera, renderer.domElement);

dragControls.addEventListener('dragstart', event => {
  orbitControls.enabled = false; // Disable orbit while dragging
  event.object.material.opacity = 0.5;
});

dragControls.addEventListener('drag', event => {
  // Snap to grid
  event.object.position.x = Math.round(event.object.position.x);
  event.object.position.z = Math.round(event.object.position.z);
});

dragControls.addEventListener('dragend', event => {
  orbitControls.enabled = true;
  event.object.material.opacity = 1.0;
});
```

---

## SelectionBox — Marquee Selection

```javascript
import { SelectionBox } from 'three/addons/interactive/SelectionBox.js';
import { SelectionHelper } from 'three/addons/interactive/SelectionHelper.js';

const selectionBox    = new SelectionBox(camera, scene);
const selectionHelper = new SelectionHelper(renderer, 'selectBox');

renderer.domElement.addEventListener('pointerdown', event => {
  selectionBox.startPoint.set(
    (event.clientX / window.innerWidth) * 2 - 1,
    -(event.clientY / window.innerHeight) * 2 + 1,
    0.5,
  );
});

renderer.domElement.addEventListener('pointermove', event => {
  if (selectionHelper.isDown) {
    selectionBox.endPoint.set(
      (event.clientX / window.innerWidth) * 2 - 1,
      -(event.clientY / window.innerHeight) * 2 + 1,
      0.5,
    );
    const selected = selectionBox.select();
    selected.forEach(obj => obj.material.emissive.set(0x333333));
  }
});

renderer.domElement.addEventListener('pointerup', () => {
  const allSelected = selectionBox.collection;
  console.log('Selected:', allSelected);
});
```

---

## Keyboard Input

```javascript
// Track multiple keys simultaneously
const keysDown = new Set();

document.addEventListener('keydown', e => keysDown.add(e.code));
document.addEventListener('keyup',   e => keysDown.delete(e.code));

function handleMovement(delta) {
  const speed = 5;
  if (keysDown.has('KeyW')) player.position.z -= speed * delta;
  if (keysDown.has('KeyS')) player.position.z += speed * delta;
  if (keysDown.has('KeyA')) player.position.x -= speed * delta;
  if (keysDown.has('KeyD')) player.position.x += speed * delta;
  if (keysDown.has('Space'))  jump();
  if (keysDown.has('ShiftLeft')) sprint();
}

// One-shot actions (not held)
document.addEventListener('keydown', e => {
  if (e.code === 'KeyE') interact();
  if (e.code === 'KeyF') toggleFlashlight();
  if (e.code === 'Tab') { e.preventDefault(); openInventory(); }
});
```

---

## Touch Input

```javascript
function getTouchNDC(touch) {
  return new THREE.Vector2(
    (touch.clientX / window.innerWidth) * 2 - 1,
    -(touch.clientY / window.innerHeight) * 2 + 1,
  );
}

renderer.domElement.addEventListener('touchstart', event => {
  event.preventDefault();
  const touch = event.touches[0];
  const ndc   = getTouchNDC(touch);

  raycaster.setFromCamera(ndc, camera);
  const hits = raycaster.intersectObjects(scene.children, true);
  if (hits.length > 0) handleTap(hits[0]);
}, { passive: false });

// Pinch-to-zoom
let lastPinchDist = 0;
renderer.domElement.addEventListener('touchmove', event => {
  if (event.touches.length === 2) {
    const dx   = event.touches[0].clientX - event.touches[1].clientX;
    const dy   = event.touches[0].clientY - event.touches[1].clientY;
    const dist = Math.sqrt(dx * dx + dy * dy);

    if (lastPinchDist > 0) {
      const delta = (lastPinchDist - dist) * 0.01;
      camera.position.z = THREE.MathUtils.clamp(camera.position.z + delta, 1, 50);
    }
    lastPinchDist = dist;
  }
}, { passive: true });

renderer.domElement.addEventListener('touchend', () => { lastPinchDist = 0; });
```

---

## Screen-to-World and World-to-Screen

```javascript
// Screen pixel → world ray origin + direction
function getWorldRayFromScreen(x, y) {
  const ndc = new THREE.Vector2(
    (x / window.innerWidth) * 2 - 1,
    -(y / window.innerHeight) * 2 + 1,
  );
  raycaster.setFromCamera(ndc, camera);
  return { origin: raycaster.ray.origin, direction: raycaster.ray.direction };
}

// World position → screen position (for UI labels, health bars, etc.)
function worldToScreen(worldPos) {
  const pos = worldPos.clone().project(camera);
  return {
    x: (pos.x *  0.5 + 0.5) * window.innerWidth,
    y: (pos.y * -0.5 + 0.5) * window.innerHeight,
  };
}
```

---

## Performance Tips

1. **Throttle mousemove raycasts** — test at ~60fps max, not every mouse event
2. **Use layer filtering** — `raycaster.layers.set(n)` to skip non-interactive objects
3. **Use invisible simple colliders** — simpler geometry for raycasting
4. **Dispose controls** — call `controls.dispose()` on teardown
5. **Avoid raycasting against everything** — maintain an explicit `interactiveObjects` array

---

## See Also

- `threejs-fundamentals` — coordinate system, camera setup
- `threejs-animation` — animating objects driven by input
- `three-js-best-practices` — raycasting performance optimisation
