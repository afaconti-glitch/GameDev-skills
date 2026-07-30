---
name: game-design-framework
description: Methodology reference for rigorous mechanic and system design. Covers the 5-Component Relevance Filter, Numbers Policy for evidence-based balancing, State Machine Checklist for player actions, and playtest scenario templates. Use alongside the game-designer persona when evaluating whether a feature earns its place or when designing a balance pass from first principles.
license: MIT
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside design docs, tuning spreadsheets, and playtest notes.
disable-model-invocation: true
metadata:
  owner: game-delivery
  version: "2.0.0"
  language: "en-GB"
  category: "game-design"
  tags:
    - game-design
    - mechanics
    - balance
    - playtesting
    - state-machine
    - systems
    - methodology
  intents:
    - mechanic-evaluation
    - balance-from-first-principles
    - action-specification
    - playtest-design
  output_types:
    - relevance-filter-verdict
    - numbers-policy-table
    - state-machine-spec
    - playtest-scenario
---

# Game Design Framework

Methodology reference for mechanic evaluation, balance, and state design. Use when you need a structured decision tool — not just intuition — to determine whether a mechanic earns its place, how to set numbers, or whether a player action has been fully specified.

---

## 1. The 5-Component Relevance Filter

Before adding or keeping any mechanic, system, or feature, run it through all five components. A mechanic that fails more than one should be cut or reshaped — not patched.

The guiding principle: **Relevance over completeness.** A game with 10 relevant mechanics is better than one with 20 loosely related ones.

### Component 1 — Clarity

> Does the player know what this mechanic is asking of them, and does the outcome match their expectation?

Questions to answer:
- Can a new player understand the mechanic's core contract without explanation?
- Is the feedback (visual, audio, haptic) legible at game speed?
- Are the failure states distinct from success states?
- If the player fails, do they know *why*?

**Failure signal:** Players repeatedly attempt the wrong action, or succeed without understanding how.

---

### Component 2 — Motivation

> Does the player *want* to engage with this mechanic, and does the desire persist?

Questions to answer:
- What is the fantasy this mechanic delivers? (power, mastery, expression, discovery)
- Does the mechanic remain motivating once the novelty fades?
- Is there a skill ceiling worth reaching?
- Does progression through the mechanic feel meaningful?

**Failure signal:** Players engage once then avoid the mechanic, or treat it as a chore.

---

### Component 3 — Response

> Does the mechanic react to the player in a way that feels satisfying and proportionate?

Questions to answer:
- Is the response timing correct? (input latency, animation commitment, hit pause)
- Is the response magnitude appropriate? (too subtle = unsatisfying, too extreme = disorienting)
- Is the response consistent across similar inputs?
- Does the response communicate the state change clearly?

**Failure signal:** The mechanic feels "floaty", "sticky", "unresponsive", or "spongy" — player-reported feel complaints almost always originate here.

---

### Component 4 — Satisfaction

> Does the mechanic produce a rewarding emotional beat at its climax?

Questions to answer:
- Is there a clear moment of resolution? (the hit lands, the puzzle solves, the combo completes)
- Are the juice elements (screen shake, sound, particle, slow-mo) proportionate to the action's weight?
- Does the satisfaction loop repeat cleanly, or does it degrade on repetition?
- Does the player feel *capable* at the mechanic's resolution?

**Failure signal:** The mechanic works but feels hollow. Players describe it as "fine" or skip the climax animation.

---

### Component 5 — Fit

> Does this mechanic belong in *this* game, with *this* audience, at *this* moment in the session?

Questions to answer:
- Does the mechanic reinforce the game's pillars and fantasy statement?
- Is the mechanic appropriate for the target skill curve at the point it is introduced?
- Does it interact safely with other mechanics already in the game?
- Would its removal make the game less coherent, or less cluttered?

**Failure signal:** The mechanic feels imported from a different game. It works in isolation but fights the tone, pace, or systems around it.

---

## 2. Numbers Policy

All tuning numbers must have a source. "It felt about right" is not a source — it is a starting point. The Numbers Policy defines a minimum standard of evidence before a value is considered stable.

### The three tiers of number confidence

| Tier | Source | Status |
|---|---|---|
| **Derived** | Calculated from a model, formula, or target curve | Hypothesis — must be playtested |
| **Observed** | Set or confirmed by playtest data or telemetry | Provisional — review on scope change |
| **Validated** | Confirmed across multiple playtests or cohorts | Stable — flag before changing |

Numbers should move up the tiers, never down without cause.

---

### Naming numbers before setting them

Before assigning a value, name what the number controls:

```
Number:          Player dash cooldown
Affects:         Defensive availability, rhythm of combat, skill expression ceiling
Target feel:     Dash feels like a meaningful resource — not spammable, not punishing
Starting value:  0.8 s  (derived: two attacks at standard cadence = one dash window)
Test signal:     Players use dash defensively at least 30% of the time in combat encounters
Tier:            Derived → Observed (after first playtest)
```

Every balance table entry should have this shape before it goes into the build.

---

### The three numbers to always set explicitly

Regardless of mechanic type, always specify:

1. **Floor** — the minimum value that keeps the mechanic functional (below this, it breaks or becomes trivial)
2. **Target** — the value that delivers the intended feel at the expected skill level
3. **Ceiling** — the maximum value a skilled player could push the mechanic to (above this, the mechanic becomes degenerate)

```
Example — enemy health (normal difficulty):
  Floor:   40 HP  (below this, enemies die before the player can read their attack)
  Target:  120 HP (2–3 full combos for a competent player)
  Ceiling: 200 HP (max before combat becomes attrition)
```

---

### Balance red flags

Immediately revisit numbers when:
- Players are consistently choosing one option exclusively (strategy dominance)
- Players are never choosing a specific option (strategy irrelevance)
- Session length exceeds target by >20%
- Players report the game as "too easy" *and* completion rates are below 60% (indicates a specific difficulty spike, not global calibration)
- A single number change required to fix a feel problem is >50% of its current value (indicates a design problem, not a tuning problem)

---

## 3. State Machine Checklist

Every player action that modifies world state or player state must be fully specified as a state machine before it goes into production. This checklist ensures nothing is left implicit.

### Required states for any player action

Run through this list for every action (move, attack, interact, ability, etc.):

```
[ ] Idle — what state does the player enter before this action is possible?
[ ] Startup — how many frames/ms before the action takes effect?
[ ] Active — what is the window in which the action has effect?
[ ] Recovery — how long after the active window before the player regains control?
[ ] Cancel windows — can the action be cancelled? Into what? From what?
[ ] Interrupt conditions — what external events cut the action short?
[ ] Success state — what changes in the world and player state on hit/completion?
[ ] Failure state — what happens if the action misses or is interrupted?
[ ] Repeat rule — can the action chain into itself? Under what conditions?
[ ] Animation commitment — is the full animation required, or can it blend out?
[ ] Resource cost — does it consume stamina, cooldown, ammo, mana?
[ ] Resource recovery — does cancelling the action refund the cost?
```

### Movement sub-checklist

For all locomotion (walk, run, dash, jump, climb, swim):

```
[ ] Ground → Air transition (takeoff)
[ ] Air → Ground transition (landing — is there a landing lag?)
[ ] Directional change responsiveness (turn radius or snap-to?)
[ ] Ceiling collision
[ ] Slope behaviour (slide, grip, max angle)
[ ] Edge handling (coyote time? snap to ledge?)
[ ] Speed cap (per state)
[ ] Stack behaviour (can multiple movement actions queue?)
```

### Combat sub-checklist

For all attacks:

```
[ ] Hitbox active frames (start, end)
[ ] Hurtbox modification during attack (invincibility frames?)
[ ] Hit pause duration (attacker and target)
[ ] Knockback direction and magnitude
[ ] Hitstun duration
[ ] Combo window (time after hit where next input is buffered)
[ ] Counter-hit state (does it change the above?)
[ ] Block/parry interaction
[ ] Multi-hit behaviour (does each hit re-trigger stun?)
```

---

## 4. Playtest Scenario Templates

Use these templates to generate structured playtest scenarios that produce actionable data rather than general impressions.

### Template A — Mechanic viability

Use when testing whether a new mechanic works at all.

```
Scenario name:   [Mechanic] First Contact
Question:        Can a player with no prior context understand and use [mechanic] within [time]?
Setup:           Present the mechanic with no tutorial. Record first 5 minutes.
Success signal:  Player attempts correct action within [X] seconds of first encountering trigger
                 Player can describe the mechanic contract after the session
Failure signal:  Player ignores mechanic, uses incorrect approach, or expresses frustration >2×
Data to collect: Time to first correct use / Number of failed attempts / Player verbal description
Session length:  [20–30 min]
Next decision:   If success → move to balance testing. If failure → redesign teach plan or mechanic contract.
```

---

### Template B — Balance confidence

Use when testing whether numbers deliver the target feel.

```
Scenario name:   [Feature] Balance Pass [N]
Question:        Do the current numbers deliver [target feel] at [skill tier]?
Target feel:     [State specifically — e.g. "combat feels tense but learnable; player rarely one-shot"]
Participant:     [Skill tier: novice / intermediate / advanced]
Setup:           Session A uses current values. Session B uses proposed values (if A/B).
Success signal:  Players at target skill tier describe feel as [target adjective]
                 Completion rate for [challenge encounter] is within [X%–Y%] range
Failure signal:  Players consistently use one dominant strategy
                 Players report [specific complaint] unprompted >30% of the time
Data to collect: Completion rate / Deaths per encounter / Strategy chosen / Unprompted feel comments
Session length:  [45–60 min for combat-heavy sessions]
Next decision:   Accept / adjust ceiling-floor range / flag as design problem
```

---

### Template C — Fit validation

Use when testing whether a mechanic belongs in the game at its current position.

```
Scenario name:   [Mechanic] Fit Check — [Context]
Question:        Does [mechanic] feel like it belongs in this game at [session moment]?
Setup:           Play [session segment] with mechanic present. Remove it in a second pass.
Success signal:  Players notice its absence unprompted in the removed version
                 Players describe the mechanic using the game's own language / tone
Failure signal:  Players do not notice removal
                 Players describe the mechanic as "different" from the rest of the game
Data to collect: Mechanic engagement rate / Unprompted mentions / Tone mismatch comments
Session length:  Matches target segment length
Next decision:   Keep / reframe / remove
```

---

## Quick-reference checklist

Before finalising any mechanic for production:

- [ ] All 5 relevance components evaluated and documented
- [ ] Numbers have named sources and at least Derived-tier confidence
- [ ] Floor, target, and ceiling defined for all key values
- [ ] Full state machine documented (all required states checked off)
- [ ] Startup, active, and recovery frames specified
- [ ] Cancel and interrupt conditions named
- [ ] At least one playtest scenario written (Template A or B)
- [ ] Success and failure signals are observable and specific (not "it felt good")
- [ ] Balance red flags checked against current telemetry or playtest notes
