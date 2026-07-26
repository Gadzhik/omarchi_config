# Omarchy config — igadzhi

Snapshot of every customization made to this Omarchy (Arch + Hyprland) system,
plus `install.sh` to reproduce it on a **clean Omarchy install**.

```
omarchi_config/
├── install.sh              # one-shot deploy script (run as normal user)
├── packages/
│   ├── repo.txt            # official-repo packages to install
│   ├── aur.txt             # AUR packages to install
│   ├── full-explicit.txt   # snapshot: ALL explicitly-installed pkgs (reference)
│   └── full-aur.txt        # snapshot: ALL foreign/AUR pkgs (reference)
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

Then **log out and back in** (for `docker`/`libvirt`/`kvm` groups and ble.sh).
The script is idempotent — safe to re-run.

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
| `hypr/looknfeel.conf` | Window gaps → **1px**, keep 2px active border; **VRR = 2** (adaptive sync in fullscreen) |
| `hypr/monitors.conf` | Display scale **1.6** (`GDK_SCALE=1.75`) — panel allows only clean 1.6/2.0 |
| `hypr/input.conf` | Layout `us,ru`; switch key **Alt+Shift** (`grp:alt_shift_toggle`, was Ctrl+Shift) |
| `hypr/hypridle.conf` | Screensaver **off**; screen off after **3 min on battery**; lock after **5 min on battery** only |
| `hypr/bindings.conf` | **SUPER+V** → clipboard history (walker), overriding default "Universal paste" |
| `hypr/autostart.conf` | Launches `refresh-rate-by-power` and `per-window-layout` |
| `hypr/hyprlock.conf` | Lock screen shows **clock, date, battery %/status** |
| `alacritty/alacritty.toml` | Font size **12** |
| `waybar/config.jsonc` | Added **keyboard-layout indicator**; CPU shows usage%+freq; battery always shows % |
| `waybar/style.css` | Bar font **13px**; spacing so the layout icon doesn't touch bluetooth |
| `elephant/clipboard.toml` | Clipboard history **max_items = 233** (walker/SUPER+V; images supported) |
| `mimeapps.list` | **VLC** default video/audio player; **Firefox** default browser |
| `.bashrc` | **fzf** (Ctrl+R/Ctrl+T/`**`) + **ble.sh** (fish/zsh-like autosuggestions) |
| `.config/mise/config.toml` | Node.js version pin |
| `.config/omarchy/backgrounds/Tokyo Night/abstract-fakurian.jpg` | Clean abstract wallpaper (Milad Fakurian), Tokyo Night theme kept |

### Custom helper scripts (`home/.local/bin/`)

- **`refresh-rate-by-power`** — on battery: 60 Hz + `power-saver` + dim brightness (saves/restores);
  on AC: 165 Hz + `balanced` + restore. Reacts to power udev events.
- **`per-window-layout`** — remembers the keyboard layout **per window** (Hyprland has no native
  per-window layout) via the Hyprland IPC socket.
- **`clipboard-history`** — optional cliphist+walker picker (only used if `cliphist` is installed).

---

## Hardware-specific values ⚠️

These files hard-code values for **this laptop** (Intel Core Ultra 5 125H, 16" 3072×1920 165 Hz).
Adjust if deploying on different hardware:

- **Monitor** `eDP-1`, refresh **165/60 Hz**, scale **1.6** — `monitors.conf`, `refresh-rate-by-power`.
- **Keyboard** `at-translated-set-2-keyboard` — `per-window-layout`, waybar `hyprland/language` on-click.
- **Power supplies** `ADP1` (AC) / `BAT0` (battery) — `refresh-rate-by-power`, `hypridle.conf`.

## Notes

- Night light is disabled at runtime, not in a config file. If it appears: `omarchy toggle nightlight`.
- `packages/full-*.txt` are complete snapshots for reference/auditing; `install.sh` uses the
  curated `repo.txt` / `aur.txt`.
