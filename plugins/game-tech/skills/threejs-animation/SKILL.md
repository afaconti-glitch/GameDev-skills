---
name: threejs-animation
description: Three.js animation system — AnimationMixer, AnimationClip, AnimationAction, keyframe tracks, skeletal animation, morph targets, animation blending, and procedural motion. Use when animating objects, playing GLTF animations, creating procedural motion, blending animations, or working with bones and morph targets. Adapted from CloudAI-X/threejs-skills (MIT).
license: MIT
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project Three.js source files with animation clips loaded from GLTF.
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
    - animation
    - animation-mixer
    - skeletal
    - morph-targets
    - keyframes
    - procedural-animation
  intents:
    - clip-playback
    - skeletal-animation
    - morph-targets
    - animation-blending
    - procedural-motion
  output_types:
    - code-example
    - api-reference
    - animation-plan
---

# Three.js Animation

## Quick Start

```javascript
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

const mixer = null; // Declare outside so update() can reach it
const clock  = new THREE.Clock();

new GLTFLoader().load('character.glb', gltf => {
  scene.add(gltf.scene);

  mixer = new THREE.AnimationMixer(gltf.scene);
  const action = mixer.clipAction(gltf.animations[0]);
  action.play();
});

function animate() {
  requestAnimationFrame(animate);
  mixer?.update(clock.getDelta()); // Always pass delta — frame-rate independent
  renderer.render(scene, camera);
}
animate();
```

---

## Core Classes

### AnimationClip

A named container of keyframe data for one animation (e.g., "walk", "jump").

```javascript
// Create a clip manually
const posTrack = new THREE.VectorKeyframeTrack(
  '.position',             // Property path
  [0, 1, 2],               // Key times (seconds)
  [0,0,0, 0,2,0, 0,0,0],  // Values (x,y,z for each key)
);

const clip = new THREE.AnimationClip('bounce', 2, [posTrack]);

// Optimise a loaded clip (reduces memory)
THREE.AnimationUtils.makeClipAdditive(clip);
```

### Keyframe Track Types

| Track class | Property type | Example path |
|---|---|---|
| `NumberKeyframeTrack` | Float | `.morphTargetInfluences[0]` |
| `VectorKeyframeTrack` | Vector3 | `.position`, `.scale` |
| `QuaternionKeyframeTrack` | Quaternion | `.quaternion` |
| `ColorKeyframeTrack` | Color | `.material.color` |
| `BooleanKeyframeTrack` | Boolean | `.visible` |
| `StringKeyframeTrack` | String | (rarely used) |

```javascript
// Rotation track using Quaternion (more reliable than Euler)
const rotTrack = new THREE.QuaternionKeyframeTrack(
  '.quaternion',
  [0, 1, 2],
  [
    0, 0, 0, 1,                        // t=0: identity
    0, Math.sin(Math.PI/4), 0, Math.cos(Math.PI/4), // t=1: 90° Y
    0, 0, 0, 1,                        // t=2: back to identity
  ],
);
```

### Interpolation Modes

```javascript
import { InterpolateDiscrete, InterpolateLinear, InterpolateSmooth } from 'three';

track.setInterpolation(InterpolateLinear);   // Default
track.setInterpolation(InterpolateSmooth);   // Cubic spline
track.setInterpolation(InterpolateDiscrete); // Step / snap
```

### AnimationMixer

Controls playback of all clips for one object (or hierarchy).

```javascript
const mixer = new THREE.AnimationMixer(rootObject);

// Always call in the render loop
function animate() {
  requestAnimationFrame(animate);
  mixer.update(clock.getDelta()); // Pass seconds-since-last-frame
  renderer.render(scene, camera);
}

// Listen for clip completion
mixer.addEventListener('finished', event => {
  console.log('Finished:', event.action.getClip().name);
});

// Remove listeners when done
mixer.removeEventListener('finished', handler);
```

### AnimationAction

Controls a single clip's playback state.

```javascript
const action = mixer.clipAction(clip, optionalRootObject);

// Playback
action.play();
action.pause();
action.stop();      // Resets to start
action.reset();     // Reset without stopping

// Speed and timing
action.timeScale     = 1;    // 1 = normal, 2 = double speed, -1 = reverse
action.time          = 0.5;  // Jump to 0.5 seconds
action.setDuration(2);       // Scale clip to 2-second playback

// Loop modes
action.loop       = THREE.LoopRepeat;  // Default — loops forever
action.loop       = THREE.LoopOnce;    // Plays once then stops
action.loop       = THREE.LoopPingPong; // Alternates forward/backward
action.repetitions = 3;               // Repeat N times then stop
action.clampWhenFinished = true;      // Freeze at last frame when done

// Weight (for blending)
action.weight     = 1.0; // 0 = invisible, 1 = full influence
action.enabled    = true;

// Fade
action.fadeIn(0.3);   // Fade in over 0.3 seconds
action.fadeOut(0.3);  // Fade out over 0.3 seconds
action.crossFadeTo(otherAction, 0.3, false);
```

---

## Skeletal Animation

### Accessing Bones

```javascript
loader.load('character.glb', gltf => {
  const model = gltf.scene;

  // Find skeleton
  let skeleton;
  model.traverse(child => {
    if (child.isSkinnedMesh) {
      skeleton = child.skeleton;
    }
  });

  // Find a named bone
  const spineBone = skeleton.getBoneByName('Spine');

  // Rotate bone manually (overrides animation for that frame)
  spineBone.rotation.z = Math.sin(Date.now() * 0.001) * 0.2;
});
```

### Attaching Objects to Bones

```javascript
// Attach a weapon to the right hand bone
const handBone = skeleton.getBoneByName('RightHand');
const weapon   = new THREE.Mesh(weaponGeo, weaponMat);
handBone.add(weapon);
weapon.position.set(0, 0.1, 0); // Offset relative to bone
```

### Skeleton Helper

```javascript
const helper = new THREE.SkeletonHelper(model);
scene.add(helper); // Visualise bone structure during development
```

---

## Morph Targets

Shape blending between different mesh states (facial expressions, deformation).

```javascript
loader.load('face.glb', gltf => {
  const mesh = gltf.scene.children[0];

  // List available morph targets
  console.log(mesh.morphTargetDictionary);
  // e.g. { 'smile': 0, 'blink': 1, 'surprised': 2 }

  // Set influence (0–1)
  mesh.morphTargetInfluences[0] = 0.5; // 50% smile
  mesh.morphTargetInfluences[1] = 1.0; // 100% blink

  // By name
  const idx = mesh.morphTargetDictionary['smile'];
  mesh.morphTargetInfluences[idx] = 0.8;
});

// Animate morph target influence over time
function animate() {
  const t = Math.sin(clock.getElapsedTime()) * 0.5 + 0.5; // 0–1
  mesh.morphTargetInfluences[0] = t;
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}
```

---

## Animation Blending

### Weight-Based Blending

```javascript
const idleAction = mixer.clipAction(idleClip);
const walkAction = mixer.clipAction(walkClip);
const runAction  = mixer.clipAction(runClip);

// Start all paused
[idleAction, walkAction, runAction].forEach(a => {
  a.play();
  a.weight = 0;
});

idleAction.weight = 1; // Start in idle

function setMovementBlend(speed) {
  // speed: 0 = idle, 0.5 = walk, 1 = run
  idleAction.weight = Math.max(0, 1 - speed * 2);
  walkAction.weight = speed < 0.5
    ? speed * 2
    : Math.max(0, 1 - (speed - 0.5) * 2);
  runAction.weight  = Math.max(0, (speed - 0.5) * 2);
}
```

### Additive Blending

Layer a secondary motion (e.g., breathing) on top of a base animation.

```javascript
// Mark clip as additive
THREE.AnimationUtils.makeClipAdditive(breatheClip);

const baseAction    = mixer.clipAction(walkClip);
const addAction     = mixer.clipAction(breatheClip);

addAction.blendMode = THREE.AdditiveAnimationBlendMode;
baseAction.play();
addAction.play();
```

### Crossfade Between Clips

```javascript
function crossfade(from, to, duration = 0.3) {
  to.reset().play();
  from.crossFadeTo(to, duration, false);
}

// Usage — e.g. on spacebar
crossfade(idleAction, jumpAction, 0.2);
```

---

## Procedural Animation

### Smooth Damping (Character Movement)

```javascript
const currentVelocity = new THREE.Vector3();
const targetPosition  = new THREE.Vector3();

function smoothDamp(current, target, velocity, smoothTime, delta) {
  const omega = 2 / smoothTime;
  const x     = omega * delta;
  const exp   = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x);
  const diff  = current.clone().sub(target);
  const temp  = velocity.clone().add(diff.clone().multiplyScalar(omega)).multiplyScalar(delta);
  velocity.copy(temp.clone().negate().multiplyScalar(omega).add(velocity));
  return target.clone().add(diff.clone().add(temp).multiplyScalar(exp));
}

// In render loop
function animate() {
  const delta = clock.getDelta();
  player.position.copy(
    smoothDamp(player.position, targetPosition, currentVelocity, 0.1, delta)
  );
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}
```

### Spring Physics

```javascript
class Spring {
  constructor(stiffness = 200, damping = 20) {
    this.stiffness = stiffness;
    this.damping   = damping;
    this.velocity  = 0;
    this.position  = 0;
    this.target    = 0;
  }

  update(delta) {
    const force    = (this.target - this.position) * this.stiffness;
    const dampForce = this.velocity * this.damping;
    this.velocity += (force - dampForce) * delta;
    this.position += this.velocity * delta;
    return this.position;
  }
}

const bounceSpring = new Spring(150, 15);

function animate() {
  const delta = clock.getDelta();
  bounceSpring.target = isJumping ? 1 : 0;
  mesh.position.y     = bounceSpring.update(delta);
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}
```

### Oscillation and Circular Motion

```javascript
function animate() {
  const t = clock.getElapsedTime();

  // Oscillate
  mesh.position.y = Math.sin(t * 2) * 0.5;

  // Circular orbit
  mesh.position.x = Math.cos(t) * 3;
  mesh.position.z = Math.sin(t) * 3;

  // Rotate to face direction of travel
  mesh.rotation.y = -t + Math.PI / 2;

  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}
```

---

## Common Patterns

### Cache Mixers for Multiple Characters

```javascript
const mixers = new Map();

function addCharacter(model, animations) {
  const mixer = new THREE.AnimationMixer(model);
  mixers.set(model.uuid, mixer);

  const actions = {};
  animations.forEach(clip => {
    actions[clip.name] = mixer.clipAction(clip);
  });

  return actions;
}

function update(delta) {
  mixers.forEach(m => m.update(delta));
}
```

### Disable Mixer for Off-Screen Objects

```javascript
function animate() {
  const delta = clock.getDelta();
  mixers.forEach((mixer, uuid) => {
    const obj = scene.getObjectByProperty('uuid', uuid);
    if (obj && obj.visible) {
      mixer.update(delta);
    }
  });
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}
```

---

## Performance Tips

1. **Always pass delta** — frame-rate-independent playback
2. **Reuse `clipAction` results** — mixer caches them; avoid calling `clipAction` every frame
3. **Disable mixer when off-screen** — save CPU for non-visible characters
4. **Limit simultaneous blending** — more than 4–5 concurrent blended actions gets expensive
5. **Optimise clips** — remove redundant keyframes with `THREE.AnimationUtils.subclip`

```javascript
// Subclip: extract frames 20–40 of a clip
const subClip = THREE.AnimationUtils.subclip(fullClip, 'run', 20, 40, 30);
```

---

## See Also

- `threejs-loaders` — loading GLTF files with animation clips
- `threejs-fundamentals` — scene setup and Clock usage
- `threejs-shaders` — vertex shader-based animation
