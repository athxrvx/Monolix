{ pkgs, ... }:
let
  lib = pkgs.lib;
  dynashell = pkgs.stdenv.mkDerivation {
    pname = "dynashell";
    version = "1.0.0";
    src = ../../desktop/quickshell/kuro/bin;
    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      install -m755 dynashell dynashell-add dynashell-remove $out/bin/
      runHook postInstall
    '';

    postFixup = ''
      wrapProgram $out/bin/dynashell --prefix PATH : ${lib.makeBinPath [
        pkgs.nix
        pkgs.zsh
        pkgs.bash
        pkgs.coreutils
        pkgs.gnused
        pkgs.gnugrep
      ]}
      wrapProgram $out/bin/dynashell-add --prefix PATH : ${lib.makeBinPath [
        pkgs.nix
        pkgs.bash
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.jq
        pkgs.fzf
      ]}
      wrapProgram $out/bin/dynashell-remove --prefix PATH : ${lib.makeBinPath [
        pkgs.bash
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.fzf
      ]}
    '';

    meta = {
      description = "Persistent imperative Nix shell and its package helpers";
      mainProgram = "dynashell";
    };
  };
in
{
  home.packages = [ dynashell ];
}
