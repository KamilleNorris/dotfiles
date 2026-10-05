# ai

Agent-agnostic instructions, skills, and per-agent settings. `install.sh` symlinks
everything into the paths each agent expects, so edits made during a session are
already staged in git.

## Layout

| Path | What it is |
| --- | --- |
| `AGENTS.md` | Canonical global instructions. Linked to Claude's `CLAUDE.md`, Copilot's `copilot-instructions.md`, Gemini's `GEMINI.md`, and Kiro's `~/.kiro/steering/agents.md`. |
| `skills/` | Portable `SKILL.md` skills you author. Each is linked into the shared `~/.agents/skills` store that Claude Code and Copilot CLI both read. That store is a real directory, so global installs (`npx skills add -g`) land there and stay out of this repo. |
| `vendor/` | Submodules for skills kept in other repos, including [agent-skills](https://github.com/KamilleNorris/agent-skills) for the ones published separately; `skills/` holds symlinks into them rather than copies. |
| `prompts/` | Reusable prompt snippets, referenced from skills or pasted by hand. |
| `adapters/claude/` | Claude Code settings and statusline. |
| `adapters/herdr/` | herdr's `config.toml`, plus the plugin set to reinstall by source. |
| `adapters/kiro/` | Kiro CLI's `cli.json` settings seed and adapter notes. Instructions ride in via `~/.kiro/steering/`. |

## Install

```bash
git submodule update --init --recursive   # first clone only
DRY_RUN=1 ./install.sh                    # print what would change
./install.sh                              # link it
```

Anything already at a target path is moved into `~/.agent-config-backups/` first.
Rerunning is a no-op.

## Keeping work config out of a public repo

This repo is public, so `adapters/claude/settings.json` holds only public
marketplaces and plugins. Employer-specific marketplaces and plugins stay in
`~/.claude/settings.local.json`, which Claude Code merges over `settings.json`
and which this repo neither tracks nor generates. Keep credentials out of both;
use environment variables.

## What deliberately stays out

Machine state and transcript data under `~/.claude`: `history.jsonl`, `projects/`,
`sessions/`, `session-env/`, `file-history/`, `shell-snapshots/`, `__store.db`,
`cache/`, `backups/`, `plugins/`, `remote-settings*.json`, `policy-limits.json`.
Plugins are reinstalled from `enabledPlugins` rather than vendored.

Copilot CLI's `~/.copilot/mcp-config.json` and Codex's `~/.codex/config.toml` are
also untracked: both are rewritten by their apps and hold absolute local paths.

## Adding a skill from someone else's repo or gist

```bash
git submodule add <clone-url> ai/vendor/<short-name>
mkdir -p ai/skills/<skill-name>
ln -s ../../vendor/<short-name>/<file>.md ai/skills/<skill-name>/SKILL.md
```

The symlink is what git tracks, so the upstream content is never copied and the
submodule pins the commit you reviewed. `git submodule update --remote` pulls
newer upstream revisions when you want them.

## Editing a skill from agent-skills

`ai/vendor/agent-skills` is a full checkout, so edits made through the linked
skill land there. Commit and push from that directory, then commit the bumped
submodule pointer here. To pick up a skill newly added there:

```bash
ln -s ../vendor/agent-skills/skills/<skill-name> ai/skills/<skill-name>
./ai/install.sh
```
