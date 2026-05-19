---
name: r3f-best-practices
description: React Three Fiber (R3F) performance and pattern reference. Use when writing, reviewing, or optimising a React Three Fiber application — covers useFrame animation, preventing re-renders, Zustand selectors, Drei helpers, Suspense/loading, visibility toggling, component patterns, physics (Rapier), and post-processing. Adapted from three-agent-skills (MIT).
license: Proprietary
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside React Three Fiber project source files and browser profiler captures.
metadata:
  owner: game-delivery
  version: "1.0.0"
  language: "en-GB"
  category: "web-rendering"
  tags:
    - react-three-fiber
    - r3f
    - drei
    - zustand
    - webgl
    - performance
    - animation
    - suspense
    - rapier
---

# React Three Fiber Best Practices

Reference guide for `@react-three/fiber` v8+. Rules are grouped by impact. Within each category, critical rules are marked **CRITICAL**.

---

## 1. Animation and useFrame

### CRITICAL — Never call setState inside useFrame

**This is the single most common performance killer in R3F.** `useFrame` runs at 60 fps. Calling `setState` inside it triggers 60 React re-renders per second, causing CPU spikes, garbage collection pauses, and frame drops.

```jsx
// BAD — 60 re-renders per second
function BadMesh() {
  const [rotation, setRotation] = useState(0);

  useFrame((state, delta) => {
    setRotation(r => r + delta); // triggers re-render every frame
  });

  return <mesh rotation-y={rotation} />;
}

// GOOD — mutates the Three.js object directly, zero re-renders
function GoodMesh() {
  const meshRef = useRef();

  useFrame((state, delta) => {
    meshRef.current.rotation.y += delta; // direct mutation, no React cycle
  });

  return <mesh ref={meshRef} />;
}
```

### Use delta time for frame-rate-independent animation

**CRITICAL — Always use the `delta` argument. Without it, animations run at different speeds on different devices.**

```jsx
function AnimatedMesh() {
  const meshRef = useRef();

  useFrame(({ clock }, delta) => {
    // GOOD — delta gives frame-rate independence
    meshRef.current.rotation.y += 1.0 * delta;  // 1 radian/second

    // GOOD — elapsedTime for oscillation at fixed frequency
    meshRef.current.position.y = Math.sin(clock.elapsedTime * 2) * 0.5;

    // GOOD — frame-rate-independent lerp
    meshRef.current.position.lerp(
      targetPosition,
      1 - Math.pow(0.001, delta)
    );
  });

  return <mesh ref={meshRef} />;
}
```

### Read global state without subscribing in useFrame

```jsx
function AnimatedByStore() {
  const meshRef = useRef();

  useFrame(() => {
    // getState() does NOT subscribe — no re-renders
    const { targetPosition, speed } = useGameStore.getState();
    meshRef.current.position.lerp(targetPosition, speed);
  });

  return <mesh ref={meshRef} />;
}
```

### Prioritise useFrame calls

```jsx
// Lower priority number = runs first (default is 0)
useFrame(() => { /* physics update */ }, -1);
useFrame(() => { /* camera follows player */ }, 0);
useFrame(() => { /* UI overlay */ }, 1);
```

---

## 2. State Management with Zustand

### CRITICAL — Use selectors, not the whole store

```jsx
// BAD — re-renders on ANY store change
function BadComponent() {
  const store = useGameStore(); // subscribes to the entire store
  return <mesh position-x={store.playerX} />;
}

// GOOD — re-renders only when playerX changes
function GoodComponent() {
  const playerX = useGameStore(state => state.playerX);
  return <mesh position-x={playerX} />;
}
```

### Select multiple values with shallow

```jsx
import { shallow } from 'zustand/shallow';

function PositionComponent() {
  const { x, y, z } = useGameStore(
    state => ({ x: state.x, y: state.y, z: state.z }),
    shallow // prevents re-render if the selected values are reference-equal
  );
  return <mesh position={[x, y, z]} />;
}
```

### Transient subscriptions — subscribe without re-renders

```jsx
function TransientComponent() {
  const meshRef = useRef();

  useEffect(() => {
    const unsubscribe = useGameStore.subscribe(
      state => state.playerPosition,
      position => {
        // Direct mutation — no React re-render
        meshRef.current?.position.copy(position);
      }
    );
    return unsubscribe;
  }, []);

  return <mesh ref={meshRef} />;
}
```

### Zustand selector performance summary

| Method | Re-renders | Use when |
|---|---|---|
| `useStore()` | Every change | Never |
| `useStore(s => s.value)` | When value changes | Standard UI or 3D props |
| `useStore(s => ({...}), shallow)` | When any selected value changes | Multiple values |
| `useStore.subscribe()` | Never | Continuous position/rotation updates |
| `useStore.getState()` | Never | Inside `useFrame` |

---

## 3. Visibility and Mounting

### Toggle visibility instead of remounting for frequently hidden objects

Mounting and unmounting Three.js objects is expensive: it triggers disposal, geometry re-upload, shader recompilation.

```jsx
// BAD for frequent show/hide — disposes and recreates geometry every toggle
function BadToggle({ show }) {
  return show ? <mesh><boxGeometry /><meshStandardMaterial /></mesh> : null;
}

// GOOD — object stays in GPU memory, just skipped in render
function GoodToggle({ show }) {
  const meshRef = useRef();
  useEffect(() => {
    if (meshRef.current) meshRef.current.visible = show;
  }, [show]);
  return <mesh ref={meshRef}><boxGeometry /><meshStandardMaterial /></mesh>;
}

// GOOD — declarative prop
function GoodToggleDeclarative({ show }) {
  return <mesh visible={show}><boxGeometry /><meshStandardMaterial /></mesh>;
}
```

Reserve conditional mounting for objects that are rarely needed and where memory matters more than GPU state (e.g., off-screen zones loaded on demand).

---

## 4. Loading with Drei and Suspense

### Use useGLTF with preloading

```jsx
import { useGLTF } from '@react-three/drei';

function Model() {
  const { scene, nodes, materials } = useGLTF('/assets/character.glb');
  return <primitive object={scene} />;
}

// Preload at module level — starts fetching immediately
useGLTF.preload('/assets/character.glb');
```

### Wrap async components in Suspense

Every component using `useGLTF`, `useTexture`, or other async Drei hooks will suspend. Always provide a Suspense boundary.

```jsx
import { Suspense } from 'react';

function Scene() {
  return (
    <Canvas>
      <Suspense fallback={<LoadingBox />}>
        <Model />
      </Suspense>
    </Canvas>
  );
}

function LoadingBox() {
  const ref = useRef();
  useFrame(({ clock }) => {
    ref.current.rotation.x = clock.elapsedTime;
  });
  return (
    <mesh ref={ref}>
      <icosahedronGeometry args={[0.5, 1]} />
      <meshBasicMaterial wireframe color="cyan" />
    </mesh>
  );
}
```

### Nested Suspense for priority loading

```jsx
function Scene() {
  return (
    <>
      {/* Environment loads first, no blocking fallback */}
      <Suspense fallback={null}>
        <Environment preset="city" />
      </Suspense>

      {/* Main content with visible loader */}
      <Suspense fallback={<Loader />}>
        <Character />
        <Props />
      </Suspense>

      {/* Background loads last */}
      <Suspense fallback={null}>
        <DistantTerrain />
      </Suspense>
    </>
  );
}
```

### useProgress loader UI

```jsx
import { useProgress, Html } from '@react-three/drei';

function Loader() {
  const { progress } = useProgress();
  return (
    <Html center>
      <div style={{ color: 'white', fontFamily: 'monospace' }}>
        {Math.round(progress)}%
      </div>
    </Html>
  );
}
```

### Clone models for multiple instances

```jsx
function Tree({ position }) {
  const { scene } = useGLTF('/assets/tree.glb');
  return <primitive object={scene.clone()} position={position} />;
}
```

---

## 5. Component Patterns

### Separate animated components from UI-driven components

Animation components should avoid React state entirely. UI-driven components (health bars, menus) can use state normally — they are not in the render loop.

```jsx
// Animation — use refs and useFrame only
function PlayerMesh({ playerRef }) {
  useFrame(() => {
    playerRef.current.position.x = useGameStore.getState().playerX;
  });
  return <mesh ref={playerRef}><capsuleGeometry /></mesh>;
}

// UI — can use state freely (not in render loop)
function HealthBar() {
  const health = useGameStore(state => state.health);
  return <div className="health-bar" style={{ width: `${health}%` }} />;
}
```

### Canvas and renderer setup

```jsx
import { Canvas } from '@react-three/fiber';

<Canvas
  shadows
  camera={{ fov: 60, near: 0.1, far: 1000, position: [0, 2, 8] }}
  gl={{
    antialias: false,       // disable when using post-processing
    stencil: false,         // save memory unless needed
    powerPreference: 'high-performance',
  }}
  dpr={[1, 2]}             // clamps pixel ratio to device range
>
  <Scene />
</Canvas>
```

### frameloop control

```jsx
// Only render when state changes — saves GPU on idle UI
<Canvas frameloop="demand">
  <Scene />
</Canvas>

// Trigger render manually when needed
const { invalidate } = useThree();
invalidate();
```

---

## 6. Post-Processing

### Use @react-three/postprocessing (pmndrs)

```jsx
import { EffectComposer, Bloom, ChromaticAberration, FXAA } from '@react-three/postprocessing';
import { BlendFunction } from 'postprocessing';

function PostFX() {
  return (
    <EffectComposer multisampling={0}> {/* disable MSAA — handled by FXAA */}
      <Bloom
        intensity={0.5}
        luminanceThreshold={0.3}
        luminanceSmoothing={0.9}
      />
      <ChromaticAberration
        blendFunction={BlendFunction.NORMAL}
        offset={[0.002, 0.002]}
      />
      <FXAA />  {/* always last */}
    </EffectComposer>
  );
}
```

### Disable antialias on Canvas when using post-processing

```jsx
<Canvas gl={{ antialias: false }}>
  {/* EffectComposer handles AA via FXAA/SMAA */}
</Canvas>
```

---

## 7. Physics with Rapier

```jsx
import { Physics, RigidBody, CuboidCollider } from '@react-three/rapier';

function PhysicsScene() {
  return (
    <Physics gravity={[0, -9.81, 0]}>
      {/* Dynamic body */}
      <RigidBody>
        <mesh>
          <boxGeometry />
          <meshStandardMaterial />
        </mesh>
      </RigidBody>

      {/* Static ground */}
      <RigidBody type="fixed">
        <CuboidCollider args={[50, 0.5, 50]} position={[0, -0.5, 0]} />
      </RigidBody>
    </Physics>
  );
}
```

### Read physics state without re-renders

```jsx
function PhysicsReader() {
  const rigidBodyRef = useRef();

  useFrame(() => {
    const translation = rigidBodyRef.current?.translation();
    if (translation) {
      // Use translation directly — no setState
      meshRef.current.position.set(translation.x, translation.y, translation.z);
    }
  });

  return <RigidBody ref={rigidBodyRef}><mesh ref={meshRef} /></RigidBody>;
}
```

---

## 8. Drei Helpers — Common Patterns

```jsx
import {
  OrbitControls,
  Environment,
  ContactShadows,
  Text,
  Billboard,
  Instances,
  Instance,
} from '@react-three/drei';

// Orbit controls — disable during gameplay
<OrbitControls enablePan={false} enableZoom={false} />

// Environment lighting from HDRI
<Environment preset="sunset" background />

// Cheap contact shadows (baked-style)
<ContactShadows position={[0, 0, 0]} opacity={0.7} scale={10} blur={2} />

// Instanced meshes with JSX syntax
<Instances limit={1000} geometry={geometry} material={material}>
  {positions.map((pos, i) => (
    <Instance key={i} position={pos} />
  ))}
</Instances>
```

---

## Quick-reference checklist

- [ ] No `setState` calls inside `useFrame`
- [ ] `delta` used in all `useFrame` animation calculations
- [ ] Zustand selectors narrow — not subscribing to the whole store
- [ ] `useGLTF.preload()` called at module level for critical models
- [ ] All async components wrapped in `<Suspense>`
- [ ] Frequent show/hide uses `visible` prop, not conditional mounting
- [ ] Canvas `antialias` disabled when using post-processing
- [ ] `frameloop="demand"` used for idle scenes
- [ ] Physics state read via `useFrame` refs, not `useState`
- [ ] Multiple effects in one `<EffectPass>` rather than separate passes
