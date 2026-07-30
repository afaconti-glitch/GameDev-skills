# Project adapter

The pipeline skills are engine-agnostic. Everything specific to *your* project — engine and version,
build and test commands, content pipeline, perf budget, risky paths, host integrations — is declared
here.

**A consuming project copies this file to `.claude/pipeline-adapter.md` and fills it in.** Pipeline
skills read it at the start of a run.

## If there is no adapter

The pipeline still runs. Skills fall back to **discovery**, in this order:

1. Repository instructions — `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `README.md`.
2. Project files that identify the engine — `ProjectSettings/ProjectVersion.txt` (Unity),
   `*.uproject` (Unreal), `project.godot` (Godot), `package.json` + a renderer dependency (web),
   `Cargo.toml` with `bevy` (Rust), a `Makefile` or `CMakeLists.txt` (custom).
3. CI configuration — `.github/workflows/*` or the equivalent. What CI runs on a pull request is the
   best available definition of "the gates".
4. Lockfile, for web projects, to pick the package manager: `pnpm-lock.yaml` → pnpm, `yarn.lock` →
   yarn, `package-lock.json` → npm, `bun.lockb` → bun.

State what was discovered and where it came from before running anything destructive. If no build or
gate chain can be discovered, say so and ask — do not invent commands, and do not assume an engine.

Discovery is a fallback, not a substitute. Game projects punish it harder than most: content cooking,
lightmap baking and platform packaging are slow, destructive, and rarely inferable from a manifest.
Writing the adapter is faster, deterministic, and records intent discovery cannot infer — which gates
are allowed to fail, which paths are risky, what "within budget" means.

---

## Template

Copy from here down.

### `project`

- **engine** — Unity / Unreal / Godot / Bevy / custom / web (Three.js, R3F, Phaser)
- **version** — the exact version. Engine APIs move between minors; a skill writing against the wrong
  one produces code that compiles and misbehaves.
- **language** — C#, C++, GDScript, Rust, TypeScript
- **platforms** — every target in scope, with the **lowest** one marked. Perf budgets are set by the
  lowest target, not the development machine.
- **liveService** — whether the game is shipped and running. If it is, save compatibility and
  server-contract changes are never Small.

### `commands`

The gate chain, in the order it should run. Omit any that do not apply.

| Key | Command | Notes |
|---|---|---|
| `build.editor` | | Compile gameplay code / scripts as the editor does |
| `build.standalone` | | A playable target used for verification |
| `test` | | Full automated suite |
| `test.affected` | | Narrow run for per-chunk validation; falls back to `test` if absent |
| `lint` | | Code and/or asset linting. Should accept a scope argument if possible |
| `cook` | | Content cook / package, at least a dry run for one platform |
| `smoke` | | Load a scene, tick N frames, assert no errors |
| `benchmark` | | Perf capture. State what hardware it needs |

If `lint` or `test` can be scoped to changed files, say how (`<test> --filter <path>`). Per-chunk
validation uses the scoped form; the final sweep uses the full form.

If a command needs a GUI, licence server, console SDK or target hardware that is not available in the
session, **say so here**. A skill that cannot run a gate must report it as not-run, never as passed.

### `gates.chain`

Ordered list of every gate that must pass for a `scope: "full"` stamp. Each entry:

- **name** — short label used in reports
- **command**
- **blocking** — `true`, or `false` for a gate that is expected to fail
- **baseline** — for non-blocking gates, the currently accepted failure count, and how to read it from
  the output

A gate with `blocking: false` and a baseline is a *ratchet*: the run fails if the count gets worse,
passes if it stays the same or improves. Record the baseline here so a regression is detectable.
**A `scope: "full"` stamp requires every blocking gate to pass and every ratchet to be no worse than
baseline** — never stamp `full` while ignoring a worsened ratchet.

Gates common in game projects, beyond compile and test:

- missing-reference validator over scenes / prefabs / blueprints / scriptable data
- shader and material compile check
- save-format compatibility — canonical saves from the shipped version still load
- network / replication contract check
- content-pipeline cook or packager dry run for at least one platform
- localisation completeness
- platform-cert lint (TRC / TCR / Lotcheck-style checks the project automates)

### `artefacts`

Derived files that must stay in sync with their source. For each:

- **source** — glob
- **generated** — path or glob
- **regenerate** — command
- **driftCheck** — command that fails when the generated output is stale
- **compare** — `structural` for JSON/YAML compared after parse, `bytes` otherwise

In game projects this category is larger than in application code: baked lighting, nav meshes,
occlusion data, sprite and font atlases, content manifests and asset registries, generated code from
data assets, localisation tables.

Never silently overwrite a derived artefact that drifts. Regenerate, report the diff, and let the
caller decide. Binary bakes in particular are expensive to review after the fact.

### `perf.budget`

The numbers `close-chunk` and `cleanup-verify` check against. Per platform tier where they differ.

- **frameBudgetMs** — target frame time on the lowest target (16.6 at 60fps, 33.3 at 30fps)
- **memory** — heap and/or VRAM ceiling
- **drawCalls** — ceiling per frame
- **loadTimeSeconds** — cold start and level transition
- **benchmarkScene** — the scene or capture procedure that produces these numbers

If there is no benchmark, say so. Skills then record "no benchmark available — perf delta not
measured" rather than guessing.

### `paths.risk`

Globs that raise the tier when touched. The pipeline ships these defaults; extend rather than replace:

- save-game format, serialisation and migration code
- netcode, replication and server-authority logic
- build configuration, packaging and platform settings
- entitlement, DLC, store and IAP code
- anti-cheat surface
- input binding and remap tables
- engine plugins, native modules and third-party middleware integration
- CI configuration and anything under a hooks directory

Add your own — the tuning tables designers depend on, the content manifest, anything whose breakage is
expensive or hard to detect in a build.

### `state`

- **directory** — where pipeline state lives. Default `.claude/cache/`. See
  [`state-schema.md`](./state-schema.md).
- **gateStampTtlSeconds** — how long a `full` stamp stays inheritable. Default `300`.
- **writable** — whether the host grants Write here. If `false`, skills report in chat and skip
  persistence.

### `integrations`

Optional host features. Each is **off unless declared** — the pipeline never assumes a specific agent
host.

- **todoMirror** — the host's task-list primitive, if it has one, for mirroring progress. Name the tool.
- **independentReview** — an external reviewer run against the cumulative diff before completion.
  Declare how it is invoked, whether it is mandatory for Large, and the maximum number of runs
  (default `2`; the last verdict is final).
- **subagents** — names of any isolated-context agents available for repository inspection and
  planning. Absent means the pipeline reads files inline instead.

Anything named here is host-specific by definition. A pipeline skill must treat an undeclared
integration as unavailable and carry on, never as an error.

---

## Worked example

A Unity 6 project shipping to Steam and Switch, with baked lighting, a content manifest generated from
ScriptableObjects, and an asset validator carrying accepted debt.

```yaml
project:
  engine:      Unity
  version:     "6000.0.32f1"
  language:    C#
  platforms:
    - StandaloneWindows64
    - Switch          # LOWEST — budgets below are set by this target
  liveService: false

commands:
  build.editor:     unity -batchmode -quit -projectPath . -executeMethod Build.CompileScripts
  build.standalone: unity -batchmode -quit -projectPath . -executeMethod Build.Standalone
  test:             unity -batchmode -runTests -testPlatform EditMode
  test.affected:    unity -batchmode -runTests -testPlatform EditMode -testFilter <path>
  lint:             dotnet format --verify-no-changes
  cook:             unity -batchmode -quit -executeMethod Build.Addressables
  smoke:            ./Tools/smoke.sh Scenes/Boot.unity 300
  benchmark:        ./Tools/bench.sh Scenes/Bench_Combat.unity   # needs devkit; not run in CI

gates:
  chain:
    - name: compile
      command: unity -batchmode -quit -executeMethod Build.CompileScripts
      blocking: true
    - name: missing-refs
      command: unity -batchmode -quit -executeMethod Validate.MissingReferences
      blocking: true
    - name: shader-compile
      command: unity -batchmode -quit -executeMethod Validate.Shaders
      blocking: true
    - name: save-compat
      command: ./Tools/save-compat.sh Fixtures/saves/
      blocking: true
    - name: addressables-dryrun
      command: unity -batchmode -quit -executeMethod Build.AddressablesDryRun
      blocking: true
    - name: asset-validator
      command: unity -batchmode -quit -executeMethod Validate.Assets
      blocking: false
      baseline:
        read: 'grep -E "^Asset validation" | tail -1'
        accepted: 23        # update deliberately; a drop is an improvement to keep

artefacts:
  - source:     Assets/Data/**/*.asset
    generated:  Assets/Generated/ContentManifest.cs
    regenerate: unity -batchmode -quit -executeMethod Generate.ContentManifest
    compare:    bytes
  - source:     Assets/Scenes/**/*.unity
    generated:  Assets/Scenes/**/LightingData.asset
    regenerate: unity -batchmode -quit -executeMethod Bake.Lighting
    compare:    bytes       # binary bake — report drift, never auto-commit
  - source:     Assets/Localisation/*.csv
    generated:  Assets/Generated/LocKeys.cs
    regenerate: unity -batchmode -quit -executeMethod Generate.LocKeys
    driftCheck: ./Tools/check-loc-drift.sh
    compare:    structural

perf:
  budget:
    frameBudgetMs:    33.3           # Switch, 30fps
    memory:           2.5GB
    drawCalls:        900
    loadTimeSeconds:  12
    benchmarkScene:   Scenes/Bench_Combat.unity

paths:
  risk:
    - Assets/Scripts/Save/**
    - Assets/Scripts/Net/**
    - Assets/Scripts/Entitlements/**
    - Assets/Settings/Addressables/**
    - ProjectSettings/**
    - Packages/manifest.json
    - Assets/Plugins/**
    - Assets/Data/Tuning/**
    - .github/workflows/**

state:
  directory:           .claude/cache/
  gateStampTtlSeconds: 300
  writable:            true

integrations:
  todoMirror: TodoWrite
  independentReview:
    invokedBy: .claude/hooks/review.sh
    trigger:   completing the trailing todo item
    mandatory: large
    maxRuns:   2
  subagents:
    inspect: Explore
    plan:    Plan
```

The example is illustrative. No pipeline skill assumes Unity, these commands, these paths, or any of
these integrations.
