{ config, pkgs, ... }:
let
  lib = pkgs.lib;
  mono = pkgs.stdenv.mkDerivation {
    pname = "mono";
    version = "2.0.0";
    src = ./mono-rs;
    nativeBuildInputs = [ pkgs.rustc pkgs.makeWrapper ];
    buildPhase = ''
      runHook preBuild
      rustc --edition=2021 -C opt-level=2 -C strip=symbols src/main.rs -o mono
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/share/mono/completions
      install -m755 mono $out/bin/mono
      install -m644 completions/_mono $out/share/mono/completions/_mono
      install -m644 completions/mono.fish $out/share/mono/completions/mono.fish
      install -m755 bootstrap.sh $out/share/mono/mono.sh
      runHook postInstall
    '';
    postFixup = ''
      wrapProgram $out/bin/mono --prefix PATH : ${lib.makeBinPath [
        pkgs.nix
        pkgs.nixos-rebuild
        pkgs.coreutils
        pkgs.systemd
        pkgs.fzf
        pkgs.nano
      ]}
    '';
    meta = {
      description = "Rust CLI for Mono NixOS and Home Manager workflows";
      mainProgram = "mono";
    };
  };
in
{
  home.packages = [ mono pkgs.fzf ];

  programs.zsh.initContent = lib.mkAfter ''
    fpath=("${mono}/share/mono/completions" $fpath)
  '';

  xdg.configFile."fish/completions/mono.fish".source = "${mono}/share/mono/completions/mono.fish";
}
