{ config, pkgs, ... }:
let
  lib = pkgs.lib;
  kuro = pkgs.stdenv.mkDerivation {
    pname = "kuro";
    version = "2.0.0";
    src = ./kuro-rs;
    nativeBuildInputs = [ pkgs.rustc pkgs.makeWrapper ];
    buildPhase = ''
      runHook preBuild
      rustc --edition=2021 -C opt-level=2 -C strip=symbols src/main.rs -o kuro
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/share/kuro/completions
      install -m755 kuro $out/bin/kuro
      install -m644 completions/_kuro $out/share/kuro/completions/_kuro
      install -m644 completions/kuro.fish $out/share/kuro/completions/kuro.fish
      install -m755 bootstrap.sh $out/share/kuro/kuro.sh
      runHook postInstall
    '';
    postFixup = ''
      wrapProgram $out/bin/kuro --prefix PATH : ${lib.makeBinPath [
        pkgs.nix
        pkgs.nixos-rebuild
        pkgs.libnotify
        pkgs.coreutils
        pkgs.systemd
        pkgs.fzf
      ]}
    '';
    meta = {
      description = "Rust CLI for Kuro NixOS and Home Manager workflows";
      mainProgram = "kuro";
    };
  };
in
{
  home.packages = [ kuro pkgs.fzf pkgs.libnotify ];

  programs.zsh.initContent = lib.mkAfter ''
    fpath=("${kuro}/share/kuro/completions" $fpath)
  '';

  xdg.configFile."fish/completions/kuro.fish".source = "${kuro}/share/kuro/completions/kuro.fish";
}
