# Post-processing

Split out of [`three-js-best-practices`](../SKILL.md) to keep that file inside the 500-line convention.

**Read this when** adding bloom, depth of field, ambient occlusion, outlines or any screen-space effect.

## Post-Processing

### Use pmndrs/postprocessing over Three.js EffectComposer

The `postprocessing` npm package is more performant than Three.js's built-in `EffectComposer` for multi-pass pipelines.

```javascript
import { EffectComposer, RenderPass, BloomEffect, EffectPass } from 'postprocessing';

const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
composer.addPass(new EffectPass(camera, new BloomEffect({ intensity: 1.5 })));
```

### Merge effects into one pass

```javascript
// BAD — two EffectPasses = two full-screen draws
composer.addPass(new EffectPass(camera, new BloomEffect()));
composer.addPass(new EffectPass(camera, new ChromaticAberrationEffect()));

// GOOD — one EffectPass with multiple effects
composer.addPass(new EffectPass(camera, new BloomEffect(), new ChromaticAberrationEffect()));
```

### Render at reduced resolution for mobile

```javascript
const composer = new EffectComposer(renderer, {
  frameBufferType: THREE.HalfFloatType,
  multisampling: 0, // disable MSAA when using post-processing
});
composer.setSize(window.innerWidth * 0.75, window.innerHeight * 0.75);
```

### Pass order

1. `RenderPass` — scene render
2. Depth-dependent effects (SSAO, depth-of-field)
3. Colour effects (bloom, colour grading)
4. FXAA / SMAA (antialiasing last)
5. Tone mapping last before output

---
