#!/usr/bin/env bash
# Omarchy rice install script - idempotent, self-pruning.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="$REPO_DIR/home"
PACKAGES_FILE="$HOME_DIR/packages.txt"
STATE_DIR="$REPO_DIR/.state"
PACMAN_STATE="$STATE_DIR/pacman-managed.txt"
AUR_STATE="$STATE_DIR/aur-managed.txt"

# shellcheck source=utils.sh
source "$REPO_DIR/scripts/utils.sh"

for module in "$REPO_DIR"/scripts/modules/*.sh; do
  log "Running $(basename "$module")"
  # shellcheck source=/dev/null
  source "$module"
done

log "Done."
