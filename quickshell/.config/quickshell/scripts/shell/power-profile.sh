#!/usr/bin/env bash
set -euo pipefail

selection=$(printf 'performance\nbalanced\npower-saver\n' \
  | fzf \
      --prompt='> ' \
      --height=35% \
      --layout=reverse \
      --no-preview \
      --no-info \
      --no-header)

[ -n "${selection:-}" ] || exit 0

powerprofilesctl set "$selection"
