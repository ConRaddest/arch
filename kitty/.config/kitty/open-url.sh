#!/usr/bin/env bash
url="$1"
if [[ "$url" == file://* ]]; then
  code --goto "${url#file://}"
else
  xdg-open "$url"
fi
