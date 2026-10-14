# omarchy-switcher

Alt+Tab window switcher with live previews, as an Omarchy shell (Quickshell/QML) overlay plugin
(id `omarchy-switcher`). Sister project: ~/code/omarchy-settings (its CLAUDE.md has the shared
ground rules: never edit /usr/share/omarchy, logs via `qs log -p /usr/share/omarchy/shell`).

- Bindings live in a block in ~/.config/hypr/bindings.lua marked `-- omarchy-switcher`, managed
  by plugin/switcher.sh enable|disable|status. ALT+TAB → next, ALT+SHIFT+TAB → prev,
  ALT+ALT_L release → commit.
- switcher.sh drives the overlay via `omarchy-shell shell call omarchy-switcher <method>`,
  falling back to `summon` when the overlay isn't loaded yet.
- A commit arriving before the window list loads (quick tap) is queued; one arriving before
  the overlay opened is remembered for 400 ms.
- After copying changes, run `omarchy restart shell` (hot reload doesn't re-create
  keepLoaded overlays). Test: `switcher.sh next; switcher.sh commit`.
