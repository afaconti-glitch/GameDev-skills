---
name: phaser-best-practices
description: Phaser 3 performance and implementation best-practice reference. Use when writing, reviewing, or optimising a Phaser 3 browser game — covers scene architecture, scene management, physics selection (Arcade vs Matter.js), asset pipeline (texture atlas, audio sprites), input handling, sprite animation, tilemap, object pooling, camera system, ScaleManager, and mobile optimisation.
license: MIT
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project Phaser 3 source files and Chrome DevTools Performance captures.
disable-model-invocation: true
metadata:
  owner: game-delivery
  version: "2.0.0"
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
  intents:
    - scene-architecture
    - physics-selection
    - atlas-pipeline
    - input-handling
    - animation-state-machine
    - tilemap-setup
    - object-pooling
    - mobile-scaling
  output_types:
    - code-example
    - architecture-recommendation
    - review-findings
    - configuration-snippet
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


## Further reference

Detail split out of this file. Each is self-contained; read one only when its trigger applies.

- [`references/tilemaps-and-camera.md`](./references/tilemaps-and-camera.md) — Tilemaps and the camera system. Read when building tile-based levels, or configuring a following, bounded or multi-viewport camera.
- [`references/performance-and-display.md`](./references/performance-and-display.md) — Performance and display targets. Read when setting up responsive layout, choosing between WebGL and Canvas, tuning for mobile, or pooling frequently spawned objects.

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
