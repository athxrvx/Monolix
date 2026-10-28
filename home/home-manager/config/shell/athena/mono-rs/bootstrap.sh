#!/usr/bin/env bash
# Build and activate Home Manager with an explicit path: flake reference.
set -euo pipefail

die() {
  printf 'mono.sh: %s\n' "$*" >&2
  exit 2
}

flake=${MONO_FLAKE:-${ATHENA_FLAKE:-}}
profile=${MONO_PROFILE:-${ATHENA_PROFILE:-athena}}
user=${MONO_USER:-${ATHENA_USER:-atharva}}
command=${1:-home}
if (($#)); then shift; fi

while (($#)); do
  case "$1" in
    --flake|-f)
      (($# >= 2)) || die 'option --flake requires a path'
      flake=$2
      shift 2
      ;;
    --profile|-p)
      (($# >= 2)) || die 'option --profile requires a name'
      profile=$2
      shift 2
      ;;
    --user)
      (($# >= 2)) || die 'option --user requires a name'
      user=$2
      shift 2
      ;;
    *) die "unknown argument '$1'" ;;
  esac
done

if [[ -z $flake ]]; then
  dir=$PWD
  while :; do
    if [[ -f $dir/flake.nix ]]; then
      flake=$dir
      break
    elif [[ -f $dir/root/flake.nix ]]; then
      flake=$dir/root
      break
    fi
    [[ $dir == / ]] && break
    dir=$(dirname "$dir")
  done
fi
[[ -n $flake && -f $flake/flake.nix ]] || die 'could not find flake.nix; run this from the config or pass --flake PATH'
flake=$(cd "$flake" && pwd -P)
case $profile in athena|athena-xmonad) ;; *) die "unknown profile '$profile'" ;; esac

case $command in
  home)
    attr="nixosConfigurations.$profile.config.home-manager.users.$user.home.activationPackage"
    printf 'Building Home Manager for %s…\n' "$profile"
    activation=$(nix build "path:$flake#$attr" --no-link --print-out-paths)
    [[ -x $activation/activate ]] || die "Home Manager activation script missing from $activation"
    "$activation/activate"
    if [[ $profile == athena ]] && command -v systemctl >/dev/null 2>&1; then
      systemctl --user daemon-reload
      systemctl --user try-restart monolix.service || true
    fi
    ;;
  *) die 'supported bootstrap command: home [--profile PROFILE] [--flake PATH] [--user USER]' ;;
esac
