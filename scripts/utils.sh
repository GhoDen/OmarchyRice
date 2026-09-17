#!/usr/bin/env bash

log() { echo -e "\033[1;32m==>\033[0m $*"; }
warn() { echo -e "\033[1;33m!!\033[0m $*"; }

require_omarchy() {
  local command_name
  for command_name in omarchy-pkg-add omarchy-webapp-install omarchy-webapp-remove; do
    command -v "$command_name" >/dev/null 2>&1 || {
      echo "$command_name not found. Is this an Omarchy install?" >&2
      exit 1
    }
  done
}

extract_section() {
  local file="$1" section="$2"
  [[ -f "$file" ]] || return 0
  awk -v want="[$section]" '
    /^\[.*\]$/ { active = ($0 == want); next }
    active && $0 !~ /^[[:space:]]*(#|$)/ { print }
  ' "$file"
}
