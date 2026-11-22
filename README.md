# Monolix

Monolix is a single-host NixOS and Home Manager flake for an HP Victus
15-fb2117ax. The flake output `athena` builds the `hosts/athena` configuration
for the `atharva` account; the repository and its `origin` remote are named
`monolix`. There is one desktop: **Hyprland** with the **Kuro** QuickShell
shell, and Kuro is the source of truth for themes, fonts and wallpapers.

## Quick start

```sh
git clone https://github.com/athxrvx/monolix.git
cd monolix

kuro sync          # build and activate NixOS + Home Manager
kuro status        # show system and Home Manager generations
```

Run `kuro` from a directory inside the flake, or point it at one with
`KURO_FLAKE=$HOME/.config/nixconfig` or `kuro --flake $HOME/.config/nixconfig ...`. There is
no checked-in `flake.lock`; the first build creates one, and `kuro update`
refreshes the inputs later.

## What's inside

- **Hyprland session** — SDDM autologin, Hyprland keybinds and autostart,
  and the QuickShell Kuro shell installed at `~/.config/quickshell/shell` and
  launched from Hyprland's autostart.
- **Kuro theming** — theme definitions are Nix-managed TOML files in
  `home/home-manager/theme/colors/`, installed to `~/.config/kuro/themes/`.
  The active setting stays imperative in `~/.config/kuro/kuro.toml`; `kurogen`
  seeds it on first run and renders runtime files for Quickshell, Zsh,
  Hyprland and kitty. Nix does not own those generated outputs.
- **Hardware and power** — hybrid AMD/NVIDIA graphics with `nvidia-offload`,
  `amd_pstate=active`, and `services.tuned` with tuned-ppd so
  `powerprofilesctl` keeps working.
- **Secure Boot** — opt-in Lanzaboote signed boot entries managed with `sbctl`.
- **`kuro` CLI** — build, activate, inspect, maintain and update the flake:
  `kuro sync`, `kuro home`, `kuro build`, `kuro test`, `kuro --dry-run sync`,
  `kuro --profile athena test`, `kuro doctor`, `kuro clean --keep 5`,
  `kuro search ...`, `kuro run ...`, `kuro try ...`, `kuro fhs ...`, `kuro jump`.

## Documentation

- [Full configuration guide](home/documentation/README.md) — repository layout,
  commands, the Kuro theme workflow, the Hyprland session, power management,
  Secure Boot and updates.
- [Kuro shell reference](home/home-manager/config/desktop/quickshell/kuro/README.md)
  — panels, bar layouts and shell internals.
