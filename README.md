# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Layout

Each top-level directory is a stow *package* whose internal structure mirrors `$HOME`:

```
dotfiles/
├── README.md
├── CLAUDE.md
└── zsh/
    └── .zshrc          # → ~/.zshrc
```

A file at `dotfiles/<pkg>/path/to/file` becomes `~/path/to/file` once the package is stowed.

`stow` defaults `--target` to the parent of its working directory, so running it from inside `~/dotfiles` automatically targets `$HOME` — no flags needed.

## Setup on a new machine

```sh
brew install stow
git clone git@github.com:brindu/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow */
```

If a target file already exists in `$HOME`, stow refuses to overwrite. Either move it aside, or run `stow --adopt <package>` to pull it into the repo at the matching path.

After stowing the `tmux` package, install [TPM](https://github.com/tmux-plugins/tpm):

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then launch tmux and press `prefix + I` (`Ctrl-a I`) to install configured plugins.

## Adding a package

1. Create the directory: `mkdir git`
2. Place files at the path they should land in `$HOME` (e.g., `git/.gitconfig` → `~/.gitconfig`).
3. `stow git`

## Commands

Run from inside `~/dotfiles`:

| Command | Purpose |
| --- | --- |
| `stow <pkg>` | Symlink one package |
| `stow -D <pkg>` | Remove a package's symlinks |
| `stow -R <pkg>` | Recreate symlinks (run after adding files to a package) |
| `stow */` | Symlink every package |
| `stow --adopt <pkg>` | Pull existing `$HOME` files into `<pkg>` |

Editing a file inside a package edits the live config — symlinks are transparent. Restow is only needed when adding or removing files.
