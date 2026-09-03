-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

hl.config({
  input = {
    -- Latin layout leads so SUPER bindings keep firing under Cyrillic.
    -- Switch with Alt + Shift.
    kb_layout = "us,ru",
    kb_options = "compose:caps,grp:alt_shift_toggle",

    -- Bindings resolve by keycode, so per-window-layout can flip the layout
    -- without the SUPER bindings moving with it.
    resolve_binds_by_sym = false,

    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,

    scroll_factor = 1.8,

    touchpad = {
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },
})

-- Per-device tuning: the built-in touchpad is oversensitive at the default,
-- the Pebble mouse undersensitive.
hl.device({ name = "gxtp7300:00-27c6:0f90-touchpad", sensitivity = 0.55 })
hl.device({ name = "pebble-m350s-mouse", scroll_factor = 1.8 })
