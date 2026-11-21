#!/usr/bin/env bash
# Bootstrap a Mac from this repo. This script only gets mise onto the machine
# and links its config; `mise bootstrap` then does the work (packages, dotfile
# links, launchd agents, tools). See the [bootstrap] part of
# mise/.config/mise/config.toml.
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
MIN_MISE="2026.11.10" # `mise bootstrap` with brew packages, dotfile groups and launchd agents
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
  if [ "$(printf '%s\n%s\n' "$MIN_MISE" "$version" | sort -t. -k1,1n -k2,2n -k3,3n | head -1)" != "$MIN_MISE" ]; then
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

# mise never replaces a real file with a link. Move real files that are in the
# way into $BACKUP_DIR. A target that already resolves to the package file (our
# own symlink, or inside a linked dir) is kept. Then remove the dirs this
# leaves empty, so mise can link a whole directory there.
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
    ! -name .DS_Store ! -name settings.template.json | sed 's|^\./||')
  while IFS= read -r rel; do
    target="$HOME/$rel"
    if [ -d "$target" ] && [ ! -L "$target" ]; then rmdir "$target" 2>/dev/null || true; fi
  done < <(cd "$pkg_dir" && find . -mindepth 1 -depth -type d | sed 's|^\./||')
}

# The mise config is in this repo. Link its directory first, so `mise bootstrap`
# reads it. This is the same link that the `mise` dotfile group declares.
link_mise_config() {
  step "Link the mise config (~/.config/mise)"
  local src="$DOTFILES/mise/.config/mise" target="$HOME/.config/mise"
  if [ "$target" -ef "$src" ]; then done_ "linked"; return; fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$BACKUP_DIR/.config"
    mv "$target" "$BACKUP_DIR/.config/mise"
    info "moved existing ~/.config/mise to $BACKUP_DIR/"
  fi
  mkdir -p "$HOME/.config"
  ln -s "$src" "$target"
  info "linked $target to $src"
}

move_conflicts() {
  step "Move files that block the dotfile links"
  local pkg_dir
  for pkg_dir in "$DOTFILES"/*/; do
    backup_conflicts "$pkg_dir"
  done
  if [ -d "$BACKUP_DIR" ]; then info "see $BACKUP_DIR"; else done_ "nothing in the way"; fi
}

# Packages (Homebrew formulae and casks, no `brew` program), git checkouts,
# dotfile links, launchd agents for Postgres and Redis, then every tool.
# The first run asks for the sudo password one time, to create /opt/homebrew.
run_bootstrap() {
  step "mise bootstrap"
  (cd "$HOME" && "$MISE" bootstrap --yes)
  eval "$(cd "$HOME" && "$MISE" env -s bash)"
}

# True when `ssh git@github.com` authenticates. Trusts GitHub's host keys from
# `gh api meta` (fetched over HTTPS), never from an unverified first connection.
github_ssh_works() {
  command -v gh >/dev/null 2>&1 || return 1
  gh auth status >/dev/null 2>&1 || return 1
  if ! ssh-keygen -F github.com >/dev/null 2>&1; then
    mkdir -p -m 700 "$HOME/.ssh"
    gh api meta --jq '.ssh_keys[] | "github.com " + .' >>"$HOME/.ssh/known_hosts"
    info "added GitHub host keys to ~/.ssh/known_hosts"
  fi
  local out
  out="$(ssh -T -o BatchMode=yes -o ConnectTimeout=10 git@github.com 2>&1 || true)"
  case "$out" in *"successfully authenticated"*) return 0 ;; esac
  return 1
}

# The bootstrap clone uses HTTPS (no SSH key yet). Switch to SSH once it works.
use_ssh_remote() {
  step "dotfiles remote over SSH"
  local url
  url="$(git -C "$DOTFILES" remote get-url origin)"
  case "$url" in
    git@github.com:*) done_ "$url"; return ;;
    https://github.com/*) ;;
    *) info "origin is $url, not changed"; return ;;
  esac
  if ! github_ssh_works; then
    info "no working GitHub SSH key yet: do 'gh auth login' (see README), then re-run setup.sh"
    return
  fi
  url="git@github.com:${url#https://github.com/}"
  git -C "$DOTFILES" remote set-url origin "$url"
  info "origin is now $url"
}

finish() {
  step "Done. Manual steps left"
  if [ -d "$BACKUP_DIR" ]; then info "Replaced files were moved to $BACKUP_DIR"; fi
  cat <<EOF
    1. Open Ghostty (installed in /Applications), then a new shell there
    2. Git identity:                create ~/.config/git/config.local (see README)
    3. Log in:                      claude, gh auth login, heroku login, codex login
    4. SSH key for GitHub:          see README ("Logins and SSH key"), then re-run
                                    setup.sh to switch ~/dotfiles to the SSH remote
    5. tmux plugins:                start tmux, press Ctrl-a I
    6. nvim plugins:                start nvim once (lazy.nvim installs them)
    7. workmux skills and hooks:    workmux setup  (Claude + Codex; needs a terminal)
    8. Project tools:               mise trust, in each cloned repo that has a mise config
    Postgres and Redis run now and start at each login (mise bootstrap macos launchd status).
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
  link_mise_config
  move_conflicts
  run_bootstrap
  use_ssh_remote
  finish
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
