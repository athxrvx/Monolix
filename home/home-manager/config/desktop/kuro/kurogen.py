#!/usr/bin/env python3
"""kurogen — render the kuro.toml settings into app-specific configs.

Source of truth : ~/.config/kuro/kuro.toml
Outputs         : ~/.cache/kuro/theme.json       (Quickshell)
                  ~/.config/hypr/kuro.lua        (Hyprland)
                  ~/.config/kitty/kuro.conf      (kitty)
                  ~/.config/helix/themes/kuro.toml (Helix)

Usage:
    kurogen                       regenerate everything
    kurogen set theme.gaps_in 0   edit one value, then regenerate
    kurogen path                  print the config path

On first run, kurogen copies kuro.toml and the default themes from
KURO_DEFAULTS (or ~/.config/kuro/defaults) into ~/.config/kuro. Existing
files are never overwritten.

Only Python's standard library is used (tomllib, Python >= 3.11).
"""

from __future__ import annotations

import copy
import json
import os
import re
import shutil
import sys
import tomllib
from pathlib import Path

HOME = Path(os.environ.get("HOME") or Path.home())
CONFIG = Path(os.environ.get("KURO_CONFIG") or HOME / ".config/kuro/kuro.toml")
THEMES_DIR = Path(os.environ.get("KURO_THEMES") or HOME / ".config/kuro/themes")
KURO_DEFAULTS = Path(os.environ.get("KURO_DEFAULTS") or "")
THEME_JSON = HOME / ".cache/kuro/theme.json"
ZSH_COLORS = HOME / ".cache/kuro/zsh-colors.zsh"
FLEA_THEME_DIR = HOME / ".cache/kuro/flea"
FLEA_COLORS = FLEA_THEME_DIR / "colors.toml"
FLEA_SHELL = FLEA_THEME_DIR / "shell.toml"
FLEA_FONT_FAMILY = FLEA_THEME_DIR / "font-family"
HYPR_LUA = HOME / ".config/hypr/kuro.lua"
KITTY_CONF = HOME / ".config/kitty/kuro.conf"
HELIX_THEME = HOME / ".config/helix/themes/kuro.toml"

DEFAULTS = {
    "colors": {
        "palette": [
            "#151515", "#e27373", "#94b979", "#ffba7b",
            "#97bedc", "#e1c0fa", "#00988e", "#dedede",
            "#888888", "#ffa1a1", "#bddeab", "#ffdca0",
            "#b1d8f6", "#fbdaff", "#1ab2a8", "#ffffff",
        ],
        "base": "#0d0d0d",
        "ink": "#dedede",
        "hot": "#e27373",
        "accent": "#8a694c",
        "accent_text": "#dedede",
        "red": "#e27373",
        "yellow": "#ffba7b",
        "orange": "#ffa560",
        "green": "#94b979",
        "cyan": "#00988e",
        "blue": "#97bedc",
        "magenta": "#e1c0fa",
        "brown": "#8a694c",
        "muted": "#888888",
        "cursor": "#ffa560",
        "cursor_text": "#0d0d0d",
        "selection_background": "#fad07a",
        "selection_foreground": "#0d0d0d",
        "url": "#97bedc",
        "active_border": "#8a694c",
        "inactive_border": "#88888888",
        "tab_active_background": "#8a694c",
        "tab_active_foreground": "#dedede",
        "tab_inactive_background": "#303030",
        "tab_inactive_foreground": "#dedede",
    },
    "theme": {
        "scheme": "jellybeans",
        "rounding": 0,
        "gaps_in": 4,
        "gaps_out": 8,
        "border_size": 2,
        "blur": True,
        "animations": True,
        "active_opacity": 1.0,
        "inactive_opacity": 1.0,
        "shadow": True,
        "shadow_range": 4,
        "shadow_power": 3,
        "shadow_color": "0x990d0d0d",
        "bar_height": 30,
        "popup_gap": 14,
        "radius": 0,
        "radius_small": 0,
        "padding": 16,
        "gap": 10,
    },
    "fonts": {
        "ui_family": "JetBrainsMono Nerd Font",
        "ui_size": 15,
        "icon_size": 20,
        "terminal_family": "JetBrainsMono Nerd Font",
        "terminal_size": 11.5,
    },
    "terminal": {"opacity": 0.97, "padding": 10, "cursor_shape": "block", "scrollback": 10000},
    "apps": {
        "terminal": "kitty",
        "file_manager": "dolphin",
        "menu": "qs -c shell ipc call launcher toggle",
        "wallpaper_dir": "~/Pictures/Wallpaper",
        "wallpaper_picker": "quickshell -c hyprquickpaper",
    },
    "hypr": {
        "layout": "dwindle",
        "kb_layout": "us",
        "kb_options": "altwin:swap_alt_win",
        "follow_mouse": 1,
        "mouse_refocus": False,
        "natural_scroll": True,
        "blur_size": 20,
        "blur_passes": 4,
        "blur_vibrancy": 0.1696,
        "rounding_power": 2,
    },
}


class KuroError(Exception):
    pass


def deep_merge(base: dict, override: dict) -> dict:
    out = copy.deepcopy(base)
    for key, value in (override or {}).items():
        if isinstance(value, dict) and isinstance(out.get(key), dict):
            out[key] = deep_merge(out[key], value)
        else:
            out[key] = value
    return out


def theme_path(name: str) -> Path:
    return THEMES_DIR / f"{name}.toml"


def list_themes() -> list[dict]:
    """Every *.toml in ~/.config/kuro/themes, sorted by file name."""
    found = []
    if THEMES_DIR.is_dir():
        for path in sorted(THEMES_DIR.glob("*.toml")):
            name = path.stem.replace("-", " ").title()
            try:
                with path.open("rb") as fh:
                    data = tomllib.load(fh)
                name = data.get("name", name)
            except (OSError, tomllib.TOMLDecodeError):
                pass
            try:
                colors = theme_colors(path.stem)
            except (KuroError, OSError, tomllib.TOMLDecodeError):
                colors = DEFAULTS["colors"]
            palette = colors.get("palette", DEFAULTS["colors"]["palette"])
            found.append({"id": path.stem, "name": name, "palette": palette[:16]})
    return found


def load_theme(name: str) -> dict:
    path = theme_path(name)
    if not path.is_file():
        known = ", ".join(t["id"] for t in list_themes()) or "none"
        raise KuroError(f"unknown theme {name!r} (available: {known})")
    try:
        with path.open("rb") as fh:
            return tomllib.load(fh)
    except tomllib.TOMLDecodeError as exc:
        raise KuroError(f"invalid theme {path}: {exc}")


def theme_colors(name: str) -> dict:
    """Normalise an Omarchy colors.toml (or a Kuro palette theme) to colors."""
    theme = load_theme(name)
    tc = theme.get("colors") if isinstance(theme.get("colors"), dict) else theme

    # Custom Kuro theme: a 16-colour palette plus explicit color keys.
    if isinstance(tc.get("palette"), list):
        palette = list(tc["palette"])
        if len(palette) < 16:
            raise KuroError(f"theme {name!r}: palette needs 16 entries, found {len(palette)}")
        colors = deep_merge(DEFAULTS["colors"], tc)
        colors["palette"] = palette[:16]
        return colors

    # Omarchy theme (flat semantic names).
    def get(key: str, fallback: str) -> str:
        value = tc.get(key)
        return str(value) if value else fallback

    bg = get("background", DEFAULTS["colors"]["base"])
    fg = get("foreground", DEFAULTS["colors"]["ink"])
    red = get("red", DEFAULTS["colors"]["hot"])
    green = get("green", DEFAULTS["colors"]["palette"][2])
    yellow = get("yellow", DEFAULTS["colors"]["palette"][3])
    blue = get("blue", DEFAULTS["colors"]["palette"][4])
    magenta = get("magenta", DEFAULTS["colors"]["palette"][5])
    cyan = get("cyan", DEFAULTS["colors"]["palette"][6])
    accent = get("accent", blue)

    palette = [
        get("dark_background", bg),
        red,
        green,
        yellow,
        blue,
        magenta,
        cyan,
        fg,
        get("muted", DEFAULTS["colors"]["palette"][8]),
        get("bright_red", red),
        get("bright_green", green),
        get("bright_yellow", yellow),
        get("bright_blue", blue),
        get("bright_magenta", magenta),
        get("bright_cyan", cyan),
        get("bright_foreground", fg),
    ]

    return {
        "palette": palette,
        "base": bg,
        "ink": fg,
        "hot": red,
        "accent": accent,
        "accent_text": get("accent_text", fg),
        "cursor": get("cursor", get("bright_foreground", fg)),
        "cursor_text": get("cursor_text", bg),
        "selection_background": get("selection", accent),
        "selection_foreground": get("selection_foreground", bg),
        "url": get("url", get("bright_blue", blue)),
        # Solitude provides a dedicated active_border_color.
        "active_border": get("active_border", get("active_border_color", accent)),
        "inactive_border": get("inactive_border", "#595959aa"),
        "tab_active_background": get("active_tab_background", accent),
        "tab_active_foreground": get("tab_active_foreground", bg),
        "tab_inactive_background": get("lighter_background", bg),
        "tab_inactive_foreground": get("tab_inactive_foreground", fg),
    }


def resolve_theme(cfg: dict, raw: dict) -> None:
    """Load the selected theme file and expand it into cfg["colors"]."""
    scheme = str(cfg.get("theme", {}).get("scheme") or "").strip()
    explicit = raw.get("colors") or {}

    if scheme:
        colors = theme_colors(scheme)
        cfg["colors"] = deep_merge(colors, explicit)
        theme = load_theme(scheme)
        cfg["scheme_name"] = theme.get("name", scheme)
    else:
        cfg["colors"] = deep_merge(cfg["colors"], explicit)
        cfg["scheme_name"] = "Custom"

    cfg["scheme"] = scheme or "custom"
    cfg["schemes"] = list_themes()

    if cfg["hypr"].get("layout") not in ("dwindle", "scrolling"):
        raise KuroError("hypr.layout must be 'dwindle' or 'scrolling'")


def bootstrap_defaults() -> bool:
    """Copy bundled first-run defaults into ~/.config/kuro without overwrites.

    KURO_DEFAULTS points at the flake's bundled kuro.toml and themes. When it
    is unset, ~/.config/kuro/defaults is used as a local fallback. Home
    Manager never owns kuro.toml or themes because `kurogen set` rewrites them.
    """
    defaults = Path(
        os.environ.get("KURO_DEFAULTS")
        or str(HOME / ".config/kuro/defaults")
    ).expanduser()
    copied = False

    default_config = defaults / "kuro.toml"
    if default_config.is_file() and not CONFIG.exists():
        CONFIG.parent.mkdir(parents=True, exist_ok=True)
        # copy2 preserves the Nix store's 0444 mode; kuro.toml is imperative
        # and must stay writable so `kurogen set` can change the scheme.
        shutil.copyfile(default_config, CONFIG)
        CONFIG.chmod(0o644)
        copied = True

    default_themes = defaults / "themes"
    if default_themes.is_dir():
        THEMES_DIR.mkdir(parents=True, exist_ok=True)
        for source in sorted(default_themes.glob("*.toml")):
            target = THEMES_DIR / source.name
            if not target.exists():
                shutil.copy2(source, target)
                copied = True

    if copied:
        print(f"kuro: bootstrapped defaults from {defaults}")
    return copied


def load(path: Path = CONFIG) -> dict:
    bootstrap_defaults()
    try:
        with path.open("rb") as fh:
            raw = tomllib.load(fh)
    except FileNotFoundError:
        raise KuroError(f"missing config: {path}")
    except tomllib.TOMLDecodeError as exc:
        raise KuroError(f"invalid TOML in {path}: {exc}")

    cfg = deep_merge(DEFAULTS, raw)
    resolve_theme(cfg, raw)
    palette = cfg["colors"].get("palette") or []
    if len(palette) < 16:
        raise KuroError(f"colors.palette needs 16 entries, found {len(palette)}")
    cfg["colors"]["palette"] = palette[:16]
    return cfg


# ── helpers ──────────────────────────────────────────────────────────
def hex_rgba(value: str) -> str:
    """#rrggbb / #rrggbbaa -> rgba(rrggbbaa) for Hyprland."""
    text = str(value).strip()
    if text.startswith(("rgba(", "rgb(")):
        return text
    h = text.lstrip("#")
    if len(h) == 6:
        h += "ff"
    if len(h) != 8:
        return "rgba(ffffffff)"
    return f"rgba({h.lower()})"


def hex_argb(value: str) -> str:
    """#rrggbb -> 0xffrrggbb (Hyprland misc.background_color)."""
    h = str(value).strip().lstrip("#")
    if len(h) == 6:
        return f"0xff{h.lower()}"
    if len(h) == 8:
        return f"0x{h[6:8]}{h[0:6]}".lower()
    return "0xff000000"


def lua(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return json.dumps(value)
    if isinstance(value, (list, tuple)):
        return "{ " + ", ".join(lua(v) for v in value) + " }"
    raise KuroError(f"cannot serialise {value!r} to Lua")


def toml_value(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return json.dumps(value)
    if isinstance(value, list):
        return "[" + ", ".join(toml_value(v) for v in value) + "]"
    if isinstance(value, dict):
        entries = (f"{json.dumps(key)} = {toml_value(item)}" for key, item in value.items())
        return "{ " + ", ".join(entries) + " }"
    raise KuroError(f"cannot serialise {value!r} to TOML")


def write_if_changed(path: Path, text: str) -> bool:
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        if path.read_text(encoding="utf-8") == text:
            return False
    except (FileNotFoundError, UnicodeDecodeError):
        pass
    path.write_text(text, encoding="utf-8")
    return True


# ── renderers ────────────────────────────────────────────────────────
def render_theme_json(cfg: dict) -> str:
    c, t, f = cfg["colors"], cfg["theme"], cfg["fonts"]
    a, app = cfg["apps"], cfg["terminal"]
    data = {
        "scheme": cfg.get("scheme", ""),
        "schemeName": cfg.get("scheme_name", ""),
        "schemes": cfg.get("schemes", []),
        "colors": {
            "palette": c["palette"],
            "base": c["base"],
            "ink": c["ink"],
            "hot": c["hot"],
            "accent": c["accent"],
            "accentText": c["accent_text"],
            "cursor": c["cursor"],
            "cursorText": c["cursor_text"],
            "selectionBg": c["selection_background"],
            "selectionFg": c["selection_foreground"],
            "url": c["url"],
            "tabActiveBg": c["tab_active_background"],
            "tabActiveFg": c["tab_active_foreground"],
            "tabInactiveBg": c["tab_inactive_background"],
            "tabInactiveFg": c["tab_inactive_foreground"],
        },
        "theme": {
            "barHeight": t["bar_height"],
            "popupGap": t["popup_gap"],
            "radius": t["radius"],
            "radiusSmall": t["radius_small"],
            "padding": t["padding"],
            "gap": t["gap"],
            "rounding": t["rounding"],
            "borderSize": t["border_size"],
            "gapsIn": t["gaps_in"],
            "gapsOut": t["gaps_out"],
        },
        "fonts": {
            "ui": f["ui_family"],
            "uiSize": f["ui_size"],
            "iconSize": f["icon_size"],
            "terminal": f["terminal_family"],
            "terminalSize": f["terminal_size"],
        },
        "apps": {
            "terminal": a["terminal"],
            "fileManager": a["file_manager"],
            "menu": a["menu"],
            "wallpaperDir": a["wallpaper_dir"],
            "wallpaperPicker": a["wallpaper_picker"],
        },
        "terminal": {
            "opacity": app["opacity"],
            "padding": app["padding"],
            "cursorShape": app["cursor_shape"],
            "scrollback": app["scrollback"],
        },
    }
    return json.dumps(data, indent=2) + "\n"


def render_helix_theme(cfg: dict) -> str:
    """Render Helix's custom theme from the currently selected Kuro colors."""
    c = cfg["colors"]
    p = c["palette"]
    groups = {
        "ui.background": {"fg": c["ink"], "bg": c["base"]},
        "ui.text": {"fg": c["ink"]},
        "ui.text.focus": {"fg": c["ink"], "modifiers": ["bold"]},
        "ui.text.inactive": {"fg": p[8]},
        "ui.virtual": {"fg": p[8]},
        "ui.virtual.indent-guide": {"fg": p[8]},
        "ui.cursor": {"fg": c["cursor_text"], "bg": c["cursor"]},
        "ui.cursor.primary": {"fg": c["cursor_text"], "bg": c["cursor"]},
        "ui.cursor.match": {"fg": c["accent_text"], "bg": c["accent"], "modifiers": ["bold"]},
        "ui.cursorline.primary": {"bg": p[0]},
        "ui.selection": {"fg": c["selection_foreground"], "bg": c["selection_background"]},
        "ui.selection.primary": {"fg": c["selection_foreground"], "bg": c["selection_background"]},
        "ui.linenr": {"fg": p[8]},
        "ui.linenr.selected": {"fg": c["accent"], "modifiers": ["bold"]},
        "ui.statusline": {"fg": c["ink"], "bg": p[0]},
        "ui.statusline.inactive": {"fg": p[8], "bg": c["base"]},
        "ui.statusline.normal": {"fg": c["accent_text"], "bg": c["accent"], "modifiers": ["bold"]},
        "ui.statusline.insert": {"fg": c["cursor_text"], "bg": p[2], "modifiers": ["bold"]},
        "ui.statusline.select": {"fg": c["cursor_text"], "bg": p[4], "modifiers": ["bold"]},
        "ui.bufferline": {"fg": p[8], "bg": c["base"]},
        "ui.bufferline.active": {"fg": c["accent_text"], "bg": c["accent"], "modifiers": ["bold"]},
        "ui.popup": {"fg": c["ink"], "bg": p[0]},
        "ui.window": {"fg": p[8], "bg": c["base"]},
        "ui.help": {"fg": c["ink"], "bg": p[0]},
        "ui.menu": {"fg": c["ink"], "bg": p[0]},
        "ui.menu.selected": {"fg": c["accent_text"], "bg": c["accent"], "modifiers": ["bold"]},
        "ui.highlight": {"fg": c["cursor_text"], "bg": c["cursor"]},
        "warning": {"fg": p[3]},
        "error": {"fg": c["hot"]},
        "info": {"fg": p[4]},
        "hint": {"fg": p[6]},
        "diagnostic.error": {"underline": {"color": c["hot"], "style": "curl"}},
        "diagnostic.warning": {"underline": {"color": p[3], "style": "curl"}},
        "diagnostic.info": {"underline": {"color": p[4], "style": "curl"}},
        "diagnostic.hint": {"underline": {"color": p[6], "style": "curl"}},
        "attribute": {"fg": p[5]},
        "comment": {"fg": p[8], "modifiers": ["italic"]},
        "constant": {"fg": p[3]},
        "constant.numeric": {"fg": p[3]},
        "constructor": {"fg": p[5]},
        "function": {"fg": p[4]},
        "function.method": {"fg": p[4]},
        "keyword": {"fg": c["accent"], "modifiers": ["bold"]},
        "namespace": {"fg": p[4]},
        "operator": {"fg": p[8]},
        "punctuation": {"fg": p[8]},
        "string": {"fg": p[2]},
        "tag": {"fg": p[1]},
        "type": {"fg": p[6]},
        "variable": {"fg": c["ink"]},
        "variable.parameter": {"fg": p[3]},
        "diff.plus": {"fg": p[2]},
        "diff.minus": {"fg": c["hot"]},
        "diff.delta": {"fg": p[3]},
    }
    lines = ["# Generated by kurogen from the active Kuro palette."]
    for name, style in groups.items():
        lines.append(f"{json.dumps(name)} = {toml_value(style)}")
    return "\n".join(lines) + "\n"


def render_zsh_colors(cfg: dict) -> str:
    """Expose the active Kuro palette as safe Zsh prompt color variables."""
    colors = cfg["colors"]

    def color(value: object, fallback: str) -> str:
        text = str(value)
        return text.lower() if re.fullmatch(r"#[0-9a-fA-F]{6}", text) else fallback

    values = {
        "KURO_PROMPT_BG": color(colors.get("base"), "#151515"),
        "KURO_PROMPT_FG": color(colors.get("ink"), "#dedede"),
        "KURO_PROMPT_ACCENT": color(colors.get("accent"), "#97bedc"),
        "KURO_PROMPT_HOT": color(colors.get("hot"), "#e27373"),
        "KURO_PROMPT_BLUE": color(colors.get("palette", [])[4] if len(colors.get("palette", [])) > 4 else None, "#97bedc"),
        "KURO_PROMPT_MUTED": color(colors.get("palette", [])[8] if len(colors.get("palette", [])) > 8 else None, "#888888"),
        "KURO_PROMPT_GREEN": color(colors.get("palette", [])[2] if len(colors.get("palette", [])) > 2 else None, "#94b979"),
        "KURO_PROMPT_YELLOW": color(colors.get("palette", [])[3] if len(colors.get("palette", [])) > 3 else None, "#ffba7b"),
        "KURO_PROMPT_MAGENTA": color(colors.get("palette", [])[5] if len(colors.get("palette", [])) > 5 else None, "#e1c0fa"),
        "KURO_PROMPT_RULE": "#333333",
    }
    return "# Generated by kurogen.\n" + "".join(f"typeset -g {key}='{value}'\n" for key, value in values.items())


def render_flea_colors(cfg: dict) -> str:
    """Export Kuro's active palette in Flea's semantic colors.toml format."""
    colors = cfg["colors"]
    palette = colors["palette"]
    values = {
        "background": colors["base"],
        "dark_background": palette[0],
        "darker_background": palette[0],
        "lighter_background": colors.get("lighter_background", palette[0]),
        "foreground": colors["ink"],
        "bright_foreground": palette[15],
        "dark_foreground": palette[8],
        "muted": palette[8],
        "accent": colors["accent"],
        "selection": colors["selection_background"],
        "red": palette[1],
        "orange": palette[3],
        "yellow": palette[3],
        "green": palette[2],
        "blue": palette[4],
        "magenta": palette[5],
        "cyan": palette[6],
        "bright_red": palette[9],
        "bright_yellow": palette[11],
        "bright_green": palette[10],
        "bright_blue": palette[12],
        "bright_magenta": palette[13],
        "bright_cyan": palette[14],
        "urgent": colors["hot"],
    }
    lines = ["# Generated by kurogen from ~/.config/kuro/kuro.toml."]
    lines.extend(f"{key} = {toml_value(value)}" for key, value in values.items())
    return "\n".join(lines) + "\n"


def render_flea_shell(cfg: dict) -> str:
    """Keep Flea's UI sizing aligned with Kuro's selected UI font size."""
    return (
        "# Generated by kurogen from ~/.config/kuro/kuro.toml.\n"
        "[font]\n"
        f"base-size = {int(cfg['fonts']['ui_size'])}\n"
    )


def render_hypr_lua(cfg: dict) -> str:
    c, t, f, h = cfg["colors"], cfg["theme"], cfg["fonts"], cfg["hypr"]

    lines = [
        "-- Generated by kurogen from ~/.config/kuro/kuro.toml.",
        "-- Do not edit by hand: change kuro.toml and run `kurogen`.",
        "",
        "-- Values exposed for other Hyprland config files.",
        "kuro = {",
        f"    layout = {lua(h['layout'])},",
        "    apps = {",
        f"        terminal    = {lua(cfg['apps']['terminal'])},",
        f"        fileManager = {lua(cfg['apps']['file_manager'])},",
        f"        menu        = {lua(cfg['apps']['menu'])},",
        "    },",
        "    fonts = {",
        f"        ui       = {lua(f['ui_family'])},",
        f"        uiSize   = {lua(f['ui_size'])},",
        f"        iconSize = {lua(f['icon_size'])},",
        f"        terminal = {lua(f['terminal_family'])},",
        f"        terminalSize = {lua(f['terminal_size'])},",
        "    },",
        "    colors = {",
        f"        base   = {lua(c['base'])},",
        f"        ink    = {lua(c['ink'])},",
        f"        accent = {lua(c['accent'])},",
        "    },",
        "    theme = {",
        f"        barHeight = {lua(t['bar_height'])},",
        f"        popupGap  = {lua(t['popup_gap'])},",
        f"        radius    = {lua(t['radius'])},",
        "    },",
        "}",
        "",
        "hl.config({",
        "    general = {",
        f"        gaps_in = {lua(t['gaps_in'])},",
        f"        gaps_out = {lua(t['gaps_out'])},",
        f"        border_size = {lua(t['border_size'])},",
        "        col = {",
        f"            active_border = {lua(hex_rgba(c['active_border']))},",
        f"            inactive_border = {lua(hex_rgba(c['inactive_border']))},",
        "        },",
        "        resize_on_border = false,",
        f"        layout = {lua(h['layout'])},",
        "    },",
        "",
        "    decoration = {",
        f"        rounding = {lua(t['rounding'])},",
        f"        rounding_power = {lua(h['rounding_power'])},",
        f"        active_opacity = {lua(t['active_opacity'])},",
        f"        inactive_opacity = {lua(t['inactive_opacity'])},",
        "        shadow = {",
        f"            enabled = {lua(t['shadow'])},",
        f"            range = {lua(t['shadow_range'])},",
        f"            render_power = {lua(t['shadow_power'])},",
        f"            color = {t['shadow_color']},",
        "        },",
        "        blur = {",
        f"            enabled = {lua(t['blur'])},",
        f"            size = {lua(h['blur_size'])},",
        f"            passes = {lua(h['blur_passes'])},",
        f"            vibrancy = {lua(h['blur_vibrancy'])},",
        "        },",
        "    },",
        "",
        "    misc = {",
        f"        background_color = {hex_argb(c['base'])},",
        "        force_default_wallpaper = -1,",
        "        disable_hyprland_logo = true,",
        "    },",
        "",
        "    layers = {",
        "        allow_new_top_layers_over_existing_fullscreen = true,",
        "    },",
        "",
        "    input = {",
        f"        kb_layout = {lua(h['kb_layout'])},",
        f"        kb_options = {lua(h['kb_options'])},",
        f"        follow_mouse = {lua(h['follow_mouse'])},",
        f"        mouse_refocus = {lua(h['mouse_refocus'])},",
        "        sensitivity = 0,",
        f"        touchpad = {{ natural_scroll = {lua(h['natural_scroll'])} }},",
        "    },",
        "",
        f"    animations = {{ enabled = {lua(t['animations'])} }},",
        "    dwindle = { preserve_split = true },",
        "})",
        "",
    ]
    return "\n".join(lines)


def render_kitty_conf(cfg: dict) -> str:
    c, f, t = cfg["colors"], cfg["fonts"], cfg["theme"]
    term = cfg["terminal"]
    lines = [
        "# Generated by kurogen from ~/.config/kuro/kuro.toml.",
        "# Do not edit by hand: change kuro.toml and run `kurogen`.",
        "",
        f"font_family      {f['terminal_family']}",
        "bold_font        auto",
        "italic_font      auto",
        "bold_italic_font auto",
        f"font_size        {f['terminal_size']}",
        "",
        f"background_opacity    {term['opacity']}",
        f"window_padding_width  {term['padding']}",
        f"cursor_shape          {term['cursor_shape']}",
        "cursor_blink_interval 0",
        f"scrollback_lines      {term['scrollback']}",
        "",
        f"cursor            {c['cursor']}",
        f"cursor_text_color {c['cursor_text']}",
        "",
        f"selection_foreground {c['selection_foreground']}",
        f"selection_background {c['selection_background']}",
        "",
        f"foreground {c['ink']}",
        f"background {c['base']}",
        "",
    ]
    for i, color in enumerate(c["palette"]):
        lines.append(f"color{i} {color}")
    lines += [
        "",
        f"url_color {c['url']}",
        f"active_tab_foreground   {c['tab_active_foreground']}",
        f"active_tab_background   {c['tab_active_background']}",
        f"inactive_tab_foreground {c['tab_inactive_foreground']}",
        f"inactive_tab_background {c['tab_inactive_background']}",
        "",
    ]
    return "\n".join(lines)


def generate(cfg: dict) -> list[str]:
    changed = []
    if write_if_changed(THEME_JSON, render_theme_json(cfg)):
        changed.append(str(THEME_JSON))
    if write_if_changed(ZSH_COLORS, render_zsh_colors(cfg)):
        changed.append(str(ZSH_COLORS))
    # Flea is disabled in this setup; keep the renderers for reference only.
    # if write_if_changed(FLEA_COLORS, render_flea_colors(cfg)):
    #     changed.append(str(FLEA_COLORS))
    # if write_if_changed(FLEA_SHELL, render_flea_shell(cfg)):
    #     changed.append(str(FLEA_SHELL))
    # if write_if_changed(FLEA_FONT_FAMILY, str(cfg["fonts"]["ui_family"]) + "\n"):
    #     changed.append(str(FLEA_FONT_FAMILY))
    if write_if_changed(HYPR_LUA, render_hypr_lua(cfg)):
        changed.append(str(HYPR_LUA))
    if write_if_changed(KITTY_CONF, render_kitty_conf(cfg)):
        changed.append(str(KITTY_CONF))
    if write_if_changed(HELIX_THEME, render_helix_theme(cfg)):
        changed.append(str(HELIX_THEME))
    return changed


# ── one-value edit (used by the Appearance page / launcher) ──────────
def _split_comment(rest: str) -> tuple[str, str]:
    """Split `value  # comment` while respecting quoted strings."""
    quote = None
    escaped = False
    for i, ch in enumerate(rest):
        if escaped:
            escaped = False
            continue
        if ch == "\\" and quote:
            escaped = True
            continue
        if quote:
            if ch == quote:
                quote = None
            continue
        if ch in ('"', "'"):
            quote = ch
        elif ch == "#":
            return rest[:i].rstrip(), rest[i:].rstrip()
    return rest.strip(), ""


def coerce_like(old, raw: str):
    if isinstance(old, bool):
        low = raw.strip().lower()
        if low in ("true", "yes", "on", "1"):
            return True
        if low in ("false", "no", "off", "0"):
            return False
        raise KuroError(f"expected a boolean, got {raw!r}")
    if isinstance(old, int) and not isinstance(old, bool):
        return int(raw, 0)
    if isinstance(old, float):
        return float(raw)
    if isinstance(old, str):
        value = raw.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
            value = value[1:-1]
        return value
    raise KuroError("refusing to change an unknown value type")


def set_values(pairs: list[tuple[str, str]]) -> None:
    """Edit one or more values in kuro.toml while preserving comments."""
    cfg = load()
    text = CONFIG.read_text(encoding="utf-8")
    lines = text.splitlines()

    for dotted, raw in pairs:
        try:
            section, key = dotted.split(".", 1)
        except ValueError:
            raise KuroError(f"expected <section>.<key>, got {dotted!r}")
        if section not in cfg or key not in cfg[section]:
            raise KuroError(f"unknown setting: {dotted}")
        value = coerce_like(cfg[section][key], raw)

        header = f"[{section}]"
        start = None
        end = len(lines)
        for i, line in enumerate(lines):
            if line.strip() == header:
                start = i
                for j in range(i + 1, len(lines)):
                    if lines[j].lstrip().startswith("["):
                        end = j
                        break
                break
        if start is None:
            raise KuroError(f"section [{section}] not found in {CONFIG}")

        pattern = re.compile(rf"^(\s*){re.escape(key)}(\s*)=")
        target = None
        for i in range(start + 1, end):
            if pattern.match(lines[i]):
                target = i
                break
        if target is None:
            raise KuroError(f"key {key!r} not found in [{section}]")

        match = pattern.match(lines[target])
        indent = match.group(1) if match else ""
        rest = lines[target][match.end():] if match else ""
        _, comment = _split_comment(rest)
        new_line = f"{indent}{key} = {toml_value(value)}"
        if comment:
            new_line += "  " + comment
        lines[target] = new_line

    updated = "\n".join(lines) + ("\n" if text.endswith("\n") else "")
    # Validate before writing.
    try:
        tomllib.loads(updated)
    except tomllib.TOMLDecodeError as exc:
        raise KuroError(f"edit would produce invalid TOML: {exc}")
    CONFIG.write_text(updated, encoding="utf-8")


def set_value(dotted: str, raw: str) -> None:
    set_values([(dotted, raw)])


# ── entry point ──────────────────────────────────────────────────────
def main(argv: list[str]) -> int:
    try:
        if len(argv) > 1 and argv[1] == "path":
            print(CONFIG)
            return 0
        if len(argv) > 1 and argv[1] == "themes":
            cfg = load()
            for item in cfg["schemes"]:
                mark = "*" if item["id"] == cfg["scheme"] else " "
                print(f"{mark} {item['id']:<20} {item['name']}")
            return 0
        if len(argv) > 1 and argv[1] == "scheme":
            if len(argv) != 3:
                raise KuroError("usage: kurogen scheme <name>")
            set_value("theme.scheme", argv[2])
        elif len(argv) > 1 and argv[1] == "set":
            rest = argv[2:]
            if len(rest) < 2 or len(rest) % 2 != 0:
                raise KuroError(
                    "usage: kurogen set <section.key> <value> "
                    "[<section.key> <value> ...]")
            set_values(list(zip(rest[0::2], rest[1::2])))
        elif len(argv) > 1 and argv[1] not in ("generate", "apply"):
            raise KuroError(f"unknown command: {argv[1]}")

        cfg = load()
        changed = generate(cfg)
        for path in changed:
            print(f"kuro: wrote {path}")
        if not changed:
            print("kuro: configs already up to date")
        return 0
    except KuroError as exc:
        print(f"kurogen: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
