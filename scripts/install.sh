#!/usr/bin/env bash
# Omarchy rice install script — idempotent, safe to re-run.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$REPO_DIR/home"
PACMAN_LIST="$REPO_DIR/packages/pacman.txt"
AUR_LIST="$REPO_DIR/packages/aur.txt"

log() { echo -e "\033[1;32m==>\033[0m $*"; }

require_omarchy() {
  command -v omarchy-pkg-add >/dev/null 2>&1 || {
    echo "omarchy-pkg-add not found. Is this an Omarchy install?" >&2
    exit 1
  }
}

install_pacman_packages() {
  [[ -f "$PACMAN_LIST" ]] || return 0
  log "Installing pacman packages via omarchy-pkg-add"
  while read -r pkg; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    pacman -Qi "$pkg" &>/dev/null && { log "  $pkg already installed, skipping"; continue; }
    log "  installing $pkg"
    omarchy-pkg-add "$pkg"
  done < "$PACMAN_LIST"
}

install_aur_packages() {
  [[ -f "$AUR_LIST" ]] || return 0
  log "Installing AUR packages via omarchy-pkg-aur-add"
  while read -r pkg; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    pacman -Qi "$pkg" &>/dev/null && { log "  $pkg already installed, skipping"; continue; }
    log "  installing $pkg"
    omarchy-pkg-aur-add "$pkg"
  done < "$AUR_LIST"
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
  local flake_target
  flake_target="$(whoami)@$(hostname)"

  if command -v home-manager >/dev/null 2>&1; then
    home-manager switch --flake "$HOME_DIR#$flake_target"
  else
    log "  home-manager not on PATH yet, bootstrapping via nix run"
    nix run home-manager/master -- switch --flake "$HOME_DIR#$flake_target" \
      --extra-experimental-features "nix-command flakes"
  fi
}

main() {
  require_omarchy
  install_pacman_packages
  install_aur_packages
  install_nix
  apply_home_manager
  log "Done."
}

main "$@"
