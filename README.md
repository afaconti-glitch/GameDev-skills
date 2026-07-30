# game-dev-skills

A game studio as **47 Agent Skills**, in two installable plugins — 20 studio roles, a 7-skill delivery
pipeline, 2 design methodology frameworks, 14 browser-rendering references and 4 Blender automation
skills — with a routing brain that decides which one a request belongs to.

Invoke a role when you want a specific discipline's judgement: a mechanic spec, an encounter pass, an
art-bible call, a HUD readability review, a threat model, a cert-readiness decision. Run the pipeline
when a task should be classified, chunked and verified rather than just done.

Every skill is engine-agnostic, so the same suite works on a Unity, Unreal, Godot, Bevy or browser
project without dragging another project's context along.

## Quick start

**Claude Code (terminal):**

```
/plugin marketplace add afovea/game-dev-skills
/plugin install game-team@gamedev-skills
```

**Claude Desktop** — `/plugin` is terminal-only, so use the CLI:

```bash
claude plugin marketplace add afovea/game-dev-skills
claude plugin install game-team@gamedev-skills
```

Building for the browser, or generating assets in Blender? Add the companion plugin:

```bash
claude plugin install game-tech@gamedev-skills
```

Restart your session. The skills appear in **Settings → Skills** and become invocable by name.

```
/game-designer Our dodge has no commitment. Add a parry window without making it strictly better.
```

## Two plugins, one marketplace

| Plugin | Skills | Install it when |
|---|---|---|
| **`game-team`** | 29 — 20 roles, 7 pipeline, 2 frameworks | Always. This is the studio |
| **`game-tech`** | 18 — 14 browser rendering, 4 Blender | The game runs in a browser, or you script Blender |

They are split because always-on metadata is charged in **every** session, including projects with
nothing to do with games. A Unity team has no use for fourteen Three.js skills and should not pay for
them. See [Cost](#cost) for the numbers.

## Invoking a skill

Type `/` then the skill name, **and give it the task in the same message.** Invoking bare loads the
persona with no brief, and it will just ask you what you want.

```
/level-designer This corridor reads as a dead end. Players stop and backtrack.
/technical-artist Our foliage shader costs 4ms on Switch. Where does that go?
/security-specialist Players are editing the save file to unlock cosmetics. Options?
/run-pipeline Add a stamina cost to sprinting, surfaced on the HUD.
```

Two forms both work:

| Form | Use when |
|---|---|
| `/game-designer` | Normal use — shortest form |
| `/game-team:game-designer` | Unambiguous. Needed only if a personal or project skill shares the name |

### They do not fire on their own

Every skill sets `disable-model-invocation: true`. Describing a balance problem in prose will **not**
auto-summon `/game-designer`. That is deliberate: automatic invocation selects by description
keyword-matching, and keyword-matching routes game work particularly badly — "performance" pulls four
plausible roles, "shader" pulls three, and "balance" pulls the designer when the honest answer is that
nobody has the evidence yet.

You get selection two ways instead:

- **Explicitly**, with `/name` — when you know which discipline you want.
- **Via the routing brain**, by asking in plain prose — when you don't. See
  [The routing brain](#the-routing-brain-optional-second-layer).

### Once invoked, a skill stays loaded

The persona persists across turns for the rest of the conversation. Invoke a different one to switch;
start a fresh session to drop it.

## The 47 skills

### `game-team` — production and direction

| Invoke | Use when |
|---|---|
| `/game-producer` | Scoping, scheduling, dependency tracking, risk, milestones, cross-discipline coordination |
| `/creative-director` | Vision, pillars, tone, creative cohesion, "does this fit the game" calls |
| `/game-director` | Gameplay vision execution, design ownership, feature trade-offs, design arbitration |

### `game-team` — research, insight and data

| Invoke | Use when |
|---|---|
| `/player-researcher` | Research planning, playtests, interviews, observational studies, surveys, qualitative synthesis, evidence-strength calls |
| `/game-analyst` | Metric definition, telemetry design, funnel and retention analysis, A/B experiments, balance evidence, dashboards |

### `game-team` — design

| Invoke | Use when |
|---|---|
| `/game-designer` | Mechanics, systems, economy, progression, balance, prototyping, paper design |
| `/level-designer` | Layout, pacing, encounter design, spatial flow, beats, blockout-to-polish |
| `/narrative-designer` | Story, characters, dialogue, world lore, quests, branching, in-world text |
| `/game-ux-designer` | HUD, menus, onboarding, control schemes, readability, input affordance, UI architecture and data flow, diegesis, localisation, UI performance, world-space/XR UI, game accessibility |

### `game-team` — art

| Invoke | Use when |
|---|---|
| `/art-director` | Visual style, pillars, art bible, cross-discipline visual consistency, art QA |
| `/concept-artist` | Visual ideation, mood, character/environment/prop concepts, look-dev |
| `/technical-artist` | Shaders, materials, rigging, pipelines, perf budgets, art-to-engine handoff |

### `game-team` — engineering

| Invoke | Use when |
|---|---|
| `/gameplay-programmer` | Mechanic implementation, AI behaviour, input, character controller, gameplay systems |
| `/engine-tools-programmer` | Engine systems, editor tools, build pipeline, automation, platform integration |
| `/graphics-programmer` | Rendering, shaders, lighting, post-processing, GPU profiling, scalability |
| `/web-renderer` | Three.js / R3F scene architecture, WebGL/WebGPU performance, draw-call budget, TSL shaders, glTF pipeline, WebXR, cross-device scaling |
| `/security-specialist` | Threat modelling, anti-cheat and server authority, save and entitlement integrity, identity, privacy, platform-cert security, modding surface, AI safety, incident readiness |

### `game-team` — audio, quality and community

| Invoke | Use when |
|---|---|
| `/audio-director` | Sound design, music direction, mix, audio implementation patterns, audio pipeline |
| `/qa-lead` | Test planning, regression, bug triage, build certification readiness, repro discipline |
| `/community-manager` | Player feedback, sentiment, launch readiness from a player perspective, live-service signal |

### `game-team` — delivery pipeline

| Invoke | Use when |
|---|---|
| `/run-pipeline` | **Start here for any build task.** Classifies Small / Medium / Large and dispatches |
| `/requirements-generator` | Turning a rough feature pitch into a confirmation-ready mini-GDD |
| `/shape-task` | Decomposing a brief into requirements, strategy and vertical-slice chunks |
| `/execute-chunk` | Implementing one approved chunk with scoped edits and targeted validation |
| `/close-chunk` | Verifying a chunk against its acceptance criteria, including feel and perf |
| `/cleanup-verify` | Post-run sweep: regenerate artefacts, rebuild, run the gate chain, check the perf budget, report drift |
| `/diagnose` | Iron Law debugging — root cause → pattern → hypothesis → fix. Use before writing any fix |

### `game-team` — methodology frameworks

| Invoke | Use when |
|---|---|
| `/game-design-framework` | Deciding whether a mechanic earns its place (5-Component Filter); setting balance numbers from first principles (Numbers Policy, floor/target/ceiling); fully specifying a player action before production (State Machine Checklist); writing structured playtest scenarios |
| `/game-ui-ux-framework` | Placing UI relative to the fiction (diegetic / spatial / meta / non-diegetic, with the "immersion is earned" evidence); choosing a UI technology; wiring UI to a source of truth; turning accessibility into acceptance criteria (WCAG 2.2, Game Accessibility Guidelines, XAG, APX); localisation and fonts; a competency rubric and learning library |

### `game-tech` — browser rendering

| Invoke | Use when |
|---|---|
| `/three-js-best-practices` | Writing, reviewing or optimising Three.js — memory disposal, draw calls, instancing, glTF, shaders (GLSL and TSL), WebGPU, WebXR, mobile |
| `/r3f-best-practices` | React Three Fiber — useFrame, preventing re-renders, Zustand selectors, Drei, Suspense, Rapier physics |
| `/phaser-best-practices` | Phaser 3 — scene lifecycle, Arcade vs Matter.js, texture atlases, audio sprites, input, animation state machines, tilemaps, pooling, ScaleManager |
| `/web-game-browser-constraints` | Engine-agnostic browser reality — tab throttling, iOS audio unlock, Fullscreen, Pointer Lock, Wake Lock, localStorage vs IndexedDB, Service Worker caching, memory pressure, Web Workers |
| `/threejs-fundamentals` | Scene, cameras, renderer, Object3D hierarchy, transforms, Vector3/Quaternion/Matrix4 maths |
| `/threejs-animation` | AnimationMixer, clips and actions, skeletal bones, morph targets, blending, spring physics |
| `/threejs-shaders` | ShaderMaterial vs RawShaderMaterial, uniform types, Fresnel/dissolve/noise patterns, onBeforeCompile |
| `/threejs-geometry` | BufferGeometry, 15+ built-ins, InstancedMesh, merging, EdgesGeometry, point clouds |
| `/threejs-interaction` | Camera controls, raycasting for click and hover, TransformControls, keyboard and touch input |
| `/threejs-lighting` | 6 light types, shadow config, HDR environments via PMREM, 3-point studio, LightProbe |
| `/threejs-textures` | Loading, colour spaces, wrapping and filtering, PBR sets, video and canvas textures, KTX2, disposal |
| `/threejs-materials` | 9 material types, PBR clearcoat/transmission/iridescence/sheen, toon, transparency |
| `/threejs-postprocessing` | EffectComposer, bloom, SSAO, depth of field, outlines, FXAA/SMAA, custom ShaderPass |
| `/threejs-loaders` | GLTFLoader with DRACO/KTX2, OBJ/FBX/STL, RGBELoader, LoadingManager, async patterns |

### `game-tech` — Blender automation

| Invoke | Use when |
|---|---|
| `/blender-scripting` | Any Blender Python script — headless execution, `bpy`, import/export, batch processing. **Start here**; the other three build on it |
| `/blender-3d-modeling` | Procedural geometry — `from_pydata`, BMesh, modifiers, curves, NURBS, terrain |
| `/blender-render-automation` | Renders from code — Cycles/EEVEE, GPU setup, camera and lighting rigs, batch renders, turntables |
| `/blender-compositing` | Compositor node graphs — colour grading, render passes, glare, depth of field, multi-layer EXR |

All Blender skills target Blender 3.0+ with Python 3.10+ and are headless-compatible.

## Install options

| Route | Command | You get |
|---|---|---|
| **Plugin** *(recommended)* | `claude plugin install game-team@gamedev-skills` | Skills visible in Settings → Skills, updatable with one command. Skills only |
| **Per project** | `install.sh /path/to/project` | Skills in `<project>/.claude/skills/` **plus** the routing brain in its `CLAUDE.md` and a seeded pipeline adapter |
| **Personal** | `install.sh --personal` | Skills in `~/.claude/skills/` — every project. Skills only |
| **Submodule** | `install.sh --submodule /path/to/project` | Per-project, pinned to a tag, symlinked so discovery still works |

The script is in the repo, so clone first for those routes:

```bash
git clone https://github.com/afovea/game-dev-skills.git
./game-dev-skills/install.sh /path/to/your-project
```

It copies the skills, appends the routing brain to `CLAUDE.md` **with the paths already rewritten**,
updates `.gitignore`, and seeds a pipeline adapter template. Re-running updates the routing block in
place between its markers and leaves anything you wrote above it alone.

Add `--team-only` or `--tech-only` to install one plugin instead of both.

### Which route

- **Just want the skills, everywhere, visible?** Plugin.
- **Want role arbitration too?** Plugin *plus* a per-project install — they stack. Only the per-project
  route can add `routing.md`, because `CLAUDE.md` is a per-project file.
- **Want it pinned and tracked in the consuming repo?** Submodule.

**The repo is the source, not an installation.** Cloning it makes the skills visible nowhere. Claude
Code discovers them at `~/.claude/skills/<name>/SKILL.md` or
`<project>/.claude/skills/<name>/SKILL.md`; the Skills panel lists only plugin-provided skills. Pick a
route above, or you will not see them.

### Precedence and duplicates

Enterprise overrides personal, personal overrides project, and any of them overrides a plugin skill of
the same name. So a personal install **shadows the plugin silently** — both work, but you are running
the copy you probably did not mean to update. Pick one route per machine.

### Cost

Plugin metadata is loaded in every session, including projects with nothing to do with games. These are
the figures Claude Code reports for v2.0.0, not estimates:

| Plugin | Skills | Always-on | Heaviest single skill on invoke |
|---|---|---|---|
| `game-team` | 29 | ~2,465 tokens | `game-ui-ux-framework`, ~5.3k |
| `game-tech` | 18 | ~1,866 tokens | `blender-render-automation`, ~3.7k |
| Both | 47 | ~4,331 tokens | |

Check your own install with `claude plugin details game-team`. If the cost is unwelcome:

```bash
claude plugin disable game-tech           # off, still installed
claude plugin install ... --scope project # confine it to one repo
```

Installing only `game-team` on non-browser projects is the main reason the suite ships as two plugins.

### Compatibility

The skills are plain markdown following the [Agent Skills](https://agentskills.io) standard, so they
work with any host that reads `SKILL.md`. The plugin route, `/name` invocation and the `claude plugin`
CLI are Claude Code features. The routing brain is a `CLAUDE.md` convention and needs a host that reads
that file.

### Migrating

**From `afovea/GameDev-skills`.** The repository is now `afovea/game-dev-skills`. GitHub redirects
automatically, but update your remote and marketplace reference when convenient.

**From the v1.x layout.** v1 shipped loose markdown files (`game-team/game-designer.md`) with the
pipeline nested under `skills/pipeline/`. v2 gives every skill its own directory. An old filesystem
install leaves both behind, and the skills end up present twice:

```bash
rm -f ~/.claude/skills/*.md              # personal installs
rm -r ~/.claude/skills/pipeline
rm -f <project>/.claude/skills/*.md      # project installs
rm -r <project>/.claude/skills/pipeline
```

`install.sh` detects this and prints the exact commands rather than deleting anything itself.

One skill was renamed: **`systematic-debugging` is now `diagnose`**, matching the sibling
[product-team-skills](https://github.com/afovea/product-team-skills) suite so `/diagnose` means the same
thing in both. The Iron Law methodology is unchanged.

## The routing brain (optional second layer)

[`routing.md`](./routing.md) goes in a project's `CLAUDE.md` and decides which role or squad a request
belongs to, so you can ask in prose instead of picking a skill:

> "The jump feels floaty at the apex." → Game Designer
> "Players can't tell which door is unlocked." → Game UX Designer
> "Fix the typo in the tutorial bark." → no specialist; it is a mechanical edit

It also defines **six squads** for cross-functional work — Concept, Pre-production, Production,
Polish & Cert, Live & Community, Tech Foundation — because "is this ready to ship?" is not one
discipline's call.

Two rules do the heavy lifting, and are worth reading before you edit it:

- **Route on the decision, not on a noun.** A collision table covers the words that reliably drag a
  request to the wrong role: *performance*, *balance*, *feel*, *shader*, *UI*, *story*, *risk*, *level*,
  and "players are complaining". A build-versus-buy question about audio middleware is a pipeline
  decision that happens to mention audio.
- **Trivial work needs no specialist.** Typo fixes, renames and placeholder swaps go straight to
  implementation. That is a floor on role selection, not on care — the pipeline's bump-up rules still
  apply if the change touches a risky path.

There is also a **Working with engines, middleware and assets** section, which exists because its
failures are silent: writing against the wrong engine major, missing a font or middleware licence that
changes at ship, or losing track of who maintains a copied-in asset.

## Delivery pipeline

`/run-pipeline` is the entry point. It classifies scope, surfaces a plan for confirmation, then
dispatches — Small runs a single scoped change, Medium adds requirements/shaping and a chunk loop,
Large adds repository inspection and an architect plan.

Two documents make it portable:

| Document | Purpose |
|---|---|
| [`project-adapter.md`](./plugins/game-team/reference/project-adapter.md) | Your project's engine and version, build/test/cook commands, gate chain, derived artefacts, perf budget, risky paths, host integrations. Copy to `.claude/pipeline-adapter.md` and fill in |
| [`state-schema.md`](./plugins/game-team/reference/state-schema.md) | The shared state contract, and how skills degrade when state is unavailable |

**It runs without an adapter.** Skills fall back to discovering the engine from its project files
(`ProjectVersion.txt`, `*.uproject`, `project.godot`, `Cargo.toml`, a lockfile) and the gates from CI
config, and state what they found. Writing the adapter makes it deterministic and lets you declare what
discovery cannot infer — which gates may fail, which paths are risky, what "within budget" means, and
which commands need hardware or a licence server this session does not have.

The gate chain is game-shaped rather than web-app-shaped: missing-reference validation over scenes and
prefabs, shader compile checks, save-format compatibility against canonical saves, a cook or packager
dry run, localisation completeness, and platform-cert lint. Derived artefacts include baked lighting,
nav meshes, atlases and content manifests — which is why `cleanup-verify` reports binary drift and
refuses to commit it rather than silently regenerating.

Nothing assumes a particular engine, a JavaScript toolchain, or a writable cache.

## Repository layout

```
game-dev-skills/
├── .claude-plugin/
│   └── marketplace.json              # makes the repo an addable marketplace
├── plugins/
│   ├── game-team/                    # 29 skills — the studio
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/<name>/SKILL.md    # 20 roles + 7 pipeline + 2 frameworks, flat
│   │   └── reference/                # shared pipeline docs, deliberately not skills
│   │       ├── project-adapter.md
│   │       └── state-schema.md
│   └── game-tech/                    # 18 skills — the technical library
│       ├── .claude-plugin/plugin.json
│       └── skills/<name>/SKILL.md    # 14 web rendering + 4 Blender, flat
├── routing.md                        # the routing brain
├── install.sh
├── NOTICE.md                         # upstream attributions
└── README.md
```

`reference/` holds documents the pipeline skills share. They are not skills, so they sit outside
`skills/` rather than being forced into a directory that pretends otherwise.

## Conventions

- All skills use **UK English**.
- Frontmatter carries `name` and `description` (the two fields the standard requires) plus `license`,
  `compatibility`, `disable-model-invocation`, and a `metadata` block with `version`, `language`,
  `persona_type` or `category`, `tags`, `intents` and `output_types`. Everything past the first two is
  this repo's own convention; hosts ignore what they do not recognise.
- Keep skill bodies **under 500 lines**, per
  [Anthropic's authoring guidance](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).
  Past that, move detail into that skill's `references/` and link to it with a stated trigger for when
  to read it — as `three-js-best-practices` and `phaser-best-practices` do. Four skills currently sit
  just over the line (`blender-compositing` 524, `threejs-interaction` 509, `blender-render-automation`
  508, `r3f-best-practices` 504); splitting those would cost more in indirection than it saves.
- Skills are **engine-agnostic**. Engine specifics (Unity / Unreal / Godot / custom) belong in the
  consuming project's `CLAUDE.md` and pipeline adapter, not in a skill.
- Cross-plugin references use `/skill-name`, never a relative path — a `game-team` skill cannot assume
  `game-tech` is installed. Within a plugin, relative markdown links are fine.
- Every skill ends with `## Maintenance` listing its review triggers. Treat that as a versioning
  prompt: bump the skill's `version` whenever behaviour-shaping content changes.

## Versioning

Semver, tagged `v<MAJOR>.<MINOR>.<PATCH>` on `main`.

- **MAJOR** — breaking change to a skill's contract or to installed paths.
- **MINOR** — new skill, new intent, new output type.
- **PATCH** — wording, clarifications, frontmatter fixes.

`version` is declared in each plugin's `plugin.json` and nowhere else. Claude Code pins a plugin to that
string, so pushing commits without bumping it leaves existing users on the cached copy.

Consuming projects should pin to a tag and update deliberately.

## Attribution

Thirteen skills are adapted from MIT-licensed upstreams — [obra/superpowers](https://github.com/obra/superpowers),
[CloudAI-X/threejs-skills](https://github.com/CloudAI-X/threejs-skills) and
[emalorenzo/three-agent-skills](https://github.com/emalorenzo/three-agent-skills). See
[NOTICE.md](./NOTICE.md) for what came from where.

## Licence

[MIT](./LICENSE). Use it, fork it, adapt it. Attribution appreciated but the licence only requires the
copyright notice.

## Contributing

Issues and pull requests welcome.

- Follow the existing skill structure when adding one, and put it in the right plugin: judgement and
  process go in `game-team`, technology references go in `game-tech`.
- Update [routing.md](./routing.md): a row in the relevant table, squad memberships if cross-functional,
  and an entry in the specialist-routing examples. **The table matters more than the prose** — when a
  request routes wrongly, fix the table wording first.
- Bump the plugin's `plugin.json` version and the skill's frontmatter `version` on behaviour-shaping
  changes.
- Run `claude plugin validate .` and `claude plugin validate ./plugins/<name>` before opening the PR.
- Tag a release after merge to `main`.
