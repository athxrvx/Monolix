# Athena NixOS configuration

NixOS and Home Manager configuration for an HP Victus 15-fb2117ax, using the
`atharva` account. The main desktop is Niri with Monolix, a Quickshell desktop
shell based on Caelestia and its Niri adaptation. XMonad is
available as a second profile.

## Profiles

- `athena`: Niri and Monolix, with Monolix's bar, launcher, dashboard, control
  center, notifications, wallpaper tools and session controls. Monolix reads
  workspace and window state through Niri IPC.
- `athena-xmonad`: XMonad, Xmobar, and Picom.

Both profiles share the same host and Home Manager configuration. Desktop
coding tools and the shared shell are managed by Home Manager. Desktop-only
packages are kept in the profile that uses them. The NixOS modules provide
hardware drivers, login, system services, and security settings.

## Rebuild with `mono`

The Home Manager package provides a `mono` command dispatcher inspired by
[hlissner's `hey`](https://github.com/hlissner/dotfiles). Run it from the
configuration directory (or set `ATHENA_FLAKE` to the directory containing
`flake.nix`):

```sh
mono help
mono sync                 # rebuild system and activate Home Manager
mono home                 # activate Home Manager only
mono build                # build without activating
mono test                 # temporarily activate until reboot
mono sync athena-xmonad   # switch desktop profile
mono --dry-run sync       # preview without running commands
mono --profile athena-xmonad test
mono status               # show system/home generations and Monolix status
mono doctor               # check the local setup
mono shell logs           # inspect Monolix logs
mono clean --keep 5       # keep the latest five Home Manager generations
mono search fastfetch     # find a package in Nixpkgs
mono run hello --greeting hi
mono try ripgrep fd       # temporary shell with packages
mono fhs ./some-linux-installer # run a downloaded binary in an FHS environment
mono jump                 # return to the previous Home Manager generation
```

`mono` also supports `generations`, `check`, `update`, `edit`, and
`system clean --keep COUNT`. Use `--flake PATH` to select a flake explicitly,
`--verbose` to print commands while they run, and `mono --help` for the full
command list.

Monolix panels are controlled through Quickshell IPC from Niri keybinds:
`Mod+D` opens the launcher, `Mod+S` opens Control Center, `Mod+V` opens
clipboard history, `Mod+Alt+L` locks the session, and `Mod+Shift+S` opens the
region picker. `Mod+Shift+Space` toggles quick controls and `Ctrl+Alt+Delete`
opens the session menu. Natural touchpad scrolling is disabled. Power profiles
go through TLP's power-profiles D-Bus API
(`powerprofilesctl`). User settings live in `~/.config/monolix` and runtime
state in `~/.local/state/monolix`; edit
`root/home/home-manager/config/desktop/quickshell/monolix` and rebuild.

There is no checked-in `flake.lock`; the first build creates one. Run
`mono pull` later to update inputs.

## Secure Boot (HP Victus)

Secure Boot is opt-in. By default (`athena.secureboot.enable = false` in
`root/hosts/athena/athena.nix`) the system uses plain systemd-boot, so the first
rebuild works without any keys. To switch to Lanzaboote with custom keys managed
by `sbctl`, keep firmware Secure Boot disabled and run:

```sh
sudo sbctl create-keys         # creates keys in /var/lib/sbctl
# set athena.secureboot.enable = true in hosts/athena/athena.nix
mono sync                      # signs and installs the NixOS boot entries
sudo sbctl verify              # confirm generated boot entries are signed
```

Then reboot into the firmware setup, enter Secure Boot Setup Mode, and boot back
into NixOS. Enroll the keys while retaining Microsoft certificates for firmware
option ROM compatibility, then reboot and confirm enforcement:

```sh
sudo sbctl enroll-keys --microsoft
sudo reboot
bootctl status                 # should report Secure Boot: enabled (user)
```

Do not enable Secure Boot enforcement in firmware until `sbctl verify` reports
the boot entries as signed. Back up `/var/lib/sbctl` securely; its private keys
are required to sign future boot entries.

## Updating the GitHub copy

After cloning this project, enter the repository directory and push its current
branch:

```sh
git remote set-url origin https://github.com/athxrvx/athena.git
git push -u origin HEAD
```

If the download has no `.git` directory, clone the GitHub repository first and
copy the project files into that clone before committing and pushing; a source
archive by itself has no branch or remote to update.

Choose one profile per rebuild. Disks come from the generated
`root/hosts/athena/hardware-configuration.nix`; regenerate it with
`nixos-generate-config` when moving to different hardware.

## Layout

- `root/hosts/athena`: Victus-specific system configuration and the generated
  `hardware-configuration.nix`.
- `root/users/atharva.nix`: system account.
- `root/modules/desktop`: Niri and XMonad login/session modules.
- `root/home/home-manager/core`: shared Home Manager modules and applications.
- `root/home/home-manager/profiles`: Niri and XMonad user profiles.
- `root/home/home-manager/config`: Home Manager configuration grouped under
  `shell`, `desktop`, `terminal`, and `apps`.
- `root/home/home-manager/config/desktop/quickshell/monolix`: the Niri-adapted
  Monolix shell and its QML plugin. It is based on
  [Caelestia Shell](https://github.com/caelestia-dots/shell) and
  [AyushKr2003's Niri adaptation](https://github.com/AyushKr2003/niri-caelestia-shell).
  `package.nix` builds the `monolix` executable; `quickshell.nix` installs it.
  The shell source is GPL-3.0-only; see its bundled `LICENSE` for terms and
  upstream copyright notices.
- `root/home/home-manager/core/development.nix`: shared programming toolchain.
- `root/home/home-manager/theme`: palette consumed by Home Manager desktop and
  terminal configuration.
- `root/modules`: hardware and system-level NixOS configuration.

System package installs are intentionally omitted; development tools are
installed per user through Home Manager. Hybrid-graphics (PRIME) bus IDs are set in
`root/hosts/athena/athena.nix` (Radeon 06:00.0, RTX 01:00.0).
