#!/usr/bin/env bash
# shellcheck source=../utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"

configure_keyd() {
  log "Configuring keyd"
  "$REPO_DIR/scripts/keyd/setup.sh"
}

configure_keyd
