# GameDev-skills

Reusable Claude Code agent skills implementing a coordinated game-development studio operating system. Engine-agnostic personas and a delivery pipeline tuned for game features, systems, and content — works alongside any engine (Unity, Unreal, Godot, or custom).

The suite contains 20 studio role personas, a delivery pipeline, 2 methodology references (game design + game UI/UX), 14 web rendering reference skills (Three.js/R3F/Phaser + browser constraints), and 4 Blender automation skills — plus a routing brain. Each skill is a self-contained markdown skill (frontmatter + body) following the [Agent Skills](https://agentskills.io/home) format used by Claude Code, OpenAI Codex, and other compatible agents.

## What's in here

```
GameDev-skills/
├── game-team/                        # The 20 studio role personas
│   ├── game-producer.md
│   ├── creative-director.md
│   ├── game-director.md
│   ├── player-researcher.md
│   ├── game-analyst.md
│   ├── game-designer.md
│   ├── level-designer.md
│   ├── narrative-designer.md
│   ├── game-ux-designer.md
│   ├── art-director.md
│   ├── concept-artist.md
│   ├── technical-artist.md
│   ├── gameplay-programmer.md
│   ├── engine-tools-programmer.md
│   ├── graphics-programmer.md
│   ├── web-renderer.md               # Three.js / R3F / WebGL / WebGPU / WebXR
│   ├── security-specialist.md
│   ├── audio-director.md
│   ├── qa-lead.md
│   └── community-manager.md
├── pipeline/                         # Delivery pipeline execution suite
│   ├── run-pipeline.md               # Entry point — classify, confirm, dispatch
│   ├── requirements-generator.md     # Lightweight feature/system intake
│   ├── shape-task.md                 # Decompose brief into vertical slices
│   ├── execute-chunk.md              # Implement one chunk safely
│   ├── close-chunk.md                # Verify chunk closure against feel + acceptance
│   ├── cleanup-verify.md             # Post-pipeline build, perf, and asset sweep
│   └── systematic-debugging.md       # Iron Law 4-phase debugging — root cause before any fix
├── web-rendering/                    # Browser game reference skills (rules + runnable examples)
│   ├── three-js-best-practices.md    # 120+ rules — memory, draw calls, shaders, WebGPU, WebXR, mobile
│   ├── r3f-best-practices.md         # 70+ rules — useFrame, Zustand, Drei, Suspense, physics
│   ├── phaser-best-practices.md      # Phaser 3 — scene lifecycle, physics, atlas, input, animation, tilemap, pooling
│   ├── web-game-browser-constraints.md # Engine-agnostic — tab throttling, iOS audio, fullscreen, save data, SW cache
│   ├── threejs-fundamentals.md       # Scene, cameras, renderer, Object3D, transforms, math utilities
│   ├── threejs-animation.md          # AnimationMixer, skeletal, morph targets, blending, spring physics
│   ├── threejs-shaders.md            # ShaderMaterial, uniforms, 6 GLSL patterns, onBeforeCompile
│   ├── threejs-geometry.md           # BufferGeometry, 15+ shapes, InstancedMesh, merging, point clouds
│   ├── threejs-interaction.md        # Camera controls, raycasting, TransformControls, keyboard/touch
│   ├── threejs-lighting.md           # 6 light types, shadows, HDR/PMREM, 3-point studio, LightProbe
│   ├── threejs-textures.md           # Loading, colour spaces, PBR set, video/canvas, KTX2, disposal
│   ├── threejs-materials.md          # 9 material types, PBR advanced (clearcoat/transmission), toon
│   ├── threejs-postprocessing.md     # EffectComposer, 15+ passes, bloom, SSAO, custom ShaderPass
│   └── threejs-loaders.md            # GLTFLoader+DRACO/KTX2, OBJ/FBX/STL, RGBELoader, async patterns
├── blender/                          # Blender Python automation skills
│   ├── blender-scripting.md          # Foundation — headless execution, bpy API, import/export, batch
│   ├── blender-3d-modeling.md        # Procedural meshes, BMesh, modifiers, curves, terrain
│   ├── blender-render-automation.md  # Cycles/EEVEE config, GPU setup, batch renders, turntables
│   └── blender-compositing.md        # Compositor nodes, colour grading, render passes, EXR output
├── game-design/                      # Game design + UI/UX methodology references
│   ├── game-design-framework.md      # 5-Component Filter, Numbers Policy, State Machine Checklist, playtest templates
│   └── game-ui-ux-framework.md       # UI design-space model, tech landscape, data-driven UI, accessibility standards, competency rubric, learning library
├── routing.md                        # The routing brain (paste into your CLAUDE.md)
└── README.md
```

## Delivery pipeline

Seven skills that work as an integrated execution framework for game features and systems. The entry point is `run-pipeline` — it classifies work by size and routes it through the right phase composition, sharing state via `.claude/cache/pipeline.json`.

| Skill | Use when |
|---|---|
| run-pipeline | Starting any feature, system, content, or tools task — it classifies scope (Small/Medium/Large) and dispatches to the right flow |
| requirements-generator | Turning a rough feature pitch into a confirmation-ready mini-GDD |
| shape-task | Decomposing a confirmed brief into requirements, strategy, and vertical-slice chunks |
| execute-chunk | Implementing one approved chunk safely with inspection, scoped edits, and targeted validation |
| close-chunk | Verifying a completed chunk against acceptance criteria including feel, perf, and build health |
| cleanup-verify | Post-pipeline gate sweep: build runs, no missing references, perf budget, editor opens cleanly |
| systematic-debugging | Iron Law 4-phase methodology (Root Cause → Pattern → Hypothesis → Implementation) — use before writing any fix |

See `routing.md` for the full tier matrix and when to invoke each skill directly.

## Game design & UI/UX methodology

Two structured methodology references that complement the Game Designer and Game UX Designer personas. Use directly when you need a decision framework, not just a persona stance.

| Skill | Use when |
|---|---|
| game-design-framework | Evaluating whether a mechanic earns its place (5-Component Filter); setting balance numbers from first principles (Numbers Policy with floor/target/ceiling); fully specifying a player action before production (State Machine Checklist); writing structured playtest scenarios |
| game-ui-ux-framework | Deciding where a UI element sits relative to the fiction (diegetic / spatial / meta / non-diegetic design-space model, with the "immersion is earned" evidence); choosing a UI technology/paradigm (retained / immediate / MVVM / embedded web; Unity, Unreal, RmlUi, ImGui, Noesis, web, Godot landscape); wiring UI to a source of truth (data-driven architecture); turning accessibility into concrete acceptance criteria (WCAG 2.2, Game Accessibility Guidelines, XAG, APX); localisation/fonts; competency rubric, portfolio gates, and a curated free learning library |

## Web rendering reference skills

Fourteen technical reference skills for browser-based games — two rule-set/best-practice files plus ten topic-focused skills with Quick Start snippets and runnable code examples. Use alongside the Web Renderer persona or directly for specific implementation lookups.

| Skill | Use when |
|---|---|
| three-js-best-practices | Writing, reviewing, or optimising Three.js — memory disposal, draw calls, instancing, glTF loading, shaders (GLSL/TSL), WebGPU, WebXR, mobile |
| r3f-best-practices | Writing, reviewing, or optimising React Three Fiber — useFrame animation, preventing re-renders, Zustand selectors, Drei helpers, Suspense, physics (Rapier) |
| phaser-best-practices | Phaser 3 games — scene lifecycle, physics selection (Arcade vs Matter.js), texture atlas pipeline, audio sprites, input, sprite animation state machines, tilemap, object pooling, camera, ScaleManager, mobile |
| web-game-browser-constraints | Engine-agnostic browser concerns — tab visibility/RAF throttling, iOS audio context unlock, Fullscreen API, Pointer Lock, Screen Wake Lock, localStorage vs IndexedDB, Service Worker caching, memory pressure, Web Workers |
| threejs-fundamentals | Scene/camera/renderer setup, Object3D hierarchy, transforms, Vector3/Quaternion/Matrix4/Color math |
| threejs-animation | AnimationMixer, clip/action API, skeletal bones, morph targets, blending, spring physics, procedural motion |
| threejs-shaders | ShaderMaterial vs RawShaderMaterial, uniform types, Fresnel/dissolve/noise patterns, onBeforeCompile |
| threejs-geometry | BufferGeometry custom creation, 15+ built-ins, InstancedMesh, merging, EdgesGeometry, point clouds |
| threejs-interaction | OrbitControls/PointerLockControls, raycasting (click/hover), TransformControls, keyboard/touch input |
| threejs-lighting | 6 light types, shadow config, HDR env via PMREMGenerator, 3-point studio setup, LightProbe |
| threejs-textures | Texture loading, colour spaces, wrapping/filtering, PBR set (ORM), video/canvas, KTX2 compression |
| threejs-materials | 9 material types, PBR clearcoat/transmission/iridescence/sheen, MeshToonMaterial, transparency |
| threejs-postprocessing | EffectComposer, UnrealBloomPass, SSAOPass, BokehPass, OutlinePass, FXAA/SMAA, custom ShaderPass |
| threejs-loaders | GLTFLoader+DRACO/KTX2, OBJ/FBX/STL/PLY, RGBELoader, LoadingManager, caching, async/Promise |

## Blender 3D pipeline skills

Four Blender Python automation skills for game asset creation, rendering, and compositing. All scripts are headless-compatible and written for Blender 3.0+ / Python 3.10+.

| Skill | Use when |
|---|---|
| blender-scripting | Writing any Blender Python script — headless execution, `bpy` API, import/export, batch processing. Foundation skill — start here |
| blender-3d-modeling | Generating geometry procedurally — `from_pydata`, BMesh operations, modifiers, curves, NURBS, terrain |
| blender-render-automation | Configuring renders from code — Cycles/EEVEE setup, GPU acceleration, camera/lighting rigs, batch renders, turntable animations |
| blender-compositing | Building compositor node graphs — colour grading, render pass combination, glare, depth-of-field, multi-layer EXR output |

## Roles at a glance

### Production and direction

| Role | Use when |
|---|---|
| Game Producer | Scoping, scheduling, dependency tracking, risk, milestone planning, cross-discipline coordination |
| Creative Director | Vision, pillars, tone, holistic creative cohesion, "does this fit the game" calls |
| Game Director | Gameplay vision execution, design ownership, feature trade-offs, the design buck stops here |

### Research, insight, and data

| Role | Use when |
|---|---|
| Player Researcher | Research planning, playtests, interviews, observational studies, surveys, qualitative synthesis, evidence-strength calls |
| Game Analyst | Metric definition, telemetry design, funnel and retention analysis, A/B experiments, balance evidence, dashboards |

### Design

| Role | Use when |
|---|---|
| Game Designer | Mechanics, systems, economy, progression, balance, prototyping, paper design |
| Level Designer | Layout, pacing, encounter design, spatial flow, beats, blockout-to-polish progression |
| Narrative Designer | Story, characters, dialogue, world lore, quests, branching, in-world text |
| Game UX Designer | HUD, menus, onboarding, control schemes, readability, input affordance, game accessibility |

### Art

| Role | Use when |
|---|---|
| Art Director | Visual style, pillars, art bible, cross-discipline visual consistency, art QA |
| Concept Artist | Visual ideation, mood, character/environment/prop concepts, look-dev exploration |
| Technical Artist | Shaders, materials, rigging, pipelines, perf budgets, art-to-engine handoff |

### Engineering

| Role | Use when |
|---|---|
| Gameplay Programmer | Mechanic implementation, AI behaviour, input, character controller, gameplay systems |
| Engine/Tools Programmer | Engine systems, editor tools, build pipeline, automation, platform integration |
| Graphics Programmer | Rendering, shaders, lighting, post-processing, GPU profiling, scalability |
| Web Renderer | Three.js / R3F scene architecture, WebGL/WebGPU performance, draw-call budget, TSL shaders, glTF pipeline, WebXR, cross-device scaling |
| Security Specialist | Threat modelling, anti-cheat / server-authority, save and entitlement integrity, identity / sessions, privacy and regional compliance, platform-cert security, modding-surface, AI safety, incident readiness |

### Audio, quality, and community

| Role | Use when |
|---|---|
| Audio Director | Sound design, music direction, mix, audio implementation patterns, audio pipeline |
| QA Lead | Test planning, regression, bug triage, build certification readiness, repro discipline |
| Community Manager | Player feedback, sentiment, launch readiness from a player perspective, live-service signal |

## Installing into a project

### Option A — Git submodule (recommended)

A submodule pins the consuming project to a specific tag, makes updates deliberate (`git submodule update --remote`), and keeps the role files in one canonical place.

```bash
# Inside the consuming project's repo root

# 1. Add the submodule under .claude/skills-vendor
git submodule add https://github.com/<your-org>/GameDev-skills.git .claude/skills-vendor

# 2. Pin to a stable tag
cd .claude/skills-vendor && git checkout v1.0.0 && cd -
git add .claude/skills-vendor
git commit -m "Pin GameDev-skills to v1.0.0"

# 3. Configure .gitignore so other Claude state stays local-only
#    but the submodule path is allowed through
cat >> .gitignore <<'EOF'

# Claude Code project-local state. The skills suite lives in the
# tracked submodule below; everything else stays local.
.claude/*
!.claude/skills-vendor/
EOF

# 4. In CLAUDE.md, paste the contents of routing.md and update the
#    skill paths to point at the vendor directory:
#    .claude/skills/<role>.md  →  .claude/skills-vendor/game-team/<role>.md
```

Cloning the consuming project later: `git clone --recurse-submodules <url>` (or `git submodule update --init` after a normal clone).

Updating to a new release of this suite: `cd .claude/skills-vendor && git fetch && git checkout v1.0.0 && cd - && git commit -am "Bump GameDev-skills to v1.0.0"`.

### Option B — Copy (simpler, no upstream tracking)

```bash
git clone https://github.com/<your-org>/GameDev-skills.git /tmp/GameDev-skills
mkdir -p .claude/skills/pipeline
cp /tmp/GameDev-skills/game-team/*.md .claude/skills/
cp /tmp/GameDev-skills/pipeline/*.md .claude/skills/pipeline/
echo '.claude/' >> .gitignore
```

Updates require re-copying. Use this when the project will diverge from the canonical suite.

## Wiring into the consuming project's CLAUDE.md

Copy the contents of [routing.md](./routing.md) into the consuming project's `CLAUDE.md` under a heading like `# Game delivery operating system`.

If you used **Option A**, find-and-replace `.claude/skills/` → `.claude/skills-vendor/game-team/` in the pasted routing block so the paths point at the submodule.

If you used **Option B**, the routing paths already match (`.claude/skills/<role>.md`).

Project-specific context (engine, target platforms, tech budgets, content pipeline, working behaviour) goes **above** the routing brain in `CLAUDE.md`. The routing brain itself stays generic.

## Conventions

- All role files use **UK English** spelling.
- Frontmatter follows the Agent Skills schema: `name`, `description`, `license`, `compatibility`, `metadata` (with `version`, `language`, `persona_type`, `tags`, `intents`, `output_types`).
- Each role file ends with a `## Maintenance` section listing when to review it. Treat that as a versioning trigger — bump the role's `version` whenever you change behaviour-shaping content.
- Role files are engine-agnostic by default. Engine specifics (Unity / Unreal / Godot / custom) belong in the consuming project's CLAUDE.md, not in role files.
- Role files are stable surface area: changes that alter how the role responds should be deliberate and documented in commit messages.

## Versioning

This repo uses semver. Tag releases as `v<MAJOR>.<MINOR>.<PATCH>` on `main`.

- **MAJOR** — breaking change to a role's contract (e.g. a renamed intent that consuming routing depends on, or a removed role).
- **MINOR** — new role added, new intent on an existing role, new output type.
- **PATCH** — wording tweaks, clarifications, regression-prompt additions, frontmatter fixes.

Consuming projects should pin to a specific tag and update deliberately.

## Licence

Proprietary. Internal use only. See [LICENSE](./LICENSE).

## Contributing (internal)

- Follow the existing role file structure when adding a new role.
- Update [routing.md](./routing.md) when adding a role: new row in the relevant table, new squad memberships if the role is cross-functional, new entry in the specialist-routing examples.
- Bump the version in the role file's frontmatter on behaviour-shaping changes.
- Tag a new release after merge to `main`.
