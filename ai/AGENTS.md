- In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

# Working Style
- Propose the minimum that does the job. Offer additions as a separate question rather than bundling them in.
- When I ask for a set of things, give me the short list plus what you left out — not the exhaustive one.
- Report problems you notice next to the task; don't fix them as a side effect. Leave the file as found and tell me.
- When a grouping or naming call is mine to make, ask rather than guessing — list the ones you're unsure about.

# Verification
- Check behavior against the real system — run it, probe it, read the typings — rather than asserting from memory.
- Say plainly when something is unverified, or verified by inspection only.
- Don't act on a third party's claim about an API (a bot review, a doc snippet) until it's confirmed against typings, docs, or a migration.

# Coding Standards
- Prefer descriptive variable and method names to comments. Comments should only be used for doc blocks, describing business logic, or explaining complex logic.
- Comments (including doc blocks) are written for a future reviewer reading the code cold — keep them additive and about the code itself. Don't narrate the change, the conversation that produced it, or which existing pattern it mirrors; that history belongs in the PR or an ADR.

# Safety
- Only make GET requests against external APIs unless I ask otherwise. If a task seems to need a write, ask first.
- Never force-push (`--force-with-lease` included), and never rebase beyond a `reword`, without explicit permission. Reordering, squashing, dropping, and amending already-pushed commits all need asking first. Normal fast-forward pushes are fine.
- When a committed script fails because of a gap in the local environment, fix the invocation for that run — don't edit shared code to route around a local quirk.

# Scripts That Change My Machine
- Support a dry run that prints what would change and touches nothing.
- Back up before replacing; never overwrite in place.
- Seed config that doesn't exist rather than replacing config that does, unless I say otherwise.
- Idempotent — a second run is a no-op.

# Plans
- At the end of each plan, give me a list of unresolved questions if any. Make the questions extremely concise.

# Worktrees
- Create every new branch in its own new worktree (`wt switch --create`), even when a skill or doc just says to make a branch, unless I say otherwise.
- Always use `wt` (worktrunk) for worktree operations — never raw `git worktree add/remove/list`.
- Run git/gh and other commands directly from the worktree working directory — do not cd into the main project directory first.
- As soon as a worktree is the target for implementation, switch the session context into that worktree directory (e.g. EnterWorktree) before reading, editing, or running commands.

# Instruction Files
- This file is committed to a public dotfiles repo. Never add company-specific rules here; put work rules in a `CLAUDE.md` in the directory that holds all the checked-out work repos, which isn't itself a repo.
