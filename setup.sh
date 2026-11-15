#!/usr/bin/env bash
# Bootstrap a Mac from this repo. No Homebrew.
#
#   git clone https://github.com/brindu/dotfiles.git ~/dotfiles
#   ~/dotfiles/setup.sh
#
# Safe to re-run: every step skips work that is already done. If a step fails,
# fix the cause and run it again. Claude Code is installed early on purpose, so
# it can help when a later step fails.
#
# Log: ~/.local/state/dotfiles-setup.log
#
# Bash 3.2 compatible (the /bin/bash macOS ships).
set -Eeuo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
MISE="$LOCAL_BIN/mise"
MISE_INSTALLS="${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs"
LOG="$HOME/.local/state/dotfiles-setup.log"
MIN_MISE="2026.11" # older: compiles Ruby against Homebrew OpenSSL, breaks conda Postgres time zones
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

export PATH="$LOCAL_BIN:$PATH"
export MISE_YES=1

CURRENT_STEP="start"

step() { CURRENT_STEP="$1"; printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
info() { printf '    %s\n' "$*"; }
done_() { printf '    \033[2m%s: already done\033[0m\n' "$*"; }
stop() { printf '\n\033[1;33m!! %s\033[0m\n' "$*"; exit 1; }

on_error() {
  local code=$?
  printf '\n\033[1;31mxx Failed at step "%s" (exit %s)\033[0m\n' "$CURRENT_STEP" "$code"
  printf '   Log: %s\n' "$LOG"
  if [ -d "$MISE_INSTALLS/claude" ]; then
    printf '   Claude Code is installed. Ask it for help:\n'
    printf '     cd %s && %s x claude@latest -- claude\n' "$DOTFILES" "$MISE"
  fi
  printf '   Fix the cause, then re-run %s/setup.sh\n' "$DOTFILES"
  exit "$code"
}

# ─── Steps ──────────────────────────────────────────────────────

check_platform() {
  step "Platform"
  [ "$(uname -s)" = "Darwin" ] || stop "macOS only."
  info "$(sw_vers -productName) $(sw_vers -productVersion), $(uname -m)"
}

check_xcode_clt() {
  step "Xcode Command Line Tools (git, make, clang)"
  if xcode-select -p >/dev/null 2>&1; then done_ "installed"; return; fi
  xcode-select --install || true
  stop "Finish the installer window, then re-run this script."
}

install_mise() {
  step "mise"
  if [ -x "$MISE" ]; then
    done_ "installed"
  else
    curl -fsSL https://mise.run | sh
  fi
  local version
  version="$("$MISE" --version 2>/dev/null | grep -Eo '^[0-9]{4}\.[0-9]+\.[0-9]+' | head -1)"
  if [ "$(printf '%s\n%s\n' "$MIN_MISE" "$version" | sort -t. -k1,1n -k2,2n | head -1)" != "$MIN_MISE" ]; then
    info "mise $version is older than $MIN_MISE, updating"
    "$MISE" self-update --yes
  fi
  info "mise $("$MISE" --version 2>/dev/null | grep -Eo '^[0-9]{4}\.[0-9]+\.[0-9]+' | head -1)"
}

install_claude() {
  step "Claude Code (early, so it can help if a later step fails)"
  if [ -d "$MISE_INSTALLS/claude" ]; then done_ "installed"; return; fi
  "$MISE" install claude@latest
}

install_stow() {
  step "GNU stow (built from source with the system perl)"
  if command -v stow >/dev/null 2>&1; then done_ "$(command -v stow)"; return; fi
  command -v perl >/dev/null 2>&1 || stop "perl not found."
  command -v make >/dev/null 2>&1 || stop "make not found (Xcode Command Line Tools)."
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz | tar xz -C "$tmp" --strip-components=1
  (cd "$tmp" && ./configure --prefix="$HOME/.local" >/dev/null && make install >/dev/null)
  rm -rf "$tmp"
  info "$(stow --version | head -1)"
}

# Move real files that would block stow into $BACKUP_DIR. A target that already
# resolves to the package file (our own symlink, or inside a folded dir) is kept.
backup_conflicts() {
  local pkg_dir="$1" rel src target
  while IFS= read -r rel; do
    src="$pkg_dir$rel"
    target="$HOME/$rel"
    if [ "$target" -ef "$src" ]; then continue; fi
    if [ -e "$target" ] || [ -L "$target" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$target" "$BACKUP_DIR/$rel"
      info "moved existing ~/$rel to $BACKUP_DIR/"
    fi
  done < <(cd "$pkg_dir" && find . \( -type f -o -type l \) \
    ! -name .DS_Store ! -name .stow-local-ignore ! -name settings.template.json | sed 's|^\./||')
}

link_packages() {
  step "Link packages into \$HOME (stow)"
  local pkg_dir pkg folding
  for pkg_dir in "$DOTFILES"/*/; do
    pkg="$(basename "$pkg_dir")"
    # claude: link files one by one, so tools that install into ~/.claude/skills
    # etc. (workmux setup) write real files there, not into this repo.
    folding=""
    if [ "$pkg" = "claude" ]; then folding="--no-folding"; fi
    backup_conflicts "$pkg_dir"
    stow --dir="$DOTFILES" --target="$HOME" --restow $folding "$pkg"
    info "$pkg"
  done
}

install_claude_settings() {
  step "Claude Code settings"
  local template="$DOTFILES/claude/.claude/settings.template.json"
  if [ -e "$HOME/.claude/settings.json" ]; then
    done_ "$HOME/.claude/settings.json exists (compare with $template)"
    return
  fi
  cp "$template" "$HOME/.claude/settings.json"
  info "copied settings.template.json to ~/.claude/settings.json"
}

install_tools() {
  step "Tools from ~/.config/mise/config.toml"
  (cd "$HOME" && "$MISE" install)
  eval "$(cd "$HOME" && "$MISE" env -s bash)"
}

install_tmux_plugins() {
  step "tmux plugin manager (TPM)"
  if [ -d "$HOME/.tmux/plugins/tpm" ]; then done_ "installed"; return; fi
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
}

install_font() {
  step "Hack Nerd Font"
  if ls "$HOME"/Library/Fonts/HackNerdFont*.ttf >/dev/null 2>&1; then done_ "installed"; return; fi
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/Hack.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
  mkdir -p "$HOME/Library/Fonts"
  unzip -oq "$tmp/Hack.zip" '*.ttf' -d "$HOME/Library/Fonts"
  rm -rf "$tmp"
}

init_databases() {
  step "Databases (data dirs only; start them by hand)"
  : "${PGDATA:?PGDATA is not set: check [env] in ~/.config/mise/config.toml}"
  if [ -s "$PGDATA/PG_VERSION" ]; then
    done_ "Postgres cluster in $PGDATA"
  else
    initdb --encoding=UTF8 -D "$PGDATA" >/dev/null
    info "Postgres cluster created in $PGDATA"
  fi
  mkdir -p "$HOME/.local/share/redis"
}

finish() {
  step "Done. Manual steps left"
  if [ -d "$BACKUP_DIR" ]; then info "Replaced files were moved to $BACKUP_DIR"; fi
  cat <<EOF
    1. Open a new shell:            exec zsh
    2. Git identity:                create ~/.config/git/config.local (see README)
    3. Log in:                      claude, gh auth login, heroku login, codex login
    4. SSH key for GitHub:          see README ("Logins and SSH key")
    5. tmux plugins:                start tmux, press Ctrl-a I
    6. nvim plugins:                start nvim once (lazy.nvim installs them)
    7. workmux skills and hooks:    workmux setup  (Claude + Codex; needs a terminal)
    8. Start databases when needed:
         pg_ctl -l "\$PGDATA/server.log" start
         redis-server --daemonize yes --dir ~/.local/share/redis
EOF
}

main() {
  mkdir -p "$(dirname "$LOG")"
  exec > >(tee -a "$LOG") 2>&1
  trap on_error ERR
  printf '\n=== dotfiles setup: %s ===\n' "$(date)"

  check_platform
  check_xcode_clt
  install_mise
  install_claude
  install_stow
  link_packages
  install_claude_settings
  install_tools
  install_tmux_plugins
  install_font
  init_databases
  finish
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
