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
├── wallpaper/              # source for the cheat-sheet wallpaper (not deployed)
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
| `hypr/looknfeel.conf` | Window gaps → **1px**, keep 2px active border; **VRR = 2** (adaptive sync in fullscreen); `fadeSwitch` animation **off** so opacity changes are instant |
| `hypr/monitors.conf` | Display scale **1.6** (`GDK_SCALE=1.75`) — panel allows only clean 1.6/2.0 |
| `hypr/input.conf` | Layout `us,ru`; switch key **Alt+Shift** (`grp:alt_shift_toggle`, was Ctrl+Shift); touchpad `sensitivity = 0.55` via a `device` block, so an external mouse keeps system speed |
| `hypr/hypridle.conf` | Screensaver **off**; screen off after **3 min on battery**; lock after **5 min on battery** only |
| `hypr/bindings.conf` | **SUPER+V** → clipboard history (walker), overriding default "Universal paste"; **SUPER+ALT+BACKSPACE** → peek through the focused window while held |
| `hypr/autostart.conf` | Launches `refresh-rate-by-power` and `per-window-layout` |
| `hypr/hyprlock.conf` | Lock screen shows **clock, date, battery %/status** |
| `alacritty/alacritty.toml` | Font size **12** |
| `waybar/config.jsonc` | Added **keyboard-layout indicator**; CPU shows usage%+freq; battery always shows % |
| `waybar/style.css` | Bar font **13px**; spacing so the layout icon doesn't touch bluetooth |
| `elephant/clipboard.toml` | Clipboard history **max_items = 233** (walker/SUPER+V; images supported) |
| `mimeapps.list` | **VLC** default video/audio player; **Firefox** default browser |
| `.bashrc` | **fzf** (Ctrl+R/Ctrl+T/`**`) + **ble.sh** (fish/zsh-like autosuggestions) |
| `.zshrc` | **zsh** as login shell + zsh-autosuggestions + syntax-highlighting + starship/mise/fzf/zoxide + Omarchy aliases |
| `alacritty/alacritty.toml` | Also forces `zsh` as the terminal shell (`[terminal.shell]`) |
| `.config/mise/config.toml` | Node.js version pin |
| `.config/omarchy/backgrounds/tokyo-night/vim-omarchy-neon.png` | Active wallpaper: neon Vim / LazyVim / Omarchy cheat sheet (3072×1920, source in `wallpaper/`) |
| `.config/omarchy/backgrounds/Tokyo Night/abstract-fakurian.jpg` | Spare abstract wallpaper (Milad Fakurian). ⚠️ Omarchy only scans the theme **slug** folder (`tokyo-night`), so this one is not in the `SUPER+CTRL+SPACE` rotation |

### Custom helper scripts (`home/.local/bin/`)

- **`refresh-rate-by-power`** — on battery: 60 Hz + `power-saver` + dim brightness (saves/restores);
  on AC: 165 Hz + `balanced` + restore. Reacts to power udev events.
- **`per-window-layout`** — remembers the keyboard layout **per window** (Hyprland has no native
  per-window layout) via the Hyprland IPC socket.
- **`toggle-show-desktop`** — "show desktop" toggle (SUPER+D): stashes all windows of the
  active workspace into a special scratch workspace and restores them (Hyprland has no minimize).
- **`clipboard-history`** — optional cliphist+walker picker (only used if `cliphist` is installed).
- **`window-peek`** — makes the focused window transparent while `SUPER+ALT+BACKSPACE` is held
  (`on` saves the window address, `off` restores it), so you can look at what is underneath.
  Hyprland 0.56 names the property `opacity`, not `alpha`, and rejects `unset`, so the restore
  re-applies Omarchy's own values (`0.985 0.96`). Tune via `WINDOW_PEEK_OPACITY` /
  `WINDOW_PEEK_RESTORE`. Note the window still swallows mouse clicks while invisible.

---

## Hardware-specific values ⚠️

These files hard-code values for **this laptop** (Intel Core Ultra 5 125H, 16" 3072×1920 165 Hz).
Adjust if deploying on different hardware:

- **Monitor** `eDP-1`, refresh **165/60 Hz**, scale **1.6** — `monitors.conf`, `refresh-rate-by-power`.
- **Keyboard** `at-translated-set-2-keyboard` — `per-window-layout`, waybar `hyprland/language` on-click.
- **Touchpad** `gxtp7300:00-27c6:0f90-touchpad` — `input.conf` `device` block. Get yours from
  `hyprctl devices`; a wrong name is silently ignored (no config error, no effect).
- **Power supplies** `ADP1` (AC) / `BAT0` (battery) — `refresh-rate-by-power`, `hypridle.conf`.

## Notes

- Night light is disabled at runtime, not in a config file. If it appears: `omarchy toggle nightlight`.
- `packages/full-*.txt` are complete snapshots for reference/auditing; `install.sh` uses the
  curated `repo.txt` / `aur.txt`.
