#!/bin/bash
THEME_URL="https://github.com/ejuro/omarchy-thunderstruck-theme.git"
THEME_DIR="$HOME/.config/omarchy/themes/omarchy-thunderstruck-theme"

if [ ! -d "$THEME_DIR" ]; then
  echo "Installing Thunderstruck theme..."
  omarchy theme install "$THEME_URL"
else
  echo "Updating Thunderstruck theme..."
  git -C "$THEME_DIR" pull
fi
