#!/usr/bin/env bash
# Omarchy rice install script - idempotent, self-pruning.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="$REPO_DIR/home"
PACKAGES_FILE="$HOME_DIR/packages.txt"
STATE_DIR="$REPO_DIR/.state"
PACMAN_STATE="$STATE_DIR/pacman-managed.txt"
AUR_STATE="$STATE_DIR/aur-managed.txt"
WEBAPP_STATE="$STATE_DIR/webapps-managed.txt"
UPDATE_HOOK="$HOME/.config/omarchy/hooks/post-update.d/omarchyrice-install.hook"

# shellcheck source=utils.sh
source "$REPO_DIR/scripts/utils.sh"

install_update_hook() {
  command -v omarchy >/dev/null 2>&1 || return 0

  mkdir -p "$(dirname "$UPDATE_HOOK")"
  cat > "$UPDATE_HOOK" <<EOF
#!/usr/bin/env bash
exec "$REPO_DIR/scripts/install.sh"
EOF
  chmod 755 "$UPDATE_HOOK"
  log "Installed Omarchy post-update hook"
}

install_update_hook

for module in "$REPO_DIR"/scripts/modules/*.sh; do
  log "Running $(basename "$module")"
  # shellcheck source=/dev/null
  source "$module"
done

log "Done."
