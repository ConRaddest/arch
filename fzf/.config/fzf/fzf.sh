# fzf configuration ported from ~/OS/home/fzf.nix
# Tokyo Night colors from ~/OS/themes/tokyo-night/theme.nix

export FZF_DEFAULT_OPTS="--height 95% --layout=default --info=default"
export FZF_CTRL_T_OPTS='--preview "([[ -f {} ]] && (bat --style=numbers --color=always {} 2>/dev/null || sed -n \"1,120p\" {})) || ([[ -d {} ]] && (eza -la --color=always {} 2>/dev/null || ls -la {}))"'
export FZF_ALT_C_OPTS='--preview "eza -la --color=always {} 2>/dev/null || ls -la {}"'
export FZF_COMPLETION_OPTS='--info=default'

# Previews for **<TAB> completions
_fzf_comprun() {
  local command=$1
  shift
  case "$command" in
    cd)           fzf --preview 'eza -la --color=always {} 2>/dev/null || ls -la {}' "$@" ;;
    export|unset) fzf --preview 'eval echo \${}' "$@" ;;
    ssh)          fzf --preview 'dig {} 2>/dev/null || host {} 2>/dev/null' "$@" ;;
    *)            fzf --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} 2>/dev/null || sed -n "1,120p" {})) || ([[ -d {} ]] && (eza -la --color=always {} 2>/dev/null || ls -la {}))' "$@" ;;
  esac
}
