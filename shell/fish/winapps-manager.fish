# WinApps Window Manager - fish shell functions (wmctrl-based)
# Install: copy to ~/.config/fish/conf.d/winapps-manager.fish

function __wamgr_get_pid
    ps aux | grep xfreerdp | grep -v grep | awk '{print $2}' | head -1
end

function __wamgr_get_windows
    set xpid (__wamgr_get_pid)
    if test -z "$xpid"
        return
    end
    wmctrl -l -p | grep $xpid 2>/dev/null
end

function wamgr-list
    set xpid (__wamgr_get_pid)
    if test -z "$xpid"
        echo "No WinApps running (xfreerdp process not found)"
        return
    end

    echo "=== WinApps Window List (xfreerdp PID: $xpid) ==="
    echo ""
    printf "%-12s %s\n" "Window ID" "Title"
    echo "─────────────────────────────────────────────"

    set found 0
    wmctrl -l -p | while read -l line
        if echo $line | grep -q $xpid
            set wid (echo $line | awk '{print $1}')
            set title (echo $line | awk '{for(i=5;i<=NF;i++) printf $i" "; print ""}' | sed 's/^ *//' | sed 's/ *$//')
            if test -n "$title" -a "$title" != "N/A"
                printf "%-12s %s\n" $wid $title
                set found (math $found + 1)
            end
        end
    end

    if test $found -eq 0
        echo "(No windows visible)"
    else
        echo ""
        echo "Total: $found window(s)"
    end
end

function wamgr-raise
    set xpid (__wamgr_get_pid)
    if test -z "$xpid"
        echo "No WinApps running"
        return
    end

    set keyword $argv[1]
    set raised 0

    wmctrl -l -p | while read -l line
        if echo $line | grep -q $xpid
            set wid (echo $line | awk '{print $1}')
            set title (echo $line | awk '{for(i=5;i<=NF;i++) printf $i" "; print ""}' | sed 's/^ *//' | sed 's/ *$//')

            if test -z "$keyword"
                wmctrl -ia $wid 2>/dev/null
                and echo "↑ $title"
                set raised (math $raised + 1)
            else
                if echo $title | grep -qi "$keyword"
                    wmctrl -ia $wid 2>/dev/null
                    and echo "↑ $title"
                    set raised (math $raised + 1)
                end
            end
        end
    end

    if test $raised -eq 0
        echo "No windows to raise"
    else
        echo "Total: $raised window(s) raised"
    end
end

function wamgr-kill
    set xpid (__wamgr_get_pid)
    if test -z "$xpid"
        echo "No WinApps running"
        return
    end

    if test "$argv[1]" = "-f"
        pkill -9 -f xfreerdp
        echo "Force killed"
        return
    end

    echo "Kill WinApps (xfreerdp PID: $xpid)?"
    read -P "[y/N] " confirm

    if test "$confirm" = "y" -o "$confirm" = "Y"
        kill $xpid 2>/dev/null
        and echo "Killed (PID $xpid)"
        or pkill -f xfreerdp; and echo "Force killed"
    else
        echo "Cancelled"
    end
end

function wamgr-restart
    echo "Terminating WinApps RDP connection..."
    pkill -f xfreerdp 2>/dev/null
    sleep 1
    echo "Done. Please relaunch your app."
end

function wamgr
    switch $argv[1]
        case list ls l
            wamgr-list
        case raise show r
            wamgr-raise $argv[2..]
        case kill stop k
            wamgr-kill $argv[2..]
        case restart
            wamgr-restart
        case gui g
            python3 $HOME/winappsmgr/winapps-manager.py &
        case '*'
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
    end
end
