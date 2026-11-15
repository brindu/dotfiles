# ─── Colors ──────────────────────────────────────────────────────
autoload -U colors && colors
export CLICOLOR=1

# ─── Shell options ───────────────────────────────────────────────
setopt prompt_subst
setopt extended_glob

# ─── History ─────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt extended_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
setopt share_history

# ─── Editor / keybindings ────────────────────────────────────────
export VISUAL=nvim
export EDITOR=$VISUAL
bindkey "^R" history-incremental-search-backward

# ─── Aliases ─────────────────────────────────────────────────────
[[ -r "$HOME/.aliases" ]] && source "$HOME/.aliases"

# ─── PATH ────────────────────────────────────────────────────────
# Homebrew is optional: only for what mise cannot install. Load it if present.
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"

# ─── Misc env ────────────────────────────────────────────────────
# CA bundle for OpenSSL-based tools (Ruby, Python, …). macOS ships and updates it.
export SSL_CERT_FILE=/etc/ssl/cert.pem

# ─── Completion (full rebuild at most once per day) ──────────────
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qNmh+24) ]]; then
  compinit
else
  compinit -C
fi

# Custom shell functions (must follow compinit — `g` calls compdef)
for fn in ~/.zsh/functions/*(N); do
  source "$fn"
done

# ─── Prompt ──────────────────────────────────────────────────────
# Tokyo Night accents. Prompt char is red as root or after failure, magenta otherwise.
PROMPT='$(ssh_prompt_info)%F{#7aa2f7} $(pwd_prompt_info)%f$(git_prompt_info) %(!.%F{#f7768e}.%(?.%F{#bb9af7}.%F{#f7768e}))❯%f '
RPROMPT=''

# ─── Tool hooks ──────────────────────────────────────────────────
# mise first: direnv and workmux are mise-installed and must be on PATH.
[[ -x ~/.local/bin/mise ]] && eval "$(~/.local/bin/mise activate zsh)"
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
(( $+commands[workmux] )) && eval "$(workmux completions zsh)"
