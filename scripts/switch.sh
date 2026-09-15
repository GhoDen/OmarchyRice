#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

USER_NAME="$(whoami)"
SYSTEM="$(nix eval --impure --expr 'builtins.currentSystem' --raw)"

exec nix run home-manager/master -- switch \
  --flake "./home#${USER_NAME}" \
  --override-input 'flake-arg:user'    "str:${USER_NAME}" \
  --override-input 'flake-arg:system'  "str:${SYSTEM}" \
  --extra-experimental-features "nix-command flakes"
