# GameDev-skills

Reusable Claude Code agent skills implementing a coordinated game-development studio operating system. Engine-agnostic personas and a delivery pipeline tuned for game features, systems, and content — works alongside any engine (Unity, Unreal, Godot, or custom).

The suite contains 18 studio role personas plus a routing brain. Each role is a self-contained markdown skill (frontmatter + persona body) following the [Agent Skills](https://agentskills.io/home) format used by Claude Code, OpenAI Codex, and other compatible agents.

## What's in here

```
GameDev-skills/
├── game-team/                        # The 18 studio role personas
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
│   ├── audio-director.md
│   ├── qa-lead.md
│   └── community-manager.md
├── pipeline/                         # Delivery pipeline execution suite
│   ├── run-pipeline.md               # Entry point — classify, confirm, dispatch
│   ├── requirements-generator.md     # Lightweight feature/system intake
│   ├── shape-task.md                 # Decompose brief into vertical slices
│   ├── execute-chunk.md              # Implement one chunk safely
│   ├── close-chunk.md                # Verify chunk closure against feel + acceptance
│   └── cleanup-verify.md             # Post-pipeline build, perf, and asset sweep
├── routing.md                        # The routing brain (paste into your CLAUDE.md)
└── README.md
```

## Delivery pipeline

Six skills that work as an integrated execution framework for game features and systems. The entry point is `run-pipeline` — it classifies work by size and routes it through the right phase composition, sharing state via `.claude/cache/pipeline.json`.

| Skill | Use when |
|---|---|
| run-pipeline | Starting any feature, system, content, or tools task — it classifies scope (Small/Medium/Large) and dispatches to the right flow |
| requirements-generator | Turning a rough feature pitch into a confirmation-ready mini-GDD |
| shape-task | Decomposing a confirmed brief into requirements, strategy, and vertical-slice chunks |
| execute-chunk | Implementing one approved chunk safely with inspection, scoped edits, and targeted validation |
| close-chunk | Verifying a completed chunk against acceptance criteria including feel, perf, and build health |
| cleanup-verify | Post-pipeline gate sweep: build runs, no missing references, perf budget, editor opens cleanly |

See `routing.md` for the full tier matrix and when to invoke each skill directly.

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
