{ config, ... }:
{
  stylix.targets.starship.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    defaultKeymap = "emacs";
    autocd = true;
    dotDir = "${config.xdg.configHome}/zsh";
    shellAliases = import ./alias.nix;
    history = {
      size = 10000;
      save = 10000;
      path = "${config.xdg.dataHome}/zsh_history";
      share = true;
      ignoreDups = true;
      extended = true;
    };
    initContent = ''
      setopt AUTO_CD HIST_FCNTL_LOCK HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_VERIFY INTERACTIVE_COMMENTS NO_BEEP
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$username [in](#7f898d) [$directory](bold base0D)$git_branch$git_status $character";
      right_format = "$cmd_duration";
      username = {
        show_always = true;
        style_user = "bold base0B";
        style_root = "bold base08";
        format = "[$user]($style)";
      };
      directory = {
        style = "bold base0D";
        truncation_length = 3;
        truncate_to_repo = true;
        read_only = " 󰌾";
        read_only_style = "base08";
      };
      git_branch = {
        symbol = " ";
        style = "base0E";
        format = " [ $symbol$branch]($style)";
      };
      git_status = {
        style = "base0A";
        format = "([$all_status$ahead_behind]($style))";
        conflicted = "=";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        untracked = "?";
        modified = "!";
        staged = "+";
        deleted = "✘";
      };
      character = {
        success_symbol = "[❯](bold base0B)";
        error_symbol = "[❯](bold base08)";
        vimcmd_symbol = "[❮](bold base0E)";
      };
      cmd_duration = {
        min_time = 2000;
        format = "[ $duration](base0A)";
      };
      time = {
        disabled = true;
        format = "[$time](base03)";
        time_format = "%H:%M";
      };
    };
  };
}
