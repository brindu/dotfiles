# Repository guidance

This repo manages dotfiles via **GNU Stow**. Every top-level non-hidden directory is a stow package whose internal layout mirrors `$HOME`.

## Conventions

- `dotfiles/<pkg>/foo/.bar` symlinks to `~/foo/.bar` after `stow <pkg>`.
- Repo root holds only metadata: `README.md`, `CLAUDE.md`, `.gitignore`. Everything else lives inside a package directory.
- `.claude/` is local Claude Code state and is gitignored — never commit it.

## Operations

Run `stow` from inside `~/dotfiles` (it defaults `--target` to the parent dir, i.e. `$HOME`).

- New file added to an existing package → `stow -R <pkg>`
- New package directory created → `stow <pkg>`
- Existing `$HOME` file to pull into a package → `stow --adopt <pkg>`

Editing a file already inside a package edits the live config — no restow needed.

## Safety

- `stow`, `stow --adopt`, and any `mv ~/.<file>` step modify the live `$HOME`. Confirm with the user before running them.
- Before adopting or restowing, sanity-check that the live file and the package file aren't going to clobber each other unexpectedly (`diff`, or `ls -l` to see whether the live path is already a symlink).
