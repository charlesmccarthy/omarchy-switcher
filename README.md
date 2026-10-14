# Omarchy Window Switcher

A macOS- and Windows-style Alt+Tab for [Omarchy](https://omarchy.org): hold Alt and tap Tab
to step through **live previews** of your windows, then let go to switch.

![Window switcher](screenshots/switcher.png)

It's an Omarchy shell plugin built from the same components as Omarchy's own overlays, so
it follows your theme, font and corner style.

## Install

```bash
git clone https://github.com/charlesmccarthy/omarchy-switcher ~/code/omarchy-switcher
~/code/omarchy-switcher/install.sh
```

## Use

| Key | Action |
|---|---|
| Alt + Tab | Open the switcher on the previous window; tap Tab again to move on |
| Alt + Shift + Tab, ← → | Move backwards / forwards |
| Release Alt | Switch to the selected window |
| Quick Alt + Tab tap | Jump straight to the previous window, no overlay |
| Click a preview | Switch to it |
| Esc | Cancel |

Windows on every workspace are listed, most recently used first; choosing one on another
workspace takes you there. Floating windows are brought to the front.

## How it works

- `install.sh` copies `plugin/` to `~/.config/omarchy/plugins/omarchy-switcher/`, enables
  it, and adds a marked block to `~/.config/hypr/bindings.lua` that replaces Omarchy's
  Alt+Tab bindings. Releasing Alt is caught with a Hyprland release binding.
- Previews are captured with Quickshell's `ScreencopyView` from Hyprland's toplevel list.
  Windows that haven't been drawn since the shell started show their app icon instead.
- `plugin/switcher.sh enable | disable | status` turns the bindings on and off; the
  [Omarchy Settings](https://github.com/charlesmccarthy/omarchy-settings) app uses it for
  its Windows → Window switcher toggle.

## Uninstall

```bash
~/code/omarchy-switcher/uninstall.sh
```

This removes the plugin and restores Omarchy's default Alt+Tab.

## License

MIT
