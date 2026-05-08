# Repository guidance

This repo manages dotfiles via **GNU Stow**. Every top-level non-hidden directory is a stow package whose internal layout mirrors `$HOME`.

## Conventions

- `dotfiles/<pkg>/foo/.bar` symlinks to `~/foo/.bar` after `stow <pkg>`.
- Repo root holds only metadata: `README.md`, `CLAUDE.md`, `.gitignore`. Everything else lives inside a package directory.
- `.claude/` is local Claude Code state and is gitignored — never commit it.
- Identity, secrets, and machine-specific values go in `*.local` files outside the repo (see "Private data" below).

## Private data

Anything that shouldn't be public — `[user]` identity (name/email/signing key), API tokens, keychain helper commands, work-only hostnames, personal aliases the user has flagged as private — never lands in a tracked package file. Pattern:

- Tracked package file holds public settings **plus** an `[include]`/`source`/`Include` directive pointing at a sibling `*.local` file (e.g. `~/.config/git/config.local`)
- The `*.local` file lives outside the repo, is created per-machine by the user, and is gitignored defensively at the repo root

When working in this repo:

1. **Before adding any file to a package**, scan it for private bits: `[user]` blocks, tokens, keychain `!security find-internet-password ...` invocations, hardcoded `/Users/<name>/...` paths, GitHub usernames, personal aliases. Surface findings before importing.
2. **When private bits exist**, propose splitting: public stays in the package file, private goes to a `*.local` companion that the public file `[include]`s. Update the README to document the new `*.local`'s expected content.
3. **Never write a `*.local` file containing the user's real PII yourself.** Provide a template with placeholders and let the user populate it (they can copy from a `*.bak` of the file you're replacing). Their identity belongs in their hands, not in tool output.
4. **When verifying a private value resolves**, use plain `git config <key>` — not `git config --global <key>`. The `--global` scope does **not** follow `[include]` directives and gives false negatives.

Existing private companions (don't commit, don't recreate):
- `~/.config/git/config.local` — `[user]`, `[commit].gpgsign`, `[github].user`, `[ghi].token`

## Operations

Run `stow` from inside `~/dotfiles` (it defaults `--target` to the parent dir, i.e. `$HOME`).

- New file added to an existing package → `stow -R <pkg>`
- New package directory created → `stow <pkg>`
- Existing `$HOME` file to pull into a package → `stow --adopt <pkg>`

Editing a file already inside a package edits the live config — no restow needed.

## Safety

- `stow`, `stow --adopt`, and any `mv ~/.<file>` step modify the live `$HOME`. Confirm with the user before running them.
- Before adopting or restowing, sanity-check that the live file and the package file aren't going to clobber each other unexpectedly (`diff`, or `ls -l` to see whether the live path is already a symlink).
