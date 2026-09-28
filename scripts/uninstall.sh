#!/usr/bin/env bash
# Remove the parts of the system owned by this Omarchy rice repository.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$REPO_DIR/.state"
PACMAN_STATE="$STATE_DIR/pacman-managed.txt"
AUR_STATE="$STATE_DIR/aur-managed.txt"
WEBAPP_STATE="$STATE_DIR/webapps-managed.txt"
UPDATE_HOOK="$HOME/.config/omarchy/hooks/post-update.d/omarchyrice-install.hook"

# shellcheck source=utils.sh
source "$REPO_DIR/scripts/utils.sh"

remove_packages() {
  local state_file="$1" label="$2" pkg

  [[ -f "$state_file" ]] || return 0
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if pacman -Qi "$pkg" &>/dev/null; then
      log "Removing managed $label package: $pkg"
      omarchy-pkg-drop "$pkg" || warn "Could not remove $pkg"
    fi
  done < "$state_file"
}

remove_webapps() {
  local app

  [[ -f "$WEBAPP_STATE" ]] || return 0
  while IFS= read -r app; do
    [[ -z "$app" ]] || {
      log "Removing managed web app: $app"
      omarchy-webapp-remove "$app" || warn "Could not remove $app"
    }
  done < "$WEBAPP_STATE"
}

remove_update_hook() {
  if [[ -f "$UPDATE_HOOK" ]] && grep -Fq "$REPO_DIR/scripts/install.sh" "$UPDATE_HOOK"; then
    rm "$UPDATE_HOOK"
    log "Removed Omarchy post-update hook"
  fi
}

remove_repo_integrations() {
  if [[ -L /etc/keyd/default.conf ]] && [[ "$(readlink /etc/keyd/default.conf)" == "$REPO_DIR/dotfiles/keyd/default.conf" ]]; then
    sudo rm /etc/keyd/default.conf
    sudo systemctl disable --now keyd.service || true
    log "Removed keyd integration"
  fi

  if getent group libvirt >/dev/null 2>&1 && id -nG "$USER" | tr ' ' '\n' | grep -Fxq libvirt; then
    sudo gpasswd --delete "$USER" libvirt || true
    log "Removed $USER from libvirt group"
  fi

  if systemctl is-enabled --quiet libvirtd.service 2>/dev/null; then
    sudo systemctl disable --now libvirtd.service
    log "Disabled libvirt integration"
  fi
}

require_omarchy
remove_packages "$PACMAN_STATE" pacman
remove_packages "$AUR_STATE" AUR
remove_webapps
remove_update_hook
remove_repo_integrations

rm -rf "$STATE_DIR"
log "Removed repository state"
log "Home Manager generations and linked files were left intact; remove them manually if desired."
log "Done."
