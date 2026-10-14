#!/bin/bash
# Remove the window switcher and restore Omarchy's default Alt+Tab.
set -euo pipefail

ID="omarchy-switcher"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$ID"

if [[ -x $PLUGIN_DIR/switcher.sh ]]; then
  "$PLUGIN_DIR/switcher.sh" disable
else
  sed -i "/-- $ID/d" "$HOME/.config/hypr/bindings.lua"
fi
omarchy plugin disable "$ID" >/dev/null 2>&1 || true
rm -rf "$PLUGIN_DIR"
hyprctl reload >/dev/null
echo "Window switcher removed; Alt+Tab is back to Omarchy's default."
