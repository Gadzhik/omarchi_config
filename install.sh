#!/usr/bin/env bash
#
# Deploy igadzhi's Omarchy configuration onto a clean Omarchy install.
# Run as the normal user (it calls sudo where needed):  ./install.sh
#
# Idempotent: safe to re-run. Skips work that is already done.

set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
pkgs() { grep -vE '^\s*#|^\s*$' "$1" | sed 's/#.*//' | awk '{print $1}'; }

command -v pacman >/dev/null || { echo "This must run on Arch/Omarchy."; exit 1; }

# ---------------------------------------------------------------------------
# 1. Packages
# ---------------------------------------------------------------------------
info "Updating system & installing official-repo packages"
sudo pacman -Syu --needed --noconfirm $(pkgs "$DIR/packages/repo.txt")

info "Installing AUR packages (yay)"
if command -v yay >/dev/null; then
  yay -S --needed --noconfirm $(pkgs "$DIR/packages/aur.txt")
else
  warn "yay not found — install an AUR helper, then: yay -S $(pkgs "$DIR/packages/aur.txt" | tr '\n' ' ')"
fi

info "Installing VS Code via Omarchy"
command -v code >/dev/null || omarchy install vscode || warn "run 'omarchy install vscode' manually"

# ---------------------------------------------------------------------------
# 2. Node.js (via mise — matches ~/.config/mise/config.toml that we copy below)
# ---------------------------------------------------------------------------
info "Node.js via mise"
if command -v mise >/dev/null; then
  mise use -g node@lts && mise install || warn "check mise / node"
else
  warn "mise not found — Omarchy ships it; install mise, then: mise use -g node@lts"
fi

# ---------------------------------------------------------------------------
# 3. Config files  (merge everything under home/ into $HOME)
# ---------------------------------------------------------------------------
info "Copying configuration files into \$HOME"
cp -a "$DIR/home/." "$HOME/"
chmod +x "$HOME"/.local/bin/* 2>/dev/null || true

# ---------------------------------------------------------------------------
# 4. Default applications
# ---------------------------------------------------------------------------
info "Setting default apps (Firefox browser; VLC player via mimeapps.list)"
xdg-settings set default-web-browser firefox.desktop 2>/dev/null || warn "set Firefox default manually"

# ---------------------------------------------------------------------------
# 5. Services & groups
# ---------------------------------------------------------------------------
info "Enabling services and adding groups"
sudo systemctl enable --now docker.socket 2>/dev/null || warn "docker"
sudo systemctl enable --now libvirtd      2>/dev/null || warn "libvirtd"
sudo systemctl enable --now ollama        2>/dev/null || warn "ollama"
# intel_lpmd ships enabled on Omarchy; enable if present
systemctl is-enabled intel_lpmd &>/dev/null || sudo systemctl enable --now intel_lpmd 2>/dev/null || true
sudo usermod -aG docker,libvirt,kvm "$USER" 2>/dev/null || true
getent group wireshark >/dev/null && sudo usermod -aG wireshark "$USER" 2>/dev/null || true  # non-root packet capture

# Native PostgreSQL: initialize the cluster once
if pacman -Qq postgresql &>/dev/null && [[ ! -d /var/lib/postgres/data ]]; then
  info "Initializing PostgreSQL cluster"
  sudo -iu postgres initdb -D /var/lib/postgres/data && sudo systemctl enable --now postgresql
fi

# ---------------------------------------------------------------------------
# 6. Theme + IT wallpaper (keeps Tokyo Night colors, cyberpunk background)
# ---------------------------------------------------------------------------
info "Applying Tokyo Night theme + IT wallpaper"
omarchy theme set "Tokyo Night" 2>/dev/null || true
BG="$HOME/.config/omarchy/backgrounds/Tokyo Night/it-synth-scape.jpg"
if [[ -f $BG ]]; then
  ln -nsf "$BG" "$HOME/.config/omarchy/current/background"
  pkill -x swaybg 2>/dev/null
  setsid uwsm-app -- swaybg -i "$HOME/.config/omarchy/current/background" -m fill >/dev/null 2>&1 &
fi

# ---------------------------------------------------------------------------
# 7. Reload the desktop
# ---------------------------------------------------------------------------
info "Reloading Hyprland / waybar / elephant"
hyprctl reload 2>/dev/null || true
omarchy restart waybar 2>/dev/null || true
systemctl --user restart elephant.service 2>/dev/null || true

cat <<'EOF'

============================================================
 Done.  Remaining manual steps:
  • Log out and back in  → docker/libvirt/kvm group membership,
    and ble.sh (open a fresh terminal) take effect.
  • Turn OFF the night light if it comes on:  omarchy toggle nightlight
  • Hardware-specific values in the copied files assume the same
    laptop (see README.md → "Hardware-specific values").
============================================================
EOF
