---
name: delegate
description: Delegate implementation work to workmux worktree agents instead of in-process subagents. Use BEFORE calling the Agent tool for any task that changes files, runs long, or can run in parallel with other tasks (features, fixes, refactors, migrations, test writing). Also use when the user says "delegate", "hand off", "spin up agents", or "in parallel". Do not use for read-only research, search, or review; the Agent tool stays the right choice there.
allowed-tools: Bash, Write, Read
---

# Delegate with workmux

A workmux agent is a full Claude Code session in its own git worktree,
branch, and tmux window. The user can watch it, talk to it, and merge its
branch. An Agent-tool subagent is invisible, shares this checkout, and
returns only a summary. So: code changes go to workmux; questions stay with
the Agent tool.

## 1. Choose the tool

| Task | Tool |
| --- | --- |
| Changes files (feature, fix, refactor, tests, migration) | workmux |
| Several independent changes at once | workmux, one worktree per task |
| Long task (more than a few minutes) | workmux |
| Search, read, explore, answer a question | Agent tool (`Explore` / `general-purpose`) |
| Review a diff, second opinion | Agent tool |
| A handful of tool calls | Do it yourself |

Two tasks that edit the same files are not independent. Run them in sequence,
or give them to one agent.

## 2. Check preconditions

```bash
command -v workmux && [ -n "$TMUX" ] && git rev-parse --show-toplevel
```

If one check fails, do not use workmux. Tell the user which check failed,
then fall back to the Agent tool with `isolation: "worktree"`.

## 3. Write the prompt files

The worktree agent cannot see this conversation. Each prompt file is the
only context it gets. Write ALL prompt files first, THEN spawn.

Each prompt must contain:

- **Goal**: what "done" means, as a checkable result.
- **Context**: facts from this conversation the agent needs, copied
  verbatim. Decisions already made. Approaches already ruled out, and why.
- **Pointers**: files and docs to read, as RELATIVE paths (each worktree
  has its own root).
- **Scope**: what NOT to touch.
- **Verification**: the test or command that proves the change works.
- **Finish rules**, always, verbatim:

```
When the work is done and verified, commit it on this branch.
You may push this branch and open a PR from it (draft unless told
otherwise), and fix CI on it. Push only this branch. Do not push to the
base branch, do not force-push, and do not merge any branch or PR.
Do not run `workmux add`, do not use the delegate, worktree, or coordinator
skills, and do not create more worktrees.
End with a short summary: what changed, how you verified it, open questions,
and the PR URL if you opened one.
```

If the user names a skill for the task (e.g. `/plan-feature`,
`/implement-ticket`), tell the agent to use it for the full pipeline,
including its push, PR, and CI stages. Do not split the pipeline between the
agent and this session. Do not write the implementation steps yourself.

Open a PR only when the task asks for one (the user, or the named skill).
Otherwise the agent stops after the commit, and the branch comes back here
for merge.

Do NOT explore the codebase to write a better prompt. Use the context you
already have. If the context is not sufficient to state the goal, ask the
user.

```bash
dir=$(mktemp -d)
cat > "$dir/auth-refresh.md" <<'EOF'
...
EOF
```

## 4. Spawn

Run from the CURRENT directory. The new branch starts from the branch
checked out here, unless you pass `--base`.

```bash
workmux add auth-refresh -b -P "$dir/auth-refresh.md"
workmux add billing-tests -b -P "$dir/billing-tests.md"
```

- Handle: 2-4 words, kebab-case. The handle must NOT be `main`, `master`,
  `production`, or `release` (the branch-guard hook blocks commits on them).
- Always pass `-b`, so the user's tmux focus stays here.
- `--fork` copies this conversation into the agent. Use it only when the
  context is too large to write down; the "Finish rules" stay mandatory.

Confirm each agent started:

```bash
workmux wait auth-refresh billing-tests --status working --timeout 120
```

Then tell the user the handles, and that `Ctrl-a w` shows the dashboard.

## 5. Monitor

Run the wait with `run_in_background: true`, so this session stays free and
gets a notification when it exits:

```bash
workmux wait auth-refresh billing-tests --timeout 3600
```

Exit codes: 0 all done, 1 timeout, 2 worktree not found, 3 agent exited.

An agent in status `waiting` needs input (a question, or a permission
prompt). `wait` does not return for it. On timeout, or when the user asks:

```bash
workmux status auth-refresh billing-tests
workmux capture auth-refresh -n 80
```

Answer with `workmux send auth-refresh "..."` only when the answer follows
from what the user already decided. Otherwise relay the question to the user.

## 6. Verify the result

Do not trust the agent's summary. Read the branch:

```bash
base=$(git config --get "branch.auth-refresh.workmux-base" || echo main)
git log --oneline "$base..auth-refresh"
git diff "$base...auth-refresh" --stat
git diff "$base...auth-refresh"
```

Run the verification command in the worktree: `cd "$(workmux path auth-refresh)"`.
If the agent opened a PR, also check it: `gh pr view auth-refresh` and
`gh pr checks auth-refresh`.
If the result is wrong, send the agent a correction with `workmux send`;
do not fix it in this checkout.

## 7. Hand back

Report to the user, per handle: what changed, how it was verified, open
questions, and the PR URL if there is one. Merge and removal change the
user's branches. Run them only when the user says so:

```bash
workmux merge auth-refresh --rebase   # no PR: merge into base, remove worktree
workmux rm auth-refresh               # PR merged on GitHub, or discard
```

When a PR exists, do not run `workmux merge`. The PR merges on GitHub; after
that, `workmux rm` removes the worktree.
