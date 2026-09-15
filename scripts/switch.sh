#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

USER_NAME="$(whoami)"

exec nix run home-manager/master -- switch \
  --flake "./home#${USER_NAME}" \
  --extra-experimental-features "nix-command flakes"
