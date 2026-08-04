#!/usr/bin/env bash
#
# Verify that install.sh actually took effect. Read-only, no sudo, safe anytime.
#   ./verify.sh
#
# Exit code: 0 = everything expected is in place, 1 = something needs attention.

set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PASS=0; FAIL=0; SKIP=0
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$*"; FAIL=$((FAIL+1)); }
note() { printf '  \033[33m·\033[0m %s\n' "$*"; SKIP=$((SKIP+1)); }
head_() { printf '\n\033[1;36m== %s\033[0m\n' "$*"; }

THIS_MODEL="Redmi Book Pro 16 2024"
MODEL="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo unknown)"

# ---------------------------------------------------------------------------
head_ "Home configuration"
# ---------------------------------------------------------------------------
for f in .config/hypr/input.conf .config/hypr/bindings.conf .config/alacritty/alacritty.toml \
         .config/starship.toml .config/waybar/config.jsonc .zshrc \
         .local/bin/per-window-layout; do
  if [[ ! -e $HOME/$f ]]; then
    bad "$f — missing in \$HOME"
  elif diff -q "$DIR/home/$f" "$HOME/$f" >/dev/null 2>&1; then
    ok "$f"
  else
    note "$f — deployed but differs from the repo (local edit?)"
  fi
done

for s in "$HOME"/.local/bin/*; do
  [[ -e $s ]] || continue
  [[ -x $s ]] || bad "$(basename "$s") is not executable"
done

# ---------------------------------------------------------------------------
head_ "Keyboard: shortcuts in the ru layout"
# ---------------------------------------------------------------------------
if grep -q '^\s*resolve_binds_by_sym\s*=\s*false' "$HOME/.config/hypr/input.conf" 2>/dev/null; then
  ok "Hyprland resolves binds by key position"
else
  bad "resolve_binds_by_sym = false missing — SUPER+<letter> will break in ru"
fi

if grep -q '^\s*kb_layout\s*=\s*us' "$HOME/.config/hypr/input.conf" 2>/dev/null; then
  ok "Latin layout is first in kb_layout"
else
  bad "kb_layout must start with a Latin layout, otherwise binds resolve against Cyrillic"
fi

if command -v python3 >/dev/null && [[ -f $HOME/.config/alacritty/alacritty.toml ]]; then
  n=$(python3 - <<'PY' 2>/dev/null
import tomllib, os
p = os.path.expanduser("~/.config/alacritty/alacritty.toml")
try:
    b = tomllib.load(open(p, "rb"))["keyboard"]["bindings"]
    print(sum(1 for x in b if any(c in str(x.get("key","")) for c in "абвгдежзийклмнопрстуфхцчшщъыьэюя")))
except Exception:
    print(-1)
PY
)
  if [[ ${n:-0} -ge 50 ]]; then
    ok "Alacritty has $n Cyrillic bindings (TOML parses)"
  elif [[ ${n:-0} -eq -1 ]]; then
    bad "Alacritty TOML does not parse — the terminal will ignore the whole config"
  else
    bad "only ${n:-0} Cyrillic bindings — Ctrl/Alt+<letter> will not work in ru"
  fi
else
  note "python3 missing — skipped the Alacritty TOML check"
fi

# ---------------------------------------------------------------------------
head_ "Thermal: fans and power limit"
# ---------------------------------------------------------------------------
if [[ $MODEL != "$THIS_MODEL" ]]; then
  note "hardware is '$MODEL', not '$THIS_MODEL' — thermal fix does not apply here"
else
  for f in /etc/modprobe.d/bitland-mifs-fan-fix.conf \
           /usr/local/bin/set-power-limit.sh \
           /etc/systemd/system/power-limit.service \
           /etc/systemd/system/power-limit-resume.service \
           /etc/udev/rules.d/99-power-limit.rules; do
    rel="system${f}"
    if [[ ! -e $f ]]; then
      bad "$f — missing"
    elif diff -q "$DIR/$rel" "$f" >/dev/null 2>&1; then
      ok "$f"
    else
      bad "$f — differs from the repo"
    fi
  done

  [[ -x /usr/local/bin/set-power-limit.sh ]] ||
    bad "set-power-limit.sh is not executable"

  for u in power-limit power-limit-resume; do
    if [[ "$(systemctl is-enabled $u.service 2>/dev/null)" == enabled ]]; then
      ok "$u.service enabled"
    else
      bad "$u.service not enabled — PL1 will not be applied at boot"
    fi
  done

  # The fan fix itself
  if lsmod 2>/dev/null | grep -q '^bitland_mifs_wmi'; then
    bad "bitland_mifs_wmi is LOADED — fans will not spin. REBOOT required."
    note "PL1 is deliberately held at 28 W while the module is loaded"
  else
    ok "bitland_mifs_wmi not loaded — fan control works"
  fi

  # PL1 vs power source
  RAPL=/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
  AC=/sys/class/power_supply/ADP1/online
  if [[ -r $RAPL && -r $AC ]]; then
    now=$(( $(cat $RAPL) / 1000000 ))
    if lsmod 2>/dev/null | grep -q '^bitland_mifs_wmi'; then want=28
    elif [[ "$(cat $AC)" == 1 ]]; then want=45
    else want=28; fi
    src=$([[ "$(cat $AC)" == 1 ]] && echo AC || echo battery)
    if [[ $now -eq $want ]]; then
      ok "PL1 = ${now} W on ${src} (expected ${want} W)"
    else
      bad "PL1 = ${now} W on ${src}, expected ${want} W — run: sudo systemctl restart power-limit.service"
    fi
  else
    note "RAPL or ADP1 unreadable — skipped the PL1 check"
  fi
fi

# ---------------------------------------------------------------------------
head_ "Services and groups"
# ---------------------------------------------------------------------------
for u in docker.socket libvirtd; do
  systemctl is-enabled "$u" &>/dev/null && ok "$u enabled" || note "$u not enabled"
done
for g in docker libvirt kvm; do
  id -nG 2>/dev/null | tr ' ' '\n' | grep -qx "$g" && ok "member of $g" ||
    note "not in group $g yet — log out and back in"
done

# ---------------------------------------------------------------------------
head_ "Disk IO responsiveness"
# ---------------------------------------------------------------------------
want_dirty=268435456
got_dirty=$(cat /proc/sys/vm/dirty_bytes 2>/dev/null || echo 0)
if [[ $got_dirty == "$want_dirty" ]]; then
  ok "vm.dirty_bytes = 256M"
elif [[ $got_dirty == 0 ]]; then
  bad "vm.dirty_bytes unset — ratio-based limit lets multi-GB writeback stall the desktop"
else
  note "vm.dirty_bytes = $got_dirty (repo expects $want_dirty)"
fi

for d in /sys/block/nvme[0-9]n[0-9]; do
  [[ -e $d ]] || continue
  name=${d##*/}
  if grep -q '\[bfq\]' "$d/queue/scheduler" 2>/dev/null; then
    ok "$name scheduler = bfq"
  else
    note "$name scheduler = $(sed 's/.*\[\(.*\)\].*/\1/' "$d/queue/scheduler" 2>/dev/null)"
  fi
done

# ---------------------------------------------------------------------------
head_ "Idle power: PCIe runtime PM and ASPM"
# ---------------------------------------------------------------------------
for f in /etc/udev/rules.d/99-pcie-runtime-pm.rules /etc/tmpfiles.d/99-pcie-aspm.conf; do
  rel="system${f}"
  if [[ ! -e $f ]]; then
    bad "$f — missing"
  elif diff -q "$DIR/$rel" "$f" >/dev/null 2>&1; then
    ok "$f"
  else
    bad "$f — differs from the repo"
  fi
done

# The rule is only worth anything if devices actually flipped to "auto".
on=0; auto=0
for f in /sys/bus/pci/devices/*/power/control; do
  [[ -r $f ]] || continue
  [[ "$(cat "$f")" == on ]] && on=$((on+1)) || auto=$((auto+1))
done
if [[ $((on + auto)) -eq 0 ]]; then
  note "no PCI power/control attributes readable — skipped"
elif [[ $on -eq 0 ]]; then
  ok "PCI runtime PM: all $auto devices on 'auto'"
elif [[ $on -le 2 ]]; then
  ok "PCI runtime PM: $auto on 'auto', $on still 'on' (host bridge and friends)"
else
  bad "PCI runtime PM: $on devices still on 'on' — run: sudo udevadm trigger --subsystem-match=pci"
fi

# Both NVMe specifically: they are the reason this exists.
for d in /sys/class/nvme/nvme[0-9]; do
  [[ -e $d ]] || continue
  ctl="$d/device/power/control"
  [[ -r $ctl ]] || continue
  model=$(cat "$d/model" 2>/dev/null | xargs)
  if [[ "$(cat "$ctl")" == auto ]]; then
    ok "$(basename "$d") ($model) runtime PM = auto"
  else
    bad "$(basename "$d") ($model) runtime PM = on — will never enter D3"
  fi
done

ASPM=/sys/module/pcie_aspm/parameters/policy
if [[ ! -r $ASPM ]]; then
  note "pcie_aspm policy unreadable — skipped"
elif grep -q '\[powersave\]' "$ASPM"; then
  ok "PCIe ASPM policy = powersave"
elif grep -q '\[default\]' "$ASPM"; then
  bad "PCIe ASPM policy = default — firmware kept ASPM control, enable it in BIOS"
else
  note "PCIe ASPM policy = $(sed 's/.*\[\(.*\)\].*/\1/' "$ASPM")  (repo expects powersave)"
fi

# ---------------------------------------------------------------------------
printf '\n\033[1m%s\033[0m\n' "passed: $PASS   failed: $FAIL   notes: $SKIP"
if [[ $FAIL -gt 0 ]]; then
  printf '\033[31m%s\033[0m\n' "Something needs attention — see the ✗ lines above."
  exit 1
fi
printf '\033[32m%s\033[0m\n' "All good."
