-- Change the default Omarchy look'n'feel.

local active_border_color = { colors = { "rgba(ff1744ff)", "rgba(ff4f9aff)" }, angle = 45 }

hl.config({
  general = {
    -- Near-flat gaps: screen real estate over breathing room.
    gaps_in = 1,
    gaps_out = 1,
    border_size = 2,

    col = {
      active_border = active_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
    },
  },

  misc = {
    -- Variable refresh rate, fullscreen only.
    vrr = 2,
  },
})

-- The low-battery warning from ~/.local/bin/battery-low-warn: big, centered,
-- and on top of whatever is in the way.
o.window("^battery-warning$", {
  float = true,
  center = true,
  pin = true,
  size = { 1100, 640 },
})
