#!/usr/bin/env python3
"""Create and manage user-scoped Monolix web app launchers."""

from __future__ import annotations

import argparse
import configparser
import hashlib
from html.parser import HTMLParser
import json
import mimetypes
import os
import re
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path


def data_home() -> Path:
    return Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))


def registry_path() -> Path:
    return data_home() / "monolix" / "webapps.json"


def applications_dir() -> Path:
    return data_home() / "applications"


def icon_dir() -> Path:
    return data_home() / "icons" / "monolix-webapps"


def papirus_theme_dirs() -> list[Path]:
    data_dirs = [str(data_home())]
    data_dirs.extend(os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":"))
    result = []
    for data_dir in data_dirs:
        for theme in ("Papirus-Dark", "Papirus"):
            path = Path(data_dir) / "icons" / theme
            if path.is_dir() and path not in result:
                result.append(path)
    return result


def icon_candidates(name: str, url: str) -> list[str]:
    values = [name]
    host = urllib.parse.urlsplit(url).hostname or ""
    host = re.sub(r"^www\.", "", host).split(":", 1)[0]
    host_label = host.split(".", 1)[0]
    values.extend([host_label, host])
    aliases = {
        "youtube": ["youtube", "youtube-music"],
        "google drive": ["google-drive", "drive"],
        "google docs": ["google-docs", "google-documents"],
        "google calendar": ["google-calendar"],
        "gmail": ["gmail", "google-mail"],
        "whatsapp": ["whatsapp", "whatsapp-web"],
        "discord": ["discord"],
        "reddit": ["reddit"],
        "spotify": ["spotify"],
        "twitch": ["twitch"],
        "netflix": ["netflix"],
        "github": ["github"],
        "google maps": ["google-maps"],
    }
    values.extend(aliases.get(name.strip().lower(), []))
    candidates = []
    for value in values:
        normalized = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
        for candidate in (normalized, f"{normalized}-symbolic"):
            if candidate and candidate not in candidates:
                candidates.append(candidate)
    return candidates


def find_papirus_icon(name: str, url: str) -> str:
    candidates = icon_candidates(name, url)
    extensions = (".svg", ".png", ".xpm")
    for theme_dir in papirus_theme_dirs():
        index = theme_dir / "index.theme"
        directories = []
        if index.is_file():
            config = configparser.ConfigParser(interpolation=None)
            try:
                config.read(index, encoding="utf-8")
                directories = [item.strip() for item in config.get("Icon Theme", "Directories", fallback="").split(",") if item.strip()]
            except (configparser.Error, OSError):
                directories = []
        if not directories:
            directories = ["scalable/apps", "48x48/apps", "32x32/apps", "24x24/apps", "64x64/apps"]
        directories.sort(key=lambda item: ("apps" not in item, "scalable" not in item, "48x48" not in item))
        for directory in directories:
            for candidate in candidates:
                for extension in extensions:
                    path = theme_dir / directory / f"{candidate}{extension}"
                    if path.is_file():
                        return str(path)
    return ""


class FaviconParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.icons: list[tuple[int, str]] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag.lower() != "link":
            return
        values = {key.lower(): value or "" for key, value in attrs}
        rel = values.get("rel", "").lower().split()
        href = values.get("href", "").strip()
        if href and ("icon" in rel or "shortcut" in rel):
            sizes = values.get("sizes", "").lower()
            score = 2 if "svg" in values.get("type", "").lower() else 0
            match = re.search(r"(\d+)x(\d+)", sizes)
            if match:
                score += min(int(match.group(1)), int(match.group(2)))
            self.icons.append((score, href))


def save_remote_icon(icon_url: str, app_id: str) -> str:
    request = urllib.request.Request(icon_url, headers={"User-Agent": "Monolix/1.0"})
    with urllib.request.urlopen(request, timeout=8) as response:
        content_type = response.headers.get_content_type()
        data = response.read(2 * 1024 * 1024 + 1)
    if len(data) > 2 * 1024 * 1024:
        raise ValueError("Icon image is larger than 2 MiB")
    if not content_type.startswith("image/"):
        raise ValueError("Icon URL did not return an image")
    extension = mimetypes.guess_extension(content_type) or ".img"
    if extension == ".jpe":
        extension = ".jpg"
    path = icon_dir() / f"{app_id}{extension}"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return str(path)


def favicon_candidates(page_url: str) -> list[str]:
    try:
        request = urllib.request.Request(page_url, headers={"User-Agent": "Monolix/1.0", "Accept": "text/html"})
        with urllib.request.urlopen(request, timeout=6) as response:
            final_url = response.geturl()
            page = response.read(512 * 1024).decode("utf-8", errors="replace")
        parser = FaviconParser()
        parser.feed(page)
        candidates = [urllib.parse.urljoin(final_url, value) for _, value in sorted(parser.icons, reverse=True)]
        origin = urllib.parse.urlsplit(final_url)
        candidates.append(urllib.parse.urlunsplit((origin.scheme, origin.netloc, "/favicon.ico", "", "")))
        return list(dict.fromkeys(candidates))
    except (OSError, UnicodeError, urllib.error.URLError, ValueError):
        return []


def preview_favicon(page_url: str, url: str) -> str:
    cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "monolix" / "webapp-previews"
    cache.mkdir(parents=True, exist_ok=True)
    for candidate in favicon_candidates(page_url):
        try:
            request = urllib.request.Request(candidate, headers={"User-Agent": "Monolix/1.0"})
            with urllib.request.urlopen(request, timeout=5) as response:
                content_type = response.headers.get_content_type()
                data = response.read(2 * 1024 * 1024 + 1)
            if len(data) > 2 * 1024 * 1024 or not content_type.startswith("image/"):
                continue
            extension = mimetypes.guess_extension(content_type) or ".img"
            if extension == ".jpe":
                extension = ".jpg"
            path = cache / f"{hashlib.sha256(url.encode()).hexdigest()}{extension}"
            path.write_bytes(data)
            return str(path)
        except (OSError, ValueError, urllib.error.URLError):
            continue
    return ""


def fetch_favicon(page_url: str, app_id: str) -> str:
    for candidate in favicon_candidates(page_url):
        try:
            return save_remote_icon(candidate, app_id)
        except (OSError, ValueError, urllib.error.URLError):
            continue
    return ""


def preview(args: argparse.Namespace) -> None:
    name = clean_text(args.name, "Name")
    url = validate_url(args.url)
    source = find_papirus_icon(name, url)
    if not source:
        source = preview_favicon(url, url)
    print(json.dumps({"name": name, "source": source}))


def read_registry() -> list[dict[str, str]]:
    path = registry_path()
    if not path.exists():
        return []
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, list):
        raise ValueError("Web app registry is not a list")
    return [item for item in value if isinstance(item, dict) and item.get("id")]


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp_name, path)
    except Exception:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass
        raise


def clean_text(value: str, field: str) -> str:
    value = value.strip()
    if not value:
        raise ValueError(f"{field} is required")
    if "\n" in value or "\r" in value or "\0" in value:
        raise ValueError(f"{field} must be a single line")
    return value


def validate_url(value: str) -> str:
    value = clean_text(value, "URL")
    parsed = urllib.parse.urlsplit(value)
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        raise ValueError("URL must start with http:// or https://")
    return value


def desktop_quote(value: str) -> str:
    value = value.replace("%", "%%")
    value = value.replace("\\", "\\\\").replace('"', '\\"').replace("`", "\\`").replace("$", "\\$")
    return f'"{value}"'


def desktop_text(value: str) -> str:
    return value.replace("\\", "\\\\").replace("\n", "\\n").replace("\r", "\\r")


def icon_for(app_id: str, icon_url: str, name: str, page_url: str) -> str:
    icon_url = icon_url.strip()
    if icon_url:
        parsed = urllib.parse.urlsplit(icon_url)
        if parsed.scheme not in ("http", "https") or not parsed.netloc:
            raise ValueError("Icon must be an http(s) URL")
        return save_remote_icon(icon_url, app_id)
    matched_icon = find_papirus_icon(name, page_url)
    if matched_icon:
        return matched_icon
    return fetch_favicon(page_url, app_id) or "web-browser"


def desktop_path(app_id: str) -> Path:
    return applications_dir() / f"monolix-webapp-{app_id}.desktop"


def write_desktop_entry(app: dict[str, str]) -> None:
    icon = app.get("iconPath") or "web-browser"
    content = "\n".join(
        [
            "[Desktop Entry]",
            "Version=1.0",
            "Type=Application",
            f"Name={desktop_text(app['name'])}",
            f"Comment={desktop_text('Open ' + app['url'])}",
            f"Exec=systemd-run --user --scope --collect --quiet -- chromium --app={desktop_quote(app['url'])}",
            f"Icon={desktop_text(icon)}",
            "Terminal=false",
            "Categories=Network;WebBrowser;",
            "StartupNotify=true",
            "",
        ]
    )
    atomic_write(desktop_path(app["id"]), content)


def write_registry(apps: list[dict[str, str]]) -> None:
    atomic_write(registry_path(), json.dumps(apps, ensure_ascii=False, indent=2) + "\n")


def delete_icon(app: dict[str, str]) -> None:
    icon = app.get("iconPath", "")
    if icon:
        path = Path(icon)
        try:
            path.relative_to(icon_dir())
        except ValueError:
            return
        path.unlink(missing_ok=True)


def create(args: argparse.Namespace) -> None:
    name = clean_text(args.name, "Name")
    url = validate_url(args.url)
    app_id = uuid.uuid4().hex
    app = {"id": app_id, "name": name, "url": url, "icon": args.icon.strip(), "iconPath": ""}
    app["iconPath"] = icon_for(app_id, app["icon"], name, url)
    apps = read_registry()
    apps.append(app)
    write_desktop_entry(app)
    write_registry(apps)
    print(f"Created {name}")


def update(args: argparse.Namespace) -> None:
    name = clean_text(args.name, "Name")
    url = validate_url(args.url)
    apps = read_registry()
    for app in apps:
        if app["id"] == args.id:
            previous_icon = app.get("iconPath", "")
            icon_url = args.icon.strip()
            icon_path = icon_for(args.id, icon_url, name, url)
            app.update({"name": name, "url": url, "icon": icon_url, "iconPath": icon_path})
            write_desktop_entry(app)
            write_registry(apps)
            if previous_icon != icon_path:
                delete_icon({"iconPath": previous_icon})
            print(f"Updated {name}")
            return
    raise ValueError("Web app no longer exists")


def remove(args: argparse.Namespace) -> None:
    apps = read_registry()
    for index, app in enumerate(apps):
        if app["id"] == args.id:
            apps.pop(index)
            desktop_path(args.id).unlink(missing_ok=True)
            delete_icon(app)
            write_registry(apps)
            print(f"Removed {app['name']}")
            return
    raise ValueError("Web app no longer exists")


def main() -> int:
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    inspect = commands.add_parser("preview")
    inspect.add_argument("name")
    inspect.add_argument("url")
    inspect.set_defaults(func=preview)
    add = commands.add_parser("create")
    add.add_argument("name")
    add.add_argument("url")
    add.add_argument("icon", nargs="?", default="")
    add.set_defaults(func=create)
    edit = commands.add_parser("update")
    edit.add_argument("id")
    edit.add_argument("name")
    edit.add_argument("url")
    edit.add_argument("icon", nargs="?", default="")
    edit.set_defaults(func=update)
    delete = commands.add_parser("delete")
    delete.add_argument("id")
    delete.set_defaults(func=remove)
    args = parser.parse_args()
    try:
        args.func(args)
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
