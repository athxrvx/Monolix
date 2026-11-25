#!/usr/bin/env python3
"""Validate that every shipped Kuro palette fully implements the color contract."""

from __future__ import annotations

import re
import sys
import tomllib
from pathlib import Path


THEME_DIR = Path(__file__).resolve().parent
REQUIRED_COLORS = (
    "accent", "accent_text", "selection", "selection_foreground", "muted",
    "background", "dark_background", "darker_background", "lighter_background",
    "foreground", "dark_foreground", "light_foreground", "bright_foreground",
    "red", "orange", "yellow", "green", "cyan", "blue", "magenta", "brown",
    "bright_red", "bright_yellow", "bright_green", "bright_cyan", "bright_blue", "bright_magenta",
    "cursor", "cursor_text", "url", "inactive_border", "active_border_color",
    "active_tab_background", "tab_active_foreground", "tab_inactive_background", "tab_inactive_foreground",
)
OPTIONAL_COLOR_KEYS = ("icon_mark", "active_border")
HEX_COLOR = re.compile(r"#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?\Z")


def check_file(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        with path.open("rb") as handle:
            theme = tomllib.load(handle)
    except (OSError, tomllib.TOMLDecodeError) as exc:
        return [f"{path.name}: cannot read TOML: {exc}"]

    for key in ("name", "mode"):
        if not isinstance(theme.get(key), str) or not theme[key].strip():
            errors.append(f"{key}: must be a non-empty string")
    if theme.get("mode") not in {"dark", "light"}:
        errors.append("mode: expected 'dark' or 'light'")

    for key in REQUIRED_COLORS:
        if key not in theme:
            errors.append(f"missing required color '{key}'")
        elif not isinstance(theme[key], str) or not HEX_COLOR.fullmatch(theme[key]):
            errors.append(f"{key}: expected #RRGGBB or #RRGGBBAA, got {theme[key]!r}")

    for key in OPTIONAL_COLOR_KEYS:
        if key in theme and (not isinstance(theme[key], str) or not HEX_COLOR.fullmatch(theme[key])):
            errors.append(f"{key}: expected #RRGGBB or #RRGGBBAA, got {theme[key]!r}")
    return [f"{path.name}: {error}" for error in errors]


def main() -> int:
    theme_dir = Path(sys.argv[1]).expanduser() if len(sys.argv) > 1 else THEME_DIR
    paths = sorted(theme_dir.glob("*.toml"))
    if not paths:
        print(f"No theme TOML files found in {theme_dir}", file=sys.stderr)
        return 2
    errors = [error for path in paths for error in check_file(path)]
    if errors:
        print("Kuro palette contract failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        print(f"{len(errors)} issue(s) across {len(paths)} palette(s)", file=sys.stderr)
        return 1
    print(f"Kuro palette contract passed: {len(paths)} palettes, {len(REQUIRED_COLORS)} required colors each.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
