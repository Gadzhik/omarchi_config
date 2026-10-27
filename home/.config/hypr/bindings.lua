-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

local bin = os.getenv("HOME") .. "/.local/bin"

-- Omarchy 4 ships nautilus as the file manager; keep thunar.
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "File manager", { launch = "thunar" })

hl.unbind("SUPER + ALT + SHIFT + F")
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", o.launch('thunar "$(omarchy-cmd-terminal-cwd)"'))

-- Typora keeps the key Omarchy 4 gave to Omawrite.
hl.unbind("SUPER + SHIFT + W")
o.bind("SUPER + SHIFT + W", "Typora", o.launch("typora --enable-wayland-ime"))

o.bind("SUPER + D", "Show desktop (toggle)", bin .. "/toggle-show-desktop")
o.bind("SUPER + SHIFT + I", "Battery idle (toggle)", bin .. "/battery-idle")

-- Screenshot on CTRL + ` instead of PRINT. Named by keysym, but input.lua's
-- resolve_binds_by_sym = false matches it by key position, so the same key
-- (ё in the ru layout) triggers it under Cyrillic too.
hl.unbind("PRINT")
o.bind("CTRL + grave", "Screenshot", "omarchy-capture-screenshot")

o.bind("SUPER + ALT + R", "Screenrecord (toggle)", "omarchy-capture-screenrecording")
o.bind("SUPER + ALT + SHIFT + R", "Screenrecord with audio (toggle)", "omarchy-capture-screenrecording --with-desktop-audio")

-- Hold to see through the focused window, release to restore it.
o.bind("SUPER + ALT + BACKSPACE", "Peek through window (hold)", bin .. "/window-peek on")
o.bind("SUPER + ALT + BACKSPACE", "Restore window opacity", bin .. "/window-peek off", { release = true })

-- Omarchy 4's universal clipboard binds pass the key by NAME ("C") to
-- send_key_state, and Hyprland resolves that name against the ACTIVE xkb group.
-- The ru group has no latin C/V/X (key <AB03> is [c,C] in group 1 but
-- [Cyrillic_es,Cyrillic_ES] in group 2), so under Cyrillic they die with
-- "send_key_state: key not found" and pop the error overlay. Send the keycode
-- instead: it is the same physical key in every layout. X11 codes: x=53, c=54,
-- v=55. Insert needs no code — it exists in both groups.
-- resolve_binds_by_sym in input.lua only fixes recognising a bind, not sending one.
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

local function universal_clipboard_shortcut(default_mods, default_key, terminal_mods, terminal_key)
  return function()
    if active_window_is_terminal() then
      send_shortcut_once(terminal_mods, terminal_key)()
    else
      send_shortcut_once(default_mods, default_key)()
    end
  end
end

hl.unbind("SUPER + C")
o.bind("SUPER + C", "Universal copy", universal_clipboard_shortcut("CTRL", "code:54", "CTRL", "Insert"))

hl.unbind("SUPER + V")
o.bind("SUPER + V", "Universal paste", universal_clipboard_shortcut("CTRL", "code:55", "SHIFT", "Insert"))

hl.unbind("SUPER + X")
o.bind("SUPER + X", "Universal cut", send_shortcut_once("CTRL", "code:53"))
