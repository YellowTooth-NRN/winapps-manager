# WinApps 창 관리 fish 함수 모음 (wmctrl 기반)
# 설치: ~/.config/fish/conf.d/winapps-manager.fish 에 복사

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
        echo "실행 중인 WinApps 없음 (xfreerdp 프로세스 없음)"
        return
    end

    echo "=== WinApps 창 목록 (xfreerdp PID: $xpid) ==="
    echo ""
    printf "%-12s %s\n" "창 ID" "제목"
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
        echo "(표시된 창 없음)"
    else
        echo ""
        echo "총 $found 개 창"
    end
end

function wamgr-raise
    set xpid (__wamgr_get_pid)
    if test -z "$xpid"
        echo "실행 중인 WinApps 없음"
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
        echo "올릴 수 있는 창이 없습니다"
    else
        echo "총 $raised 개 창 활성화"
    end
end

function wamgr-kill
    set xpid (__wamgr_get_pid)
    if test -z "$xpid"
        echo "실행 중인 WinApps 없음"
        return
    end

    if test "$argv[1]" = "-f"
        pkill -9 -f xfreerdp
        echo "강제 종료됨"
        return
    end

    echo "WinApps (xfreerdp PID: $xpid) 를 종료하시겠습니까?"
    read -P "[y/N] " confirm

    if test "$confirm" = "y" -o "$confirm" = "Y"
        kill $xpid 2>/dev/null
        and echo "종료됨 (PID $xpid)"
        or pkill -f xfreerdp; and echo "강제 종료됨"
    else
        echo "취소"
    end
end

function wamgr-restart
    echo "WinApps RDP 연결을 종료합니다..."
    pkill -f xfreerdp 2>/dev/null
    sleep 1
    echo "완료. 앱을 다시 실행하세요."
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
            echo "WinApps 관리자 (wamgr)"
            echo ""
            echo "사용법:"
            echo "  wamgr list              — 열린 창 목록"
            echo "  wamgr raise             — 모든 창 앞으로 올리기"
            echo "  wamgr raise <검색어>    — 특정 창 찾아서 올리기"
            echo "  wamgr kill              — WinApps 종료"
            echo "  wamgr kill -f           — 강제 종료"
            echo "  wamgr restart           — RDP 재연결"
            echo "  wamgr gui               — GUI 실행"
    end
end
