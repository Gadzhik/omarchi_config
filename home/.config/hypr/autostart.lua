-- Extra autostart processes.

local bin = os.getenv("HOME") .. "/.local/bin"

-- Adjust refresh rate / power profile / brightness by AC vs battery.
o.launch_on_start(bin .. "/refresh-rate-by-power")

-- Remember keyboard layout per window.
o.launch_on_start(bin .. "/per-window-layout")

-- Never start a session with the idle actions left disabled from last time.
o.exec_on_start(bin .. "/battery-idle reset")

-- Big on-screen warning when the battery drops below 20%.
o.launch_on_start(bin .. "/battery-low-warn")
