#!/usr/bin/env bash
# Links the agent-agnostic config in this directory into each agent's expected paths.
# Idempotent. Existing non-symlink files are backed up to <path>.bak-<timestamp>.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/link.sh
. "$REPO/../lib/link.sh"

# Skills vendored as submodules are symlinks into ai/vendor; a missing checkout
# leaves those links dangling
if [ -f "$REPO/../.gitmodules" ] && [ -z "$(ls -A "$REPO/vendor/explain-diff" 2>/dev/null)" ]; then
  log "warn  ai/vendor/explain-diff is empty; run: git submodule update --init --recursive"
fi

link() {
  local src="$1" dest="$2"
  [ -e "$src" ] || { log "skip  $dest (missing source)"; return; }
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    log "ok    $dest"
    return
  fi
  if [ "$DRY_RUN" = "1" ]; then
    log "would link $dest -> $src"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local backup="$BACKUP_DIR/$(printf '%s' "${dest#$HOME/}" | tr '/' '_').bak-$STAMP"
    mkdir -p "$BACKUP_DIR"
    mv "$dest" "$backup"
    log "backup $dest -> $backup"
  fi
  ln -s "$src" "$dest"
  log "link  $dest -> $src"
}

# Shared skill store, read by any agent that resolves ~/.agents/skills. Global
# installs (npx skills add -g) write into it too, so it stays a real directory
# and only this repo's skills are linked in, one per skill. Older setups linked
# the whole directory to $REPO/skills; that link is replaced with a directory.
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
for skill in "$REPO"/skills/*/; do
  [ -d "$skill" ] || continue
  link "${skill%/}" "$store/$(basename "$skill")"
done

# Claude Code
if [ -d "$HOME/.claude" ] || command -v claude >/dev/null 2>&1; then
  link "$REPO/AGENTS.md" "$HOME/.claude/CLAUDE.md"
  link "$REPO/adapters/claude/settings.json" "$HOME/.claude/settings.json"
  link "$REPO/adapters/claude/statusline.sh" "$HOME/.claude/statusline.sh"

  # Claude Code discovers skills under ~/.claude/skills, so point one link per
  # skill at the shared store
  for skill in "$REPO"/skills/*/; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    link "$HOME/.agents/skills/$name" "$HOME/.claude/skills/$name"
  done
fi

# Copilot CLI reads personal instructions from copilot-instructions.md and
# personal skills from ~/.agents/skills, linked above
[ -d "$HOME/.copilot" ] && link "$REPO/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"

# Kiro CLI's default agent loads global instructions from ~/.kiro/steering/*.md
# and discovers skills under ~/.kiro/skills. cli.json is Kiro's own flat-schema
# settings file, seeded only when absent since Kiro rewrites it.
if [ -d "$HOME/.kiro" ] || command -v kiro-cli >/dev/null 2>&1; then
  link "$REPO/AGENTS.md" "$HOME/.kiro/steering/agents.md"
  link_if_absent "$REPO/adapters/kiro/cli.json" "$HOME/.kiro/settings/cli.json"

  for skill in "$REPO"/skills/*/; do
    [ -d "$skill" ] || continue
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
