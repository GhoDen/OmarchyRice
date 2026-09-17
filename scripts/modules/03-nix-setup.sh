#!/usr/bin/env bash
# shellcheck source=../utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"

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

update_flake_inputs() {
  log "Updating flake inputs to latest (bleeding-edge mode)"
  nix flake update --flake "$HOME_DIR" \
    --extra-experimental-features "nix-command flakes"
}

apply_home_manager() {
  log "Applying Home Manager flake from $HOME_DIR"
  "$REPO_DIR/scripts/switch.sh"
}

install_nix
update_flake_inputs
apply_home_manager
