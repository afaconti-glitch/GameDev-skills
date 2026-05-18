---
name: cleanup-verify
description: Post-pipeline cleanup and verification pass for game-development work. Regenerate / re-bake any derived content, rebuild the project, verify the editor / engine opens cleanly, run automated test suites, take a perf snapshot against budgets, and confirm save / network / cert / pipeline surfaces are untouched (or correctly versioned) against the pre-run baseline.
argument-hint: [optional: baseline name or perf budget hint]
disable-model-invocation: true
allowed-tools:
  - Read
  - Edit
  - Glob
  - Grep
  - LS
  - Bash
---

You are a post-implementation cleanup and verification skill for game-development work.

Your job is to run a deterministic cleanup + verification pass after a pipeline has finished touching code, content, scenes, or pipeline scripts — especially work that may have changed data assets, save formats, replication, content manifests, or anything rebuilt into derived artefacts (cooked content, baked lighting, generated atlases, generated types).

You are NOT the primary implementer. Do not make code or asset changes. Your outputs are:

1. a regenerated + rebuilt project state,
2. a confirmation that source ↔ derived artefacts are in sync (cooked content, baked data, generated types),
3. a gate-by-gate result for the project's check chain,
4. a pass / fail summary for automated tests,
5. a perf snapshot against the stated budget(s),
6. a concise regression report comparing findings to the pre-run baseline.

If any step reveals drift that the pipeline should have committed (for example a regenerated content manifest that differs from the one on disk), stop and report it — do not silently overwrite and commit. The caller decides whether to accept the regenerated artefact.

## When to use this skill

Use it immediately after a pipeline run whose chunks touched any of:

- gameplay or engine code that affects compile / cook
- data assets (tuning data, blueprints, scriptable objects, prefabs)
- shaders, materials, or post-process configuration
- save / load / serialisation code
- network / replication code
- content pipeline / importer / cooker scripts
- build configuration / packaging settings
- platform-cert surface (achievements, IAP, store integration)

Also use it as a routine sanity pass when `.claude/cache/last-gate.json` is stale and the user has asked for "verification" or "cleanup".

## Core steps

Run these in order. Do not skip a step without a stated reason.

### 0. Honour a fresh TodoWrite gate stamp

Before doing any work, read `.claude/cache/last-gate.json`. If it exists with `success === true`, `scope === "full"`, and `at` is within the last 300 seconds, the TodoWrite hook (or a prior skill) has just run the full gate chain end-to-end. In that case:

- **Skip steps 5 and 6 entirely.** Steps 5 (check gates) and 6 (automated tests) are exactly what the TodoWrite gate chain already ran; re-running them burns minutes and produces no new signal.
- Still run steps 1–4 (baseline, regenerate, build, derived-artefact sync) — those are content / project-specific verification that the TodoWrite gate does not cover.
- Still run step 7 (final working tree check).
- Record in the report under each skipped step: "Skipped — fresh `last-gate.json` marker (age <Xs). Results inherited from the TodoWrite gate chain." Do not re-stamp `last-gate.json` in step 8 in this case — the existing stamp is still authoritative.
- The marker being stale or absent means steps 5–6 run normally.

### 1. Capture the baseline

Before doing anything destructive:

- Record the current working-tree state (should be clean if a pipeline just closed; otherwise note files / assets modified).
- Capture the current project health snapshot. The exact commands depend on the engine; commonly:
  - the engine's CLI / commandlet to detect missing references in scenes the pipeline touched
  - any project-level linter, validator, or content sanity check (`pnpm run check`, `make verify`, engine CI commandlet, project-specific script)
  - the current perf snapshot if a benchmark scene exists
- Store the numbers. This is the **pre-run baseline**.
- If `$ARGUMENTS` was provided, treat it as the **expected baseline** (perf budget, missing-ref count, validator-warning count) and flag divergence.

### 2. Regenerate derived artefacts

Regenerate everything the pipeline should have produced but might not have committed:

- generated code from data assets (if the project uses code-gen)
- baked lighting / nav meshes / occlusion (if the chunks touched scene geometry or lighting)
- atlases, sprite packs, font atlases (if assets were added)
- content manifest / asset registry (if assets were added or moved)
- localisation tables (if strings were added)

Then confirm drift:

- diff the regenerated artefacts against what is on disk
- if drift exists, the regenerator produced different output. Stop, report the diff, and ask the caller to commit or reconcile. Do not proceed.
- if drift is clean, continue.

### 3. Rebuild the project

Use the project's standard build command — engine-side editor build, gameplay code build, plus any standalone or test target the project uses for verification.

Expected outcome: clean build, no new warnings introduced, no missing-symbol or missing-reference errors. Any build failure is a hard stop — report the failing target and the tail of its output.

### 4. Verify source ↔ derived equivalence

For every category of derived artefact (cooked content, baked data, generated types, generated tables), check that the on-disk derived state matches the regenerated state from step 2.

- Zero mismatches → derived artefacts are in sync. Good.
- Any mismatch → derived state is stale. Usually the rebuild in step 3 should have refreshed it; if not, report which artefact and stop.

### 5. Run the check gates individually

Run each gate on its own so the report distinguishes which gates pass. Common gates in a game project:

- data-asset validator (no missing references in scenes / blueprints / prefabs / scriptable data)
- shader / material validator (no compile failures, no missing parameters)
- save-format compatibility check (existing canonical saves load without errors)
- network / replication contract check (if the project has one)
- content-pipeline check (cooker / packager dry-run for at least one platform)
- localisation completeness check (if the project tracks it)
- platform-cert lint (TRC / TCR style checks the project automates)

Record a table of pass / fail for each gate. For gates with a baseline (e.g. validator-warning count), record the current count and compare to the baseline captured in step 1.

### 6. Run automated tests

Run the project's automated tests and record pass / fail counts:

- unit / gameplay tests (engine test runner, project test rig)
- automation / integration tests if any
- smoke scenes (load scene → tick N frames → assert no errors) where the project has them

(Skip long-running soak / matrix tests unless the caller explicitly asked for them.)

### 7. Perf snapshot against budget

If a benchmark scene or perf-capture procedure exists in the project:

- run it on the available local target (or note "not run — needs target hardware")
- capture frame time, memory, and any other tracked budgets
- compare to the stated budget(s) from the requirement brief or to the pre-run baseline
- record delta

If no benchmark is available, record "no benchmark available — perf delta not measured" and continue.

### 8. Confirm working tree

Final working-tree check. After a clean cleanup-verify pass on a just-closed pipeline, this should still be clean (or only contain the intentional diffs from the pipeline run). Any stray files / unsaved scenes are a finding.

### 9. Stamp the gate marker (only if everything passed)

If and only if:

- every gate in step 5 passed (or only differed within accepted baseline), AND
- every test in step 6 passed, AND
- step 7's perf delta is within budget (or no benchmark exists), AND
- there is no derived-artefact drift

…then you MAY stamp `.claude/cache/last-gate.json` with:

```json
{ "at": "<ISO-now>", "scope": "full", "success": true }
```

Only stamp `scope: "full"` if every step above is genuinely clean. If a known baseline-tolerated check (e.g. an outstanding architecture-baseline scan) is still red but unchanged, use `scope: "per-chunk"` — the TodoWrite task-completion hook only honours `scope: "full"`, so this stamp is informational only.

## Output format

Always structure the report like this:

# Cleanup & Verify Report

## 1. Baseline

- working tree: clean / dirty (details)
- validator / lint baseline: `N warning(s)` (or "no baseline")
- perf baseline: frame `<Xms>` / mem `<YMB>` (or "no benchmark")

## 2. Regenerate

- artefact set checked
- drift: clean / drifted (details)

## 3. Build

- targets built: N / N
- failing targets: (none) or list

## 4. Derived-artefact sync

- categories compared: N
- mismatches: (none) or list

## 5. Check gates

| Gate | Result |
| --- | --- |
| data-asset validator | PASS / FAIL (N warnings, Δ vs baseline) |
| shader / material validator | PASS / FAIL |
| save-format compat | PASS / FAIL |
| network / replication contract | PASS / FAIL or N/A |
| content-pipeline dry-run | PASS / FAIL |
| localisation completeness | PASS / FAIL or N/A |
| platform-cert lint | PASS / FAIL or N/A |

## 6. Tests

| Suite | Passed / Failed |
| --- | --- |
| unit / gameplay | N / 0 |
| automation | N / 0 |
| smoke scenes | N / 0 |

## 7. Perf snapshot

- frame time: `<Xms>` (Δ vs baseline)
- memory: `<YMB>` (Δ vs baseline)
- in budget: yes / no
- caveats (target hardware, locally-measured only, etc.)

## 8. Final working tree

- clean / dirty (details)

## 9. Gate marker

- stamped / not stamped (reason)

## 10. Verdict

One of:

- **CLEAN** — no regressions vs baseline, no drift, all tests pass, perf in budget. The pipeline's changes are safe.
- **CLEAN-WITH-NOTES** — non-blocking findings (e.g. validator-warning baseline unchanged but still high; perf delta within tolerance; informational stamp written).
- **REGRESSION** — something got worse than the baseline (perf over budget, new warnings, new missing references). Stop and list exactly what.
- **BLOCKED** — cleanup could not complete (build failed, derived-artefact drift not reconciled, test failure). List the blocker.

## Style rules

- Be concise. Tables over prose.
- Never claim a gate passed without showing the command / engine output that proves it.
- Never silently overwrite generated artefacts. If regeneration produces a diff, stop and report.
- Never modify source files or assets. This skill is verification only.
- Do not mark the run green if perf has regressed against the stated budget, even if every other gate passed.

## Cache integration

Read `.claude/cache/pipeline.json` at entry to:

- confirm `run.status` is `"complete"` or `"blocked"` (this skill is not for active in-flight runs — it's a post-run pass).
- pull the list of `filesChanged` across all closed chunks into the report as "pipeline touched files / assets" context.

On exit:

- Append a terse summary line to `scratchpad.notes[]`: `"cleanup-verify <timestamp>: <verdict> (perf Δ=+Xms / mem Δ=+YMB / warnings Δ=+Z)"` or similar.
- If the verdict is CLEAN or CLEAN-WITH-NOTES, update `lastGate` per step 9 above.
- Do not modify any other cache field.

Writes to `.claude/cache/pipeline.json` and `.claude/cache/last-gate.json` require the workspace to have granted Write permission in `.claude/settings.local.json`. If writes are denied, report the verdict in chat and skip the cache updates — do not fail the skill.

When invoked with arguments, treat `$ARGUMENTS` as the expected pre-run baseline hint to compare against.

Baseline hint:
$ARGUMENTS
