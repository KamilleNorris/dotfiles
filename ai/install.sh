#!/usr/bin/env bash
# Links the agent-agnostic config in this directory into each agent's expected paths.
# Idempotent. Existing non-symlink files are backed up to <path>.bak-<timestamp>.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/link.sh
. "$REPO/../lib/link.sh"

# Skills vendored as submodules are symlinks into ai/vendor; a missing checkout
# leaves those links dangling
for vendored in "$REPO"/vendor/*/; do
  if [ -z "$(ls -A "$vendored" 2>/dev/null)" ]; then
    log "warn  ai/vendor/$(basename "$vendored") is empty; run: git submodule update --init --recursive"
  fi
done

# Skills published separately live in a working clone of agent-skills; it is
# cloned when missing and its skills are linked alongside this repo's own.
AGENT_SKILLS_URL="https://github.com/KamilleNorris/agent-skills.git"
AGENT_SKILLS_DIR="${AGENT_SKILLS_DIR:-$HOME/projects/agent-skills}"
if [ ! -d "$AGENT_SKILLS_DIR/.git" ]; then
  if [ -e "$AGENT_SKILLS_DIR" ]; then
    log "warn  $AGENT_SKILLS_DIR exists but is not a git checkout; its skills are skipped"
  elif [ "$DRY_RUN" = "1" ]; then
    log "would clone $AGENT_SKILLS_URL -> $AGENT_SKILLS_DIR"
  else
    git clone --quiet "$AGENT_SKILLS_URL" "$AGENT_SKILLS_DIR"
    log "clone $AGENT_SKILLS_URL -> $AGENT_SKILLS_DIR"
  fi
fi

skill_dirs=()
for skill in "$REPO"/skills/*/ "$AGENT_SKILLS_DIR"/skills/*/; do
  if [ -d "$skill" ]; then skill_dirs+=("${skill%/}"); fi
done

# Shared skill store, read by any agent that resolves ~/.agents/skills. Global
# installs (npx skills add -g) write into it too, so it stays a real directory
# and only the skills collected above are linked in, one per skill. Older
# setups linked the whole directory to $REPO/skills; that link is replaced with
# a directory.
store="$HOME/.agents/skills"
if [ -L "$store" ] && [ "$(readlink "$store")" = "$REPO/skills" ]; then
  if [ "$DRY_RUN" = "1" ]; then
    log "would replace $store link with a directory"
  else
    rm "$store"
    log "unlink $store (was -> $REPO/skills)"
  fi
fi
[ "$DRY_RUN" = "1" ] || mkdir -p "$store"
for skill in ${skill_dirs[@]+"${skill_dirs[@]}"}; do
  link "$skill" "$store/$(basename "$skill")"
done

# Claude Code
if [ -d "$HOME/.claude" ] || command -v claude >/dev/null 2>&1; then
  link "$REPO/AGENTS.md" "$HOME/.claude/CLAUDE.md"
  link "$REPO/adapters/claude/settings.json" "$HOME/.claude/settings.json"
  link "$REPO/adapters/claude/statusline.sh" "$HOME/.claude/statusline.sh"

  # Claude Code discovers skills under ~/.claude/skills, so point one link per
  # skill at the shared store
  for skill in ${skill_dirs[@]+"${skill_dirs[@]}"}; do
    name="$(basename "$skill")"
    link "$HOME/.agents/skills/$name" "$HOME/.claude/skills/$name"
  done
fi

# Copilot CLI reads personal instructions from copilot-instructions.md and
# personal skills from ~/.agents/skills, linked above
[ -d "$HOME/.copilot" ] && link "$REPO/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"

# Kiro CLI's default agent loads global instructions from ~/.kiro/steering/*.md
# and discovers skills under ~/.kiro/skills. cli.json is Kiro's own flat-schema
# settings file, seeded only when absent since Kiro rewrites it. The default
# agent config carries the hooks, which Kiro only reads from agent configs.
if [ -d "$HOME/.kiro" ] || command -v kiro-cli >/dev/null 2>&1; then
  link "$REPO/AGENTS.md" "$HOME/.kiro/steering/agents.md"
  link_if_absent "$REPO/adapters/kiro/cli.json" "$HOME/.kiro/settings/cli.json"
  link "$REPO/adapters/kiro/agents/default.json" "$HOME/.kiro/agents/default.json"

  for skill in ${skill_dirs[@]+"${skill_dirs[@]}"}; do
    name="$(basename "$skill")"
    link "$HOME/.agents/skills/$name" "$HOME/.kiro/skills/$name"
  done
fi

# herdr keeps one hand-authored file; the rest of its config dir is generated
[ -d "$HOME/.config/herdr" ] && link "$REPO/adapters/herdr/config.toml" "$HOME/.config/herdr/config.toml"

# Cursor reads AGENTS.md directly
[ -d "$HOME/.cursor" ] && link "$REPO/AGENTS.md" "$HOME/.cursor/AGENTS.md"

# Gemini CLI looks for GEMINI.md unless contextFileName is overridden
[ -d "$HOME/.gemini" ] && link "$REPO/AGENTS.md" "$HOME/.gemini/GEMINI.md"

log "done"
