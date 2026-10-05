# kiro adapter

Kiro CLI's default agent loads global instructions from `~/.kiro/steering/*.md`
(every `.md`, recursively) and also reads `AGENTS.md`. `install.sh` links the
canonical `AGENTS.md` to `~/.kiro/steering/agents.md` so the same instructions
Claude/Copilot/Gemini get are in Kiro's steering context.

`cli.json` is Kiro's settings file (`~/.kiro/settings/cli.json`), a flat
dot-notation schema — not Claude's `settings.json` schema, so it is a separate
file, not a copy. It is seeded only if absent (`link_if_absent`); Kiro rewrites
it, so machine-specific values stay out of this repo.

Skills are linked one per skill into `~/.kiro/skills/<name>`, pointing at the
shared `~/.agents/skills` store, the same store the other agents read.

What stays out: everything else under `~/.kiro` is machine state —
`sessions/`, `agents/` (generated), the rest of `settings/`
(`feed_state.json`, `survey_state.json`), and existing hand-authored steering
files that predate this link (e.g. `tool-preferences.md`).
