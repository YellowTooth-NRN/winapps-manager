#!/bin/bash
# WinApps 창 관리 bash 함수 모음 (wmctrl 기반)
# 설치: source ~/.bashrc 또는 ~/.bash_aliases 에 추가
# source /path/to/winapps-manager.ko.bash

__wamgr_get_pid() {
    ps aux | grep xfreerdp | grep -v grep | awk '{print $2}' | head -1
}

wamgr-list() {
    local xpid
    xpid=$(__wamgr_get_pid)
    if [ -z "$xpid" ]; then
        echo "실행 중인 WinApps 없음"
        return
    fi

    echo "=== WinApps 창 목록 (xfreerdp PID: $xpid) ==="
    echo ""
    printf "%-12s %s\n" "창 ID" "제목"
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
        echo "(표시된 창 없음)"
    else
        echo ""
        echo "총 $found 개 창"
    fi
}

wamgr-raise() {
    local xpid keyword raised=0
    xpid=$(__wamgr_get_pid)
    keyword="${1:-}"

    if [ -z "$xpid" ]; then
        echo "실행 중인 WinApps 없음"
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

    [ "$raised" -eq 0 ] && echo "올릴 수 있는 창이 없습니다" || echo "총 $raised 개 창 활성화"
}

wamgr-kill() {
    local xpid
    xpid=$(__wamgr_get_pid)

    if [ -z "$xpid" ]; then
        echo "실행 중인 WinApps 없음"
        return
    fi

    if [ "$1" = "-f" ]; then
        pkill -9 -f xfreerdp
        echo "강제 종료됨"
        return
    fi

    echo -n "WinApps (PID: $xpid) 를 종료하시겠습니까? [y/N] "
    read -r confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        kill "$xpid" 2>/dev/null && echo "종료됨" || { pkill -f xfreerdp && echo "강제 종료됨"; }
    else
        echo "취소"
    fi
}

wamgr-restart() {
    echo "WinApps RDP 연결을 종료합니다..."
    pkill -f xfreerdp 2>/dev/null
    sleep 1
    echo "완료. 앱을 다시 실행하세요."
}

wamgr() {
    case "${1:-}" in
        list|ls|l)    wamgr-list ;;
        raise|show|r) wamgr-raise "${2:-}" ;;
        kill|stop|k)  wamgr-kill "${2:-}" ;;
        restart)      wamgr-restart ;;
        gui|g)        python3 "$HOME/winappsmgr/winapps-manager.py" & ;;
        *)
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
            ;;
    esac
}
