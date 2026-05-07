# WinApps Manager

A lightweight GUI and CLI tool for managing WinApps (xfreerdp) windows on KDE Wayland.

> 한국어 README: [README.ko.md](README.ko.md)

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)
![DE](https://img.shields.io/badge/DE-KDE%20Wayland-blue.svg)

---

## Features

- **GUI** — GTK3-based window manager with dark theme
  - List all open WinApps windows
  - Raise all / minimize selected / minimize all / close selected / kill WinApps
  - Search by window title
  - Double-click to raise a specific window
  - Auto-closes when all WinApps windows are gone
- **CLI** (`wamgr`) — fish & bash shell functions
  - `wamgr list` — List open windows
  - `wamgr raise [keyword]` — Raise windows
  - `wamgr kill [-f]` — Kill WinApps
  - `wamgr gui` — Launch GUI
- **Monitor** — Auto-launches GUI when WinApps starts

---

## Requirements

| Package | Arch | Debian/Ubuntu | RHEL/Fedora |
|---|---|---|---|
| python3-gobject | `python-gobject` | `python3-gi` | `python3-gobject` |
| wmctrl | `wmctrl` | `wmctrl` | `wmctrl` |
| xdotool | `xdotool` | `xdotool` | `xdotool` |

---

## Installation

```bash
git clone https://github.com/YellowTooth-NRN/winapps-manager.git
cd winapps-manager
chmod +x install.sh

# English version
bash install.sh

# Korean version
bash install.sh ko
```

---

## Manual Installation

### GUI only
```bash
mkdir -p ~/winappsmgr
cp gui/winapps-manager.py ~/winappsmgr/
```

### Shell functions (fish)
```bash
cp shell/fish/winapps-manager.fish ~/.config/fish/conf.d/
```

### Shell functions (bash)
```bash
echo "source /path/to/winapps-manager.bash" >> ~/.bashrc
```

### Autostart (KDE)
```bash
cp autostart/winapps-monitor.desktop ~/.config/autostart/
# Edit the Exec path in the .desktop file
```

---

## Usage

### GUI
```bash
wamgr gui
# or directly
python3 ~/winappsmgr/winapps-manager.py
```

### CLI
```bash
wamgr list          # List open WinApps windows
wamgr raise         # Raise all windows
wamgr raise notepad # Raise window matching "notepad"
wamgr kill          # Kill WinApps (with confirmation)
wamgr kill -f       # Force kill
wamgr restart       # Restart RDP connection
```

### Example: Launch WinApps Explorer with auto GUI (fish)
Add to your fish config:
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

## Notes

- Designed for **KDE Wayland** with **WinApps** (xfreerdp3)
- Window detection uses `wmctrl` — works via XWayland
- RAIL protocol windows (e.g. some 32-bit apps) may not be detectable
- Tested on **CachyOS / Arch Linux**

---

## License

MIT License — see [LICENSE](LICENSE)

## Author

[YellowTooth-NRN](https://github.com/YellowTooth-NRN)
