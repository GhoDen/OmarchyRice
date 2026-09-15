#!/usr/bin/env bash
# Omarchy rice install script — idempotent, self-pruning.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="$REPO_DIR/home"
PACMAN_LIST="$REPO_DIR/packages/pacman.txt"
AUR_LIST="$REPO_DIR/packages/aur.txt"
STATE_DIR="$REPO_DIR/.state"
PACMAN_STATE="$STATE_DIR/pacman-managed.txt"
AUR_STATE="$STATE_DIR/aur-managed.txt"

log() { echo -e "\033[1;32m==>\033[0m $*"; }
warn() { echo -e "\033[1;33m!!\033[0m $*"; }

require_omarchy() {
  command -v omarchy-pkg-add >/dev/null 2>&1 || {
    echo "omarchy-pkg-add not found. Is this an Omarchy install?" >&2
    exit 1
  }
}

# Strip comments/blanks/trailing whitespace, one package per line.
filter_list() {
  [[ -f "$1" ]] || return 0
  grep -vE '^\s*(#|$)' "$1" | sed 's/[[:space:]]*$//' || true
}

sync_packages() {
  local list_file="$1" state_file="$2" add_cmd="$3" label="$4"
  mkdir -p "$STATE_DIR"

  local desired
  desired="$(filter_list "$list_file")"

  # --- install ---
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

  # --- prune: only things THIS repo installed before, that are now gone from the file ---
  if [[ -f "$state_file" ]]; then
    local previously_managed to_remove
    previously_managed="$(cat "$state_file")"
    to_remove="$(comm -23 <(sort -u <<< "$previously_managed") <(sort -u <<< "$desired") | grep -v '^$' || true)"

    if [[ -n "$to_remove" ]]; then
      while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        if pacman -Qi "$pkg" &>/dev/null; then
          log "  removing $pkg (dropped from $label list)"
          omarchy-pkg-remove "$pkg" || warn "  failed to remove $pkg (in use by something else? left installed)"
        fi
      done <<< "$to_remove"
    fi
  fi

  # --- update state to reflect current desired set ---
  echo "$desired" > "$state_file"
}

install_nix() {
  if command -v nix >/dev/null 2>&1; then
    log "Nix already installed, skipping"
    return 0
  fi
  log "Installing Nix (Determinate Systems installer)"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
    sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
}

apply_home_manager() {
  log "Applying Home Manager flake from $HOME_DIR"
  "$REPO_DIR/scripts/switch.sh"
}

main() {
  require_omarchy
  sync_packages "$PACMAN_LIST" "$PACMAN_STATE" omarchy-pkg-add "pacman"
  sync_packages "$AUR_LIST" "$AUR_STATE" omarchy-pkg-aur-add "AUR"
  install_nix
  apply_home_manager
  log "Done."
}

main "$@"
