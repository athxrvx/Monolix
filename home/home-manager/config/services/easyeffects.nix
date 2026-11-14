{ ... }:

{
  services.easyeffects = {
    enable = true;
    preset.output = "nixos-victus";
  };

  xdg.dataFile."easyeffects/output/nixos-victus.json".source =
    ./nixos-victus.json;
}
