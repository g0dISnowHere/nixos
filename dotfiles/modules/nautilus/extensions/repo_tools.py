import os
import subprocess
import urllib.parse
from datetime import datetime

from gi.repository import GObject, Gtk, Nautilus


class RepoToolsExtension(
    GObject.GObject, Nautilus.MenuProvider, Nautilus.PropertyPageProvider
):
    def _format_bytes(self, size):
        units = ["B", "KiB", "MiB", "GiB", "TiB"]
        value = float(size)
        for unit in units:
            if value < 1024.0 or unit == units[-1]:
                if unit == "B":
                    return f"{int(value)} {unit}"
                return f"{value:.1f} {unit}"
            value /= 1024.0

    def _format_timestamp(self, timestamp):
        try:
            return datetime.fromtimestamp(timestamp).isoformat(
                sep=" ", timespec="seconds"
            )
        except Exception:
            return "unknown"

    def _notify(self, title, body):
        try:
            subprocess.Popen(["notify-send", title, body])
        except Exception:
            pass

    def _copy_text(self, text, title, body):
        try:
            subprocess.run(
                ["wl-copy"],
                input=text,
                text=True,
                check=True,
            )
            self._notify(title, body)
        except Exception as exc:
            self._notify(title, f"Failed: {exc}")

    def _path_from_file(self, file_info):
        if file_info is None:
            return None
        uri = file_info.get_uri()
        if not uri or not uri.startswith("file://"):
            return None
        return urllib.parse.unquote(uri[7:])

    def _mime_type_from_file(self, file_info):
        try:
            return file_info.get_mime_type() or "unknown"
        except Exception:
            return "unknown"

    def _safe_stat(self, path):
        try:
            return os.stat(path)
        except Exception:
            return None

    def _read_exif_summary(self, path):
        try:
            result = subprocess.run(
                [
                    "exiftool",
                    "-s3",
                    "-Model",
                    "-LensModel",
                    "-DateTimeOriginal",
                    "-ImageSize",
                    path,
                ],
                capture_output=True,
                text=True,
                check=True,
            )
        except Exception:
            return []

        values = [line.strip() for line in result.stdout.splitlines() if line.strip()]
        labels = ["Camera", "Lens", "Taken", "Image size"]
        return [(label, value) for label, value in zip(labels, values) if value]

    def _metadata_rows(self, file_info):
        path = self._path_from_file(file_info)
        if not path:
            return []

        stat_info = self._safe_stat(path)
        rows = [
            ("Path", path),
            ("Type", self._mime_type_from_file(file_info)),
        ]

        if stat_info is not None:
            rows.extend(
                [
                    ("Size", self._format_bytes(stat_info.st_size)),
                    ("Modified", self._format_timestamp(stat_info.st_mtime)),
                    ("Created", self._format_timestamp(stat_info.st_ctime)),
                ]
            )

        if os.path.isfile(path):
            rows.extend(self._read_exif_summary(path))

        return rows

    def _build_property_page(self, title, rows):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_border_width(12)

        grid = Gtk.Grid(column_spacing=16, row_spacing=8)
        grid.set_hexpand(True)
        grid.set_vexpand(True)

        for index, (label_text, value_text) in enumerate(rows):
            label = Gtk.Label(label=f"{label_text}:", xalign=0)
            label.get_style_context().add_class("heading")
            value = Gtk.Label(xalign=0, selectable=True, wrap=True)
            value.set_text(value_text)
            grid.attach(label, 0, index, 1, 1)
            grid.attach(value, 1, index, 1, 1)

        box.append(grid)
        box.show()

        page_label = Gtk.Label(label=title)
        return Nautilus.PropertyPage(
            name="RepoToolsExtension::Metadata", label=page_label, page=box
        )

    def _selected_paths(self, files):
        paths = []
        for file_info in files:
            path = self._path_from_file(file_info)
            if path:
                paths.append(path)
        return paths

    def _launch_terminal(self, directory):
        try:
            subprocess.Popen(["alacritty", "--working-directory", directory])
        except Exception as exc:
            self._notify("Open in terminal", f"Failed: {exc}")

    def _copy_paths(self, files):
        paths = self._selected_paths(files)
        if not paths:
            return
        self._copy_text(
            "\n".join(paths),
            "Paths copied",
            f"Copied {len(paths)} path(s) to the clipboard.",
        )

    def _copy_relative_paths(self, files):
        paths = self._selected_paths(files)
        if not paths:
            return

        if len(paths) == 1:
            base_dir = os.path.dirname(paths[0])
        else:
            common_path = os.path.commonpath(paths)
            base_dir = (
                common_path
                if os.path.isdir(common_path)
                else os.path.dirname(common_path)
            )

        relative_paths = [os.path.relpath(path, base_dir) for path in paths]
        self._copy_text(
            "\n".join(relative_paths),
            "Relative paths copied",
            f"Copied {len(relative_paths)} relative path(s) to the clipboard.",
        )

    def _copy_sha256(self, files):
        paths = self._selected_paths(files)
        if not paths:
            return

        lines = []
        for path in paths:
            if not os.path.isfile(path):
                continue
            result = subprocess.run(
                ["sha256sum", path],
                capture_output=True,
                text=True,
                check=True,
            )
            lines.append(result.stdout.strip())

        if not lines:
            self._notify("SHA256", "No regular files selected.")
            return

        self._copy_text(
            "\n".join(lines),
            "SHA256 copied",
            f"Copied {len(lines)} checksum(s) to the clipboard.",
        )

    def _file_items(self, files):
        items = []

        copy_paths_item = Nautilus.MenuItem(
            name="RepoToolsExtension::CopyPaths",
            label="Copy Path(s)",
            tip="Copy selected paths to the clipboard",
        )
        copy_paths_item.connect("activate", lambda _menu: self._copy_paths(files))
        items.append(copy_paths_item)

        copy_relative_paths_item = Nautilus.MenuItem(
            name="RepoToolsExtension::CopyRelativePaths",
            label="Copy Relative Path(s)",
            tip="Copy selected paths relative to their common parent",
        )
        copy_relative_paths_item.connect(
            "activate",
            lambda _menu: self._copy_relative_paths(files),
        )
        items.append(copy_relative_paths_item)

        copy_sha_item = Nautilus.MenuItem(
            name="RepoToolsExtension::CopySha256",
            label="Copy SHA256",
            tip="Copy SHA256 checksums for selected files",
        )
        copy_sha_item.connect("activate", lambda _menu: self._copy_sha256(files))
        items.append(copy_sha_item)

        if len(files) == 1:
            path = self._path_from_file(files[0])
            if path:
                target_dir = path if os.path.isdir(path) else os.path.dirname(path)
                open_terminal_item = Nautilus.MenuItem(
                    name="RepoToolsExtension::OpenTerminal",
                    label="Open in Terminal Here",
                    tip="Open Alacritty in this location",
                )
                open_terminal_item.connect(
                    "activate",
                    lambda _menu: self._launch_terminal(target_dir),
                )
                items.insert(0, open_terminal_item)

        return items

    def get_file_items(self, *args):
        files = args[-1] if args else []
        if not files:
            return []
        return self._file_items(files)

    def get_background_items(self, *args):
        current_folder = args[-1] if args else None
        path = self._path_from_file(current_folder)
        if not path:
            return []

        item = Nautilus.MenuItem(
            name="RepoToolsExtension::BackgroundOpenTerminal",
            label="Open in Terminal Here",
            tip="Open Alacritty in this location",
        )
        item.connect("activate", lambda _menu: self._launch_terminal(path))
        return [item]

    def get_property_pages(self, *args):
        files = args[-1] if args else []
        if not files or len(files) != 1:
            return []

        rows = self._metadata_rows(files[0])
        if not rows:
            return []

        return [self._build_property_page("Metadata", rows)]
