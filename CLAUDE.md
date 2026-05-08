# Repository guidance

This repo manages dotfiles via **GNU Stow**. Every top-level non-hidden directory is a stow package whose internal layout mirrors `$HOME`.

## Conventions

- `dotfiles/<pkg>/foo/.bar` symlinks to `~/foo/.bar` after `stow <pkg>`.
- Repo root holds only metadata: `Makefile`, `README.md`, `CLAUDE.md`, `.gitignore`. Everything else lives inside a package directory.
- `.claude/` is local Claude Code state and is gitignored — never commit it.

## Operations

Always go through the `Makefile`, not raw `stow` invocations.

- New file added to an existing package → `make restow-<pkg>`
- New package directory created → `make install-<pkg>`
- Existing `$HOME` file to pull into a package → `make adopt PKG=<pkg>` (file must already be at the matching path inside `<pkg>`)

Editing a file already inside a package edits the live config — no restow needed.

## Safety

- `make install`, `make adopt`, and any `mv ~/.<file>` step modify the live `$HOME`. Confirm with the user before running them.
- Before adopting or restowing, sanity-check that the live file and the package file aren't going to clobber each other unexpectedly (`diff`, or `ls -l` to see whether the live path is already a symlink).
