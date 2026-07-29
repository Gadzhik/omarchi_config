#!/bin/bash
# PL1 в зависимости от источника питания.
# От сети 45W (штатный максимум по intel-rapl-mmio), от батареи 28W (дефолт прошивки).
# Требует рабочего обдува: bitland_mifs_wmi должен быть заблокирован.

RAPL=/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
AC=/sys/class/power_supply/ADP1/online

AC_LIMIT=45000000
BAT_LIMIT=28000000

[ -w "$RAPL" ] || { echo "нет доступа к $RAPL" >&2; exit 1; }
[ -r "$AC" ]   || { echo "нет $AC" >&2; exit 1; }

# Страховка: без обдува высокий лимит опасен (35W давали 100C за 30с).
if lsmod | grep -q '^bitland_mifs_wmi'; then
    echo "bitland_mifs_wmi загружен — обдув не работает, высокий лимит не применяю" >&2
    echo "$BAT_LIMIT" > "$RAPL"
    exit 0
fi

if [ "$(cat $AC)" = "1" ]; then
    echo "$AC_LIMIT" > "$RAPL"
else
    echo "$BAT_LIMIT" > "$RAPL"
fi
