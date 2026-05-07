# WinApps Manager

KDE Wayland에서 WinApps(xfreerdp) 창을 관리하는 경량 GUI/CLI 도구입니다.

> English README: [README.md](README.md)

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)
![DE](https://img.shields.io/badge/DE-KDE%20Wayland-blue.svg)

---

## 기능

- **GUI** — GTK3 기반 다크 테마 창 관리자
  - 열린 WinApps 창 목록 표시
  - 전체 올리기 / 선택 내리기 / 전체 내리기 / 선택 닫기 / WinApps 종료
  - 창 제목 검색
  - 더블클릭으로 특정 창 바로 올리기
  - 모든 창이 사라지면 자동 종료
- **CLI** (`wamgr`) — fish & bash 쉘 함수
  - `wamgr list` — 열린 창 목록
  - `wamgr raise [검색어]` — 창 올리기
  - `wamgr kill [-f]` — WinApps 종료
  - `wamgr gui` — GUI 실행
- **모니터** — WinApps 실행 시 GUI 자동 실행

---

## 요구사항

| 패키지 | Arch | Debian/Ubuntu | RHEL/Fedora |
|---|---|---|---|
| python3-gobject | `python-gobject` | `python3-gi` | `python3-gobject` |
| wmctrl | `wmctrl` | `wmctrl` | `wmctrl` |
| xdotool | `xdotool` | `xdotool` | `xdotool` |

---

## 설치

```bash
git clone https://github.com/YellowTooth-NRN/winapps-manager.git
cd winapps-manager
chmod +x install.sh

# 한국어 버전
bash install.sh ko

# 영어 버전
bash install.sh
```

---

## 수동 설치

### GUI만 설치
```bash
mkdir -p ~/winappsmgr
cp gui/winapps-manager.ko.py ~/winappsmgr/winapps-manager.py
```

### 쉘 함수 (fish)
```bash
cp shell/fish/winapps-manager.ko.fish ~/.config/fish/conf.d/winapps-manager.fish
```

### 쉘 함수 (bash)
```bash
echo "source /path/to/winapps-manager.ko.bash" >> ~/.bashrc
```

### 자동시작 (KDE)
```bash
cp autostart/winapps-monitor.desktop ~/.config/autostart/
# .desktop 파일의 Exec 경로를 수정하세요
```

---

## 사용법

### GUI
```bash
wamgr gui
# 또는 직접 실행
python3 ~/winappsmgr/winapps-manager.py
```

### CLI
```bash
wamgr list            # 열린 WinApps 창 목록
wamgr raise           # 모든 창 올리기
wamgr raise notepad   # "notepad" 검색해서 올리기
wamgr kill            # WinApps 종료 (확인 후)
wamgr kill -f         # 강제 종료
wamgr restart         # RDP 연결 재시작
```

### 예시: WinApps 탐색기 실행 + 자동 GUI (fish)
fish 설정에 추가:
```fish
function winexp
    pkill -f winapps-manager.py 2>/dev/null
    pkill -f winapps-monitor.sh 2>/dev/null
    sleep 2
    bash ~/winappsmgr/winapps-monitor.sh &
    disown
    winapps manual "C:/Windows/explorer.exe" $argv &
    disown
end
```

---

## 참고사항

- **KDE Wayland** + **WinApps**(xfreerdp3) 환경에서 동작
- 창 감지는 `wmctrl` 사용 — XWayland를 통해 동작
- RAIL 프로토콜 창(일부 32비트 앱 등)은 감지가 안 될 수 있음
- **CachyOS / Arch Linux** 에서 테스트됨

---

## 라이선스

MIT License — [LICENSE](LICENSE) 참고

## 작성자

[YellowTooth-NRN](https://github.com/YellowTooth-NRN)
