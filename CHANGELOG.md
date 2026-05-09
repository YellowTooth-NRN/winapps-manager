# Changelog

## [1.1.0] - 2026-05-09

### Bug Fixes

- **[Critical] Fixed unintended killing of unrelated xfreerdp sessions**
  - Previously, `pkill -f xfreerdp` killed ALL xfreerdp processes including non-WinApps RDP sessions
  - Now uses `kill <pid>` targeting only the specific WinApps process

- **[Critical] Fixed infinite GUI restart loop**
  - Non-WinApps xfreerdp sessions were incorrectly detected as WinApps, causing an infinite kill/restart loop
  - Fixed by filtering with `/app:program` flag (WinApps-specific)

- **[Fix] Monitor script now ignores non-WinApps RDP sessions**
  - `winapps-monitor.sh`: `pgrep -x "xfreerdp3"` → `pgrep -f "xfreerdp3.*app:program"`

- **[Fix] GUI PID detection is now WinApps-specific**
  - `get_xfreerdp_pid()`: `pgrep -f xfreerdp3` → `pgrep -f "xfreerdp3.*app:program"`

---

## [1.0.0] - 2026-05-07

### Initial Release

- GTK3 GUI with dark theme
- Window list with auto-refresh
- Raise all / Minimize / Close / Kill WinApps
- Window title search
- Auto-close when all WinApps windows are gone
- fish & bash shell functions (`wamgr`)
- Korean / English versions
- Supports Arch, Debian/Ubuntu, RHEL/Fedora
