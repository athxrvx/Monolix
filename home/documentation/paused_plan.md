# Paused plan: Athena configuration restructuring

**Status:** Paused. Keep the existing layout and behavior unchanged until this
plan is resumed.

## Goal

Reorganize the full Athena NixOS and Home Manager configuration so host,
system, desktop-profile, development-tool, and application settings are easy
to find. Keep each application's Nix configuration and supporting files
separate. Preserve Niri with Monolix as the primary desktop and XMonad as an
optional profile.

## Proposed layout

```text
athena/
├── flake.nix
├── flake.lock
├── README.md
│
├── hosts/
│   └── athena/
│       ├── default.nix
│       └── hardware-configuration.nix
│
├── users/
│   └── atharva.nix
│
├── nixos/
│   ├── boot/
│   │   └── lanzaboote.nix
│   ├── hardware/
│   │   ├── graphics.nix
│   │   └── audio.nix
│   ├── desktop/
│   │   ├── niri.nix
│   │   └── xmonad.nix
│   ├── power/
│   │   ├── laptop.nix
│   │   └── lid-close.nix
│   ├── security/
│   ├── services/
│   └── networking/
│
├── home/
│   ├── default.nix
│   ├── shared/
│   │   ├── shell/
│   │   ├── cli/
│   │   └── base.nix
│   ├── profiles/
│   │   ├── niri.nix
│   │   └── xmonad.nix
│   ├── development/
│   │   ├── android.nix
│   │   ├── flutter.nix
│   │   ├── web.nix
│   │   └── monovim/
│   │       ├── default.nix
│   │       ├── init.lua
│   │       └── plugins/
│   ├── applications/
│   │   ├── firefox/
│   │   │   ├── default.nix
│   │   │   └── userChrome.css
│   │   ├── chromium/
│   │   ├── qutebrowser/
│   │   ├── emacs/
│   │   ├── kitty/
│   │   └── cosmic/
│   │       ├── files.nix
│   │       ├── screenshot.nix
│   │       ├── reader.nix
│   │       ├── player.nix
│   │       └── calculator.nix
│   ├── desktop/
│   │   ├── niri/
│   │   │   ├── default.nix
│   │   │   └── config.kdl
│   │   ├── xmonad/
│   │   │   ├── default.nix
│   │   │   ├── xmonad.hs
│   │   │   └── xmobar.hs
│   │   └── monolix/
│   │       ├── package.nix
│   │       ├── config/
│   │       ├── modules/
│   │       ├── services/
│   │       └── assets/
│   └── theme/
│       ├── stylix.nix
│       ├── palettes/
│       └── cosmic-theme.nix
│
└── tools/
    └── mono/
        ├── default.nix
        └── mono.sh
```

## Organization rules

- The host entry point composes hardware and system modules; generated hardware
  configuration stays isolated under `hosts/athena`.
- NixOS modules remain separate from Home Manager modules.
- Home Manager profiles assemble shared settings and profile-specific apps;
  they should not duplicate application configuration.
- Keep each app's configuration in its own folder. Shared theme generation
  belongs in `home/theme`, while individual app settings remain with that app.
- COSMIC apps are installed individually in the Niri profile; do not enable the
  COSMIC desktop session. Keep Kitty as the terminal and Monovim as the primary
  editor.
- Keep Android, Flutter, and web toolchains as separable development features
  so profiles can include the ones they need.
- Move `flake.nix` and `flake.lock` to the repository top level so it matches
  the project directory users invoke `mono` from.

## Migration outline

1. Move files into the new directories without changing their contents.
2. Update flake outputs and module imports to the new paths.
3. Confirm each profile still composes the intended modules, including Niri +
   Monolix and XMonad.
4. Connect COSMIC's own theme configuration to the Stylix palette while keeping
   app-specific config separate.
5. Update documentation and remove old paths only after references are moved.

Do not begin this migration until explicitly resumed.
