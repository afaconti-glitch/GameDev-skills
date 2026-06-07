---
name: game-ui-ux-framework
description: Methodology reference for video-game UI/UX design and implementation. Covers the UI design-space model (diegetic / spatial / meta / non-diegetic), the UI technology landscape and how to choose a system, data-driven UI architecture, accessibility grounded in real standards (WCAG 2.2, Game Accessibility Guidelines, Xbox Accessibility Guidelines, the APX model), localisation and fonts, a competency rubric with portfolio gates, and a curated library of free learning materials. Use alongside the game-ux-designer persona when you need a decision tool, a technology comparison, concrete accessibility acceptance criteria, or a study path — not just a stance.
license: Proprietary
compatibility: Portable reference skill for agents that support markdown skills or prompt files. Works best alongside UI mocks, the project's engine choice, accessibility targets, localisation matrices, and playtest notes.
metadata:
  owner: game-delivery
  version: "1.0.0"
  language: "en-GB"
  category: "game-ux"
  tags:
    - game-ux
    - ui
    - hud
    - design-space
    - diegetic-ui
    - data-driven-ui
    - accessibility
    - localisation
    - ui-performance
    - methodology
---

# Game UI/UX Framework

Methodology reference for designing and implementing game UI that makes play *easier* and turns the front-end into a design opportunity, not just a layer of friction. Use when you need a structured decision tool — where a UI element should live relative to the fiction, which UI technology fits the goal, how UI should be wired to game state, what accessibility actually requires, and what to study next.

This reference is engine-agnostic in its principles and names real systems only as a landscape. The actual per-project engine choice belongs in the consuming project's CLAUDE.md, not here.

---

## 1. The UI design space

Game UI is not a single layer. The most useful model places every element on two axes (after Fagerholt & Lorentzon, *Beyond the HUD*, popularised by Marcus Andrews):

- **Fiction** — does the element exist within the game's story/world, or is it for the player only?
- **Space (geometry)** — is the element rendered in the game's 3D space, or drawn flat on the screen?

This yields four categories:

| Category | In the fiction? | In the 3D space? | What it is | Examples |
|---|---|---|---|---|
| **Non-diegetic** | No | No | Classic flat overlay drawn for the player | Minimap, ability cooldowns, score, most settings menus |
| **Diegetic** | Yes | Yes | UI that characters could see and that lives in the world | *Dead Space* spine health bar, in-world wrist devices, holographic displays the avatar reads |
| **Spatial** | No | Yes | Drawn in 3D space but the character is not aware of it | Waypoint markers, objective pings, enemy outlines, footstep trails |
| **Meta** | Yes | No | Part of the fiction but flat on the screen | Blood/cracks on the screen for damage, rain on a "camera lens", HUD framed as a helmet visor |

### The core conclusion: immersion is earned, not assumed

The most important research finding for this work is that **immersive/diegetic UI is not automatically better.** A diegetic health bar is only a win if it still reads at game speed. Player-preference research on integrated vs overlay UI finds **no necessary link between transparent/diegetic UI and involvement** — and that players often *prefer* overlay UI precisely because it communicates information more clearly and faster.

So the goal is never "hide the HUD." The goal is a *deliberate* balance of: fiction payoff, clarity, input/reading speed, accessibility, performance, and screen real-estate.

### Diegesis decision guide

For each element, before choosing where it lives, score these and let the weakest dominate:

1. **Clarity at speed** — can the player read it in a glance during the gameplay it serves? If a diegetic placement loses a glance, it loses the argument.
2. **Reading/input speed** — does the placement add travel or interpretation cost in a time-critical moment?
3. **Accessibility** — diegetic/world-space placements often hurt low-vision, colourblind, and motion-sensitive players more than overlays; can you mitigate, or must it stay overlay?
4. **Screen real-estate** — does the placement free space that gameplay needs, or steal it?
5. **Fiction payoff** — what does the fiction actually gain? Mood, presence, reduced abstraction? Name it; "it's cooler" is not a reason.

A good HUD frequently mixes categories deliberately: spatial markers for navigation, a meta damage vignette for hits, a small non-diegetic cluster for resources that must be exact.

> **Sources:** *Beyond the HUD* (Fagerholt & Lorentzon, Chalmers, 2009); player-preference study on integrated vs overlay UIs; GDC talks (see §7).

---

## 2. UI technology landscape

Four paradigms cover almost all game UI. Choosing the paradigm first — before the layout — prevents most architecture pain.

| Paradigm | What it is | Best for | Watch out for |
|---|---|---|---|
| **Retained-mode engine UI** | A persistent widget tree the engine lays out and redraws (most shipping HUDs/front-ends) | Player-facing HUDs, menus, animated production UI | Rebuild/redraw cost if driven by tick or ad-hoc updates |
| **Immediate-mode UI** | UI rebuilt every frame from code; no retained tree | Internal tools, profilers, editors, debug overlays | Not ideal for art-heavy shipping front-ends; you build more presentation yourself |
| **XAML/MVVM middleware** | Designer-authored markup + data-binding, designer/engineer separation | Large, scalable, binding-heavy production UI | Licensing cost; added dependency |
| **Embedded web** | A browser-style HTML/CSS renderer inside the engine | Teams with strong web skills, or browser-style layout reuse | Heavier integration, security/update burden |

### Representative systems

Reference grounding only — the project's engine decides which of these is even available.

| System | Cost / licence | Paradigm | Best fit | Strengths | Weaknesses |
|---|---|---|---|---|---|
| **Unity uGUI** | Free, built-in | Retained | Mature runtime HUDs/menus, animation-heavy shipping UI | Large ecosystem, mature Canvas workflow, still Unity's recommended runtime system | Canvas rebuild costs; layout misuse gets expensive early |
| **Unity UI Toolkit** | Free, built-in | Retained (flexbox-style) | Scalable menus, data-heavy screens, design systems, editor UI, custom controls | Flexbox layout, UI Builder, runtime data binding, debugger, localisation, custom shaders, XR world-space | Lighter animation tooling; Unity still lists it as the *alternative* runtime system |
| **Unreal UMG** | Free, built-in | Retained | In-game HUDs, menus, animated widgets | Strong widget editor, built-in animation, good fonts/localisation, first-party optimisation docs | Brittle if driven by tick/ad-hoc bindings — prefer events/MVVM |
| **Unreal Common UI** | Free built-in plugin | Retained (on UMG) | Console-grade layered menus with reliable controller focus | Activatable widgets, input routing, platform action icons, style assets | Requires understanding focus/navigation architecture |
| **Unreal Slate** | Free, built-in | Retained (C++ declarative) | Bespoke widgets, tools, editor-like UI | Low-level control; Epic's own editor is built on it | Steep curve; not artist-friendly |
| **RmlUi** | Free, open source | Retained (HTML/CSS-like) | Player-facing UI in custom engines | Data-model bindings, visual debugger, localisation hooks, decorators, sprite sheets, high-DPI | Narrower CSS coverage than a browser — don't assume web parity |
| **Dear ImGui** | Free, open source | Immediate | Tools, profilers, debug overlays, instrumentation | Minimal deps, huge ecosystem, copy-pasteable demo, easy renderer integration | Not for art-heavy shipping front-ends |
| **NoesisGUI** | Free to evaluate, paid after | XAML/MVVM | High-end production UI with designer/engineer split | Strong MVVM binding, visual-state workflow, localisation, sample gallery | Commercial after evaluation; proprietary dependency |
| **Ultralight** | Free non-commercial / indie threshold; commercial otherwise | Embedded web | Lightweight embedded HTML UI | GPU-accelerated HTML, lighter than a full browser, game-focused docs | Browser-style runtime complexity; not OSI open-source |
| **CEF (Chromium Embedded)** | Free, open source | Embedded web | Near-browser parity, reuse of existing web apps | True browser embedding, off-screen rendering | Heavy footprint; security/update/integration burden |
| **Nuklear** | Public-domain-style, open source | Immediate | Tiny low-dependency tooling in C | Single-header, ANSI C, dependency-light | Bare-bones vs ImGui for production UX |
| **Godot Control nodes** | Free, open source | Retained | Responsive UI in Godot; useful second ecosystem | Container-driven responsive layout, strong localisation, XR UI tools | Smaller AAA footprint for benchmarking |

### Which system by goal

- **Unity portfolio** — first shippable HUD in **uGUI**; second, more architectural project in **UI Toolkit**.
- **Unreal portfolio** — layout/animation in **UMG**, then **Common UI + MVVM viewmodels** for scale and controller focus.
- **Custom engine** — **RmlUi** for retained player UI, **Dear ImGui** for tooling/debug; reach for **CEF/Ultralight** only if you specifically need web tech at runtime.
- **Tooling & debug overlays** — **Dear ImGui** (+ ImPlot for telemetry graphs, netImgui for remote inspection on constrained platforms).

---

## 3. Data-driven UI architecture

The single biggest determinant of whether UI stays maintainable is **where its state comes from.**

**Principle:** UI state should flow from a *source of truth* through bindings, viewmodels, or data models — **not** from every widget polling game state each frame.

### Source-of-truth checklist

For every dynamic value on screen (health, ammo, currency, quest state, settings):

```
[ ] What single system owns this value? (the source of truth)
[ ] How does the UI observe it — binding, viewmodel, event, or poll?
[ ] Is the update event-driven (changes push) rather than tick-driven (widget pulls every frame)?
[ ] If it must poll, why, and at what cadence (not every frame unless justified)?
[ ] Can the locale, theme, or input device change without rebuilding this by hand?
[ ] On teardown, are bindings/subscriptions released (no leaks)?
```

### Separation patterns

- **MVVM (Model–View–ViewModel)** — the view binds to a viewmodel that exposes ready-to-display state; the model stays UI-agnostic. Best for binding-heavy, designer-authored UI. Reduces glue code and improves testability.
- **MVP (Model–View–Presenter)** — a presenter mediates; common in event-driven engine UI where the view is passive.
- **Immediate-mode** — the *right* call for tools and debug overlays: rebuilding every frame from current state is simpler than maintaining a retained tree for short-lived UI. Don't use it for art-heavy shipping front-ends.

**Failure signal:** "the HUD updates on Tick" / "each widget reads the player every frame" — almost all UI perf problems and stale-state bugs start here.

---

## 4. Accessibility, grounded in real standards

Accessibility is a default, not a settings-menu afterthought. Turn the following real standards into concrete, testable acceptance criteria.

### Standards to draw from

| Standard | What it gives you |
|---|---|
| **WCAG 2.2** (W3C) | Contrast ratios, target size, focus visibility, no colour-only signalling, text resize — the most concrete acceptance criteria |
| **Game Accessibility Guidelines** (gameaccessibilityguidelines.com) | Game-specific guidance tiered Basic / Intermediate / Advanced, framed by reach · impact · cost; includes a checklist |
| **Xbox Accessibility Guidelines (XAG)** (Microsoft) | Platform-grade, game-specific criteria with test steps — strong for turning goals into acceptance criteria |
| **APX — Accessible Player Experiences** | The access → challenge-enablement → accessible-player-experience model; separates baseline access from preserving the intended challenge. Good for production planning |

### Concrete acceptance criteria (starter set)

```
[ ] Text/icon contrast meets WCAG 2.2 ratios against their actual backgrounds (incl. gameplay behind a transparent HUD)
[ ] Interactive targets meet a minimum size on the smallest supported screen (handheld/TV distance considered)
[ ] Focus is always visibly indicated; focus order is logical; no focus traps (controller and kbm)
[ ] No information conveyed by colour alone — pair with shape, icon, text, or pattern
[ ] Text size and/or UI scale is adjustable; layouts survive the largest setting without clipping
[ ] Input is remappable; no essential action requires a single un-rebindable button or simultaneous inputs
[ ] Motion/flash respects a reduce-motion option; no content in known seizure-risk flash ranges
[ ] Audio cues have a visual equivalent (and vice-versa) for critical signals
[ ] Subtitles/captions: legible size, background plate, speaker labels where relevant
```

### Triage

Rank findings by **severity** (blocks play / degrades play / polish) and state **options-menu implications** (what becomes a setting vs a default vs a fixed guarantee). Keep a carry-over backlog for what can't ship this pass.

---

## 5. Localisation & fonts

Bake localisation-readiness in from the first screen, not before ship.

```
[ ] All player-facing text comes from string tables/keys, never baked into layouts or textures
[ ] Layouts tolerate expansion (German/Finnish can run +30–40% longer than English)
[ ] Font stack has CJK fallback; glyphs don't tofu on Chinese/Japanese/Korean
[ ] RTL/bidirectional handling where Arabic/Hebrew are in scope (mirrored layouts, not just reversed text)
[ ] Live locale switch works without a restart where practical (re-resolves bindings)
[ ] Numbers, dates, plurals, and gendered strings use locale-aware formatting, not concatenation
[ ] Pseudo-localisation pass run before release (accenting + length-padding to surface clipping and hard-coded strings)
```

Pseudo-localisation is the cheapest high-value check: it exposes hard-coded strings and layout fragility without a single translator.

---

## 6. Competency rubric & portfolio gates

Use these as assessable gates, not just study notes. "Competent" is observable.

| Skill | What competent looks like |
|---|---|
| **HUD layout & hierarchy** | A combat HUD that stays scannable, keeps critical info in consistent zones, and reads during motion and effects |
| **Responsive UI & safe areas** | Supports 16:9 / 21:9 / portrait where relevant, plus console/mobile safe areas, with no overlap or clipped text |
| **Data-driven UI** | State comes from bindings/viewmodels/data models; inventory, settings, health update from a source of truth, not per-frame polling |
| **Animation & state transitions** | Menus animate between states cleanly, give feedback, and never break readability or input flow |
| **Accessibility** | Meets contrast/target-size criteria, robust focus indication, no colour-only signalling, text-size/display options, tested on target platforms |
| **Localisation & fonts** | String tables, live locale switch where practical, long-string and CJK handling, pseudo-loc before release |
| **Performance** | Profiles UI separately, avoids tick/binding churn, isolates expensive redraws, stable under menu stress |
| **Runtime debugging** | Inspects hierarchy, event routing, focus, and invalidation while the UI runs |
| **Shader/material-driven UI** | At least one intentional custom-rendered widget (masked panel, gradient badge, animated meter) used for meaning, not decoration |
| **VR/AR (world-space) UI** | One world-space interface that is legible, comfortably placed, and interactable with controllers/hands/pointers |

### Portfolio: finish three, not one

The fastest way to become visibly good is **three focused projects**, not one "ultimate UI":

1. **Responsive menu stack** — main/pause/settings, controller-first, safe-area-correct, no broken focus.
2. **Data-driven gameplay screen** — inventory / quest log / loadout, backed by real data, locale-switchable.
3. **Specialised capstone** — pick one: a world-space/XR radial menu, a diegetic in-world panel, or a tools-and-debug-overlay suite.

### Phased curriculum

| Phase | Duration | Focus | Milestone |
|---|---|---|---|
| **Foundation & teardown** | 1–2 weeks | Read one theory source; study 20–30 real UI screenshots; rebuild one pause menu + HUD wireframe | You can explain information hierarchy, focal points, and *why* each element sits where it does |
| **Engine fundamentals** | 2–4 weeks | Learn one engine UI stack deeply; build menus + a simple HUD | No broken focus order, no overlap at target resolutions, controls wired to real state |
| **Architecture & data flow** | 3–5 weeks | Move to bindings/viewmodels/data models; add localisation + input abstraction | No per-frame polling; locale can change; one controller-first path end to end |
| **Polish & quality pass** | 3–5 weeks | Add animation, accessibility, profiling, one custom-rendered widget | Perf evidence, visible focus, adjustable text, one intentional shader/material effect |
| **Specialisation & capstone** | 4–8 weeks | Pick XR, embedded web, or tooling/debug overlays | One genuinely "high-end" UI feature cluster, not just a pretty menu |

---

## 7. Curated free learning library

Primary/official sources first, then the literature and talks that materially improve judgement. Names are canonical so each is findable; verify the current URL at use time.

### Engine UI documentation & samples

| Resource | Type | Good for |
|---|---|---|
| Unity — *UI systems in Unity* & *Comparison of UI systems* | Official docs | Deciding uGUI vs UI Toolkit vs IMGUI |
| Unity — *User interface design and implementation in Unity* (e-book) | Official e-book | Long-form design process + both Unity UI systems |
| Unity — *UI Toolkit for advanced developers* (e-book) | Official e-book | Scalable UI Toolkit: assets, custom controls, binding, localisation, perf |
| Unity — **Dragon Crashers** & **QuizU** samples | Official sample projects | Dragon Crashers: production patterns, themes, safe areas, localisation. QuizU: event-driven architecture, MVP-style separation, bindings, custom controls |
| Unity — *Accessibility module* + *screen reader quickstart* + *Digital accessibility* course | Official docs/course | First-party accessibility implementation in Unity |
| Unity — *Optimisation tips for Unity UI* | Official guide | Canvas splitting, layout cost, pooling (uGUI-focused) |
| Epic — *Your First Hour in UMG* + *Creating UIs with UMG and Blueprints* | Official courses | Fastest practical entry to Unreal UI |
| Epic — UMG/Common UI/MVVM/Slate/Widget Reflector/Optimisation/Accessibility/Localisation docs | Official doc cluster | The most complete free production-UI architecture reference for games |
| Epic — **Lyra** & **ShooterGame** samples | Official sample games | Modern modular UE5 UI integration; simpler HUD + front-end baseline |
| **RmlUi** docs (data models, debugger, localisation, decorators, sprite sheets) | Official docs | Best open retained-mode documentation set for engine-agnostic UI |
| **Dear ImGui** README, *Getting Started*, `imgui_demo.cpp`, *Useful Extensions* (incl. ImPlot, netImgui) | Official docs/code | Best "learn by integrating + reading the demo" tooling ecosystem |
| **NoesisGUI** docs, Data Binding & Localisation tutorials, Samples | Official docs | Designer/engineer separation, visual states, binding-heavy UI |
| **Godot** Control nodes + internationalisation + XR Tools | Official docs | Responsive containers, localisation, world-space UI as a second ecosystem |

### Accessibility standards

| Resource | Type | Good for |
|---|---|---|
| **Game Accessibility Guidelines** | Industry guideline set | Tiered (Basic/Intermediate/Advanced), reach·impact·cost framing, checklist |
| **Xbox Accessibility Guidelines (XAG)** | Platform standard | Concrete acceptance criteria with test steps |
| **WCAG 2.2** (W3C) | Web standard, transferable | Contrast, target size, focus, text resize — hard criteria |
| **APX — Accessible Player Experiences** | Conceptual model | Separating baseline access from preserving challenge in production planning |

### Design literature & talks

| Resource | Type | Good for |
|---|---|---|
| *Beyond the HUD* (Fagerholt & Lorentzon) | Open thesis | Foundational diegetic/non-diegetic/spatial/meta design-space thinking |
| Player-preference study on integrated vs overlay UIs | Open paper | Corrective to "diegetic = better"; overlay often preferred for clarity |
| *Future Design of Accessibility in Games* (APX paper) | Open paper | The access → challenge-enablement → APX model |
| GDC — *God of War Ragnarök: Building the UI for a AAA Sequel* | Free GDC talk | Current AAA production reference for process and quality |
| GDC — *Immersing a Creative World into a Usable UI* | Free GDC talk | Embedding world-building into usable UI without losing clarity |
| GDC — *Bridging the Gap Between UX Principles and Game Design* | Free GDC talk | Connecting traditional UX principles to game constraints |

### Visual reference repositories

| Resource | Good for |
|---|---|
| **Game UI Database** | Large searchable archive of game UI screenshots, filterable by screen attributes |
| **Interface In Game** | Clean visual index of real game UI screenshots and articles |
| **ArtStation (UI channel)** / **Behance** | Presentation quality, style exploration, process boards |

---

## 8. Quick-reference checklist

Before finalising any UI/UX deliverable for production:

- [ ] Each element's place in the design space (diegetic / spatial / meta / non-diegetic) is **chosen on purpose**, with clarity winning over immersion where they conflict
- [ ] The UI paradigm fits the goal (retained / immediate / MVVM / embedded web); engine specifics deferred to the project
- [ ] Every dynamic value has a named **source of truth**; updates are event-driven, not per-frame polling
- [ ] Accessibility acceptance criteria met (contrast, target size, focus, no colour-only signalling, text size, remappable input, reduce-motion, audio/visual parity)
- [ ] Localisation-ready (string tables, expansion-tolerant layout, CJK/RTL handling, pseudo-loc run)
- [ ] UI profiled separately; redraw/rebuild cost and update cadence understood
- [ ] Validation defined (playtest signal, profiler evidence, accessibility test pass) — not "it felt good"
