#!/bin/bash
# WinApps Window Manager - bash functions (wmctrl-based)
# Install: add to ~/.bashrc or ~/.bash_aliases
# source /path/to/winapps-manager.bash

__wamgr_get_pid() {
    ps aux | grep xfreerdp | grep -v grep | awk '{print $2}' | head -1
}

wamgr-list() {
    local xpid
    xpid=$(__wamgr_get_pid)
    if [ -z "$xpid" ]; then
        echo "No WinApps running (xfreerdp not found)"
        return
    fi

    echo "=== WinApps Window List (xfreerdp PID: $xpid) ==="
    echo ""
    printf "%-12s %s\n" "Window ID" "Title"
    echo "─────────────────────────────────────────────"

    local found=0
    while IFS= read -r line; do
        if echo "$line" | grep -q "$xpid"; then
            local wid title
            wid=$(echo "$line" | awk '{print $1}')
            title=$(echo "$line" | awk '{for(i=5;i<=NF;i++) printf $i" "; print ""}' | sed 's/^ *//;s/ *$//')
            if [ -n "$title" ] && [ "$title" != "N/A" ]; then
                printf "%-12s %s\n" "$wid" "$title"
                found=$((found + 1))
            fi
        fi
    done < <(wmctrl -l -p 2>/dev/null)

    if [ "$found" -eq 0 ]; then
        echo "(No windows visible)"
    else
        echo ""
        echo "Total: $found window(s)"
    fi
}

wamgr-raise() {
    local xpid keyword raised=0
    xpid=$(__wamgr_get_pid)
    keyword="${1:-}"

    if [ -z "$xpid" ]; then
        echo "No WinApps running"
        return
    fi

    while IFS= read -r line; do
        if echo "$line" | grep -q "$xpid"; then
            local wid title
            wid=$(echo "$line" | awk '{print $1}')
            title=$(echo "$line" | awk '{for(i=5;i<=NF;i++) printf $i" "; print ""}' | sed 's/^ *//;s/ *$//')
            if [ -z "$keyword" ] || echo "$title" | grep -qi "$keyword"; then
                wmctrl -ia "$wid" 2>/dev/null && echo "↑ $title"
                raised=$((raised + 1))
            fi
        fi
    done < <(wmctrl -l -p 2>/dev/null)

    [ "$raised" -eq 0 ] && echo "No windows to raise" || echo "Total: $raised window(s) raised"
}

wamgr-kill() {
    local xpid
    xpid=$(__wamgr_get_pid)

    if [ -z "$xpid" ]; then
        echo "No WinApps running"
        return
    fi

    if [ "$1" = "-f" ]; then
        pkill -9 -f xfreerdp
        echo "Force killed"
        return
    fi

    echo -n "Kill WinApps (PID: $xpid)? [y/N] "
    read -r confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        kill "$xpid" 2>/dev/null && echo "Killed" || { pkill -f xfreerdp && echo "Force killed"; }
    else
        echo "Cancelled"
    fi
}

wamgr-restart() {
    echo "Terminating WinApps RDP connection..."
    pkill -f xfreerdp 2>/dev/null
    sleep 1
    echo "Done. Please relaunch your app."
}

wamgr() {
    case "${1:-}" in
        list|ls|l)    wamgr-list ;;
        raise|show|r) wamgr-raise "${2:-}" ;;
        kill|stop|k)  wamgr-kill "${2:-}" ;;
        restart)      wamgr-restart ;;
        gui|g)        python3 "$HOME/winappsmgr/winapps-manager.py" & ;;
        *)
            echo "WinApps Manager (wamgr)"
            echo ""
            echo "Usage:"
            echo "  wamgr list              — List open windows"
            echo "  wamgr raise             — Raise all windows"
            echo "  wamgr raise <keyword>   — Raise window by title"
            echo "  wamgr kill              — Kill WinApps"
            echo "  wamgr kill -f           — Force kill"
            echo "  wamgr restart           — Restart RDP connection"
            echo "  wamgr gui               — Launch GUI"
            ;;
    esac
}
