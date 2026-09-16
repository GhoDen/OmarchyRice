#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

USER_NAME="$(whoami)"

HOME_MANAGER_BACKUP_EXT="backup" nix run ./home#homeConfigurations."${USER_NAME}".activationPackage \
  --extra-experimental-features "nix-command flakes"
