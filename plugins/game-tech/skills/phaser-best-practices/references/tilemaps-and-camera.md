# Tilemaps and the camera system

Split out of [`phaser-best-practices`](../SKILL.md) to keep that file inside the 500-line convention.

**Read this when** building tile-based levels, or configuring a following, bounded or multi-viewport camera.

## Tilemaps

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

## Camera System

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
