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

# ─── Homebrew & PATH ─────────────────────────────────────────────
eval "$(/opt/homebrew/bin/brew shellenv)"
export QLTY_INSTALL="$HOME/.qlty"
export PATH="/opt/homebrew/opt/postgresql@18/bin:$HOME/.local/bin:$QLTY_INSTALL/bin:$PATH"

# ─── Misc env ────────────────────────────────────────────────────
export GPG_TTY=$(tty)
export SSL_CERT_FILE=/opt/homebrew/etc/ca-certificates/cert.pem

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

[[ -r "/opt/homebrew/share/zsh/site-functions/_qlty" ]] && \
  source "/opt/homebrew/share/zsh/site-functions/_qlty"

# ─── Prompt ──────────────────────────────────────────────────────
# Tokyo Night accents. Prompt char is red as root or after failure, magenta otherwise.
PROMPT='$(ssh_prompt_info)%F{#7aa2f7} %~%f$(git_prompt_info) %(!.%F{#f7768e}.%(?.%F{#bb9af7}.%F{#f7768e}))❯%f '
RPROMPT=''

# ─── Tool hooks ──────────────────────────────────────────────────
eval "$(direnv hook zsh)"
eval "$(~/.local/bin/mise activate zsh)"
eval "$(workmux completions zsh)"
