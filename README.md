# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Layout

Each top-level directory is a stow *package* whose internal structure mirrors `$HOME`:

```
dotfiles/
├── Makefile
├── README.md
├── CLAUDE.md
└── zsh/
    └── .zshrc          # → ~/.zshrc
```

A file at `dotfiles/<pkg>/path/to/file` becomes `~/path/to/file` once the package is stowed.

## Setup on a new machine

```sh
brew install stow
git clone <url> ~/dotfiles
cd ~/dotfiles
make install
```

If a target file already exists in `$HOME`, stow refuses to overwrite. Either move it aside, or use `make adopt PKG=<package>` to pull it into the repo at the matching path.

## Adding a package

1. Create the directory: `mkdir git`
2. Place files at the path they should land in `$HOME` (e.g., `git/.gitconfig` → `~/.gitconfig`).
3. `make install-git`

## Commands

| Command | Purpose |
| --- | --- |
| `make install` | Symlink all packages |
| `make uninstall` | Remove all symlinks |
| `make restow` | Recreate all symlinks (run after adding files to a package) |
| `make list` | Show discovered packages |
| `make install-<pkg>` | Stow one package |
| `make uninstall-<pkg>` | Unstow one package |
| `make restow-<pkg>` | Restow one package |
| `make adopt PKG=<pkg>` | Pull existing `$HOME` files into `<pkg>` |

Editing a file inside a package edits the live config — symlinks are transparent. Restow is only needed when adding or removing files.
