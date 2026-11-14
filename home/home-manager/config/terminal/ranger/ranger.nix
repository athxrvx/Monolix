{ config, pkgs, ... }:
{
  programs.ranger = {
    enable = true;

    # Basic settings written to ~/.config/ranger/rc.conf
    settings = {
      preview_images = true;
      preview_images_method = "kitty";
      use_preview_script = true;
      column_ratios = "1,3,4";
      draw_borders = false;
    };

    # Key mappings written to ~/.config/ranger/rc.conf
    mappings = {
      "yt" = "cd ~/.config/mono";
    };

    # Custom aliases
    aliases = {
      q = "quit";
    };

    # Extra configuration lines for rc.conf
    extraConfig = ''
      set dirname_in_tabs true
      set mouse_enabled true
    '';

    # Additional plugins
    plugins = [
      # e.g., pkgs.rangerPlugins.ranger-archives
    ];
  };
}
