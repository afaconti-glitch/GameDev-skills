---
name: web-game-browser-constraints
description: Browser-specific constraints reference for web games. Covers tab visibility and RAF throttling, iOS audio context unlock, Fullscreen API, Pointer Lock, Screen Wake Lock, save data (localStorage vs IndexedDB), Service Worker asset caching, mobile memory pressure, and Web Workers for offloading heavy computation. Complements three-js-best-practices and phaser-best-practices with browser-environment concerns that apply regardless of engine.
license: Proprietary
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Engine-agnostic — applies to Phaser, Three.js, Babylon.js, plain canvas, or any browser game runtime.
metadata:
  owner: game-delivery
  version: "1.0.0"
  language: "en-GB"
  category: "web-rendering"
  tags:
    - browser
    - web-game
    - mobile
    - ios
    - audio
    - fullscreen
    - pointer-lock
    - service-worker
    - indexeddb
    - performance
    - visibility-api
---

# Web Game Browser Constraints

Reference guide for browser-specific concerns that apply to all web games regardless of engine. Rules are grouped by constraint type. Critical rules are marked **CRITICAL**.

---

## 1. Tab Visibility and RAF Throttling

**CRITICAL — `requestAnimationFrame` is throttled or suspended when a tab is hidden.** Timers also drift. If your game loop relies on wall-clock time, unhandled tab switching will cause:
- physics simulation tunnelling (objects teleport through walls on return)
- audio desync
- incorrect delta accumulation (a 30-second tab switch produces a 30-second delta on return)

### Pause and resume on visibility change

```javascript
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    pauseGame();      // stop game loop, mute audio, save state
  } else {
    resetDelta();     // discard accumulated delta time
    resumeGame();
  }
});
```

### Clamping delta time

Always clamp the maximum delta to a safe value before passing it to your update loop:

```javascript
const MAX_DELTA = 1 / 15; // cap at 15 fps equivalent (~66ms)

function gameLoop(timestamp) {
  const rawDelta = (timestamp - lastTimestamp) / 1000;
  const delta = Math.min(rawDelta, MAX_DELTA); // prevents physics explosion on tab return
  lastTimestamp = timestamp;

  update(delta);
  render();
  requestAnimationFrame(gameLoop);
}
```

### Background tabs in mobile Chrome and Safari

On mobile browsers, background tabs may be fully suspended (not just throttled). Treat any delta > 250 ms as an indication the tab was backgrounded — reset physics integrators and particle timers rather than simulating the gap.

---

## 2. Audio Context — iOS and Mobile Unlock

**CRITICAL — Safari (iOS and macOS) and many mobile browsers suspend the AudioContext until a user gesture.** Any attempt to play audio before the first gesture produces silence, or a `NotAllowedError`.

### Unlock pattern (engine-agnostic)

```javascript
const audioContext = new AudioContext();

function unlockAudio() {
  if (audioContext.state === 'suspended') {
    audioContext.resume().then(() => {
      console.log('AudioContext unlocked');
    });
  }
  document.removeEventListener('pointerdown', unlockAudio);
  document.removeEventListener('keydown', unlockAudio);
}

document.addEventListener('pointerdown', unlockAudio, { once: true });
document.addEventListener('keydown', unlockAudio, { once: true });
```

### Web Audio API format support

Always provide OGG and MP3 fallbacks. Safari does not support OGG.

```javascript
const formats = ['ogg', 'mp3'];
const supportedFormat = formats.find(fmt => {
  const a = document.createElement('audio');
  return a.canPlayType(`audio/${fmt}`) !== '';
});
```

### iOS audio sprite requirement

iOS limits concurrent audio channels. Use audio sprites (single file, multiple named regions) rather than many individual files.

```javascript
// Howler.js example
const sfx = new Howl({
  src: ['sfx.webm', 'sfx.mp3'],
  sprite: {
    coin:  [0,    500],
    jump:  [600,  400],
    death: [1100, 800],
  }
});
sfx.play('coin');
```

---

## 3. Fullscreen API

**Do not attempt to enter fullscreen outside a user gesture handler.** Browsers will reject it silently or throw `TypeError`.

```javascript
async function enterFullscreen() {
  const el = document.documentElement; // or your canvas element
  try {
    if (el.requestFullscreen) {
      await el.requestFullscreen();
    } else if (el.webkitRequestFullscreen) {  // Safari
      el.webkitRequestFullscreen();
    }
  } catch (err) {
    console.warn('Fullscreen not available:', err);
  }
}

async function exitFullscreen() {
  if (document.fullscreenElement) {
    await document.exitFullscreen();
  }
}

// Detect change (e.g. user presses Esc)
document.addEventListener('fullscreenchange', () => {
  const isFullscreen = !!document.fullscreenElement;
  onFullscreenToggled(isFullscreen);
});
```

### Handling the resize on fullscreen change

On fullscreen entry the viewport dimensions change. Resize your renderer inside `fullscreenchange`:

```javascript
document.addEventListener('fullscreenchange', () => {
  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
});
```

---

## 4. Pointer Lock (FPS and mouse-look games)

Pointer Lock captures the mouse cursor inside the canvas, enabling unlimited relative movement. Required for first-person games and mouse-look controls.

```javascript
const canvas = document.getElementById('game-canvas');

// Request — must be called from a user gesture
canvas.addEventListener('click', () => {
  canvas.requestPointerLock();
});

// Listen for lock/unlock
document.addEventListener('pointerlockchange', () => {
  if (document.pointerLockElement === canvas) {
    document.addEventListener('mousemove', onMouseMove);
  } else {
    document.removeEventListener('mousemove', onMouseMove);
  }
});

function onMouseMove(e) {
  // movementX / movementY give unbounded relative deltas
  rotateCamera(e.movementX * sensitivity, e.movementY * sensitivity);
}
```

**Browsers may reject Pointer Lock on insecure origins (HTTP).** Serve over HTTPS in production.

---

## 5. Screen Wake Lock

Prevents the device from sleeping during gameplay. Essential for mobile games where player inactivity on menus or cutscenes would otherwise lock the screen.

```javascript
let wakeLock = null;

async function requestWakeLock() {
  if (!('wakeLock' in navigator)) return; // not supported — fail silently
  try {
    wakeLock = await navigator.wakeLock.request('screen');
    wakeLock.addEventListener('release', () => {
      // Re-acquire on tab re-focus if still playing
      if (!document.hidden) requestWakeLock();
    });
  } catch (err) {
    console.warn('Wake lock not acquired:', err);
  }
}

async function releaseWakeLock() {
  if (wakeLock) {
    await wakeLock.release();
    wakeLock = null;
  }
}

// Acquire when game starts, release on pause/menu/game-over
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    releaseWakeLock();
  } else {
    requestWakeLock();
  }
});
```

Wake lock is released automatically when the page is backgrounded — always re-request on visibility restore.

---

## 6. Save Data: localStorage vs IndexedDB

| | `localStorage` | `IndexedDB` |
|---|---|---|
| Capacity | ~5 MB | Hundreds of MB |
| API | Synchronous (blocks main thread) | Asynchronous |
| Data types | Strings only | Any serialisable JS value |
| Use for | Small settings, flags, quick saves | Full save files, asset cache, level state |

### localStorage (small saves)

```javascript
// Write
localStorage.setItem('gameSettings', JSON.stringify({ volume: 0.8, quality: 'high' }));

// Read
const settings = JSON.parse(localStorage.getItem('gameSettings') ?? '{}');
```

**Do not store large objects in localStorage.** Synchronous writes block the main thread; on mobile, writing > 50 KB can cause a visible frame hitch.

### IndexedDB (full save data)

```javascript
// idb-keyval is the recommended minimal wrapper
import { get, set, del } from 'idb-keyval';

// Save
await set('saveSlot1', { level: 5, hp: 80, inventory: [...] });

// Load
const save = await get('saveSlot1');

// Delete
await del('saveSlot1');
```

Always handle the case where IndexedDB is unavailable (private browsing in some browsers) and fall back to localStorage.

---

## 7. Service Worker Asset Caching

Cache game assets with a Service Worker to enable near-instant repeat loads and offline play.

### Minimal install + fetch strategy

```javascript
// sw.js
const CACHE = 'game-v1';
const PRECACHE_ASSETS = [
  '/',
  '/index.html',
  '/assets/sprites.png',
  '/assets/sprites.json',
  '/assets/level1.json',
  '/assets/sfx.mp3',
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE).then(cache => cache.addAll(PRECACHE_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request).then(cached => cached ?? fetch(event.request))
  );
});
```

### Registering the Service Worker

```javascript
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js').catch(console.warn);
}
```

**Update the cache name (`game-v1` → `game-v2`) on every deployment** that changes cached assets. The old cache is deleted in the `activate` handler.

---

## 8. Mobile Memory Pressure

iOS fires a private memory warning; Chrome on Android exposes `onmemorypressure`. Neither is reliable, but you can listen for performance degradation signals:

```javascript
// Chrome Android — experimental
if ('memory' in performance) {
  setInterval(() => {
    const { usedJSHeapSize, jsHeapSizeLimit } = performance.memory;
    const ratio = usedJSHeapSize / jsHeapSizeLimit;
    if (ratio > 0.85) {
      reduceQuality();        // lower texture resolution, disable post-processing
    }
  }, 10000);
}
```

### Proactive memory management

- Dispose textures for levels that are no longer active
- Never store full frame buffers in JS arrays
- Unload audio buffers when leaving a zone
- Use texture compression (KTX2/Basis for Three.js, or compressed atlas for Phaser) to reduce GPU memory footprint

---

## 9. Network-Adaptive Quality

Use the Network Information API to detect slow connections and reduce initial load cost:

```javascript
const connection = navigator.connection ?? navigator.mozConnection ?? navigator.webkitConnection;

function getQualityTier() {
  if (!connection) return 'high';
  const { effectiveType, saveData } = connection;
  if (saveData) return 'low';
  if (effectiveType === 'slow-2g' || effectiveType === '2g') return 'low';
  if (effectiveType === '3g') return 'medium';
  return 'high';
}

// Load different asset sets based on tier
const tier = getQualityTier();
const atlasUrl = {
  low:    'assets/sprites-512.png',
  medium: 'assets/sprites-1024.png',
  high:   'assets/sprites-2048.png',
}[tier];
```

---

## 10. Web Workers for Heavy Computation

Move pathfinding, procedural generation, physics pre-computation, and chunk loading off the main thread to prevent frame drops.

```javascript
// worker.js
self.onmessage = ({ data }) => {
  if (data.type === 'pathfind') {
    const path = findPath(data.grid, data.start, data.end); // heavy A* computation
    self.postMessage({ type: 'pathResult', path });
  }
};

// main.js
const worker = new Worker('/worker.js', { type: 'module' });

worker.postMessage({ type: 'pathfind', grid, start, end });

worker.onmessage = ({ data }) => {
  if (data.type === 'pathResult') {
    applyPath(data.path);
  }
};
```

### Shared memory with SharedArrayBuffer

For high-frequency data sharing (particle positions, physics state) use `SharedArrayBuffer` to avoid message-copy overhead:

```javascript
// Requires Cross-Origin-Opener-Policy: same-origin
// Requires Cross-Origin-Embedder-Policy: require-corp

const buffer = new SharedArrayBuffer(Float32Array.BYTES_PER_ELEMENT * particleCount * 3);
const positions = new Float32Array(buffer);

worker.postMessage({ type: 'init', buffer });
// Worker writes positions[i*3 … i*3+2] each tick
// Main thread reads positions[] in the render loop without blocking
```

**`SharedArrayBuffer` requires both COOP and COEP response headers.** Verify your server configuration before relying on it.

---

## Quick-reference checklist

- [ ] `visibilitychange` handler pauses game loop and resets delta on return
- [ ] Delta time clamped to MAX_DELTA (≤ 66 ms) before physics update
- [ ] AudioContext unlocked on first `pointerdown` or `keydown`
- [ ] Audio files supplied in both OGG and MP3
- [ ] Fullscreen and Pointer Lock requests placed inside user gesture handlers
- [ ] Screen Wake Lock acquired on game start, released on pause/game-over
- [ ] Save data ≤ 50 KB uses localStorage; anything larger uses IndexedDB
- [ ] Service Worker installed and precaching all critical game assets
- [ ] Cache name versioned — update on every deployment with new assets
- [ ] Performance.memory ratio monitored; quality reduced above 85% heap usage
- [ ] Network Information API used to select appropriate asset quality tier
- [ ] Heavy computation (pathfinding, proc-gen) moved to a Web Worker
- [ ] HTTPS served in production (required for Pointer Lock, Service Worker, Wake Lock)
