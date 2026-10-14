#!/bin/bash
# Window switcher control, called from Hyprland key bindings and installers.
#
#   switcher.sh next | prev | commit | cancel
#                                      drive the overlay by hand (for testing;
#                                      the Alt+Tab bindings write the command
#                                      file directly from Hyprland)
#   switcher.sh enable | disable       add or remove the Alt+Tab bindings
#   switcher.sh status                 print "enabled" or "disabled"

id=omarchy-switcher
bindings="$HOME/.config/hypr/bindings.lua"
marker="-- omarchy-switcher"

enable_bindings() {
  disable_bindings
  # One guarded line, so a removed plugin can't break the config.
  printf '%s\n' "local f = os.getenv(\"HOME\") .. \"/.config/omarchy/plugins/$id/bindings.lua\"; local h = io.open(f); if h then h:close(); dofile(f) end $marker" >>"$bindings"
}

disable_bindings() {
  [[ -f $bindings ]] && sed -i "/$marker/d" "$bindings"
}

case "${1:-}" in
  next | prev | commit | cancel)
    commands="${XDG_RUNTIME_DIR:-/tmp}/omarchy-switcher"
    echo "$1" >>"$commands"
    ;;
  enable) enable_bindings ;;
  disable) disable_bindings ;;
  status)
    if grep -qF -e "$marker" "$bindings" 2>/dev/null; then echo enabled; else echo disabled; fi
    ;;
  *)
    echo "usage: switcher.sh next | prev | commit | cancel | enable | disable | status" >&2
    exit 1
    ;;
esac
