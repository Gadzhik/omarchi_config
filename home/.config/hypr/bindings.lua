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

o.bind("SUPER + ALT + R", "Screenrecord (toggle)", "omarchy-capture-screenrecording")
o.bind("SUPER + ALT + SHIFT + R", "Screenrecord with audio (toggle)", "omarchy-capture-screenrecording --with-desktop-audio")

-- Hold to see through the focused window, release to restore it.
o.bind("SUPER + ALT + BACKSPACE", "Peek through window (hold)", bin .. "/window-peek on")
o.bind("SUPER + ALT + BACKSPACE", "Restore window opacity", bin .. "/window-peek off", { release = true })
