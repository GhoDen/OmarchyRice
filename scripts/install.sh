#!/usr/bin/env bash
# Omarchy rice install script — idempotent, self-pruning.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="$REPO_DIR/home"
PACKAGES_FILE="$HOME_DIR/packages.txt"
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

extract_section() {
  local file="$1" section="$2"
  [[ -f "$file" ]] || return 0
  awk -v want="[$section]" '
    /^\[.*\]$/ { active = ($0 == want); next }
    active && $0 !~ /^[[:space:]]*(#|$)/ { print }
  ' "$file"
}

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

configure_biopass() {
  log "Configuring Biopass PAM and polkit integration"
  "$REPO_DIR/scripts/biopass/configure-biopass.sh"
}

download_biopass_models() {
  log "Downloading Biopass models"
  "$REPO_DIR/scripts/biopass/download-biopass-models.sh"
}

configure_keyd() {
  log "Configuring keyd"
  "$REPO_DIR/scripts/keyd/setup.sh"
}

update_flake_inputs() {
  log "Updating flake inputs to latest (bleeding-edge mode)"
  nix flake update --flake "$HOME_DIR" \
    --extra-experimental-features "nix-command flakes"
}

main() {
  require_omarchy
  local pacman_packages aur_packages excluded_packages
  pacman_packages="$(extract_section "$PACKAGES_FILE" pacman)"
  aur_packages="$(extract_section "$PACKAGES_FILE" aur)"
  excluded_packages="$(extract_section "$PACKAGES_FILE" remove)"
  validate_package_lists "$pacman_packages" "$excluded_packages"
  validate_package_lists "$aur_packages" "$excluded_packages"
  sync_packages "$pacman_packages" "$PACMAN_STATE" omarchy-pkg-add "pacman"
  sync_packages "$aur_packages" "$AUR_STATE" omarchy-pkg-aur-add "AUR"
  drop_packages "$excluded_packages"
  install_nix
  update_flake_inputs
  apply_home_manager
  configure_biopass
  download_biopass_models
  configure_keyd
  log "Done."
}

main "$@"
