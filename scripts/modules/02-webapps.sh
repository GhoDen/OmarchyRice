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

validate_webapps() {
  local webapps="$1" line name url icon extra

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    read -r name url icon extra <<< "$line"
    if [[ -z "$name" || -z "$url" || -z "$icon" || -n "$extra" ]]; then
      echo "Invalid web app entry (expected: name url icon-url): $line" >&2
      exit 1
    fi
  done <<< "$webapps"
}

prune_webapps() {
  local webapps="$1" managed_names desired_names app remaining

  [[ -f "$WEBAPP_STATE" ]] || return 0
  managed_names="$(<"$WEBAPP_STATE")"
  desired_names="$(awk '{ if ($1 != "") print $1 }' <<< "$webapps")"
  remaining="$managed_names"

  while IFS= read -r app; do
    [[ -z "$app" ]] && continue
    if printf '%s\n' "$desired_names" | grep -Fqx "$app"; then
      continue
    fi
    log "  removing $app (dropped from webapps list)"
    if omarchy-webapp-remove "$app"; then
      remaining="$(printf '%s\n' "$remaining" | awk -v app="$app" '$0 != app')"
    else
      warn "failed to remove $app"
    fi
  done <<< "$managed_names"

  printf '%s\n' "$remaining" | awk 'NF && !seen[$0]++' > "$WEBAPP_STATE"
}

install_webapps() {
  local webapps="$1" name url icon extra managed_names

  mkdir -p "$STATE_DIR"
  managed_names=""
  [[ -f "$WEBAPP_STATE" ]] && managed_names="$(<"$WEBAPP_STATE")"
  log "Installing web apps"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    read -r name url icon extra <<< "$line"
    if printf '%s\n' "$managed_names" | grep -Fqx "$name"; then
      log "  $name already managed, skipping"
      continue
    fi
    log "  installing $name"
    if omarchy-webapp-install "$name" "$url" "$icon"; then
      managed_names="${managed_names}${managed_names:+$'\n'}$name"
    else
      warn "failed to install $name"
    fi
  done <<< "$webapps"

  printf '%s\n' "$managed_names" | awk 'NF && !seen[$0]++' > "$WEBAPP_STATE"
}

webapps_to_remove="$(extract_section "$PACKAGES_FILE" webapps-remove)"
webapps="$(extract_section "$PACKAGES_FILE" webapps)"
validate_webapps "$webapps"
remove_webapps "$webapps_to_remove"
prune_webapps "$webapps"
install_webapps "$webapps"
