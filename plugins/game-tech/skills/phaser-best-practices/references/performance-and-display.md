# Performance and display targets

Split out of [`phaser-best-practices`](../SKILL.md) to keep that file inside the 500-line convention.

**Read this when** setting up responsive layout, choosing between WebGL and Canvas, tuning for mobile, or pooling frequently spawned objects.

## Object Pooling

**CRITICAL — Use `Group` with `maxSize` and `createCallback` for frequently spawned objects** (bullets, particles, enemies, collectables). Never create and destroy mid-game.

```javascript
// In create()
this.bullets = this.physics.add.group({
  classType: Phaser.Physics.Arcade.Image,
  maxSize: 50,
  runChildUpdate: true,    // calls update() on each active child each frame
  createCallback: bullet => {
    bullet.setTexture('game', 'bullet');
    bullet.body.setAllowGravity(false);
  },
});

// Firing a bullet — get from pool or create if under maxSize
fire(x, y, direction) {
  const bullet = this.bullets.get(x, y);
  if (!bullet) return;          // pool exhausted — silently skip

  bullet.setActive(true).setVisible(true);
  bullet.body.setVelocityX(direction * 400);

  // Auto-recycle when off screen
  this.time.delayedCall(2000, () => {
    this.bullets.killAndHide(bullet);
    bullet.body.setVelocity(0, 0);
  });
}
```

---

## ScaleManager (Responsive Layout)

### Recommended config for most games

```javascript
scale: {
  mode: Phaser.Scale.FIT,          // letterbox / pillarbox to fit window
  autoCenter: Phaser.Scale.CENTER_BOTH,
  width: 1280,
  height: 720,
}
```

| Mode | Use when |
|---|---|
| `FIT` | Fixed-ratio game (most cases) |
| `ENVELOP` | Allow cropping to fill screen (action games) |
| `RESIZE` | Game adapts to window size (UI-heavy, web apps) |
| `NONE` | Manual scaling only |

### Density-independent positioning

Do not hard-code pixel positions against screen edges. Use `this.scale.width` and `this.scale.height`:

```javascript
// BAD — breaks on non-1280×720 canvas
this.scoreText = this.add.text(20, 20, 'Score: 0');

// GOOD — always top-left with margin
this.scoreText = this.add.text(20, 20, 'Score: 0').setScrollFactor(0);
// Or for right-aligned:
this.livesText = this.add.text(this.scale.width - 20, 20, 'Lives: 3')
  .setOrigin(1, 0)
  .setScrollFactor(0);
```

`setScrollFactor(0)` pins an object to the camera (HUD element).

---

## WebGL vs Canvas Renderer

Phaser defaults to WebGL when available. Canvas is the fallback.

| | WebGL | Canvas |
|---|---|---|
| Performance | Faster for complex scenes | Adequate for simple games |
| Shader effects | Yes (`pipeline`) | No |
| Blend modes | All | Limited |
| Batch rendering | Automatic | No |
| iOS compatibility | Safari 15+ | All |

**Do not force Canvas** unless targeting very old devices or the game is extremely simple. WebGL batch rendering handles hundreds of sprites far more efficiently.

To force a renderer:

```javascript
type: Phaser.WEBGL,   // or Phaser.CANVAS
```

### Custom pipeline (WebGL only)

```javascript
class GlowPipeline extends Phaser.Renderer.WebGL.Pipelines.PostFXPipeline {
  constructor(game) {
    super({
      game,
      fragShader: `
        precision mediump float;
        uniform sampler2D uMainSampler;
        uniform float uTime;
        varying vec2 outTexCoord;
        void main() {
          vec4 colour = texture2D(uMainSampler, outTexCoord);
          gl_FragColor = colour + vec4(0.1 * sin(uTime), 0.0, 0.0, 0.0);
        }
      `,
    });
  }
}

// Register and apply
this.renderer.pipelines.addPostPipeline('Glow', GlowPipeline);
this.player.setPostPipeline('Glow');
```

---

## Mobile Optimisation

### Target frame rate and pixel ratio

```javascript
// In game config
fps: {
  target: 60,
  forceSetTimeOut: false,   // use RAF, not setTimeout
},
render: {
  pixelArt: false,          // set true for pixel-art games (disables texture smoothing)
  antialias: true,
},

// In create() — cap pixel ratio for performance
this.scale.on('resize', () => {
  const dpr = Math.min(window.devicePixelRatio, 2); // cap at 2× on high-DPI devices
  this.renderer.setPixelRatio(dpr);
});
```

### Reduce update cost on mobile

```javascript
// In update() — early-exit when game is not active
if (!this.sys.isActive()) return;

// Limit physics FPS on low-end devices
physics: {
  arcade: {
    fixedStep: true,        // decouple physics from render rate
    fps: 60,
  }
}
```

### Audio on mobile

**CRITICAL — Mobile browsers require a user gesture before playing audio.** Handle this explicitly:

```javascript
// In create() — unlock audio on first touch
this.input.once('pointerdown', () => {
  if (this.sound.context.state === 'suspended') {
    this.sound.context.resume();
  }
});
```

---
