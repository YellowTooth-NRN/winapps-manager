#!/bin/bash
# WinApps Monitor - Auto-launch GUI when WinApps is running
# Modify TARGET_PY to match your installation path

TARGET_PY="$HOME/winappsmgr/winapps-manager.py"
UID_NUM=$(id -u)

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${UID_NUM}/bus"
export XDG_RUNTIME_DIR="/run/user/${UID_NUM}"
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0

ABSENT_COUNT=0
ABSENT_THRESHOLD=3
WAGUI_PID=""

while true; do
    if pgrep -x "xfreerdp3" > /dev/null; then
        ABSENT_COUNT=0
        if ! pgrep -f "winapps-manager.py" > /dev/null; then
            DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 python3 "$TARGET_PY" &
            WAGUI_PID=$!
        fi
    else
        ABSENT_COUNT=$((ABSENT_COUNT + 1))
        if [ "$ABSENT_COUNT" -ge "$ABSENT_THRESHOLD" ]; then
            ABSENT_COUNT=0
            pkill -f "winapps-manager.py" 2>/dev/null
        fi
    fi
    sleep 1
done
