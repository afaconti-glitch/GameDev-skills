---
name: phaser-best-practices
description: Phaser 3 performance and implementation best-practice reference. Use when writing, reviewing, or optimising a Phaser 3 browser game — covers scene architecture, scene management, physics selection (Arcade vs Matter.js), asset pipeline (texture atlas, audio sprites), input handling, sprite animation, tilemap, object pooling, camera system, ScaleManager, and mobile optimisation.
license: Proprietary
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project Phaser 3 source files and Chrome DevTools Performance captures.
metadata:
  owner: game-delivery
  version: "1.0.0"
  language: "en-GB"
  category: "web-rendering"
  tags:
    - phaser3
    - phaser
    - 2d
    - web-game
    - canvas
    - webgl
    - tilemap
    - physics
    - mobile
---

# Phaser 3 Best Practices

Reference guide for Phaser 3.60+. Rules are grouped by topic. Critical rules are marked **CRITICAL**.

---

## 1. Scene Architecture

### The five lifecycle methods

```javascript
class GameScene extends Phaser.Scene {
  constructor() {
    super({ key: 'GameScene' });
  }

  init(data) {
    // Called first. Receive data passed from previous scene.
    // Initialise instance variables here — NOT in constructor.
    this.level = data.level ?? 1;
  }

  preload() {
    // Load assets. Runs once per scene start.
    this.load.image('player', 'assets/player.png');
    this.load.atlas('sprites', 'assets/sprites.png', 'assets/sprites.json');
  }

  create(data) {
    // Assets are loaded. Build the scene here.
    this.player = this.physics.add.sprite(100, 200, 'player');
  }

  update(time, delta) {
    // Called every frame. Keep this lean — no object creation.
    this.player.setVelocityX(this.cursors.left.isDown ? -160 : 0);
  }

  shutdown() {
    // Called when a scene stops. Clean up event listeners.
    this.input.keyboard.removeAllListeners();
  }
}
```

**CRITICAL — Do not create objects in `update()`.** Creating `new` objects every frame causes GC pauses. Allocate once in `create()` and reuse.

**CRITICAL — Put instance variable initialisation in `init()`, not in the constructor.** The constructor runs once; `init()` runs every time the scene restarts, so state resets correctly.

---

### Boot → Preload → Game scene pattern

Always use a dedicated preload scene for asset loading. Never load game assets inside the Boot scene.

```
Boot (scene key: 'Boot')
  → create: launch 'Preload'

Preload (scene key: 'Preload')
  → preload: load all assets
  → create: show loading bar, then start 'MainMenu' on complete

MainMenu → Game → HUD (overlay) → GameOver
```

```javascript
// Boot.js
create() {
  this.scene.start('Preload');
}

// Preload.js
preload() {
  // Loading bar using load events
  this.load.on('progress', value => {
    this.progressBar.clear();
    this.progressBar.fillRect(240, 270, 320 * value, 30);
  });

  this.load.image('tileset', 'assets/tileset.png');
  this.load.tilemapTiledJSON('level1', 'assets/level1.json');
  // ...
}

create() {
  this.scene.start('MainMenu');
}
```

---

## 2. Scene Management

### Starting, stopping, and sleeping scenes

| Method | Use when |
|---|---|
| `scene.start('Key')` | Fully restart target scene — runs init → preload → create |
| `scene.launch('Key')` | Start scene in parallel (useful for HUD overlays) |
| `scene.sleep('Key')` | Pause rendering and updates but keep state in memory |
| `scene.wake('Key')` | Resume a sleeping scene without re-running create |
| `scene.stop('Key')` | Tear down scene completely, free memory |
| `scene.pause('Key')` | Stop updates but keep rendering |
| `scene.resume('Key')` | Resume updates on a paused scene |

**Prefer `sleep`/`wake` over `stop`/`start` for frequently toggled scenes** (e.g. pause menus). Avoids re-running `preload` and rebuilding the scene graph.

```javascript
// Open pause menu without destroying game scene
this.scene.launch('PauseMenu');
this.scene.sleep('GameScene');

// Close pause menu
this.scene.stop('PauseMenu');
this.scene.wake('GameScene');
```

### Passing data between scenes

```javascript
// Sending data
this.scene.start('GameOver', { score: this.score, level: this.level });

// Receiving data in init()
init(data) {
  this.finalScore = data.score;
  this.level = data.level;
}
```

### Scene event bus

Use `this.events` for inter-scene communication rather than direct scene references.

```javascript
// In GameScene — emit
this.events.emit('playerDied', { lives: this.lives });

// In HUDScene — listen
this.scene.get('GameScene').events.on('playerDied', ({ lives }) => {
  this.livesText.setText(`Lives: ${lives}`);
});
```

---

## 3. Physics

### Arcade Physics vs Matter.js

| Need | Use |
|---|---|
| Platformers, top-down, simple hitboxes | **Arcade** |
| Rotation, complex shapes, joints, constraints | **Matter.js** |
| Many moving bodies (> 100) | **Arcade** (AABB only — far fewer calculations) |
| Simulated destruction, ragdoll, chains | **Matter.js** |

**Arcade is significantly faster.** Default to Arcade unless the design genuinely requires physics features it cannot provide.

### Arcade Physics setup

```javascript
// In Phaser.Game config
physics: {
  default: 'arcade',
  arcade: {
    gravity: { y: 600 },
    debug: false,           // set true during dev to see hitboxes
  }
}

// In create()
this.player = this.physics.add.sprite(100, 450, 'player');
this.player.setBounce(0.1);
this.player.setCollideWorldBounds(true);

// Shrink hitbox to match character sprite (critical for feel)
this.player.body.setSize(20, 32);        // width, height
this.player.body.setOffset(6, 16);       // offset from sprite origin
```

### Collider vs Overlap

```javascript
// Collider — physically blocks movement
this.physics.add.collider(this.player, this.platforms);

// Overlap — detects contact, no physical response
this.physics.add.overlap(
  this.player,
  this.coins,
  this.collectCoin,   // callback
  null,               // process callback (optional filter)
  this                // context
);
```

### Matter.js setup

```javascript
physics: {
  default: 'matter',
  matter: {
    gravity: { y: 1 },
    debug: false,
  }
}

// Compound body for a character (head + body)
this.player = this.matter.add.sprite(100, 200, 'player');
this.player.setBody({
  type: 'rectangle',
  width: 24,
  height: 48,
});
this.player.setFixedRotation(); // prevent unwanted spin
```

---

## 4. Asset Pipeline

### Always use texture atlases

**CRITICAL — Pack individual sprites into a texture atlas.** Loading 50 individual PNG files creates 50 WebGL texture binds per frame. One atlas = one bind.

```bash
# TexturePacker CLI
TexturePacker assets/sprites/ \
  --format phaser3 \
  --data assets/sprites.json \
  --sheet assets/sprites.png \
  --max-size 2048
```

```javascript
// Load atlas
this.load.atlas('game', 'assets/sprites.png', 'assets/sprites.json');

// Use frame from atlas
this.add.image(100, 100, 'game', 'player_idle_01');
this.physics.add.sprite(200, 200, 'game', 'enemy_walk_01');
```

### Audio sprites for SFX

Pack multiple short sound effects into a single audio sprite to reduce HTTP requests and audio engine overhead.

```javascript
this.load.audioSprite('sfx', 'assets/sfx.json', [
  'assets/sfx.ogg',
  'assets/sfx.mp3',  // fallback
]);

// Play a named sprite
this.sound.playAudioSprite('sfx', 'coin_collect');
this.sound.playAudioSprite('sfx', 'player_jump');
```

### LoadingManager pattern

```javascript
preload() {
  // Progress bar
  const bar = this.add.graphics();
  this.load.on('progress', v => {
    bar.clear().fillStyle(0xffffff).fillRect(100, 280, 600 * v, 20);
  });
  this.load.on('complete', () => bar.destroy());

  // Load everything needed for the first playable scene
  this.load.atlas('game', 'assets/game.png', 'assets/game.json');
  this.load.tilemapTiledJSON('level1', 'assets/level1.json');
  this.load.audioSprite('sfx', 'assets/sfx.json', ['assets/sfx.ogg', 'assets/sfx.mp3']);
}
```

---

## 5. Input Handling

### Keyboard

```javascript
// In create()
this.cursors = this.input.keyboard.createCursorKeys();
this.wasd = this.input.keyboard.addKeys({
  up: Phaser.Input.Keyboard.KeyCodes.W,
  down: Phaser.Input.Keyboard.KeyCodes.S,
  left: Phaser.Input.Keyboard.KeyCodes.A,
  right: Phaser.Input.Keyboard.KeyCodes.D,
});

// One-shot key events (preferred over polling for actions)
this.input.keyboard.on('keydown-SPACE', () => {
  this.player.jump();
});

// In update() — polling for held keys
if (this.cursors.left.isDown) {
  this.player.setVelocityX(-160);
}
```

**CRITICAL — Remove keyboard listeners in `shutdown()`.** Listeners on `this.input.keyboard` persist if not removed, causing duplicate callbacks when a scene restarts.

```javascript
shutdown() {
  this.input.keyboard.removeAllListeners();
}
```

### Pointer / touch

```javascript
// Unified pointer (mouse and touch)
this.input.on('pointerdown', pointer => {
  this.shoot(pointer.worldX, pointer.worldY);
});

// Multi-touch
this.input.addPointer(2); // support up to 3 touch points total

// Interactive game objects
this.button.setInteractive();
this.button.on('pointerdown', () => this.scene.start('Game'));
this.button.on('pointerover', () => this.button.setTint(0xaaaaaa));
this.button.on('pointerout', () => this.button.clearTint());
```

### Gamepad

```javascript
// Enable in game config
input: { gamepad: true }

// In update()
const pad = this.input.gamepad.getPad(0);
if (pad) {
  const { x, y } = pad.leftStick;
  this.player.setVelocity(x * 200, y * 200);
  if (pad.A) this.player.jump();
}
```

---

## 6. Sprite Animation

### Defining animations

**CRITICAL — Define animations once in a shared scene or registry, not in every scene that uses them.** Duplicate definitions cause silent overwrites.

```javascript
// In Preload scene or a dedicated AnimationManager helper
create() {
  // Atlas-based animation
  this.anims.create({
    key: 'player_walk',
    frames: this.anims.generateFrameNames('game', {
      prefix: 'player_walk_',
      start: 1,
      end: 8,
      zeroPad: 2,         // player_walk_01 … player_walk_08
    }),
    frameRate: 12,
    repeat: -1,           // -1 = loop forever
  });

  this.anims.create({
    key: 'player_jump',
    frames: this.anims.generateFrameNames('game', {
      prefix: 'player_jump_',
      start: 1,
      end: 4,
    }),
    frameRate: 10,
    repeat: 0,            // play once
  });
}
```

### Playing animations

```javascript
// Play (restarts from frame 0 if already playing)
this.player.play('player_walk');

// Play only if not already playing this animation
this.player.anims.play('player_walk', true);

// Chain: play jump, then return to idle
this.player.play('player_jump');
this.player.once('animationcomplete', () => {
  this.player.play('player_idle');
});
```

### Animation state machine pattern

```javascript
// In update() — drive animations from player state
updateAnimation() {
  const { onFloor } = this.player.body;
  const vx = this.player.body.velocity.x;
  const vy = this.player.body.velocity.y;

  if (!onFloor) {
    this.player.play(vy < 0 ? 'player_jump' : 'player_fall', true);
  } else if (Math.abs(vx) > 10) {
    this.player.play('player_walk', true);
    this.player.setFlipX(vx < 0);
  } else {
    this.player.play('player_idle', true);
  }
}
```

---

## 7. Tilemaps

### Loading a Tiled map

```javascript
// Preload
this.load.tilemapTiledJSON('level1', 'assets/level1.json');
this.load.image('tileset', 'assets/tileset.png');

// Create
const map = this.make.tilemap({ key: 'level1' });
const tiles = map.addTilesetImage('TilesetName', 'tileset'); // name must match Tiled export

const ground = map.createLayer('Ground', tiles, 0, 0);
const platforms = map.createLayer('Platforms', tiles, 0, 0);
const decorations = map.createLayer('Decorations', tiles, 0, 0);

// Enable collision on tiles with collision property set in Tiled
ground.setCollisionByProperty({ collides: true });

// Add player-tilemap collision
this.physics.add.collider(this.player, ground);
```

### Object layers for spawn points

```javascript
const spawns = map.getObjectLayer('Spawns').objects;
spawns.forEach(obj => {
  if (obj.name === 'PlayerStart') {
    this.player.setPosition(obj.x, obj.y);
  }
  if (obj.name === 'Coin') {
    this.coins.create(obj.x, obj.y, 'game', 'coin_01');
  }
});
```

### Culling and large maps

Phaser culls tilemap layers automatically. For very large maps (> 200×200 tiles), manually set the camera bounds to limit tile rendering:

```javascript
this.cameras.main.setBounds(0, 0, map.widthInPixels, map.heightInPixels);
this.physics.world.setBounds(0, 0, map.widthInPixels, map.heightInPixels);
```

---

## 8. Object Pooling

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

## 9. Camera System

### Basic follow and bounds

```javascript
// Follow player with deadzone (camera lags slightly behind)
this.cameras.main.startFollow(this.player, true, 0.08, 0.08);
this.cameras.main.setDeadzone(100, 50);

// Clamp camera to map bounds
this.cameras.main.setBounds(0, 0, map.widthInPixels, map.heightInPixels);
```

### Camera effects

```javascript
// Screen shake on impact
this.cameras.main.shake(150, 0.01);

// Zoom in for dramatic moment
this.cameras.main.zoomTo(1.5, 500, 'Linear', true);

// Fade in at scene start
this.cameras.main.fadeIn(500, 0, 0, 0);

// Fade out before scene change
this.cameras.main.fadeOut(500, 0, 0, 0);
this.cameras.main.once('camerafadeoutcomplete', () => {
  this.scene.start('GameOver', { score: this.score });
});
```

### HUD camera (fixed overlay)

```javascript
// Elements that should not move with the world
this.hudCamera = this.cameras.add(0, 0, this.scale.width, this.scale.height);
this.hudCamera.ignore(this.worldObjects); // world objects ignored by HUD camera
this.cameras.main.ignore(this.hudObjects); // HUD objects ignored by world camera
```

---

## 10. ScaleManager (Responsive Layout)

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

## 11. WebGL vs Canvas Renderer

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

## 12. Mobile Optimisation

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

## Quick-reference checklist

- [ ] Instance variables initialised in `init()`, not constructor
- [ ] No object creation in `update()`
- [ ] All sprites packed into a texture atlas
- [ ] Audio SFX packed into an audio sprite
- [ ] Keyboard and pointer listeners removed in `shutdown()`
- [ ] Animations defined once (not in every scene)
- [ ] Hitboxes adjusted to match visual bounds (`setSize` / `setOffset`)
- [ ] Frequently spawned objects use a pooled `Group`
- [ ] Camera bounds set to map bounds for scrolling levels
- [ ] HUD elements use `setScrollFactor(0)` or a separate camera
- [ ] ScaleManager mode set; positions use `this.scale.width` / `this.scale.height`
- [ ] Audio context unlocked on first user gesture (mobile)
- [ ] Physics choice justified: Arcade for performance, Matter.js only when needed
