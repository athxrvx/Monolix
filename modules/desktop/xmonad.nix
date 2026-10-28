{ pkgs, ... }:
{
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --xsessions /run/current-system/sw/share/xsessions --cmd startx";
      user = "greeter";
    };
  };

  services.libinput.enable = true;
  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
    };
  };

  security.polkit.enable = true;
}
