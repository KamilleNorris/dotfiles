#!/usr/bin/env bash
# Pre-tool hook for Kiro CLI only: blocks a `git commit` whose message lacks the
# "Assisted-by: Kiro" trailer, so every Kiro-authored commit is marked.
#
# Kiro preToolUse hooks cannot rewrite a command (exit 0 allows, exit 2 blocks),
# so this enforces the trailer rather than injecting it: the model re-issues the
# commit with the trailer added. The AGENTS.md commit rule makes adding it the
# default; this hook is the stop-gap for when it is missed.
#
# Best-effort by design. It only inspects messages passed inline via -m/--message.
# A commit that opens an editor (no inline message), reads -F/--file, or pipes a
# heredoc is allowed through untouched, since the message text is not reliably
# visible at hook time. The steering rule tells the agent to commit with -m so the
# trailer stays enforceable.
set -euo pipefail

input="$(cat)"

# Kiro CLI names the event "preToolUse"; anything else (e.g. Claude's "PreToolUse")
# is out of scope for this Kiro-only hook.
[[ "$(jq -r '.hook_event_name // ""' <<<"$input")" == "preToolUse" ]] || exit 0

command="$(jq -r '.tool_input.command // ""' <<<"$input")"

TRAILER='Assisted-by: Kiro'

deny() {
    echo "$1" >&2
    exit 2
}

# Only act on an actual `git commit` invocation.
grep -qE '(^|[;&|]|\s)git\s+(-[^ ]+\s+)*commit\b' <<<"$command" || exit 0

# A -F/--file commit reads the message from a file we cannot see; allow it through.
if grep -qE '(^| )(-F|--file)( |=)' <<<"$command"; then
    exit 0
fi

# Only a commit carrying an inline -m/--message has an inspectable message here;
# editor, -F/--file, and heredoc commits are not, so allow them through.
if ! grep -qE '(^| )(-m|--message)( |=)' <<<"$command"; then
    exit 0
fi

grep -qF "$TRAILER" <<<"$command" ||
    deny "Kiro commits must include a \"$TRAILER\" trailer. Add it as the last line of the commit message (after a blank line), then re-run the commit."
