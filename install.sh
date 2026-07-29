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
[[ $EUID -eq 0 ]] && { echo "Run as your normal user, not root — it calls sudo itself."; exit 1; }

# Take the sudo password once up front and keep the ticket alive, so a long run
# never stalls waiting for a prompt halfway through.
info "Asking for sudo once (kept alive for the whole run)"
sudo -v || { echo "sudo is required."; exit 1; }
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
SUDO_KEEPALIVE=$!
trap 'kill $SUDO_KEEPALIVE 2>/dev/null' EXIT

# This laptop. The thermal section is tuned to its cooling and is skipped on
# anything else — see "Hardware-specific values" in README.md.
THIS_MODEL="Redmi Book Pro 16 2024"
MODEL="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo unknown)"

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

info "Making zsh the default login shell"
if [[ ${SHELL:-} != */zsh ]] && command -v zsh >/dev/null; then
  sudo chsh -s /usr/bin/zsh "$USER" 2>/dev/null || warn "run: chsh -s /usr/bin/zsh"
fi
# Seed zsh history from bash so autosuggestions have data on first launch
[[ -f $HOME/.bash_history && ! -s $HOME/.zsh_history ]] && cp "$HOME/.bash_history" "$HOME/.zsh_history"

# ---------------------------------------------------------------------------
# 3b. System files outside $HOME  (fan fix + power limit)
#     See docs/thermal-fan-fix.md for the full story.
# ---------------------------------------------------------------------------
info "Installing thermal fix (fan blacklist + PL1 by AC state)"
if [[ ${SKIP_THERMAL:-0} == 1 ]]; then
  warn "SKIP_THERMAL=1 — thermal fix skipped on request"
elif [[ $MODEL != "$THIS_MODEL" ]]; then
  # Refusing here is deliberate. The blacklist and the 45 W PL1 are tuned to this
  # laptop's cooling; applying them blind to other hardware can cook it. Without
  # working fans THIS machine reaches 100 C in 30 s at 35 W.
  warn "Hardware is '$MODEL', not '$THIS_MODEL' — thermal fix NOT installed."
  warn "It is model-specific; see docs/thermal-fan-fix.md before forcing it."
  warn "To install anyway: FORCE_THERMAL=1 ./install.sh"
  [[ ${FORCE_THERMAL:-0} == 1 ]] && MODEL="$THIS_MODEL"
fi
if [[ -d $DIR/system && $MODEL == "$THIS_MODEL" && ${SKIP_THERMAL:-0} != 1 ]]; then
  # bitland_mifs_wmi breaks fan control on this laptop: without the blacklist the
  # fans never spin, not even at 100 C. Costs the keyboard backlight.
  sudo install -Dm644 "$DIR/system/etc/modprobe.d/bitland-mifs-fan-fix.conf" \
                      /etc/modprobe.d/bitland-mifs-fan-fix.conf
  sudo install -Dm755 "$DIR/system/usr/local/bin/set-power-limit.sh" \
                      /usr/local/bin/set-power-limit.sh
  sudo install -Dm644 "$DIR/system/etc/systemd/system/power-limit.service" \
                      /etc/systemd/system/power-limit.service
  sudo install -Dm644 "$DIR/system/etc/systemd/system/power-limit-resume.service" \
                      /etc/systemd/system/power-limit-resume.service
  sudo install -Dm644 "$DIR/system/etc/udev/rules.d/99-power-limit.rules" \
                      /etc/udev/rules.d/99-power-limit.rules

  sudo mkinitcpio -P 2>/dev/null || warn "mkinitcpio failed — rerun before rebooting"
  sudo systemctl daemon-reload
  sudo systemctl enable --now power-limit.service power-limit-resume.service 2>/dev/null ||
    warn "power-limit services"
  sudo udevadm control --reload 2>/dev/null || true

  if lsmod | grep -q '^bitland_mifs_wmi'; then
    warn "bitland_mifs_wmi is still loaded — REBOOT for the fan fix to take effect."
    warn "Until then set-power-limit.sh keeps PL1 at 28 W on purpose (no airflow)."
  fi
elif [[ ! -d $DIR/system ]]; then
  warn "system/ missing — thermal fix not installed"
fi

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

# libvirt ships with the 'default' network stopped and no storage pool at all.
# Vagrant fails with "Storage pool not found" until both exist.
info "Bootstrapping libvirt network and storage pool"
virsh -c qemu:///system net-autostart default &>/dev/null || true
virsh -c qemu:///system net-start      default &>/dev/null || true
if ! virsh -c qemu:///system pool-info default &>/dev/null; then
  virsh -c qemu:///system pool-define-as default dir --target /var/lib/libvirt/images &>/dev/null || warn "libvirt pool"
fi
virsh -c qemu:///system pool-autostart default &>/dev/null || true
virsh -c qemu:///system pool-start     default &>/dev/null || true

# Vagrant defaults to VirtualBox, whose hypervisor clashes with the loaded KVM
# modules. The libvirt provider reuses the KVM stack that is already running.
if command -v vagrant >/dev/null && ! vagrant plugin list 2>/dev/null | grep -q vagrant-libvirt; then
  info "Installing the vagrant-libvirt plugin"
  vagrant plugin install vagrant-libvirt ||
    CONFIGURE_ARGS='with-ldflags=-L/opt/vagrant/embedded/lib' vagrant plugin install vagrant-libvirt ||
    warn "vagrant-libvirt — install it manually"
fi

# ---------------------------------------------------------------------------
# 6. Theme + IT wallpaper (keeps Tokyo Night colors, cyberpunk background)
# ---------------------------------------------------------------------------
info "Applying Tokyo Night theme + cheat-sheet wallpaper"
omarchy theme set "Tokyo Night" 2>/dev/null || true
# Omarchy resolves user backgrounds via the theme *slug* in current/theme.name
# ("tokyo-night"), not the display name — anything under the old "Tokyo Night"
# folder is invisible to `omarchy theme bg next`.
BG="$HOME/.config/omarchy/backgrounds/tokyo-night/vim-omarchy-neon.png"
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

# ---------------------------------------------------------------------------
# 8. Verify what actually landed
# ---------------------------------------------------------------------------
info "Verifying the deployment"
if [[ -x $DIR/verify.sh ]]; then
  "$DIR/verify.sh" || warn "verify.sh reported problems — see the ✗ lines above"
else
  warn "verify.sh missing — cannot self-check"
fi

cat <<'EOF'

============================================================
 Done.  Remaining manual steps:
  • REBOOT — required for the fan fix (blacklist bitland_mifs_wmi).
    Logging out is not enough; the module loads early at boot.
    Until you reboot, PL1 deliberately stays at 28 W (no airflow).
    Verify after reboot:  lsmod | grep -c '^bitland_mifs_wmi'   → 0
    See docs/thermal-fan-fix.md
  • Log out and back in  → docker/libvirt/kvm group membership,
    and ble.sh (open a fresh terminal) take effect.
  • Turn OFF the night light if it comes on:  omarchy toggle nightlight
  • Hardware-specific values in the copied files assume the same
    laptop (see README.md → "Hardware-specific values").

 Re-check at any time (read-only, no sudo):   ./verify.sh
============================================================
EOF
