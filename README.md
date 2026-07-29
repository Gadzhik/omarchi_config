# Omarchy config — igadzhi

Snapshot of every customization made to this Omarchy (Arch + Hyprland) system,
plus `install.sh` to reproduce it on a **clean Omarchy install**.

```
omarchi_config/
├── install.sh              # one-shot deploy script (run as normal user)
├── vim-omarchy-neon.png    # → the active wallpaper (symlink, for a quick look)
├── packages/
│   ├── repo.txt            # official-repo packages to install
│   ├── aur.txt             # AUR packages to install
│   ├── full-explicit.txt   # snapshot: ALL explicitly-installed pkgs (reference)
│   └── full-aur.txt        # snapshot: ALL foreign/AUR pkgs (reference)
├── wallpaper/              # source for the cheat-sheet wallpaper (not deployed)
├── docs/                   # setup notes for tools that live outside home/
├── scripts/                # generators/helpers used to produce config (not deployed)
├── system/                 # files installed OUTSIDE $HOME (needs sudo)
│   ├── etc/modprobe.d/…    # fan fix: blacklist bitland_mifs_wmi
│   ├── etc/systemd/system/ # power-limit services
│   ├── etc/udev/rules.d/…  # reapply PL1 on AC plug/unplug
│   └── usr/local/bin/…     # set-power-limit.sh
└── home/                   # files copied verbatim into $HOME
    ├── .bashrc
    ├── .config/…           # hypr, waybar, alacritty, elephant, mise, mimeapps, wallpaper
    └── .local/bin/…        # custom helper scripts
```

## Usage

```bash
cd ~/Documents/omarchi_config
./install.sh
```

Then **reboot** — the fan fix blacklists a kernel module that loads early at boot,
so logging out is not enough. (Logging out still suffices for the
`docker`/`libvirt`/`kvm` groups and ble.sh if you skip the thermal part.)
The script is idempotent — safe to re-run.

⚠️ `install.sh` now also writes files **outside `$HOME`** (`/etc`, `/usr/local/bin`)
for the thermal fix — see `system/` and `docs/thermal-fan-fix.md`.

---

## What gets installed

**Repo:** IntelliJ IDEA CE, PyCharm CE, JDK 21, Go, PostgreSQL, DBeaver, Ollama,
VLC, ffmpeg, yt-dlp (+ aria2, atomicparsley, rtmpdump, python-mutagen/pycryptodomex/brotli/websockets),
OpenVPN, Docker (+ compose), QEMU/KVM + libvirt + virt-manager (+ edk2-ovmf, swtpm).
**AUR:** Postman, LM Studio, Slack, Android Studio, pgAdmin 4, ble.sh.
**Via Omarchy:** VS Code (`omarchy install vscode`).
**Via mise:** Node.js LTS (npm included; `mise use -g pnpm`/`yarn` for those).

---

## Configuration changes (all captured in `home/`)

| File | Change |
|------|--------|
| `hypr/looknfeel.conf` | Window gaps → **1px**, keep 2px active border; **VRR = 2** (adaptive sync in fullscreen); `fadeSwitch` animation **off** so opacity changes are instant |
| `hypr/monitors.conf` | Display scale **1.6** (`GDK_SCALE=1.75`) — panel allows only clean 1.6/2.0 |
| `hypr/input.conf` | Layout `us,ru`; switch key **Alt+Shift** (`grp:alt_shift_toggle`, was Ctrl+Shift); `resolve_binds_by_sym = false` so `SUPER+<letter>` resolves by key **position** and keeps working in the ru layout (the Latin layout must stay first); touchpad `sensitivity = 0.55` via a `device` block, so an external mouse keeps system speed |
| `hypr/hypridle.conf` | Screensaver **off**; screen off after **3 min on battery**; lock after **5 min on battery** only |
| `hypr/bindings.conf` | **SUPER+V** → clipboard history (walker), overriding default "Universal paste"; **SUPER+ALT+BACKSPACE** → peek through the focused window while held |
| `hypr/autostart.conf` | Launches `refresh-rate-by-power` and `per-window-layout` |
| `hypr/hyprlock.conf` | Lock screen shows **clock, date, battery %/status** |
| `alacritty/alacritty.toml` | Font size **12**; **62 Cyrillic key bindings** so `Ctrl+<letter>` / `Alt+<letter>` keep working in the ru layout — Alacritty matches bindings by the *character* the layout produces, and `Ctrl+ф` yields no control code at all (see `docs/keyboard-layout-shortcuts.md`) |
| `waybar/config.jsonc` | Added **keyboard-layout indicator**; CPU shows usage%+freq; battery always shows % |
| `waybar/style.css` | Bar font **13px**; spacing so the layout icon doesn't touch bluetooth |
| `elephant/clipboard.toml` | Clipboard history **max_items = 233** (walker/SUPER+V; images supported) |
| `mimeapps.list` | **VLC** default video/audio player; **Firefox** default browser |
| `.bashrc` | **fzf** (Ctrl+R/Ctrl+T/`**`) + **ble.sh** (fish/zsh-like autosuggestions) |
| `.zshrc` | **zsh** as login shell + zsh-autosuggestions + syntax-highlighting + starship/mise/fzf/zoxide + Omarchy aliases |
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
  per-window layout) via the Hyprland IPC socket.
- **`toggle-show-desktop`** — "show desktop" toggle (SUPER+D): jumps to an empty workspace and
  back (Hyprland has no minimize). It deliberately does *not* move windows — stashing them in a
  special workspace and pulling them back re-inserts each one into the dwindle tree next to
  whatever is focused, which comes back reshuffled.
- **`clipboard-history`** — optional cliphist+walker picker (only used if `cliphist` is installed).
- **`window-peek`** — makes the focused window transparent while `SUPER+ALT+BACKSPACE` is held
  (`on` saves the window address, `off` restores it), so you can look at what is underneath.
  Hyprland 0.56 names the property `opacity`, not `alpha`, and rejects `unset`, so the restore
  re-applies Omarchy's own values (`0.985 0.96`). Tune via `WINDOW_PEEK_OPACITY` /
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

- **Monitor** `eDP-1`, refresh **165/60 Hz**, scale **1.6** — `monitors.conf`, `refresh-rate-by-power`.
- **Keyboard** `at-translated-set-2-keyboard` — `per-window-layout`, waybar `hyprland/language` on-click.
- **Touchpad** `gxtp7300:00-27c6:0f90-touchpad` — `input.conf` `device` block. Get yours from
  `hyprctl devices`; a wrong name is silently ignored (no config error, no effect).
- **Power supplies** `ADP1` (AC) / `BAT0` (battery) — `refresh-rate-by-power`, `hypridle.conf`,
  `set-power-limit.sh`.
- **Thermal / fans** — the whole `system/` tree is specific to **Redmi Book Pro 16 2024**
  (BIOS `RMAMT6B0P0B0B`). The `bitland_mifs_wmi` blacklist and the 45 W PL1 assume *this*
  cooling system. **Do not deploy on other hardware** without re-testing: without working
  fans this machine hits 100 °C in 30 s at 35 W. See `docs/thermal-fan-fix.md`.
- **Keyboard layout** — the Alacritty Cyrillic bindings assume the standard **ЙЦУКЕН**
  ru layout; a different `kb_variant` breaks the mapping. Regenerate with
  `scripts/gen-cyrillic-bindings.py`.

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
