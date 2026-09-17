#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

sudo ln -sf "$REPO_DIR/dotfiles/keyd/default.conf" /etc/keyd/default.conf
sudo systemctl enable --now keyd.service
