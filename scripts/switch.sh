#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

USER_NAME="$(whoami)"

exec nix run ./home#homeConfigurations."${USER_NAME}".activationPackage \
  --extra-experimental-features "nix-command flakes" -- -b backup
