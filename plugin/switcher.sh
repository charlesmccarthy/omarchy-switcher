#!/bin/bash
# Window switcher control, called from Hyprland key bindings and installers.
#
#   switcher.sh next | prev | commit   drive the overlay (Alt+Tab bindings)
#   switcher.sh enable | disable       add or remove the Alt+Tab bindings
#   switcher.sh status                 print "enabled" or "disabled"

id=omarchy-switcher
bindings="$HOME/.config/hypr/bindings.lua"
marker="-- omarchy-switcher"
self="$HOME/.config/omarchy/plugins/$id/switcher.sh"

enable_bindings() {
  disable_bindings
  cat >>"$bindings" <<LUA
$marker: Alt+Tab window switcher (remove with: switcher.sh disable)
hl.unbind("ALT + TAB") $marker
hl.unbind("ALT + SHIFT + TAB") $marker
o.bind("ALT + TAB", "Switch windows", '"$self" next') $marker
o.bind("ALT + SHIFT + TAB", "Switch windows backwards", '"$self" prev') $marker
o.bind("ALT + ALT_L", "Finish switching windows", '"$self" commit', { release = true }) $marker
LUA
}

disable_bindings() {
  [[ -f $bindings ]] && sed -i "/$marker/d" "$bindings"
}

case "${1:-}" in
  next | prev | commit)
    # The first call after the shell starts may find the overlay not yet
    # loaded; summoning it loads it and delivers the step.
    result=$(omarchy-shell shell call "$id" "$1" "" 2>/dev/null)
    if [[ $result == "unknown" && $1 != "commit" ]]; then
      omarchy-shell shell summon "$id" "{\"step\":\"$1\"}" >/dev/null
    fi
    ;;
  enable) enable_bindings ;;
  disable) disable_bindings ;;
  status)
    if grep -qF -e "$marker" "$bindings" 2>/dev/null; then echo enabled; else echo disabled; fi
    ;;
  *)
    echo "usage: switcher.sh next | prev | commit | enable | disable | status" >&2
    exit 1
    ;;
esac
