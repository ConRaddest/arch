# Zsh config

# User scripts
export PATH="$HOME/.local/bin:$PATH"
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt append_history share_history hist_ignore_dups hist_ignore_space

# Completion / autocomplete
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# FZF-powered completion with previews
if command -v fzf >/dev/null 2>&1; then
  [ -f "$HOME/.config/fzf/fzf.sh" ] && source "$HOME/.config/fzf/fzf.sh"
  [ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh 2>/dev/null
  [ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh 2>/dev/null
fi

# Aliases
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -la'
  alias la='eza -a'
fi

# Use zoxide for cd
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# Better prompt if starship is installed
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Useful defaults
autoload -Uz colors && colors
setopt auto_cd correct interactive_comments
bindkey -e
