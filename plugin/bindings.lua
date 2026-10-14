-- Alt+Tab bindings for omarchy-switcher, loaded from ~/.config/hypr/bindings.lua.
--
-- Steps are appended to a small command file the switcher service streams;
-- writing a file from here is far faster than starting an IPC client per key.
-- A switch finishes when Alt is no longer held. Hyprland's release bindings
-- miss that in common cases (Tab still down as Alt comes up, or the key-up
-- going to the focused overlay), so a short repeating timer watches the
-- physical key state while a switch is in progress.

local command_path = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/omarchy-switcher"

-- Append one step for the switcher to read. The file lives in RAM and is
-- cleared once it reaches 64 KB (a large shrink the reader always notices).
local function run(step)
  local file = io.open(command_path, "a")
  if not file then return end
  if file:seek("end") > 65536 then
    file:close()
    file = io.open(command_path, "w")
    if not file then return end
  end
  file:write(step .. "\n")
  file:close()
end

local switching = false
local watcher = nil

local function alt_down()
  return hl.is_key_down("Alt_L") or hl.is_key_down("Alt_R")
end

local function finish()
  switching = false
  watcher:set_enabled(false)
  run("commit")
end

local function step(direction)
  if not switching then
    switching = true
    if watcher then
      watcher:set_enabled(true)
    else
      watcher = hl.timer(function()
        if switching and not alt_down() then finish() end
      end, { timeout = 15, type = "repeat" })
    end
  end
  run(direction)
end

hl.unbind("ALT + TAB")
hl.unbind("ALT + SHIFT + TAB")
o.bind("ALT + TAB", "Switch windows", function() step("next") end)
o.bind("ALT + SHIFT + TAB", "Switch windows backwards", function() step("prev") end)
