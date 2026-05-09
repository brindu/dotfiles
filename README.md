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

After stowing the `nvim` package, launch `nvim` once — [lazy.nvim](https://github.com/folke/lazy.nvim) bootstraps itself on first run and installs every plugin pinned in `lazy-lock.json`. To update those pins later, run `:Lazy sync` and commit the resulting `lazy-lock.json` change.

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

## Neovim

The `nvim` package is a Lua-only nvim 0.11+ config built on [lazy.nvim](https://github.com/folke/lazy.nvim). Layout:

```
nvim/.config/nvim/
├── init.lua                # loads each `config/*.lua` in order
├── .luarc.json             # tells lua_ls about the `vim` global
├── lazy-lock.json          # plugin commit pins (tracked)
└── lua/
    ├── config/             # imperative setup
    │   ├── options.lua     # vim.opt + autocmds (trim whitespace, Lazy cursorline)
    │   ├── mappings.lua    # general (non-LSP, non-plugin) keymaps
    │   ├── lazy.lua        # bootstrap lazy.nvim and load plugins/
    │   ├── lsp_config.lua  # mason + vim.lsp.config + LspAttach autocmd
    │   └── completion.lua  # nvim-cmp setup
    └── plugins/            # one file per plugin or domain; lazy auto-loads each
```

### Plugins

| Plugin | Purpose |
| --- | --- |
| **lazy.nvim** | Plugin manager |
| **kanagawa.nvim** | Colorscheme (`kanagawa-dragon` variant) |
| **lualine.nvim** | Statusline |
| **nvim-tree.lua** + nvim-web-devicons | Sidebar file tree |
| **telescope.nvim** + plenary.nvim | Fuzzy finder for files, grep, LSP results |
| **nvim-treesitter** + treesitter-endwise + ts-autotag | Syntax / indent / autoclose HTML and JSX tags |
| **mason.nvim** + mason-lspconfig + nvim-lspconfig | LSP server install + bridging |
| **nvim-cmp** + cmp-{buffer,path,nvim-lsp} + cmp_luasnip | Completion engine + sources |
| **LuaSnip** + friendly-snippets | Snippet engine + library |
| **vim-fugitive** | Git porcelain (`:G`, `:Git blame`, etc.) |
| **gitsigns.nvim** | Gutter signs for hunks + inline blame |
| **diffview.nvim** | Side-by-side diff and per-file history views |
| **neotest** + neotest-rspec + nvim-nio | Test runner UI for RSpec |
| **vim-rails** | Rails-aware navigation (`:Rmodel`, `:Rcontroller`, `:A`, etc.) |
| **nvim-surround** | Surround pairs (`ys`, `cs`, `ds`) |
| **vim-easy-align** | Column alignment by delimiter (`ga…`) |
| **rename.vim** | `:Rename newname.ext` for current file |
| **which-key.nvim** | Popup showing pending keymaps after `<leader>` |
| **nvim-autopairs** | Auto-close brackets/quotes; cmp-aware (adds `()` on function completion) |
| **todo-comments.nvim** | Highlight `TODO`/`FIXME`/`HACK` + `:TodoTelescope` |
| **indent-blankline.nvim** | Indent guides (no scope highlight) |
| **fidget.nvim** | LSP progress spinner |
| **flash.nvim** | 2-key jump motion (`s`, `S`) |
| **harpoon** (harpoon2) | Pin a handful of files for instant switching |
| **trouble.nvim** | Panel for diagnostics, LSP refs, quickfix |
| **conform.nvim** | Formatter runner (stylua, RuboCop, Prettier, shfmt); owns `<leader>F` with LSP fallback |
| **nvim-lint** | Linter runner (RuboCop on Ruby; runs on save / read / insert leave) |
| **oil.nvim** | Edit a directory as a buffer (rename = `:w`); `-` opens parent dir |
| **nvim-dap** + nvim-dap-ui + nvim-nio | Debug adapter UI (adapters wired per-language as needed) |

### Keybindings

Leader is `<Space>`. Tables below cover custom bindings; nvim 0.11 LSP defaults (`K`, `<C-S>`, `[d`/`]d`, `gO`, `gra`, `grn`, `grr`, `gri`, `grt`) are still available where not overridden.

#### General

| Mode | Key | Action |
| --- | --- | --- |
| n | `<C-h/j/k/l>` | Move between splits |
| n | `<S-h>` / `<S-l>` | Previous / next buffer |
| n | `<leader>[` / `<leader>]` | Resize current split height +2 / -2 |
| n | `<leader>-` / `<leader>=` | Resize current split width +2 / -2 |
| v | `<` / `>` | Indent left/right (re-selects range) |
| v | `<leader>,` / `<leader>.` | Move selection down / up one line |
| v | `p` | Paste without yanking the replaced text |
| n / x / o | `s` | Flash jump (overrides default `s` / `cl`) |
| n / x / o | `S` | Flash treesitter jump |
| n | `<leader>?` | which-key: show buffer-local keymaps |

#### LSP (active when a server attaches)

| Key | Action |
| --- | --- |
| `gd` | Definitions (Telescope picker) |
| `gr` | References (Telescope) |
| `gi` | Implementations (Telescope) |
| `gy` | Type definitions (Telescope) |
| `<leader>rn` | Rename symbol |
| `<leader>ca` (n, v) | Code action |
| `<leader>F` | Format buffer (conform.nvim; falls back to `vim.lsp.buf.format` for filetypes with no configured formatter) |
| `<leader>e` | Open diagnostic float for current line |

#### Telescope

| Key | Action |
| --- | --- |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Open buffers |
| `<leader>fh` | Help tags |

Inside the picker: `<C-j>`/`<C-k>` move, `<CR>` open, `<C-x>`/`<C-v>`/`<C-t>` open in split / vsplit / tab, `<Esc>` close.

#### Git

| Key | Action |
| --- | --- |
| `<leader>gp` | Preview hunk under cursor (gitsigns) |
| `<leader>gtb` | Toggle inline blame |
| `<leader>gd` | Diffview vs HEAD |
| `<leader>gm` | Diffview vs `origin/main` |
| `<leader>gh` | Diffview file history (current file) |

Plus all of vim-fugitive: `:G`, `:Git blame`, `:Git log`, etc.

#### File tree

| Key | Action |
| --- | --- |
| `<C-n>` | Toggle nvim-tree |
| `<C-t>` | Reveal current file in tree |
| `-` | Open parent directory in oil (edit-as-buffer) |

Inside the tree: `<CR>` open, `a` create, `d` delete, `r` rename, `R` refresh, `H` toggle hidden.

Inside oil: `<CR>` enter, `-` go up, `<C-s>` open in vsplit, edit names freely and `:w` to apply.

#### Tests (Neotest)

| Key | Action |
| --- | --- |
| `<leader>tn` | Run nearest test |
| `<leader>tf` | Run current test file |
| `<leader>tl` | Run last |
| `<leader>ts` | Toggle summary panel |
| `<leader>to` | Open output for last run |

#### Harpoon

| Key | Action |
| --- | --- |
| `<leader>ha` | Add current file to harpoon list |
| `<leader>hh` | Toggle harpoon quick menu |
| `<leader>1`–`<leader>5` | Jump to harpooned file 1–5 |

#### Diagnostics / refs (Trouble)

| Key | Action |
| --- | --- |
| `<leader>xx` | Workspace diagnostics |
| `<leader>xX` | Buffer diagnostics |
| `<leader>xs` | Document symbols |
| `<leader>xl` | LSP defs/refs panel (right) |
| `<leader>xq` | Quickfix list |
| `<leader>xL` | Location list |

#### TODO comments

| Key | Action |
| --- | --- |
| `<leader>ft` | Telescope picker for `TODO`/`FIXME`/etc. |
| `]t` / `[t` | Next / previous todo comment |

#### Debug (DAP)

Adapters/configurations are language-specific and not pre-wired — install the adapter (e.g. `mason.nvim` → `debugpy`, `js-debug-adapter`) and add a `dap.configurations.<ft>` entry as needed.

| Key | Action |
| --- | --- |
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>du` | Step out |
| `<leader>dr` | Open REPL |
| `<leader>dt` | Toggle dap-ui |

#### Surround / align

| Mode | Sequence | Action |
| --- | --- | --- |
| n | `ys{motion}{char}` | Surround `motion` with `char` (e.g. `ysiw)` → `(word)`) |
| n | `cs{old}{new}` | Change surround (`cs"'` → swap quotes) |
| n | `ds{char}` | Delete surrounding `char` |
| v | `S{char}` | Surround selection |
| n / v | `ga{motion}{delim}` | Align around `delim` (e.g. `gaip=` aligns paragraph by `=`) |

### Maintenance

| Task | Command |
| --- | --- |
| Plugin UI / status | `:Lazy` |
| Update all plugins (then commit `lazy-lock.json`) | `:Lazy update` |
| Reset to lock file | `:Lazy restore` |
| Remove orphaned plugins | `:Lazy clean` |
| LSP server installer UI | `:Mason` |
| Reinstall an LSP server | `:MasonUninstall <name>` then `:MasonInstall <name>` |
| LSP health | `:checkhealth lsp` |
| Update treesitter parsers | `:TSUpdate` |
| Install a parser by name | `:TSInstallSync <lang>` |
| Treesitter health | `:checkhealth nvim-treesitter` |
| Overall health | `:checkhealth` |

#### Adding things

- **A plugin** — drop a new file in `nvim/.config/nvim/lua/plugins/<name>.lua` returning a lazy.nvim spec, run `stow -R nvim` to symlink it, open nvim → Lazy auto-installs and bumps `lazy-lock.json`.
- **An LSP server** — append to `ensure_installed` in `nvim/.config/nvim/lua/plugins/lsp.lua`. Restart nvim → mason fetches it. Per-server overrides go through `vim.lsp.config("server_name", { … })` in `lua/config/lsp_config.lua`.
- **A treesitter parser** — append to `ensure_installed` in `nvim/.config/nvim/lua/plugins/tree_sitter.lua`. Restart, or `:TSInstallSync <lang>` immediately.

#### Gotchas

- **`ruby-lsp` + frozen Gemfile** — ruby-lsp wants to write `.ruby-lsp/Gemfile.lock`, which Bundler refuses in frozen mode. Either add `ruby-lsp`/`ruby-lsp-rails`/`debug` to the project Gemfile (preferred — team-wide), or per-machine: `mkdir -p <project>/.ruby-lsp/.bundle && printf -- '---\nBUNDLE_FROZEN: "false"\n' > <project>/.ruby-lsp/.bundle/config`.
- **Mason gems with stale interpreter paths** — Mason captures the Ruby/Node binary in the gem shebang at install time. After switching mise versions, reinstall affected packages from a shell where `which ruby`/`which node` resolves correctly.
- **Markdown treesitter is intentionally skipped** (`ignore_install` + `disable` in `tree_sitter.lua`) because upstream query files reference grammar nodes the parser doesn't expose. Revisit if a future release fixes it.
- **First nvim launch on a new machine** — accept the lazy-bootstrap prompt, wait for plugins to install. `:Mason` to confirm `lua-language-server` and `ruby-lsp` are installed (the `ensure_installed` list will trigger them automatically on first run for the matching filetype). `:TSUpdate` once if treesitter health complains.
