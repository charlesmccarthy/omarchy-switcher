import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.Commons
import qs.Ui

// Alt+Tab window switcher with live previews, like macOS and Windows.
//
// Hyprland bindings (written by the Settings app) drive it through
// switcher.sh: Alt+Tab calls next(), Alt+Shift+Tab prev(), and releasing Alt
// calls commit(). A quick tap switches to the previous window without the
// overlay ever appearing; holding Alt shows it after a short delay.
Item {
  id: root

  property var shell: null
  property var manifest: null

  // `opened` means a switch is in progress (Alt held); `shown` means the
  // overlay is on screen, which only happens once Alt has been held briefly.
  property bool opened: false
  property bool shown: false
  property var windows: []
  property int selected: 0
  property int pendingSteps: 0
  property bool loading: false
  property bool commitPending: false
  property real lastCommitAt: 0

  readonly property string ownId: (manifest && manifest.id) || "omarchy-switcher"

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property string fontFamily: Style.font.menuFamily
  readonly property int tileWidth: Style.space(232)
  readonly property int previewHeight: Style.space(138)
  readonly property int tileHeight: previewHeight + Style.space(52)
  readonly property int tileGap: Style.spacing.lg
  readonly property int padding: Style.spacing.panelPadding

  // ---- host contract (summon/hide) ---------------------------------------
  function open(payloadJson) {
    var payload = {}
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) {}
    if (!root.opened) root.begin()
    if (payload.step === "next") root.step(1)
    else if (payload.step === "prev") root.step(-1)
  }

  function close() {
    root.opened = false
    root.shown = false
  }

  // ---- IPC entry points (switcher.sh) ------------------------------------
  function next(arg) { root.ensureOpen(); root.step(1); return "ok" }
  function prev(arg) { root.ensureOpen(); root.step(-1); return "ok" }

  function commit(arg) {
    if (!root.opened) {
      // Alt released before the opening call arrived (a very quick tap).
      root.lastCommitAt = Date.now()
      return "ok"
    }
    if (root.loading) { root.commitPending = true; return "ok" }
    var target = root.windows[root.selected]
    if (target && root.selected !== 0) {
      var focus = 'hl.dsp.focus({ window = "address:' + target.address + '" })'
      Quickshell.execDetached(["sh", "-c",
        "hyprctl dispatch " + Util.shellQuote(focus) + " && hyprctl dispatch 'hl.dsp.window.bring_to_top()'"])
    }
    root.finish()
    return "ok"
  }

  function cancel() {
    root.finish()
  }

  // ---- state -------------------------------------------------------------
  function ensureOpen() {
    if (root.opened) return
    root.begin()
    // Keep the host's open state in sync so its toggle/hide behave.
    if (root.shell && typeof root.shell.summon === "function") root.shell.summon(root.ownId, "{}")
  }

  function begin() {
    root.opened = true
    root.shown = false
    root.windows = []
    root.selected = 0
    root.pendingSteps = 0
    root.loading = true
    root.commitPending = Date.now() - root.lastCommitAt < 400
    if (typeof Hyprland.refreshToplevels === "function") Hyprland.refreshToplevels()
    clientsProc.running = true
    showTimer.restart()
  }

  function finish() {
    root.opened = false
    root.shown = false
    showTimer.stop()
    if (root.shell && typeof root.shell.hide === "function") root.shell.hide(root.ownId)
  }

  function step(delta) {
    if (root.loading) { root.pendingSteps += delta; return }
    var n = root.windows.length
    if (n === 0) return
    root.selected = ((root.selected + delta) % n + n) % n
  }

  function loadClients(text) {
    var list = []
    try { list = JSON.parse(text) } catch (e) {}
    list = list.filter(function(c) { return c.mapped && !c.hidden })
    list.sort(function(a, b) { return a.focusHistoryID - b.focusHistoryID })
    root.windows = list.map(function(c) {
      return {
        address: c.address,
        title: c.title || c.class,
        appClass: c.class,
        workspace: c.workspace ? c.workspace.name : "",
        icon: root.iconFor(c.class)
      }
    })
    root.loading = false
    if (root.windows.length === 0) { root.finish(); return }
    var steps = root.pendingSteps
    root.pendingSteps = 0
    root.step(steps)
    if (root.commitPending) root.commit("")
  }

  function iconFor(appClass) {
    var entry = DesktopEntries.heuristicLookup(appClass)
    var name = entry && entry.icon ? entry.icon : appClass
    if (String(name).charAt(0) === "/") return Util.fileUrl(name)
    return Quickshell.iconPath(name, true) || Quickshell.iconPath("application-x-executable", true)
  }

  function toplevelFor(address) {
    var bare = String(address).replace(/^0x/, "")
    var values = Hyprland.toplevels ? Hyprland.toplevels.values : []
    for (var i = 0; i < values.length; i++) {
      if (String(values[i].address).replace(/^0x/, "") === bare) return values[i].wayland
    }
    return null
  }

  onSelectedChanged: if (root.shown) strip.positionViewAtIndex(root.selected, ListView.Contain)

  // A quick Alt+Tab tap should switch without flashing the overlay.
  Timer {
    id: showTimer
    interval: 110
    onTriggered: {
      if (!root.opened) return
      root.shown = true
      Qt.callLater(function() {
        strip.positionViewAtIndex(root.selected, ListView.Contain)
        keyCatcher.forceActiveFocus()
      })
    }
  }

  Process {
    id: clientsProc
    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.loadClients(text)
    }
  }

  PanelWindow {
    id: panel
    visible: root.shown || card.opacity > 0
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    MouseArea {
      anchors.fill: parent
      onClicked: root.cancel()
    }

    BorderSurface {
      id: card
      anchors.centerIn: parent
      width: Math.min(root.windows.length * (root.tileWidth + root.tileGap) - root.tileGap + root.padding * 2,
                      panel.width - Style.gapsOut * 4)
      height: root.tileHeight + root.padding * 2
      radius: Style.cornerRadius
      color: root.background
      borderSpec: root.borderSpec
      opacity: root.shown ? 1 : 0
      scale: root.shown ? 1 : 0.97

      Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
      Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          var k = event.key
          if (k === Qt.Key_Escape) root.cancel()
          else if (k === Qt.Key_Right || k === Qt.Key_Tab) root.step(1)
          else if (k === Qt.Key_Left || k === Qt.Key_Backtab) root.step(-1)
          else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.commit("")
          else return
          event.accepted = true
        }
        // Backup for the Hyprland release binding.
        Keys.onReleased: function(event) {
          if (event.key === Qt.Key_Alt && root.opened) {
            root.commit("")
            event.accepted = true
          }
        }
      }

      ListView {
        id: strip
        anchors.fill: parent
        anchors.margins: root.padding
        orientation: ListView.Horizontal
        spacing: root.tileGap
        clip: true
        interactive: false
        model: root.windows
        highlightMoveDuration: 120

        delegate: CursorSurface {
          id: tile
          required property var modelData
          required property int index

          width: root.tileWidth
          height: root.tileHeight
          foreground: root.foreground
          current: index === root.selected
          hasCursor: index === root.selected

          Item {
            id: preview
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Style.spacing.lg
            height: root.previewHeight - Style.spacing.lg

            ScreencopyView {
              id: shot
              anchors.fill: parent
              // Hold the capture until the fade-out ends, or the icon fallback
              // flashes up as the overlay disappears.
              captureSource: panel.visible ? root.toplevelFor(tile.modelData.address) : null
              live: false
              constraintSize: Qt.size(width, height)
            }

            // Windows on other workspaces may have nothing to capture.
            Image {
              visible: !shot.hasContent
              anchors.centerIn: parent
              width: Style.space(56)
              height: width
              source: tile.modelData.icon
              sourceSize: Qt.size(width * 2, height * 2)
              fillMode: Image.PreserveAspectFit
              asynchronous: true
            }
          }

          Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Style.spacing.lg
            spacing: Style.spacing.md

            Image {
              id: appIcon
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(20)
              height: width
              source: tile.modelData.icon
              sourceSize: Qt.size(width * 2, height * 2)
              fillMode: Image.PreserveAspectFit
              asynchronous: true
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - appIcon.width - wsLabel.width - parent.spacing * 2
              textFormat: Text.PlainText
              text: tile.modelData.title
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: tile.current
              elide: Text.ElideRight
            }

            Text {
              id: wsLabel
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: tile.modelData.workspace
              color: root.foreground
              opacity: 0.5
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selected = tile.index
            onClicked: { root.selected = tile.index; root.commit("") }
          }
        }
      }
    }
  }
}
