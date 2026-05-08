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

After stowing the `git` package, create `~/.config/git/config.local` with your identity. This file is intentionally **not** version-controlled — it holds the per-machine private bits that the public config `[include]`s:

```ini
[user]
	name = Your Name
	email = you@example.com
	signingkey = ABCD1234           # optional, only if you GPG-sign commits

[commit]
	gpgsign = true                   # optional, requires signingkey above

[github]
	user = your-github-username      # optional, used by some tools
```

Git is non-fatal about missing includes, so commits without identity will fail with a clear `Please tell me who you are` — the local file is the fix.

## Private data and `*.local` files

Anything machine-specific or identity-bound — your name, email, GPG key ID, keychain helper commands, API tokens, work-only hostnames — should **not** be committed. The convention here is to layer those in via a sibling `*.local` file that the public config `[include]`s (or sources) at runtime.

The `git` package is the working example:

| File | Status | What's in it |
| --- | --- | --- |
| `git/.config/git/config` | Tracked, public | Settings safe to publish + a final `[include] path = ~/.config/git/config.local` |
| `~/.config/git/config.local` | **Not tracked** (per-machine) | `[user]`, `[commit].gpgsign`, `[github].user`, etc. |

Most config formats support some equivalent:

| Tool | Layer-in mechanism |
| --- | --- |
| git | `[include] path = ~/.../something.local` |
| ssh | `Include ~/.ssh/config.local` at the top of `~/.ssh/config` |
| zsh | `[ -f ~/.zshrc.local ] && source ~/.zshrc.local` |
| direnv `.envrc` | `source_env_if_exists .envrc.local` |
| tmux | `source-file -q ~/.config/tmux/tmux.local.conf` |

When you add a new package whose live config has private bits, **split the file**: keep the public scaffolding in the repo, `[include]` (or source) the `.local` companion, and document what goes in it in this README. The repo's `.gitignore` already ignores `*.local` defensively.

**Verification pitfall**: when checking that a private value resolves correctly, use plain `git config <key>` — **not** `git config --global <key>`. The `--global` scope only reads the global config files directly and does **not** follow `[include]` directives, which produces a false negative.

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

## Tmux key bindings

Prefix is `Ctrl-a` (rebound from default `Ctrl-b`). Bindings below are the custom or override ones — defaults like `n`/`p`/`1`–`9` for window navigation, `c` new window, `s` choose session, `d` detach, `z` zoom pane, `q` show pane numbers, etc., remain in effect.

| Key | Action | Notes |
| --- | --- | --- |
| `Ctrl-a Ctrl-a` | Send literal `Ctrl-a` to the focused app | For apps that need it (e.g. emacs, zsh start-of-line) |
| `Ctrl-a a` | Toggle to last (most recently focused) window | |
| `Ctrl-a f` | Window picker (interactive tree with previews, type to filter) | Recovered from `Ctrl-a w`; replaces default `find-window` |
| `Ctrl-a \|` | Split pane horizontally, inherit cwd of current pane | Replaces default `Ctrl-a "` |
| `Ctrl-a -` | Split pane vertically, inherit cwd of current pane | Replaces default `Ctrl-a %` |
| `Ctrl-a h` / `j` / `k` / `l` | Resize pane left / down / up / right by 5 cells | Overrides default vim-style pane navigation |
| `Ctrl-a r` | Reload `~/.config/tmux/tmux.conf` in place | |
| `Ctrl-a P` | Save current pane's scrollback to a file (prompts for path) | Useful before agent output scrolls off |
| `Ctrl-a w` | Workmux dashboard in a 90% × 90% popup | Overrides default `choose-tree -Zw`; the picker now lives at `Ctrl-a f` |
| `Ctrl-a e` | Toggle the workmux sidebar split | Persistent until toggled off |
