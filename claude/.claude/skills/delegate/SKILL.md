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
| Implement a ticket, spec, or bug fix end to end, in a repo with a `dev` agent | workmux, session started as `dev` (section 4) |
| Change on a branch or PR that an existing workmux agent owns | `workmux send` to that agent (section 5) |
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

A `dev` agent (section 4) brings its own pipeline. Do not name a skill for
it. Give it the ticket ID and the base branch for the PR.

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

Start every agent with AskUserQuestion disabled. A choice dialog in another
pane cannot take `workmux send`, and the permission check blocks keypresses
into it. With the tool disabled, the agent asks in plain text and ends its
turn (status `done`), so `workmux send` can carry the answer.

```bash
no_dialog="--disallowedTools AskUserQuestion --append-system-prompt 'When you need a decision from the user, ask it as plain text at the end of your turn, then stop.'"
workmux add auth-refresh -b -a "claude $no_dialog" -P "$dir/auth-refresh.md"
workmux add billing-tests -b -a "claude $no_dialog" -P "$dir/billing-tests.md"
```

Define `no_dialog` in the same Bash call as `workmux add`: shell state does
not persist between calls.

- Handle: 2-4 words, kebab-case. The handle must NOT be `main`, `master`,
  `production`, or `release` (the branch-guard hook blocks commits on them).
- Always pass `-b`, so the user's tmux focus stays here.
- `--fork` copies this conversation into the agent. Use it only when the
  context is too large to write down; the "Finish rules" stay mandatory.

### Ticket work in a repo with a `dev` agent

Some repos define a `dev` agent that owns a ticket from reading it to a
draft PR. When the task is a ticket, spec, or bug fix to implement end to
end, check that the new worktree will have the agent. It has it when the
agent is committed on the branch the worktree starts from (`HEAD`, or the
`--base` ref), or when the main checkout holds it as a local file that
`.workmux.yaml` symlinks into each worktree:

```bash
main=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
git cat-file -e HEAD:.claude/agents/dev.md 2>/dev/null && echo committed
[ -e "$main/.claude/agents/dev.md" ] && echo local
```

If one line prints, start the session as that agent with `-a`:

```bash
workmux add eng-1234-payout-filter -b -a "claude --agent dev $no_dialog" -P "$dir/eng-1234.md"
```

If only `local` prints, the agent is not on any branch. Add
`--base <PR base branch>` when the current branch is not the PR base, so the
ticket branch does not carry commits from the current branch.

If the check fails, or the task is not ticket implementation (a refactor
step, a test file, a migration), spawn with `-a "claude $no_dialog"`.

Confirm each agent started:

```bash
workmux wait auth-refresh billing-tests --status working --timeout 120
```

Then tell the user the handles, and that `Ctrl-a w` shows the dashboard.

## 5. Give work to an existing agent

Use this path when the user names an existing agent, or when `workmux status`
lists an agent whose worktree holds the branch or PR the work belongs to. That
agent already has the branch, the PR, and the history. A new `workmux add`
starts from the branch checked out here, so it gets the wrong base.

1. Read its state:

   ```bash
   workmux status eng-742-gate
   git -C "$(workmux path eng-742-gate)" status -sb
   workmux capture eng-742-gate -n 40
   ```

2. Act on the state:

   | State | Action |
   | --- | --- |
   | `done`, worktree clean | Send the task (step 3) |
   | `working` | Wait with the poll script (section 6), then send |
   | `waiting` (dialog or permission prompt open) | `workmux send` refuses (`agent_waiting`). Relay the dialog to the user. The user answers it in the pane (`Ctrl-a w`). You cannot press keys in another agent's pane |
   | Pane ends with a question to the user | The question stays open. Name it in the message as "the user answers this", and relay it to the user |
   | Uncommitted changes in the worktree | Ask the user before you send |

3. Write the message to a file, then send it. The message has these parts,
   in this order:
   - **First line**: "New task from the user on this branch (PR #N)", and
     the source of the request (for example: QA of another PR).
   - **Goal**, **Context**, **Pointers**, **Scope**, **Verification**: as in
     section 3.
   - **Finish**: the section 3 "Finish rules", verbatim, then one line:
     "Update the PR description if the change is visible there."

   ```bash
   workmux send eng-742-gate -f "$dir/eng-742-guard.md"
   workmux wait eng-742-gate --status working --timeout 120
   ```

4. Monitor and verify as in sections 6 and 7. For the diff base of a PR
   branch, use `gh pr view <branch> --json baseRefName -q .baseRefName`.

## 6. Monitor

Do NOT use `workmux wait` to detect the end of the work. Status `done` means
only that the agent's turn ended. An agent that started background subagents
(the `dev` agent's reviewers and verifier) goes `done` while they run, then
resumes. `workmux status --json` does not show subagents; the pane footer
does.

Run the poll script with `run_in_background: true`, so this session stays
free and gets a notification when it exits:

```bash
~/.claude/skills/delegate/scripts/wait-done.sh auth-refresh billing-tests
```

It polls every 20 s and exits when all agents stay idle for 3 polls.
`--timeout SECONDS` changes the limit (default 3600).

Exit codes: 0 all done and no subagent running, 1 timeout, 2 usage error or
`workmux`/`jq` missing, 3 an agent needs input (`waiting`) or its worktree is
gone.

An agent in status `waiting` needs input (a question, or a permission
prompt). On exit 3, on timeout, or when the user asks:

```bash
workmux status auth-refresh billing-tests
workmux capture auth-refresh -n 80
```

Answer with `workmux send auth-refresh "..."` only when the answer follows
from what the user already decided. Otherwise relay the question to the user.
A dialog (a choice list or a permission prompt) does not take `workmux send`:
relay it, and the user selects the answer in the pane. When the user says it
is answered, start the poll script again.

## 7. Verify the result

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

## 8. Hand back

Report to the user, per handle: what changed, how it was verified, open
questions, and the PR URL if there is one. Merge and removal change the
user's branches. Run them only when the user says so:

```bash
workmux merge auth-refresh --rebase   # no PR: merge into base, remove worktree
workmux rm auth-refresh               # PR merged on GitHub, or discard
```

When a PR exists, do not run `workmux merge`. The PR merges on GitHub; after
that, `workmux rm` removes the worktree.
