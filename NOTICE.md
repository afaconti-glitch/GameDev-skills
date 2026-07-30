# Attribution

This repository is MIT licensed (see [LICENSE](./LICENSE)). Thirteen of its skills are adapted from
other MIT-licensed projects. Their notices are reproduced here so they travel with any copy of this
work, as MIT requires.

Nothing below is vendored verbatim. Each skill was rewritten to this suite's frontmatter schema, UK
English, and intent-router structure, and re-scoped toward game development. The upstream projects are
the origin of the technical content, not of the surrounding form.

## obra/superpowers

- **Upstream:** https://github.com/obra/superpowers
- **Licence:** MIT — [LICENSE](https://github.com/obra/superpowers/blob/main/LICENSE)
- **Derived skill:** `diagnose` (the Iron Law four-phase debugging methodology: Root Cause
  Investigation → Pattern Analysis → Hypothesis Testing → Implementation)

Shipped in this repository as `plugins/game-team/skills/diagnose/`. It was named
`systematic-debugging` before v2.0.0.

## CloudAI-X/threejs-skills

- **Upstream:** https://github.com/CloudAI-X/threejs-skills
- **Licence:** MIT, declared in the project README. The repository publishes no `LICENSE` file, so the
  full MIT text and its copyright line are not available upstream to reproduce. The grant is recorded
  here as stated by the authors.
- **Derived skills (10):** `threejs-fundamentals`, `threejs-animation`, `threejs-shaders`,
  `threejs-geometry`, `threejs-interaction`, `threejs-lighting`, `threejs-textures`,
  `threejs-materials`, `threejs-postprocessing`, `threejs-loaders`

All shipped in the `game-tech` plugin.

## emalorenzo/three-agent-skills

- **Upstream:** https://github.com/emalorenzo/three-agent-skills
- **Licence:** MIT, declared in the project README. As above, no `LICENSE` file is published upstream.
- **Derived skills (2):** `three-js-best-practices`, `r3f-best-practices`

Both shipped in the `game-tech` plugin.

## Standards and guidance referenced

These are cited by the skills as external standards, not adapted into them. No licence obligation
attaches; they are listed so the provenance of the accessibility and UI guidance is traceable.

- [WCAG 2.2](https://www.w3.org/TR/WCAG22/) — W3C
- [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/)
- [Xbox Accessibility Guidelines](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines)
- [Accessible Player Experiences (APX)](https://accessible.games/accessible-player-experiences/)

## Maintaining this file

When a skill is adapted from an external source, add it here **and** record the origin in that skill's
frontmatter under `metadata.upstream_references`. The frontmatter entry is what a reader of a single
installed skill sees; this file is what a reader of the repository sees. Both need to be right.
