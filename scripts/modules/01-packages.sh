#!/usr/bin/env bash
# shellcheck source=../utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"

sync_packages() {
  local desired="$1" state_file="$2" add_cmd="$3" label="$4"
  mkdir -p "$STATE_DIR"

  log "Syncing $label packages"
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if pacman -Qi "$pkg" &>/dev/null; then
      log "  $pkg already installed, skipping"
    else
      log "  installing $pkg"
      "$add_cmd" "$pkg"
    fi
  done <<< "$desired"

  if [[ -f "$state_file" ]]; then
    local previously_managed to_remove
    previously_managed="$(cat "$state_file")"
    to_remove="$(comm -23 <(sort -u <<< "$previously_managed") <(sort -u <<< "$desired") | grep -v '^$' || true)"
    if [[ -n "$to_remove" ]]; then
      while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        if pacman -Qi "$pkg" &>/dev/null; then
          log "  removing $pkg (dropped from $label list)"
          omarchy-pkg-drop "$pkg" || warn "  failed to remove $pkg (in use by something else? left installed)"
        fi
      done <<< "$to_remove"
    fi
  fi

  echo "$desired" > "$state_file"
}

drop_packages() {
  local packages="$1"

  log "Dropping explicitly excluded packages"
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if pacman -Qi "$pkg" &>/dev/null; then
      log "  removing $pkg (explicitly excluded)"
      omarchy-pkg-drop "$pkg" || warn "  failed to remove $pkg (in use by something else? left installed)"
    fi
  done <<< "$packages"
}

validate_package_lists() {
  local desired="$1" excluded="$2" overlap
  overlap="$(comm -12 <(sort -u <<< "$desired") <(sort -u <<< "$excluded") | grep -v '^$' || true)"
  if [[ -n "$overlap" ]]; then
    echo "Package cannot be both installed and excluded:" >&2
    echo "$overlap" >&2
    exit 1
  fi
}

require_omarchy
pacman_packages="$(extract_section "$PACKAGES_FILE" pacman)"
aur_packages="$(extract_section "$PACKAGES_FILE" aur)"
excluded_packages="$(extract_section "$PACKAGES_FILE" remove)"
validate_package_lists "$pacman_packages" "$excluded_packages"
validate_package_lists "$aur_packages" "$excluded_packages"
sync_packages "$pacman_packages" "$PACMAN_STATE" omarchy-pkg-add "pacman"
sync_packages "$aur_packages" "$AUR_STATE" omarchy-pkg-aur-add "AUR"
drop_packages "$excluded_packages"
