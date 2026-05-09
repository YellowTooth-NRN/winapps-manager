#!/usr/bin/env python3
"""
WinApps Window Manager GUI (wmctrl-based) - English
Dependencies: python3-gi, wmctrl, xdotool
"""

import os
if not os.environ.get("DISPLAY"):
    os.environ["DISPLAY"] = ":0"
if not os.environ.get("WAYLAND_DISPLAY"):
    os.environ["WAYLAND_DISPLAY"] = "wayland-0"

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Gdk
import subprocess
import threading

APP_TITLE = "WinApps Manager"
REFRESH_INTERVAL = 3000


def get_xfreerdp_pid():
    try:
        result = subprocess.run(
            ['pgrep', '-f', 'xfreerdp3.*app:program'],
            capture_output=True, text=True
        )
        pid = result.stdout.strip().split('\n')[0]
        return pid if pid else None
    except Exception:
        return None


def get_winapps_windows():
    pid = get_xfreerdp_pid()
    if not pid:
        return []
    try:
        result = subprocess.run(['wmctrl', '-l', '-p'], capture_output=True, text=True)
        windows = []
        for line in result.stdout.strip().split('\n'):
            if not line:
                continue
            parts = line.split()
            if len(parts) < 5:
                continue
            wid = parts[0]
            wpid = parts[2]
            if wpid != pid:
                continue
            title = ' '.join(parts[4:]).strip()
            if not title or title == 'N/A':
                continue
            windows.append({'wid': wid, 'pid': wpid, 'title': title})
        return windows
    except Exception:
        return []


def close_window(wid):
    try:
        subprocess.run(['wmctrl', '-ic', wid], timeout=3)
        return True
    except Exception:
        return False


def raise_window(wid):
    try:
        subprocess.run(['wmctrl', '-ia', wid], timeout=3)
        return True
    except Exception:
        return False


def raise_all_windows():
    windows = get_winapps_windows()
    for w in windows:
        raise_window(w['wid'])
    return len(windows)


class WinAppsManager(Gtk.Window):
    def __init__(self):
        super().__init__(title=APP_TITLE)
        self.set_default_size(680, 400)
        self.set_border_width(0)

        css = b"""
        window { background-color: #1a1a2e; color: #e0e0e0; }
        .header { background-color: #16213e; border-bottom: 2px solid #e94560; padding: 12px 16px; }
        .title-label { font-size: 15px; font-weight: bold; color: #e94560; }
        .subtitle-label { font-size: 11px; color: #777; }
        .btn-raise { background-color: #1a3a1a; color: #6bff6b; border: 1px solid #2a6a2a; border-radius: 5px; padding: 5px 12px; font-size: 12px; }
        .btn-raise:hover { background-color: #2a6a2a; }
        .btn-normal { background-color: #0f3460; color: #e0e0e0; border: 1px solid #1a4a8a; border-radius: 5px; padding: 5px 12px; font-size: 12px; }
        .btn-normal:hover { background-color: #1a4a8a; }
        .btn-danger { background-color: #3a1a1a; color: #ff6b6b; border: 1px solid #6a2a2a; border-radius: 5px; padding: 5px 12px; font-size: 12px; }
        .btn-danger:hover { background-color: #6a2a2a; }
        treeview { background-color: #12192b; color: #d0d0d0; font-size: 12px; }
        treeview:selected { background-color: #0f3460; color: #ffffff; }
        .statusbar { background-color: #0d1017; border-top: 1px solid #0f3460; padding: 5px 14px; font-size: 11px; color: #666; }
        """
        sp = Gtk.CssProvider()
        sp.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), sp, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self._build_ui()
        self._refresh()
        GLib.timeout_add(REFRESH_INTERVAL, self._auto_refresh)
        GLib.timeout_add(10000, self._start_alive_check)

    def _build_ui(self):
        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add(root)

        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        header.get_style_context().add_class('header')
        info = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        t = Gtk.Label(label="WinApps Manager")
        t.get_style_context().add_class('title-label')
        t.set_halign(Gtk.Align.START)
        s = Gtk.Label(label="xfreerdp Window Manager")
        s.get_style_context().add_class('subtitle-label')
        s.set_halign(Gtk.Align.START)
        info.pack_start(t, False, False, 0)
        info.pack_start(s, False, False, 0)
        header.pack_start(info, True, True, 0)

        btns = Gtk.Box(spacing=6)
        b_raise_all = Gtk.Button(label="▲▲ Raise All")
        b_raise_all.get_style_context().add_class('btn-raise')
        b_raise_all.connect('clicked', self._on_raise_all)
        b_refresh = Gtk.Button(label="↻")
        b_refresh.get_style_context().add_class('btn-normal')
        b_refresh.connect('clicked', lambda _: self._refresh())
        b_lower_sel = Gtk.Button(label="▼ Minimize")
        b_lower_sel.get_style_context().add_class('btn-normal')
        b_lower_sel.connect('clicked', self._on_lower_selected)
        b_lower_all = Gtk.Button(label="▼▼ Minimize All")
        b_lower_all.get_style_context().add_class('btn-normal')
        b_lower_all.connect('clicked', self._on_lower_all)
        b_close_sel = Gtk.Button(label="✕ Close")
        b_close_sel.get_style_context().add_class('btn-danger')
        b_close_sel.connect('clicked', self._on_close_selected)
        b_kill = Gtk.Button(label="✕✕ Kill WinApps")
        b_kill.get_style_context().add_class('btn-danger')
        b_kill.connect('clicked', self._on_kill)
        btns.pack_start(b_raise_all, False, False, 0)
        btns.pack_start(b_lower_sel, False, False, 0)
        btns.pack_start(b_lower_all, False, False, 0)
        btns.pack_start(b_refresh, False, False, 0)
        btns.pack_start(b_close_sel, False, False, 0)
        btns.pack_start(b_kill, False, False, 0)
        header.pack_end(btns, False, False, 0)
        root.pack_start(header, False, False, 0)

        search_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        search_box.set_border_width(8)
        search_box.set_spacing(6)
        self.search_entry = Gtk.SearchEntry()
        self.search_entry.set_placeholder_text("Search window title...")
        self.search_entry.connect('search-changed', self._on_search)
        search_box.pack_start(Gtk.Label(label="🔍"), False, False, 0)
        search_box.pack_start(self.search_entry, True, True, 0)
        root.pack_start(search_box, False, False, 0)

        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scroll.set_vexpand(True)

        self.store = Gtk.ListStore(str, str)
        self.filter_store = self.store.filter_new()
        self.filter_store.set_visible_func(self._filter_func)

        self.tree = Gtk.TreeView(model=self.filter_store)
        self.tree.set_headers_visible(True)
        self.tree.connect('row-activated', self._on_row_activated)

        for title, idx, width in [("Window ID", 0, 100), ("Title", 1, 500)]:
            r = Gtk.CellRendererText()
            col = Gtk.TreeViewColumn(title, r, text=idx)
            col.set_min_width(width)
            col.set_resizable(True)
            self.tree.append_column(col)

        self.tree.get_selection().set_mode(Gtk.SelectionMode.SINGLE)
        scroll.add(self.tree)
        root.pack_start(scroll, True, True, 0)

        hint = Gtk.Label(label="💡 Double-click a row to raise that window")
        hint.get_style_context().add_class('statusbar')
        hint.set_halign(Gtk.Align.START)
        root.pack_end(hint, False, False, 0)

        self.status = Gtk.Label(label="Ready")
        self.status.get_style_context().add_class('statusbar')
        self.status.set_halign(Gtk.Align.START)
        root.pack_end(self.status, False, False, 0)

    def _filter_func(self, model, iter, data):
        keyword = self.search_entry.get_text().lower()
        if not keyword:
            return True
        return keyword in model[iter][1].lower()

    def _on_search(self, entry):
        self.filter_store.refilter()

    def _refresh(self):
        selected_wid = None
        sel = self.tree.get_selection()
        model, treeiter = sel.get_selected()
        if treeiter:
            selected_wid = model[treeiter][0]

        self.store.clear()
        pid = get_xfreerdp_pid()
        windows = get_winapps_windows()
        for w in windows:
            self.store.append([w['wid'], w['title']])

        if selected_wid:
            for i, row in enumerate(self.store):
                if row[0] == selected_wid:
                    self.tree.get_selection().select_path(Gtk.TreePath(i))
                    break

        if not pid:
            self.status.set_text("WinApps is not running")
        elif not windows:
            self.status.set_text(f"xfreerdp PID {pid} — No windows detected")
        else:
            self.status.set_text(f"{len(windows)} window(s) detected — PID {pid} — Auto-refresh every {REFRESH_INTERVAL//1000}s")

    def _start_alive_check(self):
        GLib.timeout_add(1000, self._check_winapps_alive)
        return False

    def _check_winapps_alive(self):
        if not get_winapps_windows():
            pid = get_xfreerdp_pid()
            if pid:
                subprocess.run(['kill', pid])
            GLib.timeout_add(500, Gtk.main_quit)
            return False
        return True

    def _auto_refresh(self):
        self._refresh()
        return True

    def _on_row_activated(self, tree, path, col):
        model = tree.get_model()
        wid = model[path][0]
        title = model[path][1]
        if raise_window(wid):
            self.status.set_text(f"↑ {title}")

    def _on_raise_all(self, _):
        def do_raise():
            n = raise_all_windows()
            GLib.idle_add(self.status.set_text, f"↑ {n} window(s) raised")
        threading.Thread(target=do_raise, daemon=True).start()

    def _on_lower_selected(self, _):
        selection = self.tree.get_selection()
        model, treeiter = selection.get_selected()
        if not treeiter:
            self.status.set_text("Please select a window first")
            return
        wid = model[treeiter][0]
        title = model[treeiter][1]
        subprocess.run(['xdotool', 'windowminimize', wid], timeout=3)
        self.status.set_text(f"▼ {title} minimized")
        GLib.timeout_add(500, self._refresh)

    def _on_lower_all(self, _):
        windows = get_winapps_windows()
        for w in windows:
            subprocess.run(['xdotool', 'windowminimize', w['wid']], timeout=3)
        self.status.set_text(f"▼ {len(windows)} window(s) minimized")
        GLib.timeout_add(500, self._refresh)

    def _on_close_selected(self, _):
        selection = self.tree.get_selection()
        model, treeiter = selection.get_selected()
        if not treeiter:
            self.status.set_text("Please select a window to close")
            return
        wid = model[treeiter][0]
        title = model[treeiter][1]
        if close_window(wid):
            self.status.set_text(f"✕ {title} closed")
            GLib.timeout_add(800, self._refresh)

    def _on_kill(self, _):
        pid = get_xfreerdp_pid()
        if not pid:
            self.status.set_text("WinApps is not running")
            return
        dialog = Gtk.MessageDialog(
            transient_for=self, flags=0,
            message_type=Gtk.MessageType.WARNING,
            buttons=Gtk.ButtonsType.YES_NO,
            text="Kill WinApps?",
        )
        dialog.format_secondary_text("All open Windows apps will be closed.")
        resp = dialog.run()
        dialog.destroy()
        if resp == Gtk.ResponseType.YES:
            pid = get_xfreerdp_pid()
            if pid:
                subprocess.run(['kill', pid])
            self.status.set_text("WinApps terminated")
            GLib.timeout_add(800, self._refresh)


def main():
    win = WinAppsManager()
    win.connect('destroy', Gtk.main_quit)
    win.show_all()
    Gtk.main()


if __name__ == '__main__':
    main()
