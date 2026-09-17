#!/usr/bin/env bash
# shellcheck source=../utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"

remove_webapps() {
  local webapps="$1"

  log "Removing explicitly excluded web apps"
  while IFS= read -r app; do
    [[ -z "$app" ]] && continue
    log "  removing $app"
    omarchy-webapp-remove "$app" || warn "failed (already handled?)"
  done <<< "$webapps"
}

install_webapps() {
  local webapps="$1" name url icon extra

  log "Installing web apps"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    read -r name url icon extra <<< "$line"
    if [[ -z "$name" || -z "$url" || -z "$icon" || -n "$extra" ]]; then
      echo "Invalid web app entry (expected: name url icon-url): $line" >&2
      exit 1
    fi
    log "  installing $name"
    omarchy-webapp-install "$name" "$url" "$icon" || warn "failed (already handled?)"
  done <<< "$webapps"
}

webapps_to_remove="$(extract_section "$PACKAGES_FILE" webapps-remove)"
webapps="$(extract_section "$PACKAGES_FILE" webapps)"
remove_webapps "$webapps_to_remove"
install_webapps "$webapps"
