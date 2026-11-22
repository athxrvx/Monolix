pragma Singleton

import QtQuick
import Quickshell

// Unified Material Design Icons glyph set from Nerd Fonts (nf-md- prefix).
// Use code points so the file stays readable in editors without Nerd Font.
Singleton {
    function g(cp) { return String.fromCodePoint(cp) }

    readonly property string user:          g(0xF0004)
    readonly property string search:        g(0xF0349)
    readonly property string refresh:       g(0xF0450)
    readonly property string check:         g(0xF012C)
    readonly property string settings:      g(0xF0493)
    readonly property string arch:          g(0xF08C7)
    readonly property string nixos:         g(0xF313)   // nf-linux-nixos
    readonly property string cpu:           g(0xF0EE0)
    readonly property string bot:           g(0xF06A9)
    readonly property string music:         g(0xF075A)
    readonly property string memory:        g(0xF035B)
    readonly property string clipboard:     g(0xF0147)
    readonly property string trash:         g(0xF01B4)
    readonly property string close:         g(0xF0156)
    readonly property string overview:      g(0xF0570)
    readonly property string tray:          g(0xF0140)
    readonly property string whatsapp:      g(0xF05A3)
    readonly property string youtube:       g(0xF05C3)
    readonly property string discord:       g(0xF066F)
    readonly property string instagram:     g(0xF02FE)
    readonly property string spotify:       g(0xF04C7)
    readonly property string telegram:      g(0xF0501)
    readonly property string gmail:         g(0xF02AB)

    // Session
    readonly property string power:         g(0xF0425)
    readonly property string lock:          g(0xF033E)
    readonly property string logout:        g(0xF0343)
    readonly property string suspend:       g(0xF0904)
    readonly property string reboot:        g(0xF0709)

    // Network
    readonly property string ethernet:      g(0xF0200)
    readonly property string wifi:          g(0xF05A9)
    readonly property string wifiOff:       g(0xF05AA)
    readonly property var wifiStrength:     [g(0xF092F), g(0xF091F), g(0xF0922), g(0xF0925), g(0xF0928)]
    readonly property string bluetooth:     g(0xF00AF)
    readonly property string bluetoothOff:  g(0xF00B2)
    readonly property string bluetoothOn:   g(0xF00B1)

    // Sound & display
    readonly property string volume:        g(0xF057E)
    readonly property string volumeHigh:    g(0xF057E)
    readonly property string volumeMedium:  g(0xF0580)
    readonly property string volumeLow:     g(0xF057F)
    readonly property string volumeOff:     g(0xF0581)
    readonly property string speaker:       g(0xF04C3)

    function volumeForLevel(level, muted) {
        if (muted || level <= 0) return volumeOff;
        if (level < 0.34) return volumeLow;
        if (level < 0.67) return volumeMedium;
        return volumeHigh;
    }
    readonly property string mic:           g(0xF036C)
    readonly property string micOff:        g(0xF036D)
    readonly property string brightness:    g(0xF00E0)
    readonly property string night:         g(0xF0594)
    readonly property string monitor:       g(0xF0379)

    // Appearance
    readonly property string palette:       g(0xF03D8)
    readonly property string image:         g(0xF02E9)
    readonly property string keyboard:      g(0xF030C)
    readonly property string bell:          g(0xF009A)
    readonly property string bellOff:       g(0xF009B)

    // Power
    readonly property string battery:       g(0xF0079)
    readonly property string batteryAlert:  g(0xF0083)
    readonly property string charging:      g(0xF0084)
    readonly property var batteryLevels: [
        g(0xF007A), g(0xF007B), g(0xF007C), g(0xF007D), g(0xF007E),
        g(0xF007F), g(0xF0080), g(0xF0081), g(0xF0082), g(0xF0079)
    ]
    readonly property var chargingLevels: [
        g(0xF0084), g(0xF0084), g(0xF0086), g(0xF0087), g(0xF0088),
        g(0xF0089), g(0xF0089), g(0xF008A), g(0xF008B), g(0xF0085)
    ]

    function batteryForLevel(percent, charging) {
        const i = Math.max(0, Math.min(9, Math.ceil((percent ?? 0) / 10) - 1));
        return (charging ? chargingLevels : batteryLevels)[i];
    }

    readonly property string leaf:          g(0xF032A)
    readonly property string balance:       g(0xF05D1)
    readonly property string speed:         g(0xF04C5)
}
