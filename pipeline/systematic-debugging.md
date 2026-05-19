---
name: systematic-debugging
description: 4-phase debugging methodology — Root Cause Investigation, Pattern Analysis, Hypothesis Testing, and Implementation. Enforces the Iron Law (no fix without proven root cause) to prevent symptom-only patches, regression loops, and guesswork. Use when diagnosing bugs, reviewing a failed test, or responding to an error before writing any fix. Adapted from obra/superpowers (MIT).
license: Proprietary
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside project source files and test output.
metadata:
  owner: game-delivery
  version: "1.0.0"
  language: "en-GB"
  category: "pipeline"
  tags:
    - debugging
    - root-cause
    - methodology
    - systematic
    - engineering-process
---

# Systematic Debugging

## The Iron Law

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

Before writing a single line of fix code, you must be able to answer:

1. What is the exact failing condition?
2. Why does it fail — what is the underlying cause?
3. How does the proposed fix address that cause (not just the symptom)?

If you cannot answer all three, you are not ready to fix. Continue investigating.

---

## The 4 Phases

### Phase 1 — Root Cause Investigation

Reproduce the failure precisely, then trace it to its source.

**Steps:**
1. Read the full error — stack trace, error message, file, line number
2. Reproduce it in isolation (minimal test case if possible)
3. Identify the last known good state
4. Ask: "What changed between working and broken?"
5. Follow the data — trace the actual value, not the expected value, through the call chain
6. Do not stop at the first plausible cause; keep asking "why?"

**Questions to ask:**
- What input causes the failure?
- What is the exact error vs what was expected?
- Does it fail consistently or intermittently?
- Is it environment-specific (dev/prod, OS, browser, hardware)?
- What was the last commit that didn't have this bug?

**Tools:**
```
// Browser
console.log / console.table / debugger
DevTools breakpoints, call stack, scope inspection
Performance tab for rendering issues

// Node / server
node --inspect  // Attach debugger
DEBUG=* node server.js  // Verbose logging

// Three.js / WebGL
renderer.info  // Draw calls, triangles, textures in VRAM
Spector.js     // WebGL call capture per frame
```

### Phase 2 — Pattern Analysis

Understand what class of problem this is before attempting a fix.

**Identify the pattern:**
- **Off-by-one / boundary error** — range, array index, loop termination
- **Race condition / async ordering** — timing-dependent, intermittent
- **State mutation** — shared mutable state, unexpected side-effects
- **Missing guard / null check** — undefined path through logic
- **Type mismatch** — wrong data type arriving at a function
- **Resource lifecycle** — use-after-free, missing disposal, double-init
- **Configuration error** — wrong env var, wrong import path, wrong default
- **External service failure** — API, asset load, network

**Why this matters:** The fix strategy differs by class. A race condition is not fixed by adding a null check. An off-by-one is not fixed by a try/catch. Misidentifying the class leads to symptom patches.

### Phase 3 — Hypothesis Testing

Prove your root cause diagnosis before writing the fix.

**Protocol:**
1. State your hypothesis explicitly: "I believe X causes Y because Z"
2. Design a minimal test that confirms or refutes the hypothesis
3. Test in isolation (not in the middle of a feature branch with 20 other changes)
4. If confirmed: proceed to Phase 4
5. If refuted: return to Phase 1 — do not patch around a disproven hypothesis

**Evidence required before proceeding:**
- A repro case that fails without the fix
- An understanding of why the fix addresses the root cause
- Confidence the fix does not break adjacent behaviour

```javascript
// Example hypothesis test
// Hypothesis: "The mixer update is called with delta=0 on the first frame,
//              causing animation to start frozen"

// Test:
const clock = new THREE.Clock();
function animate() {
  const delta = clock.getDelta();
  console.log('delta:', delta); // Observe first-frame value
  mixer?.update(delta);
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}
// Result: delta IS 0 on first call because Clock hasn't ticked yet
// Fix: clock.getDelta() once before the loop to initialise it
clock.getDelta(); // Initialise — discard the 0
```

### Phase 4 — Implementation

Write the fix only after completing Phases 1–3.

**Requirements for a valid fix:**
- Addresses the root cause, not the symptom
- Does not introduce new failure modes (check adjacent code paths)
- Is the minimal change needed — avoid bundling refactors into bug fixes
- Comes with a test or reproduction that now passes

**After the fix:**
1. Confirm the original reproduction case passes
2. Run the full test suite (or relevant subset)
3. Check for regressions in adjacent behaviour
4. Document the root cause in the commit message, not just "fix bug"

---

## Red Flags — Stop and Investigate

These patterns indicate you are fixing symptoms, not causes:

- "I'll just wrap it in a try/catch" — hiding errors does not fix them
- "Let me add a `|| []` default" — without knowing why the value is undefined
- "Probably a timing issue, I'll add a setTimeout" — race conditions need proper async handling
- "It works on my machine" — environment differences are root causes, not excuses
- "I'll disable the test for now" — the test is finding a real problem
- "Add a null check and move on" — find out why null arrived there
- Changing 3 things at once — you can no longer tell which change fixed it

---

## Anti-Patterns

| Anti-Pattern | Why It Fails | What to Do Instead |
|---|---|---|
| Shotgun debugging | Random changes until it works — root cause unknown | Reproduce first, then trace |
| Symptom patching | Fix passes tests but underlying issue remains | Follow the chain to root cause |
| Assumption debugging | Fix based on "I think it's probably..." | Prove hypothesis before writing fix |
| Copy-paste fix | Applies a fix from a similar-looking bug | Confirm the root cause is the same |
| Scope creep fix | "While I'm in here I'll also refactor..." | Separate bug fix from refactor |
| Speculative fix | "Let me try removing this line and see" | Understand what the line does first |

---

## Intermittent Bug Checklist

For bugs that don't reproduce consistently:

- [ ] Is there shared mutable state that could be written by multiple paths?
- [ ] Are there async operations where ordering is assumed but not guaranteed?
- [ ] Does it correlate with load (CPU/GPU pressure)?
- [ ] Does it depend on animation frame timing (`getDelta()`, `getElapsedTime()`)?
- [ ] Is there a lazy initialisation that races with first use?
- [ ] Does it depend on asset loading order?
- [ ] Is there a memory leak that only manifests after extended use?

---

## Commit Message Convention for Bug Fixes

A bug fix commit message should explain the root cause, not just the symptom:

```
// BAD — no root cause
fix: crash when clicking the inventory button

// GOOD — root cause explained
fix: inventory crash when item count is 0

AnimationMixer.update() was called with delta=0 on the first frame because
Clock.getDelta() was not initialised before the animation loop started.
The mixer tried to advance a 0-duration clip causing a divide-by-zero.

Fix: call clock.getDelta() once before the animation loop to consume the
initial 0-delta tick.
```

---

## See Also

- `execute-chunk` — implementation phase where debugging occurs
- `close-chunk` — verification and regression checking after a fix
- `cleanup-verify` — final check that fixes don't introduce new issues
