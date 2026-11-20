pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Colors, sizes and fonts.
//
// The real values live in ~/.config/kuro/kuro.toml. `kurogen` renders them
// to ~/.cache/kuro/theme.json, which this singleton watches. The values
// below are fallbacks for the first run, before the file exists.
//
// Set Config.usePywal = true to let pywal override the palette.
Singleton {
    id: root

    // ── 16-color palette (color0..color15) ───────────────────────────
    property var palette: [
        "#151515", "#e27373", "#94b979", "#ffba7b",   // 0-3
        "#97bedc", "#e1c0fa", "#00988e", "#dedede",   // 4-7
        "#888888", "#ffa1a1", "#bddeab", "#ffdca0",   // 8-11
        "#b1d8f6", "#fbdaff", "#1ab2a8", "#ffffff"    // 12-15
    ]

    // Typed versions: mix() needs color objects, not strings from the array.
    // (Strings passed into JS functions have no .r/.g/.b -> invalid/black color.)
    property color c0:  palette[0]
    property color c1:  palette[1]
    property color c2:  palette[2]
    property color c3:  palette[3]
    property color c4:  palette[4]
    property color c5:  palette[5]
    property color c6:  palette[6]
    property color c7:  palette[7]
    property color c8:  palette[8]
    property color c9:  palette[9]
    property color c10: palette[10]
    property color c11: palette[11]
    property color c12: palette[12]
    property color c13: palette[13]
    property color c14: palette[14]
    property color c15: palette[15]

    // Three base colors; derived colors use the palette above.
    property color base: "#0D0D0D"     // background
    property color ink: "#dedede"      // foreground
    property color hot: "#e27373"      // color1: accent for data/danger
    property bool walActive: false

    // Scheme-specific colors (cursor, selection, link, tab)
    property color cursor:          "#ffa560"
    property color cursorText:      "#0D0D0D"
    property color selectionBg:     "#fad07a"
    property color selectionFg:     "#0D0D0D"
    property color url:             "#97bedc"
    property color tabActiveBg:     "#8a694c"   // accent (active tab)
    property color tabActiveFg:     "#dedede"
    property color tabInactiveBg:   "#202020"
    property color tabInactiveFg:   "#dedede"

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    readonly property color bg:       base
    readonly property color bgAlt:    c0                          // sidebar = color0
    readonly property color surface:  mix(c0, base, 0.35)
    readonly property color surface2: tabInactiveBg               // hover = normal tab
    readonly property color border:   mix(c0, ink, 0.16)
    readonly property color text:     ink
    readonly property color subtext:  c8                          // color8
    readonly property color muted:    mix(c8, base, 0.30)
    readonly property color accent:   tabActiveBg                 // #8a694c, not the green color2
    readonly property color accentFg: tabActiveFg                 // light text on a dark accent
    readonly property color rose:     hot
    readonly property color danger:   hot
    readonly property color link:     url                         // color4
    readonly property color warning:  c3                          // color3
    readonly property color info:     c4                          // color4
    readonly property color purple:   c5                          // color5
    readonly property color teal:     c6                          // color6

    // ── Sizes ────────────────────────────────────────────────────────
    readonly property int windowWidth: 820
    readonly property int windowHeight: 600
    readonly property int sidebarWidth: 210
    property int barHeight: 30
    property int padding: 16
    property int gap: 10
    property int popupGap: 14
    property int radius: 0
    property int radiusSmall: 0

    // ── Typography ──────────────────────────────────────────────────
    property string font: "JetBrainsMono Nerd Font"
    // Proportional Nerd Font metrics keep pictograms centered and balanced.
    property string iconFont: "JetBrainsMono Nerd Font Propo"
    property int fontSize: 15
    property int iconSize: 20

    // ── Kuro: generated theme.json ───────────────────────────────────
    FileView {
        path: Config.kuroTheme
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.applyKuro(text())
    }

    function applyKuro(raw) {
        let j;
        try { j = JSON.parse(raw); } catch (e) { return; }   // half-written file: ignore

        const c = j.colors ?? {};
        if (Array.isArray(c.palette) && c.palette.length >= 16) palette = c.palette.slice(0, 16);
        if (c.base)      base = c.base;
        if (c.ink)       ink = c.ink;
        if (c.hot)       hot = c.hot;
        if (c.cursor)    cursor = c.cursor;
        if (c.cursorText) cursorText = c.cursorText;
        if (c.selectionBg) selectionBg = c.selectionBg;
        if (c.selectionFg) selectionFg = c.selectionFg;
        if (c.url)       url = c.url;
        if (c.tabActiveBg) tabActiveBg = c.tabActiveBg;
        if (c.tabActiveFg) tabActiveFg = c.tabActiveFg;
        if (c.tabInactiveBg) tabInactiveBg = c.tabInactiveBg;
        if (c.tabInactiveFg) tabInactiveFg = c.tabInactiveFg;

        const t = j.theme ?? {};
        if (t.barHeight !== undefined)  barHeight = t.barHeight;
        if (t.popupGap !== undefined)   popupGap = t.popupGap;
        if (t.radius !== undefined)     radius = t.radius;
        if (t.radiusSmall !== undefined) radiusSmall = t.radiusSmall;
        if (t.padding !== undefined)    padding = t.padding;
        if (t.gap !== undefined)        gap = t.gap;

        const f = j.fonts ?? {};
        if (f.ui)                    font = f.ui;
        if (f.uiSize !== undefined)  fontSize = f.uiSize;
        if (f.iconSize !== undefined) iconSize = f.iconSize;
    }

    // ── pywal ────────────────────────────────────────────────────────
    FileView {
        path: Config.walColors
        watchChanges: Config.usePywal
        printErrors: false
        onFileChanged: if (Config.usePywal) reload()
        onLoaded: if (Config.usePywal) root.applyWal(text())
    }

    function applyWal(raw) {
        let j;
        try { j = JSON.parse(raw); } catch (e) { return; }   // half-written file: ignore
        if (!j.special || !j.colors) return;

        const cols = [];
        for (let i = 0; i < 16; i++) cols.push(j.colors["color" + i]);

        // Accent = the most "colorful" and sufficiently bright of color1..color6
        let best = cols[1], score = -1;
        for (let i = 1; i <= 6; i++) {
            const c = Qt.lighter(cols[i], 1.0);
            const s = c.hslSaturation * (c.hslLightness > 0.35 ? 1 : 0.4);
            if (s > score) { score = s; best = cols[i]; }
        }

        base = j.special.background;
        ink = j.special.foreground;
        hot = best;
        palette = cols;
        walActive = true;
    }
}
