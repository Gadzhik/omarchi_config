# Omarchy config — Redmi Book Pro 16 2024 (Core Ultra 5 125H)

Snapshot of every customization made to this Omarchy (Arch + Hyprland) system,
plus `install.sh` to reproduce it on a **clean Omarchy install**.

Targets **Omarchy 4 ("Quattro")**. Omarchy now ships as a pacman package at
`/usr/share/omarchy`, Hyprland is configured in **Lua** (`~/.config/hypr/*.lua`),
and one `quickshell` process serves the bar, the launcher and the clipboard —
waybar, walker, elephant, mako, swaybg, hypridle and hyprlock are all gone. See
[Migrating from Omarchy 3](#migrating-from-omarchy-3) if you are coming from the
`.conf` era.

```
omarchi_config/
├── install.sh              # one-shot deploy script (run as normal user)
├── verify.sh               # read-only self-check, no sudo — run it anytime
├── vim-omarchy-neon.png    # → the active wallpaper (symlink, for a quick look)
├── packages/
│   ├── repo.txt            # official-repo packages to install
│   └── aur.txt             # AUR packages to install
├── wallpaper/              # source for the cheat-sheet wallpaper (not deployed)
├── docs/                   # setup notes for tools that live outside home/
├── scripts/                # generators/helpers used to produce config (not deployed)
├── system/                 # files installed OUTSIDE $HOME (needs sudo)
│   ├── etc/modprobe.d/…    # fan fix: blacklist bitland_mifs_wmi
│   ├── etc/systemd/system/ # power-limit services
│   ├── etc/systemd/logind.conf.d/ # lid closed on AC does not suspend
│   ├── etc/sysctl.d/…      # dirty-page limits (no freeze on big copies)
│   ├── etc/tmpfiles.d/…    # PCIe ASPM policy = powersave
│   ├── etc/udev/rules.d/…  # reapply PL1 on AC plug/unplug, bfq, PCI runtime PM
│   └── usr/local/bin/…     # set-power-limit.sh
└── home/                   # files copied verbatim into $HOME
    ├── .bashrc
    ├── .config/…           # hypr (Lua), alacritty, foot, mise, mimeapps, wallpaper
    └── .local/bin/…        # custom helper scripts
```

## Usage

```bash
cd ~/Documents/omarchi_config
./install.sh          # asks for sudo once, then runs unattended
sudo reboot           # required — see below
./verify.sh           # confirms everything landed
```

`install.sh` is idempotent — safe to re-run. It takes the sudo password once at the
start and keeps the ticket alive, so it never stalls waiting for a prompt halfway
through. It ends by running `verify.sh` itself.

**Reboot is required, not just a logout** — the fan fix blacklists a kernel module
that loads early at boot. Until you reboot, PL1 deliberately stays at 28 W because
there is no airflow yet.

⚠️ `install.sh` also writes **outside `$HOME`** (`/etc`, `/usr/local/bin`) for the
thermal fix — see `system/` and `docs/thermal-fan-fix.md`.

### Deploying on different hardware

The thermal part is **model-specific** and refuses to install on anything whose DMI
product name is not `Redmi Book Pro 16 2024`. Everything else still deploys normally.

| variable | effect |
|----------|--------|
| *(none)* | thermal fix installs only on the matching laptop |
| `FORCE_THERMAL=1` | install it anyway — **read `docs/thermal-fan-fix.md` first** |
| `SKIP_THERMAL=1` | never install it, even on the matching laptop |

This guard exists because the blacklist and the 45 W PL1 assume *this* cooling
system. Without working fans this machine hits 100 °C in 30 s at 35 W.

### verify.sh

Read-only, needs no sudo, exits non-zero if anything is off. Checks the deployed
`home/` files against the repo, that Hyprland actually **loaded the Lua config**
(`hyprctl configerrors` is clean and `kb_layout` is live — a leftover `.conf` tree
looks right on disk but Hyprland never reads it), all three layers of the ru-layout
fix (Hyprland `resolve_binds_by_sym`, the Alacritty Cyrillic bindings including that
the TOML still parses, and that `xdg-terminal-exec` actually opens Alacritty rather
than falling back to foot), every thermal file and service, whether
`bitland_mifs_wmi` is loaded, and whether PL1 matches the current power source. It also checks the idle-power
settings: that both NVMe are on `power/control=auto` and that the PCIe ASPM policy
really came up as `powersave` — that write fails silently if the firmware kept ASPM
control for itself. On other hardware the thermal block reports as not-applicable
instead of failing.

---

## What gets installed

**Repo:** IntelliJ IDEA CE, PyCharm CE, JDK 21, Go, PostgreSQL, DBeaver, Ollama,
VLC, ffmpeg, yt-dlp (+ aria2, atomicparsley, rtmpdump, python-mutagen/pycryptodomex/brotli/websockets),
OpenVPN, Docker (+ compose), QEMU/KVM + libvirt + virt-manager (+ edk2-ovmf, swtpm).
**AUR:** Postman, LM Studio, Slack, Android Studio, pgAdmin 4, ble.sh.
**Via Omarchy:** VS Code (`omarchy install editor vscode`).
**Via mise:** Node.js LTS (npm included; `mise use -g pnpm`/`yarn` for those).

`packages/` lists only what `install.sh` installs. A full inventory of the machine
is one command away when you actually need it, so it is not kept here — it would be
a running list of everything its owner uses:

```bash
pacman -Qqe   # everything explicitly installed
pacman -Qqm   # everything foreign / from the AUR
```

---

## Configuration changes (all captured in `home/`)

| File | Change |
|------|--------|
| `hypr/hyprland.lua` | Entry point: loads Omarchy's defaults, then the five personal files below. Hyprland 0.56+ prefers this over `hyprland.conf` and **ignores the whole `.conf` tree** when it exists |
| `hypr/looknfeel.lua` | Window gaps → **1px**, keep the 2px active border (red→pink gradient); **VRR = 2** (adaptive sync in fullscreen); float/center/pin rules for the `battery-warning` window |
| `hypr/monitors.lua` | Display scale **1.6** (`GDK_SCALE=1.75`) — panel allows only clean 1.6/2.0 |
| `hypr/input.lua` | Layout `us,ru`; switch key **Alt+Shift** (`grp:alt_shift_toggle`, was Ctrl+Shift); `resolve_binds_by_sym = false` so `SUPER+<letter>` resolves by key **position** and keeps working in the ru layout (the Latin layout must stay first); touchpad `sensitivity = 0.55` and the Pebble mouse `scroll_factor` via `hl.device`, so each device is tuned without moving the system default |
| `hypr/bindings.lua` | Only what Omarchy 4 does not already bind: **Thunar** over the nautilus default and **Typora** over Omawrite (both `hl.unbind` first, since Hyprland keeps both bindings otherwise); **SUPER+D** show-desktop; **SUPER+SHIFT+I** battery-idle; **SUPER+ALT+R** screen record (add SHIFT for desktop audio); **SUPER+ALT+BACKSPACE** peek through the focused window while held, restored on `{ release = true }`. Every app and webapp binding that used to live here is now an upstream default with the same target |
| `hypr/autostart.lua` | Launches `refresh-rate-by-power`, `per-window-layout` and `battery-low-warn` through `o.launch_on_start` (uwsm-wrapped), and resets `battery-idle` on login |
| `alacritty/alacritty.toml` | Font size **14**; **58 Cyrillic key bindings** so `Ctrl+<letter>` / `Alt+<letter>` keep working in the ru layout — Alacritty matches bindings by the *character* the layout produces, and `Ctrl+ф` yields no control code at all (see `docs/keyboard-layout-shortcuts.md`) |
| `xdg-terminals.list` | Names `Alacritty.desktop` so `xdg-terminal-exec` (what `SUPER+RETURN` runs) opens Alacritty. Without it Omarchy 4 falls back to **foot**, where none of the Cyrillic bindings exist — the ru layout silently loses `Ctrl+A`, `Ctrl+R` and friends |
| `foot/foot.ini` | Font size 14, so the fallback terminal is not unusable if it ever opens |
| `mimeapps.list` | **VLC** default video/audio player; **Firefox** default browser |
| `omarchy/shell.json` | Bar layout: **weather widget removed**; the clock is `local.clock-seconds` (below) rather than stock `omarchy.clock`. `idle.screensaver` / `idle.lock` are the successors to hypridle's timers |
| `omarchy/plugins/local.clock-seconds/` | Clock widget forked to tick every second. Stock `omarchy.clock` hardcodes `precision: SystemClock.Minutes`, so an `HH:mm:ss` format renders seconds that only move once a minute. Only `BarWidget.qml` is forked — `Panel.qml` (the calendar) and `Model.js` load by absolute path out of `/usr/share/omarchy`, so they keep tracking upstream |
| `.bashrc` | **fzf** (Ctrl+R/Ctrl+T/`**`) + **ble.sh** (fish/zsh-like autosuggestions) |
| `.zshrc` | **zsh** as login shell + zsh-autosuggestions + syntax-highlighting + starship/mise/fzf/zoxide + Omarchy aliases. Forces **`bindkey -e`** before the plugins load: with no explicit keymap zsh picks one from `$VISUAL`/`$EDITOR`, and `EDITOR=nvim` contains `vi`, so it silently lands in vi mode where `^?` is `vi-backward-delete-char` and backspace refuses to erase anything that entered the buffer before insert mode — most visibly pasted text. Also binds **Home/End/Delete/Ctrl+←→**, which zsh leaves as `undefined-key` out of the box |
| `alacritty/alacritty.toml` | Also forces `zsh` as the terminal shell (`[terminal.shell]`) |
| `.config/mise/config.toml` | Node.js version pin |
| `.minikube/config/config.json` | minikube defaults: **docker** driver, 4 CPU, 8 GB |
| `.minikube/files/etc/resolv.conf` | DNS for the cluster node — see the note below |
| `.config/omarchy/backgrounds/tokyo-night/vim-omarchy-neon.png` | Active wallpaper: neon Vim / LazyVim / Omarchy cheat sheet (3072×1920, source in `wallpaper/`) |
| `.config/omarchy/backgrounds/Tokyo Night/abstract-fakurian.jpg` | Spare abstract wallpaper (Milad Fakurian). ⚠️ Omarchy only scans the theme **slug** folder (`tokyo-night`), so this one is not in the `SUPER+CTRL+SPACE` rotation |

### Custom helper scripts (`home/.local/bin/`)

- **`refresh-rate-by-power`** — on battery: 60 Hz + `power-saver` + dim brightness (saves/restores);
  on AC: 165 Hz + `balanced` + restore. Reacts to power udev events.
- **`per-window-layout`** — remembers the keyboard layout **per window** (Hyprland has no native
  per-window layout) via the Hyprland IPC socket. Two quirks it works around: Hyprland emits **no
  `activewindowv2` for layer surfaces**, so the launcher (`SUPER+SPACE`, `SUPER+ALT+SPACE`) used to
  inherit the layout of whatever window was underneath — it is now tracked by
  `openlayer`/`closelayer` under its own slot; and **fcitx5's virtual keyboard re-announces its own layout on every focus change**,
  which used to overwrite the layout just remembered for the window, so `activelayout` events are
  filtered down to the physical keyboards the daemon actually drives.
- **`toggle-show-desktop`** — "show desktop" toggle (SUPER+D): jumps to an empty workspace and
  back (Hyprland has no minimize). It deliberately does *not* move windows — stashing them in a
  special workspace and pulling them back re-inserts each one into the dwindle tree next to
  whatever is focused, which comes back reshuffled.
- **`clipboard-history`** — optional cliphist picker. ⚠️ It drove walker, which Omarchy 4 removed;
  the stock clipboard manager is now `SUPER+CTRL+V` (`omarchy-shell`). Kept only for a custom picker.
- **`window-peek`** — makes the focused window transparent while `SUPER+ALT+BACKSPACE` is held
  (`on` saves the window address, `off` restores it), so you can look at what is underneath.
  Hyprland 0.56 names the property `opacity`, not `alpha`, and rejects `unset`, so the restore
  re-applies Omarchy's own values (`0.985 0.96`) through `hl.dsp.window.set_prop`. Tune via `WINDOW_PEEK_OPACITY` /
  `WINDOW_PEEK_RESTORE`. Note the window still swallows mouse clicks while invisible.

---

## Setup notes (`docs/`)

Things that are configured *inside* an application rather than in a dotfile, so
`install.sh` cannot restore them:

- **`docs/gns3-setup.md`** — GNS3 on Arch: which AUR packages (the stable `-2`
  ones, not the `3.1` alpha), why no `ubridge` group exists here, first run, and
  where to get images that are actually licensed.
- **`docs/gns3-images.md`** — where images live under `~/GNS3/images/`, the three
  ways to add one, and the two traps hit while installing MikroTik CHR: a missing
  `hda_disk_interface` drops the VM into iPXE with "No bootable device", and CHR
  prints to VGA rather than the serial console the template asks for.
- **`docs/lmstudio-tuning.md`** — LM Studio on the Arc iGPU: measured
  throughput (GPU ~5.4 tok/s vs CPU ~0.4 on a 9B Q4), the per-model settings
  worth changing, and the models that hang the i915 driver.
- **`docs/thermal-fan-fix.md`** — ⚠️ **read before touching anything thermal.**
  Why the fans never spun (the `bitland_mifs_wmi` driver, new in kernel 7.1),
  the blacklist that fixes it, the resulting +25 % sustained clock, the PL1
  safety interlock, and the dead ends not worth re-investigating.
- **`docs/keyboard-layout-shortcuts.md`** — the two independent layers that make
  shortcuts survive the ru layout: `resolve_binds_by_sym` for Hyprland and 62
  explicit Cyrillic bindings for Alacritty.

## Hardware-specific values ⚠️

These files hard-code values for **this laptop** (Intel Core Ultra 5 125H, 16" 3072×1920 165 Hz).
Adjust if deploying on different hardware:

- **Monitor** `eDP-1`, refresh **165/60 Hz**, scale **1.6** — `monitors.lua`, `refresh-rate-by-power`.
- **Keyboard** `at-translated-set-2-keyboard` — `per-window-layout`; the bar indicator is the stock
  `omarchy.keyboard-layout` widget in `~/.config/omarchy/shell.json`.
- **Touchpad** `gxtp7300:00-27c6:0f90-touchpad` — `hl.device` in `input.lua`. Get yours from
  `hyprctl devices`; a wrong name is silently ignored (no config error, no effect).
- **Power supplies** `ADP1` (AC) / `BAT0` (battery) — `refresh-rate-by-power`, `set-power-limit.sh`.
- **Thermal / fans** — `system/` is model-specific to **Redmi Book Pro 16 2024**
  (BIOS `RMAMT6B0P0B0B`) *except* `etc/systemd/logind.conf.d/`, which is generic and
  installs unconditionally. The `bitland_mifs_wmi` blacklist and the 45 W PL1 assume *this*
  cooling system. **Do not deploy on other hardware** without re-testing: without working
  fans this machine hits 100 °C in 30 s at 35 W. See `docs/thermal-fan-fix.md`.
- **Keyboard layout** — the Alacritty Cyrillic bindings assume the standard **ЙЦУКЕН**
  ru layout; a different `kb_variant` breaks the mapping. Regenerate with
  `scripts/gen-cyrillic-bindings.py`.
- **Idle timers** — Omarchy 4 owns idle and lock in `~/.config/omarchy/shell.json`
  (`idle.screensaver`, `idle.lock`, both in seconds), not in a hypr config.

## Migrating from Omarchy 3

`omarchy-upgrade-to-quattro` moves a `3.8.x` install to the package-backed Omarchy 4
layout. It works, but it **replaces personal config with stock defaults rather than
translating it**, and it does so quietly — nothing fails, the desktop just comes back
subtly wrong. What it did here, and what had to be put back by hand:

| What the upgrade did | Consequence | Fix |
|----------------------|-------------|-----|
| Wrote stock `hypr/*.lua`, left the `.conf` files untouched beside them | Every personal Hyprland setting was in files Hyprland no longer reads. No error, no warning | Ported by hand — the `.lua` files in `home/.config/hypr/` |
| Emptied `xdg-terminals.list` | `SUPER+RETURN` opened **foot** instead of Alacritty, at 9pt and without a single Cyrillic binding | Restored the file; `verify.sh` now checks it |
| Reset the default browser to chromium | `$BROWSER` is `omarchy-launch-browser`, so a plain `xdg-settings set` refuses to write and the reset looks permanent | `env -u BROWSER xdg-settings set default-web-browser firefox.desktop` |
| Removed `vlc` as a retired default | 25 associations in `mimeapps.list` pointed at a `.desktop` that no longer existed | `omarchy pkg add vlc` |
| Recreated the `docker` group | Group membership was dropped; `docker` needs sudo again | `sudo usermod -aG docker $USER`, then **reboot** — a logout does not refresh groups under a running `systemd --user` |
| Removed `hypridle` and `hyprlock` | `hypr/hypridle.conf` and `hypr/hyprlock.conf` are dead; idle and lock moved into the shell | `battery-idle` rewritten to drive `omarchy-toggle-idle` |
| Hyprland 0.56 rewired `hyprctl` for the Lua config | **Every helper script that drove Hyprland broke silently.** `hyprctl dispatch <verb> <args>` is now wrapped in `hl.dispatch()`, so the positional form is a Lua syntax error; `hyprctl keyword` answers *"keyword can't work with non-legacy parsers"*; `hyprctl dispatch setprop` and plain `hyprctl setprop` are both gone. Nothing printed to a log — the scripts redirect stderr | See the translation table below |

### hyprctl under a Lua config

The old calls and what replaced them. Everything goes through `hl.dsp.*` (dispatchers)
or `hyprctl eval` (arbitrary Lua) now, and `hl.dsp.workspace` is **not** the workspace
switcher — that is `hl.dsp.focus`, while `hl.dsp.workspace` holds `move` and
`toggle_special`.

| Was | Is | Used by |
|-----|-----|---------|
| `hyprctl dispatch workspace <n>` | `hyprctl dispatch 'hl.dsp.focus({ workspace = "<n>" })'` | `toggle-show-desktop` |
| `hyprctl dispatch setprop address:<a> opacity <v>` | `hyprctl dispatch 'hl.dsp.window.set_prop({ window = "address:<a>", prop = "opacity", value = "<v>" })'` | `window-peek` |
| `hyprctl keyword monitor <spec>` | `hyprctl eval 'hl.monitor({ output = …, mode = …, position = "auto", scale = … })'` | `refresh-rate-by-power` |
| `hyprctl switchxkblayout <dev> <n>` | unchanged — still works | `per-window-layout` |

`set_prop` takes **one table**, not positional arguments, and `value` must stay a
string so a two-number opacity (`"0.985 0.96"`) survives as a single argument.

### Idle, and what is genuinely gone

`battery-idle` used to gate three timers on *being on battery* by having hypridle call
`battery-idle check` before each action. Omarchy 4's shell owns idle instead:
`idle.screensaver` and `idle.lock` in `~/.config/omarchy/shell.json` (seconds), plus an
all-or-nothing `stay-awake` flag with no notion of the power source. `battery-idle` now
holds the intent itself and translates intent + power source into that flag on every
transition — `refresh-rate-by-power` calls `battery-idle apply` when the adapter changes.

**Suspend is gone.** The shell's idle service only blanks and locks; there is no
suspend action, and logind's `IdleAction` is unset. The old 15-minute on-battery sleep
went away with hypridle and has no replacement here yet.

## Notes

- **minikube DNS.** The host resolves through a systemd-resolved stub on
  `127.0.0.53`, which a container cannot use, so minikube substitutes its bridge
  gateway `192.168.49.1` — and the node gets `SERVFAIL` from it, which breaks
  every image pull. Adding a `DNSStubListenerExtra` for that address does *not*
  help: the node runs kube-proxy and CNI in its own netns and cannot reach the
  host stubs at all (a plain container on the same bridge can). The fix is
  `.minikube/files/etc/resolv.conf`, which minikube copies into the node on every
  start. Keep it to bare `nameserver` lines — an `options ndots:0` in there is
  inherited by pods and stops short names like `kubernetes.default` from
  resolving through the cluster search domains.
- **libvirt / Vagrant.** `install.sh` starts the `default` network and creates
  the `default` storage pool. Without the pool `vagrant up` dies with
  "Storage pool not found"; libvirt ships without one.
- Night light is disabled at runtime, not in a config file. If it appears: `omarchy toggle nightlight`.
- `packages/full-*.txt` are complete snapshots for reference/auditing; `install.sh` uses the
  curated `repo.txt` / `aur.txt`.
