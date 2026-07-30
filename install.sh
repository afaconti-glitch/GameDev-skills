#!/usr/bin/env bash
#
# Install game-dev-skills into a consuming project.
#
#   ./install.sh /path/to/repo               # into one project (default)
#   ./install.sh --submodule /path/to/repo   # pinned to a tag, symlinked for discovery
#   ./install.sh --personal                  # into ~/.claude/skills, every project
#
#   --team-only    just the game-team plugin (29 skills: roles, pipeline, frameworks)
#   --tech-only    just the game-tech plugin (18 skills: web rendering, Blender)
#                  default is both
#
# Project modes place the skills under the project's .claude/skills/ and append
# the routing brain to its CLAUDE.md with paths already rewritten — the step
# most likely to be got wrong by hand. Copy mode leaves the project free to
# diverge; submodule mode keeps updates deliberate.
#
# Personal mode installs the skills only. They become available in every
# project as /<name>, but their metadata also loads in every project, including
# ones with nothing to do with games. The routing brain stays per-project.

set -euo pipefail

# Overridable so submodule mode can be exercised against a local clone.
SUITE_URL="${SUITE_URL:-https://github.com/afovea/game-dev-skills.git}"
MODE="copy"
PLUGINS=("game-team" "game-tech")
TARGET=""

# v1.x shipped flat .md files (game-team/game-designer.md) and nested the
# pipeline under skills/pipeline/. v2 gives every skill its own directory, so an
# older install leaves both behind and the skills end up present twice. Flag it
# rather than deleting anything in someone else's tree.
warn_stale_layout() {
  local d="$1" stale=0
  [[ -d "$d" ]] || return 0
  # A v2 skill is a directory containing SKILL.md; a v1 skill was a loose .md.
  if compgen -G "$d"/*.md >/dev/null; then stale=1; fi
  [[ -d "$d/pipeline" ]] && stale=1
  [[ $stale -eq 1 ]] || return 0
  echo
  echo "  NOTE: $d contains a v1.x install (loose *.md files and/or a pipeline/" >&2
  echo "        subdirectory). Every skill is its own directory now, so those are" >&2
  echo "        duplicates that will shadow or confuse the new layout. Remove them:" >&2
  echo "          rm -f '$d'/*.md" >&2
  echo "          rm -r '$d/pipeline'   # if present" >&2
  echo
}

# Copy each selected plugin's skills into a flat destination directory.
# No trailing slash on the glob: `cp -R src/*/ dest/` copies directory
# *contents*, which collapses every skill onto one SKILL.md.
copy_skills() {
  local dest="$1" p
  mkdir -p "$dest"
  for p in "${PLUGINS[@]}"; do
    cp -R "$SUITE_ROOT/plugins/$p/skills/"* "$dest/"
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --submodule) MODE="submodule"; shift ;;
    --copy)      MODE="copy"; shift ;;
    --personal)  MODE="personal"; shift ;;
    --team-only) PLUGINS=("game-team"); shift ;;
    --tech-only) PLUGINS=("game-tech"); shift ;;
    -h|--help)   sed -n '3,20p' "$0" | sed 's/^# \?//'; exit 0 ;;
    -*)          echo "error: unknown option '$1'" >&2; exit 1 ;;
    *)           TARGET="$1"; shift ;;
  esac
done

SUITE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

has_plugin() { local n; for n in "${PLUGINS[@]}"; do [[ "$n" == "$1" ]] && return 0; done; return 1; }

# Personal install: skills only, into ~/.claude/skills/, available in every
# project. No CLAUDE.md, .gitignore or adapter — those are project concerns.
# Note the cost: personal skills load their metadata in every project you open,
# including ones with nothing to do with game development.
if [[ "$MODE" == "personal" ]]; then
  DEST="$HOME/.claude/skills"
  copy_skills "$DEST"
  warn_stale_layout "$DEST"
  echo "Installed to $DEST"
  echo "  $(find "$DEST" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ') skills (${PLUGINS[*]})"
  echo
  echo "Available in every project as /<name>, e.g. /game-designer."
  echo "The routing brain is a per-project concern — run this without --personal"
  echo "in a project to add it to that project's CLAUDE.md."
  exit 0
fi

TARGET="${TARGET:-$PWD}"

[[ -d "$TARGET" ]] || { echo "error: target '$TARGET' is not a directory" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

if [[ "$TARGET" == "$SUITE_ROOT" ]]; then
  echo "error: target is the suite itself. Pass the consuming project's path." >&2
  exit 1
fi

echo "Installing game-dev-skills"
echo "  from:    $SUITE_ROOT"
echo "  into:    $TARGET"
echo "  mode:    $MODE"
echo "  plugins: ${PLUGINS[*]}"
echo

# ---------------------------------------------------------------- place files

if [[ "$MODE" == "submodule" ]]; then
  git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 || {
    echo "error: submodule mode needs '$TARGET' to be a git repository" >&2; exit 1; }
  if [[ -e "$TARGET/.claude/skills-vendor" ]]; then
    echo "  .claude/skills-vendor already exists — leaving it alone"
  else
    git -C "$TARGET" submodule add -q "$SUITE_URL" .claude/skills-vendor
    LATEST_TAG="$(git -C "$SUITE_ROOT" tag -l 'v*' --sort=-v:refname | head -1)"
    if [[ -n "$LATEST_TAG" ]]; then
      git -C "$TARGET/.claude/skills-vendor" checkout -q "$LATEST_TAG"
      echo "  pinned to $LATEST_TAG"
    fi
  fi
  # Skills are discovered under .claude/skills/, so symlink each vendored skill
  # directory into place. Without this the submodule gives you routing but no
  # discovery — the files exist where nothing looks for them.
  mkdir -p "$TARGET/.claude/skills"
  linked=0
  for p in "${PLUGINS[@]}"; do
    src="$TARGET/.claude/skills-vendor/plugins/$p/skills"
    # An unmatched glob expands to itself, which would symlink a literal '*'.
    # That happens for real when the pinned tag predates the plugin.
    [[ -d "$src" ]] || {
      echo "error: '$p' has no skills/ at the checked-out revision of the submodule." >&2
      echo "       Expected $src" >&2
      echo "       The pin is probably older than the two-plugin layout (v2.0.0)." >&2
      exit 1; }
    for d in "$src"/*/; do
      n="$(basename "$d")"
      [[ -e "$TARGET/.claude/skills/$n" ]] || \
        ln -s "../skills-vendor/plugins/$p/skills/$n" "$TARGET/.claude/skills/$n"
      linked=$((linked + 1))
    done
  done
  echo "  symlinked $linked skill directories into .claude/skills/ for discovery"
  REFERENCE_SRC="$TARGET/.claude/skills-vendor/plugins/game-team/reference"
  # Pipeline skills link to ../../reference/*.md. Resolved physically that lands
  # inside the submodule and works; resolved logically it lands at
  # .claude/reference/. Symlink that too so the link holds either way.
  if has_plugin game-team && [[ ! -e "$TARGET/.claude/reference" ]]; then
    ln -s "skills-vendor/plugins/game-team/reference" "$TARGET/.claude/reference"
    echo "  symlinked .claude/reference/ for the pipeline docs"
  fi
else
  copy_skills "$TARGET/.claude/skills"
  echo "  copied $(find "$TARGET/.claude/skills" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ') skills," \
       "$(find "$TARGET/.claude/skills" -path '*/references/*.md' 2>/dev/null | wc -l | tr -d ' ') skill references"
  REFERENCE_SRC="$SUITE_ROOT/plugins/game-team/reference"
  # Shared pipeline docs live outside skills/ so they are not mistaken for one.
  # .claude/reference/ is exactly where the skills' own ../../reference/ links
  # land once they sit at .claude/skills/<name>/SKILL.md, so they keep resolving.
  if has_plugin game-team; then
    mkdir -p "$TARGET/.claude/reference"
    cp "$REFERENCE_SRC"/*.md "$TARGET/.claude/reference/"
    echo "  copied $(ls "$TARGET/.claude/reference"/*.md | wc -l | tr -d ' ') shared pipeline docs"
  fi
fi

warn_stale_layout "$TARGET/.claude/skills"

# ------------------------------------------------------- routing into CLAUDE.md

MARK_START="<!-- game-dev-skills:start -->"
MARK_END="<!-- game-dev-skills:end -->"
CLAUDE_MD="$TARGET/CLAUDE.md"

# routing.md already uses the paths the files land on: skills are flat under
# .claude/skills/ in every mode, and .claude/reference/ is a real directory in
# copy mode and a symlink into the submodule otherwise. Nothing to rewrite.
ROUTING="$(cat "$SUITE_ROOT/routing.md")"

if [[ -f "$CLAUDE_MD" ]] && grep -qF "$MARK_START" "$CLAUDE_MD"; then
  # The routing text goes via a temp file, not stdin: stdin is already taken by
  # the heredoc carrying the script, and supplying both silently feeds the
  # markdown to python as its source.
  ROUTING_TMP="$(mktemp)"
  printf '%s' "$ROUTING" > "$ROUTING_TMP"
  python3 - "$CLAUDE_MD" "$MARK_START" "$MARK_END" "$ROUTING_TMP" <<'PY'
import sys, pathlib
path, start, end, block_file = sys.argv[1:5]
block = pathlib.Path(block_file).read_text()
p = pathlib.Path(path); t = p.read_text()
head, _, rest = t.partition(start)
_, _, tail = rest.partition(end)
p.write_text(f"{head}{start}\n{block}\n{end}{tail}")
PY
  rm -f "$ROUTING_TMP"
  echo "  updated existing routing block in CLAUDE.md"
else
  { [[ -f "$CLAUDE_MD" ]] && printf '\n'; printf '%s\n%s\n%s\n' "$MARK_START" "$ROUTING" "$MARK_END"; } >> "$CLAUDE_MD"
  echo "  appended routing block to CLAUDE.md"
fi

# ------------------------------------------------------------------ gitignore

GI="$TARGET/.gitignore"
if [[ "$MODE" == "submodule" ]]; then
  grep -qF '!.claude/skills-vendor/' "$GI" 2>/dev/null || {
    printf '\n# Claude Code project state. The skills suite is the tracked submodule below.\n.claude/*\n!.claude/skills-vendor/\n' >> "$GI"
    echo "  updated .gitignore (keeps the submodule tracked)"; }
else
  grep -qE '^\.claude/?$' "$GI" 2>/dev/null || {
    printf '\n# Claude Code project state, including the copied skills suite.\n.claude/\n' >> "$GI"
    echo "  updated .gitignore"; }
fi

# ------------------------------------------------------------------- adapter

if has_plugin game-team; then
  ADAPTER="$TARGET/.claude/pipeline-adapter.md"
  if [[ -e "$ADAPTER" ]]; then
    echo "  pipeline adapter already present — leaving it alone"
  else
    mkdir -p "$TARGET/.claude"
    # The template sits next to state-schema.md in the repo, but lands one level
    # above it here, so its sibling link has to be rewritten on the way in.
    sed 's#](\./state-schema\.md)#](./reference/state-schema.md)#g' \
      "$REFERENCE_SRC/project-adapter.md" > "$ADAPTER"
    echo "  seeded .claude/pipeline-adapter.md (template — fill it in)"
  fi
fi

echo
echo "Done. Next:"
if has_plugin game-team; then
  echo "  1. Fill in .claude/pipeline-adapter.md with this project's engine, commands"
  echo "     and gates. Without it the pipeline still runs, discovering what it can"
  echo "     from your engine project files and CI config, but it has to guess —"
  echo "     and guessing is expensive when the gates cook content."
  echo "  2. Put project-specific context ABOVE the routing block in CLAUDE.md."
  echo "  3. Try it:  ask for something narrow and see which role gets invoked."
else
  echo "  1. Put project-specific context ABOVE the routing block in CLAUDE.md."
  echo "  2. Try it:  /threejs-shaders with a real shader question."
fi
