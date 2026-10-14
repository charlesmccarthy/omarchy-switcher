# omarchy-switcher

Alt+Tab window switcher with live previews, as an Omarchy shell (Quickshell/QML) overlay plugin
(id `omarchy-switcher`). Sister project: ~/code/omarchy-settings (its CLAUDE.md has the shared
ground rules: never edit /usr/share/omarchy, logs via `qs log -p /usr/share/omarchy/shell`).

- Runs as a shell *service* (always loaded). plugin/bindings.lua (loaded by one guarded line in
  ~/.config/hypr/bindings.lua, managed by switcher.sh enable|disable|status) appends steps
  (next/prev/commit) to $XDG_RUNTIME_DIR/omarchy-switcher; Switcher.qml streams it with
  `tail -F` (FileView's watcher dropped quick consecutive writes).
- Finishing: a 15 ms hl.timer polls hl.is_key_down("Alt_L"/"Alt_R") during a switch. Hyprland
  release binds miss quick taps (Tab still down as Alt comes up) and key-ups that go to the
  focused overlay — don't go back to them.
- Focus the target only after the overlay unmaps (pendingFocus); otherwise Hyprland's focus
  restore on layer unmap undoes the switch. Hover selection is gated by PointerMoveGate.
- Test: `switcher.sh next; sleep 0.1; switcher.sh commit` and check `hyprctl activewindow`;
  sweep the sleep from 0.01 to 0.6 in both directions. After copying changes run
  `omarchy restart shell`.
