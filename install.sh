#!/bin/bash
# Install the Omarchy window switcher and point Alt+Tab at it.
# Safe to run again.
set -euo pipefail

ID="omarchy-switcher"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/plugin"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$ID"

echo "Copying plugin to $PLUGIN_DIR"
mkdir -p "$PLUGIN_DIR"
rm -rf "${PLUGIN_DIR:?}"/*
cp -r "$SRC"/. "$PLUGIN_DIR"/
omarchy-plugin-validate "$PLUGIN_DIR"

echo "Enabling plugin"
omarchy-shell shell rescanPlugins >/dev/null
for _ in {1..20}; do
  if omarchy-shell shell listPlugins 2>/dev/null | grep -q "\"$ID\""; then break; fi
  sleep 0.25
done
omarchy plugin enable "$ID" >/dev/null

echo "Binding Alt+Tab"
cp ~/.config/hypr/bindings.lua ~/.config/hypr/bindings.lua.bak."$ID".$(date +%s)
"$PLUGIN_DIR/switcher.sh" enable

hyprctl reload >/dev/null
errors=$(hyprctl configerrors)
if [[ -n ${errors//[[:space:]]/} ]]; then
  echo "Hyprland reported config errors:" >&2
  echo "$errors" >&2
  exit 1
fi

echo "Done. Hold Alt and tap Tab to switch windows."
