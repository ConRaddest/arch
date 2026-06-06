# Minimal bash config. Main shell config lives in ~/.zshrc.

[[ $- != *i* ]] && return

export PATH="$HOME/.local/bin:$PATH"
