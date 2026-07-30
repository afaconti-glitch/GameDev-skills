# Pipeline state schema

Version: `1`

The delivery pipeline shares state between skills through two JSON files. This document is the
contract. Skills referencing pipeline state must conform to it.

Both files live under a host-writable cache directory. The default is `.claude/cache/`, but the
location is declared by the consuming project — see [`project-adapter.md`](./project-adapter.md), key
`state.directory`. Everywhere below, `<cache>/` means that directory.

| File | Owner | Purpose |
|---|---|---|
| `<cache>/pipeline.json` | `run-pipeline` | Run state for Medium and Large flows |
| `<cache>/last-gate.json` | `cleanup-verify` (final stamp) | Records when the full gate chain last passed, so other skills can skip a redundant re-run |

Small-tier runs do not touch either file.

## Availability is not guaranteed

State is an optimisation, not a dependency. Every skill that reads it must work without it, and every
skill that writes it must degrade cleanly:

- If the cache directory does not exist or the host denies Write, report results in chat and continue.
  Do not fail the skill.
- If `pipeline.json` is absent, missing a field, or fails to parse, treat that as "no prior state" and
  proceed from the information in the conversation.
- Never block work on a cache write.

A project that provides no writable cache location still runs the whole pipeline; it just repeats some
validation.

## `pipeline.json`

```jsonc
{
  "schemaVersion": 1,

  "run": {
    "id": "pipeline-2026-07-30T13:04:49Z",   // "pipeline-<ISO-8601>", or "shape-<ISO>" when
                                             // shape-task is invoked directly
    "task": "raw user request, verbatim",
    "startedAt": "2026-07-30T13:04:49Z",
    "updatedAt": "2026-07-30T13:41:07Z",
    "completedAt": "2026-07-30T14:11:02Z",   // set on terminal status only
    "status": "shaping",
    "tier": "medium",                        // "small" | "medium" | "large"
    "reviewRuns": 0,                         // independent-review invocations; hard cap 2
    "cleanupVerify": "CLEAN"                 // verdict recorded by cleanup-verify
  },

  "designBrief":   { },                      // confirmed intake brief (requirements-generator)
  "requirements":  { },                      // shaped requirements (shape-task)
  "strategy":      { },                      // implementation strategy (shape-task)
  "repoFindings":  { },                      // repository / content inspection digest (Large only)
  "architectPlan": { },                      // architect plan digest (Large only)

  "chunks": [
    {
      "id": "C1",
      "objective": "one line",
      "size": "small",
      "acceptanceCriteria": ["testable statement, including feel where it applies"],
      "status": "pending",
      "filesChanged": ["Assets/Scripts/Player/Dash.cs"],
      "validation": { "commands": ["…"], "result": "pass" },
      "closure": { "decision": "PASS", "notes": "…" }
    }
  ],

  "scratchpad": {
    "notes": ["free-text breadcrumbs; append-only"]
  },

  "lastGate": { "at": "…", "scope": "full", "success": true }  // mirror; see below
}
```

### `run.status`

| Value | Meaning | Set by |
|---|---|---|
| `shaping` | Brief and chunks being established | run-pipeline Phase B, or shape-task on entry |
| `ready` | Shaping finished, execution not started | shape-task, when invoked directly |
| `executing` | Chunk loop in progress | run-pipeline / execute-chunk, before first chunk |
| `verifying` | All chunks closed; final sweep running | run-pipeline, wrap-up |
| `blocked` | Stopped on a failure, blocking question, or scope breach | any skill that stops the run |
| `complete` | Finished clean | run-pipeline final phase, or close-chunk on the last chunk |
| `complete_with_findings` | Finished with unresolved review findings after the cap | run-pipeline, final phase |

### `chunks[].status`

`pending` → `executing` → `passed` (execute-chunk succeeded) → `closed` (close-chunk returned a
decision).

Two other terminal values exist:

- **`split`** — the chunk was decomposed into sub-chunks and is closed by proxy. `close-chunk` treats
  `split` alongside `closed` when deciding whether the run is finished.
- **`blocked`** / **`failed`** — execute-chunk could not complete it. The run status goes to `blocked`.

Do not mark a chunk `closed` without a `closure.decision`.

### `chunks[].closure.decision`

`PASS` | `PASS_WITH_NOTES` | `FAIL`. Only `close-chunk` writes this.

### `run.cleanupVerify`

`CLEAN` | `CLEAN-WITH-NOTES` | `BLOCKED`. Only `cleanup-verify` writes this.

## `last-gate.json`

```jsonc
{
  "at": "2026-07-30T14:10:58Z",   // ISO-8601, when the chain finished
  "scope": "full",                // "full" | "per-chunk"
  "success": true
}
```

`scope` is the load-bearing field:

- **`full`** — the project's entire gate chain ran end-to-end and passed, with no known-failing gates.
  In a game project that means: no derived-artefact drift, a clean build, every gate in `gates.chain`
  green (or a ratchet no worse than baseline), tests passing, and the perf delta inside budget. Only
  claim this when all of that held.
- **`per-chunk`** — a narrower or partial validation passed. Informational. Must not be used to skip a
  full run. Use it when a baseline-tolerated check is still red but unchanged.

### Freshness

A `full` stamp may be inherited instead of re-running the chain if `at` is within the project's
`state.gateStampTtlSeconds` (adapter key; default **300 seconds**). Beyond that, re-validate.

Some skills use a tighter window for their own purposes — `run-pipeline` inherits only within 240s
before a Small-tier change, and again before dispatching final review. A skill may be stricter than the
TTL; it must never be looser.

### Stamp only on first-hand evidence

Write `last-gate.json` only for a chain **you just ran and observed in this session**. Never stamp from
a `validation` block you read out of `pipeline.json`, from a prior chunk's record, or from a user's
assertion that the build is green. The marker exists to let other skills skip work; a stamp written
from hearsay silently disables verification.

This matters more in game projects than in pure code ones, because the expensive gates — cooking
content, loading a canonical save, running a benchmark scene — are exactly the ones a reader is most
tempted to take on trust.

The `lastGate` key inside `pipeline.json` is a convenience mirror for reporting. `last-gate.json` is
authoritative.

### Carry-forward claims

If a chunk record claims a failure was "pre-existing, carried forward from a prior chunk", re-run that
check against current HEAD before trusting it. Trust the test runner or engine output over the cache.
Anything still genuinely broken becomes a tracked item before the chunk closes — never a "known gaps"
note in the closure reason.

## Concurrency

There is no locking. Assume a single pipeline run at a time per workspace.

On entry, `run-pipeline` and `shape-task` read `pipeline.json`; if `run.status` is `shaping` or
`executing` and `run.task` differs from the current request, they must warn the user and ask whether to
resume, discard, or append rather than overwriting silently.

## Changing this schema

Bump `schemaVersion` on any breaking field change. A skill reading a `schemaVersion` higher than it
recognises should treat the state as unavailable and proceed without it rather than guessing.
