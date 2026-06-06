#!/usr/bin/env bash
# Emits one pipe-delimited line: CPU%|RAM_GiB|NET_ICON|BT_ICON|BATTERY_ICON|VOLUME_ICON
# Called every second by the Quickshell status timer in shell.qml.
# No set -euo pipefail — many subcommands are optional and may not be present.

# ─── CPU ─────────────────────────────────────────────────────────────────────
# Sum user + system + steal fields from top's Cpu(s) line.
CPU_RAW=$(top -bn1 | awk '/^%Cpu/ {print $2+$4+$6}')
CPU_USAGE=$(awk -v cpu="$CPU_RAW" 'BEGIN { printf "%.1f%%", cpu }')

# Some top builds use a different column layout and return empty or 0.0% even
# under load; fall back to deriving usage from the idle percentage instead.
if [ -z "$CPU_USAGE" ] || [ "$CPU_USAGE" = "0.0%" ]; then
    CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/")
    CPU_USAGE=$(awk -v idle="$CPU_IDLE" 'BEGIN { printf "%.1f%%", 100 - idle }')
fi

# ─── RAM ─────────────────────────────────────────────────────────────────────
RAM_USAGE=$(free -m | awk '/Mem:/ { printf "%0.1fG", $3/1024 }')

# ─── Network ─────────────────────────────────────────────────────────────────
# Ethernet takes priority over Wi-Fi. Scan all en* interfaces and record
# whether any is fully routable (up) or just physically plugged in (carrier only).
LAN_STATE="none"   # none | plugged | up
for intf in $(ls /sys/class/net/ 2>/dev/null | grep '^en'); do
    operstate=$(cat /sys/class/net/$intf/operstate 2>/dev/null)
    carrier=$(cat /sys/class/net/$intf/carrier 2>/dev/null)
    if [ "$operstate" = "up" ]; then
        LAN_STATE="up"
        break
    elif [ "$carrier" = "1" ] && [ "$LAN_STATE" != "up" ]; then
        LAN_STATE="plugged"
    fi
done

if [ "$LAN_STATE" = "up" ]; then
    WIFI_ICON="󰈁"   # ethernet routable
elif [ "$LAN_STATE" = "plugged" ]; then
    WIFI_ICON="󰈂"   # cable present, link not yet up
else
    # No ethernet — inspect the first wireless interface.
    WIFI_INTF=$(ip link | awk -F': ' '/wl/ {print $2}' | head -n 1)
    [ -z "$WIFI_INTF" ] && WIFI_INTF="wlan0"

    if [ -f "/sys/class/net/$WIFI_INTF/operstate" ] && \
       [ "$(cat /sys/class/net/$WIFI_INTF/operstate)" = "up" ]; then
        # /proc/net/wireless reports link quality out of 70 on most Linux drivers;
        # normalise to 0–100 so the thresholds below are intuitive.
        WIFI_SIGNAL=$(awk -v iface="$WIFI_INTF" '
            $1 ~ iface":" {
                gsub(/\./, "", $3)
                printf "%d", ($3 / 70) * 100
            }
        ' /proc/net/wireless 2>/dev/null)
        : "${WIFI_SIGNAL:=100}"   # default to full strength if the file is unreadable

        if   [ "$WIFI_SIGNAL" -ge 75 ]; then WIFI_ICON="󰤨"
        elif [ "$WIFI_SIGNAL" -ge 50 ]; then WIFI_ICON="󰤥"
        elif [ "$WIFI_SIGNAL" -ge 25 ]; then WIFI_ICON="󰤢"
        elif [ "$WIFI_SIGNAL" -gt  0 ]; then WIFI_ICON="󰤟"
        else                                  WIFI_ICON="󰤯"
        fi
    else
        WIFI_ICON="󰤮"   # interface exists but is not up
    fi
fi

# ─── Bluetooth ───────────────────────────────────────────────────────────────
if command -v bluetoothctl &>/dev/null && \
   bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    BLUETOOTH_ICON="󰂯"
else
    BLUETOOTH_ICON="󰂲"
fi

# ─── Battery ─────────────────────────────────────────────────────────────────
# Divide capacity into 10% buckets (0–10) and select a glyph from the
# appropriate charging or discharging icon set.
if [ -d /sys/class/power_supply/BAT0 ]; then
    BAT_PCT=$(cat /sys/class/power_supply/BAT0/capacity)
    BAT_STAT=$(cat /sys/class/power_supply/BAT0/status)
    BUCKET=$(( BAT_PCT / 10 ))
    [ "$BUCKET" -gt 10 ] && BUCKET=10

    if [ "$BAT_STAT" = "Charging" ]; then
        case "$BUCKET" in
            0)  GLYPH="󰢟" ;;  1)  GLYPH="󰢜" ;;  2)  GLYPH="󰂆" ;;
            3)  GLYPH="󰂇" ;;  4)  GLYPH="󰂈" ;;  5)  GLYPH="󰢝" ;;
            6)  GLYPH="󰂉" ;;  7)  GLYPH="󰢞" ;;  8)  GLYPH="󰂊" ;;
            9)  GLYPH="󰂋" ;;  10) GLYPH="󰂅" ;;
        esac
    else
        case "$BUCKET" in
            0)  GLYPH="󰂎" ;;  1)  GLYPH="󰁺" ;;  2)  GLYPH="󰁻" ;;
            3)  GLYPH="󰁼" ;;  4)  GLYPH="󰁽" ;;  5)  GLYPH="󰁾" ;;
            6)  GLYPH="󰁿" ;;  7)  GLYPH="󰂀" ;;  8)  GLYPH="󰂁" ;;
            9)  GLYPH="󰂂" ;;  10) GLYPH="󰁹" ;;
        esac
    fi
    BAT_ICON="${GLYPH}"
else
    BAT_ICON="󰂅"   # no battery present — show full/AC icon
fi

# ─── Volume ──────────────────────────────────────────────────────────────────
VOL_RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo "Volume: 0.00")
VOL=$(awk '{printf "%d", $2 * 100}' <<< "$VOL_RAW")
if   echo "$VOL_RAW" | grep -q '\[MUTED\]'; then VOL_ICON="󰝟"
elif [ "$VOL" -ge 67 ];                     then VOL_ICON="󰕾"
elif [ "$VOL" -ge 34 ];                     then VOL_ICON="󰕾"
else                                              VOL_ICON="󰕾"
fi

# ─── Output ──────────────────────────────────────────────────────────────────
echo "${CPU_USAGE}|${RAM_USAGE}|${WIFI_ICON}|${BLUETOOTH_ICON}|${BAT_ICON}|${VOL_ICON}"
