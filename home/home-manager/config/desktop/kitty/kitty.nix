{ pkgs, ... }:
{
  stylix.targets.kitty.enable = true;

  programs.kitty = {
    enable = true;
    settings = {
      shell = "${pkgs.zsh}/bin/zsh";
      cursor_shape = "block";
      cursor_blink_interval = 0;
      window_padding_width = 12;
      window_margin_width = 0;
      confirm_os_window_close = 0;
      enable_audio_bell = "no";
      scrollback_lines = 10000;
      copy_on_select = "clipboard";
      strip_trailing_spaces = "smart";
      url_style = "curly";
    };
  };
}
