# Repository guidance

This repo sets up a Mac with **mise**: `mise bootstrap` installs packages and tools, links the dotfiles and loads the launchd agents. Every top-level non-hidden directory is a package (a mise dotfile group) whose internal layout mirrors `$HOME`. There is no GNU Stow and no `brew` program.

## Conventions

- `dotfiles/<pkg>/foo/.bar` is linked to `~/foo/.bar` by the group `[dotfile_groups.<pkg>]` in `mise/.config/mise/config.toml`. The repo must be at `~/dotfiles` (`settings.dotfiles.root`).
- Repo root holds only metadata and the bootstrap: `README.md`, `CLAUDE.md`, `.gitignore`, `setup.sh`. Everything else lives inside a package directory. A new top-level directory needs its own `[dotfile_groups.<pkg>]` table with a `root`; `setup.sh` treats every top-level directory as a package when it moves conflicting files away.
- `mise/.config/mise/config.toml` is the one declaration of the machine. `[tools]` for languages and CLIs. `[bootstrap.packages]` (`brew:`, `brew-cask:`) only for servers, shared libraries, apps and fonts. mise applies `[bootstrap.*]` and `[dotfile_groups.*]` only on `mise bootstrap`.
- LaunchAgents and hooks do not see the shell `PATH`, `[env]` or `[tools]`: use absolute paths, and `{{env.HOME}}` in place of a hardcoded home directory. Hooks run on each `mise bootstrap`, so each command must skip itself when done.
- `setup.sh` must stay idempotent (each step skips itself when done) and bash 3.2 compatible (macOS `/bin/bash`). It only installs mise, links `~/.config/mise` and runs `mise bootstrap`; put new setup work in the mise config, not in the script. When adding a tool, a package or a manual step, update the mise config and the README "Setup on a new machine" section together.
- When the user reports a failed `setup.sh` run, read `~/.local/state/dotfiles-setup.log` first.
- `.claude/` is local Claude Code state and is gitignored — never commit it.
- Identity, secrets, and machine-specific values go in `*.local` files outside the repo (see "Private data" below).

## Private data

Anything that shouldn't be public — `[user]` identity (name/email), API tokens, keychain helper commands, work-only hostnames, personal aliases the user has flagged as private — never lands in a tracked package file. Pattern:

- Tracked package file holds public settings **plus** an `[include]`/`source`/`Include` directive pointing at a sibling `*.local` file (e.g. `~/.config/git/config.local`)
- The `*.local` file lives outside the repo, is created per-machine by the user, and is gitignored defensively at the repo root

When working in this repo:

1. **Before adding any file to a package**, scan it for private bits: `[user]` blocks, tokens, keychain `!security find-internet-password ...` invocations, hardcoded `/Users/<name>/...` paths, GitHub usernames, personal aliases. Surface findings before importing.
2. **When private bits exist**, propose splitting: public stays in the package file, private goes to a `*.local` companion that the public file `[include]`s. Update the README to document the new `*.local`'s expected content.
3. **Never write a `*.local` file containing the user's real PII yourself.** Provide a template with placeholders and let the user populate it (they can copy from a `*.bak` of the file you're replacing). Their identity belongs in their hands, not in tool output.
4. **When verifying a private value resolves**, use plain `git config <key>` — not `git config --global <key>`. The `--global` scope does **not** follow `[include]` directives and gives false negatives.

5. **`claude/.claude/settings.template.json`** is the public seed for `~/.claude/settings.json`. Never copy the live `settings.json` over it: the live file collects approved permissions with project paths, commit hashes and client names. Add entries to the template one by one, with `~` instead of `/Users/<name>`.
6. **Keep the `claude` group file by file**: no `entries` path with `mode = "symlink"` under `~/.claude`. A whole-directory link would make `~/.claude/skills` a symlink into the repo, and installers would write into it.

Existing private companions (don't commit, don't recreate):
- `~/.config/git/config.local` — `[user]`, `[github].user` (commits are not signed)

## Operations

- Preview first: `mise dot diff` for links, `mise bootstrap --dry-run` for all parts, `mise bootstrap status` for drift.
- New file in a file-by-file group (`claude`, `psql`, top level of `zsh`) → `mise dot apply`
- New file in a directory linked as a whole → no command needed
- New package directory → add `[dotfile_groups.<pkg>]`, then `mise dot apply`
- Existing `$HOME` file to pull into a package → move it into the package, then `mise dot apply` (mise never replaces a real file with a link)
- New Homebrew package → `mise bootstrap packages use -g brew:<formula>`

Editing a file already inside a package edits the live config, including the mise config itself.

## Safety

- `mise bootstrap`, `mise dot apply`, `mise bootstrap packages apply|prune`, `mise bootstrap macos launchd apply` and any `mv ~/.<file>` step modify the live machine. Confirm with the user before running them. The `--dry-run` forms are safe.
- The first `mise bootstrap` on a machine needs sudo (to create `/opt/homebrew`), so the user must run it.
- Never use `--force` or `--force-dotfiles` without the user: they replace real files and no backup is documented.
- Postgres data is in `~/.local/share/postgres/<major>`. Do not delete it without the user.
