{ pkgs, ... }:

{
  stylix.targets.zed = {
    enable = true;
    colors.enable = true;
    fonts.enable = true;
  };

  programs.zed-editor = {
    enable = true;
    defaultEditor = false;

    extensions = [
      "nix"
      "toml"
      "rust"
      "python"
      "typescript"
      "dockerfile"
      "yaml"
      "json"
      "markdown"
      "make"
    ];

    userSettings = {

      vim_mode = true;

      relative_line_numbers = true;
      scroll_beyond_last_line = false;
      soft_wrap = "editor_width";
      tab_size = 2;
      hard_tabs = false;
      format_on_save = "on";
      auto_signature_help = true;

      indent_guides.enabled = true;
      inlay_hints.enabled = true;

      autosave = "on_focus_change";
      remove_trailing_whitespace_on_save = true;
      ensure_final_newline_on_save = true;

      git.inline_blame.enabled = true;

      project_panel = {
        dock = "left";
        default_width = 260;
      };

      diagnostics.inline.enabled = true;

      lsp.nix.binary = {
        path = "${pkgs.nixd}/bin/nixd";
        arguments = [ ];
      };

      agent_servers.OpenCode = {
        type = "custom";
        command = "${pkgs.opencode}/bin/opencode";
        args = [ "acp" ];
        env = { };
      };
    };

    userKeymaps = [
      {
        context = "Workspace";
        bindings = {
          "ctrl-shift-p" = "command_palette::Toggle";
          "ctrl-shift-e" = "project_panel::ToggleFocus";
          "ctrl-shift-f" = "pane::DeploySearch";
          "ctrl-shift-j" = "terminal_panel::Toggle";
        };
      }
    ];
  };
}
