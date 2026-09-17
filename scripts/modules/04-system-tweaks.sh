#!/usr/bin/env bash
# shellcheck source=../utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"

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

configure_biopass
download_biopass_models
configure_keyd
