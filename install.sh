#!/bin/bash
# WinApps Manager 설치 스크립트 / Install Script
# Supports: Arch Linux, Debian/Ubuntu, RHEL/Fedora

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/winappsmgr"
LANG_MODE="${1:-en}"  # en or ko

echo "=============================="
echo " WinApps Manager Installer"
echo "=============================="
echo ""

# 배포판 감지 / Detect distro
detect_distro() {
    if [ -f /etc/arch-release ]; then
        echo "arch"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ] || [ -f /etc/fedora-release ]; then
        echo "redhat"
    else
        echo "unknown"
    fi
}

# 의존성 설치 / Install dependencies
install_deps() {
    local distro
    distro=$(detect_distro)
    echo "[1/4] Installing dependencies ($distro)..."

    case "$distro" in
        arch)
            sudo pacman -S --needed python-gobject wmctrl xdotool xorg-xwininfo
            ;;
        debian)
            sudo apt update
            sudo apt install -y python3-gi python3-gi-cairo gir1.2-gtk-3.0 wmctrl xdotool x11-utils
            ;;
        redhat)
            sudo dnf install -y python3-gobject gtk3 wmctrl xdotool xorg-x11-utils
            ;;
        *)
            echo "WARNING: Unknown distro. Please install manually:"
            echo "  - python3-gobject (GTK3 bindings)"
            echo "  - wmctrl"
            echo "  - xdotool"
            ;;
    esac
}

# GUI 설치 / Install GUI
install_gui() {
    echo "[2/4] Installing GUI..."
    mkdir -p "$INSTALL_DIR"

    if [ "$LANG_MODE" = "ko" ]; then
        cp "$SCRIPT_DIR/gui/winapps-manager.ko.py" "$INSTALL_DIR/winapps-manager.py"
    else
        cp "$SCRIPT_DIR/gui/winapps-manager.py" "$INSTALL_DIR/winapps-manager.py"
    fi
    chmod +x "$INSTALL_DIR/winapps-manager.py"
}

# 쉘 함수 설치 / Install shell functions
install_shell() {
    echo "[3/4] Installing shell functions..."

    # fish
    if command -v fish > /dev/null 2>&1; then
        mkdir -p "$HOME/.config/fish/conf.d"
        if [ "$LANG_MODE" = "ko" ]; then
            cp "$SCRIPT_DIR/shell/fish/winapps-manager.ko.fish" "$HOME/.config/fish/conf.d/winapps-manager.fish"
        else
            cp "$SCRIPT_DIR/shell/fish/winapps-manager.fish" "$HOME/.config/fish/conf.d/winapps-manager.fish"
        fi
        echo "  → fish functions installed"
    fi

    # bash
    if [ "$LANG_MODE" = "ko" ]; then
        cp "$SCRIPT_DIR/shell/bash/winapps-manager.ko.bash" "$HOME/.winapps-manager.bash"
    else
        cp "$SCRIPT_DIR/shell/bash/winapps-manager.bash" "$HOME/.winapps-manager.bash"
    fi

    if ! grep -q "winapps-manager.bash" "$HOME/.bashrc" 2>/dev/null; then
        echo "source $HOME/.winapps-manager.bash" >> "$HOME/.bashrc"
    fi
    echo "  → bash functions installed"
}

# 모니터 & 자동시작 설치 / Install monitor & autostart
install_monitor() {
    echo "[4/4] Installing monitor & autostart..."
    cp "$SCRIPT_DIR/monitor/winapps-monitor.sh" "$INSTALL_DIR/winapps-monitor.sh"
    chmod +x "$INSTALL_DIR/winapps-monitor.sh"

    mkdir -p "$HOME/.config/autostart"
    sed "s|/PATH/TO/winapps-monitor.sh|$INSTALL_DIR/winapps-monitor.sh|g" \
        "$SCRIPT_DIR/autostart/winapps-monitor.desktop" \
        > "$HOME/.config/autostart/winapps-monitor.desktop"
    echo "  → autostart registered"
}

# 실행 / Run
install_deps
install_gui
install_shell
install_monitor

echo ""
echo "=============================="
echo " Installation complete!"
echo "=============================="
echo ""
echo "Usage:"
echo "  wamgr          — Show help"
echo "  wamgr list     — List windows"
echo "  wamgr raise    — Raise all windows"
echo "  wamgr gui      — Launch GUI"
echo ""
echo "Reload shell: source ~/.bashrc  (or open a new terminal)"
