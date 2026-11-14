
{ config, pkgs, ... }:
{
  programs.yazi = {
    enable = true;

    shellWrapperName = "y";
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;

    settings = {
      mgr = {
        ratio = [ 1 3 4 ];
        sort_by = "natural";
        sort_sensitive = false;
        sort_reverse = false;
        sort_dir_first = true;

        show_hidden = true;
        show_symlink = true;

        linemode = "size";
        scrolloff = 5;
      };

      preview = {
        wrap = "no";
        tab_size = 2;
        max_width = 1200;
        max_height = 1800;
        image_filter = "lanczos3";
        image_quality = 85;
      };

      tasks = {
        micro_workers = 5;
        macro_workers = 10;
        bizarre_retry = 5;
      };

      log.enabled = false;
    };

    keymap = {
      mgr.prepend_keymap = [
        # Navigation
        { on = "h"; run = "leave"; desc = "Parent directory"; }
        { on = "j"; run = "arrow 1"; desc = "Down"; }
        { on = "k"; run = "arrow -1"; desc = "Up"; }
        { on = "l"; run = "enter"; desc = "Enter directory"; }

        { on = [ "g" "g" ]; run = "arrow top"; desc = "First item"; }
        { on = "G"; run = "arrow bot"; desc = "Last item"; }

        # Bookmarks
        { on = [ "g" "h" ]; run = "cd ~"; desc = "Home"; }
        { on = [ "g" "r" ]; run = "cd /"; desc = "Root"; }
        { on = [ "g" "d" ]; run = "cd ~/Downloads"; desc = "Downloads"; }
        { on = [ "g" "c" ]; run = "cd ~/Code"; desc = "Code"; }
        { on = [ "g" "p" ]; run = "cd ~/Pictures"; desc = "Pictures"; }

        # Hidden files
        { on = [ "z" "h" ]; run = "hidden toggle"; desc = "Toggle hidden"; }

        # File operations
        { on = [ "y" "y" ]; run = "yank"; desc = "Copy"; }
        { on = [ "d" "d" ]; run = "yank --cut"; desc = "Cut"; }
        { on = [ "p" "p" ]; run = "paste"; desc = "Paste"; }
        { on = [ "d" "D" ]; run = "remove"; desc = "Move to trash"; }
        { on = [ "c" "w" ]; run = "rename"; desc = "Rename"; }
        { on = "a"; run = "create"; desc = "Create"; }

        # Search
        { on = "/"; run = "find --smart"; desc = "Find"; }
        { on = "n"; run = "find_arrow"; desc = "Next match"; }
        { on = "N"; run = "find_arrow --previous"; desc = "Previous match"; }
        { on = "f"; run = "filter --smart"; desc = "Filter"; }

        # Information
        { on = "i"; run = "spot"; desc = "File information"; }
        { on = "?"; run = "help"; desc = "Help"; }

        # Shell
        { on = "!"; run = "shell --interactive"; desc = "Shell command"; }
        { on = "S"; run = "shell --block"; desc = "Open shell"; }

        # Tabs
        { on = "q"; run = "close"; desc = "Close tab"; }
        { on = "Q"; run = "quit"; desc = "Quit"; }
        { on = "t"; run = "tab_create --current"; desc = "New tab"; }
        { on = "["; run = "tab_switch -1 --relative"; desc = "Previous tab"; }
        { on = "]"; run = "tab_switch 1 --relative"; desc = "Next tab"; }
      ];
    };

    theme = {
      mgr = {
        cwd = {
          fg = "reset";
          bold = true;
        };

        find_keyword = {
          fg = "black";
          bg = "yellow";
          bold = true;
        };

        find_position = {
          fg = "reset";
          italic = true;
        };

        border_style.fg = "reset";

        marker_selected = {
          fg = "reset";
          bg = "reset";
          bold = true;
        };

        marker_copied.fg = "green";
        marker_cut.fg = "red";
      };

      indicator = {
        current = {
          fg = "reset";
          bg = "reset";
        };

        parent.fg = "reset";
        preview.fg = "reset";
      };

      tabs = {
        active = {
          fg = "reset";
          bg = "reset";
          bold = true;
        };

        inactive = {
          fg = "reset";
          bg = "reset";
        };
      };

      mode = {
        normal_main = {
          fg = "reset";
          bg = "reset";
          bold = true;
        };

        normal_alt.fg = "reset";

        select_main = {
          fg = "reset";
          bg = "reset";
          bold = true;
        };

        select_alt.fg = "reset";

        unset_main = {
          fg = "reset";
          bg = "reset";
        };

        unset_alt.fg = "reset";
      };

      status = {
        overall = {
          fg = "reset";
          bg = "reset";
        };

        perm_type.fg = "reset";
        perm_read.fg = "reset";
        perm_write.fg = "reset";
        perm_exec.fg = "reset";
        perm_sep.fg = "reset";

        progress_normal = {
          fg = "reset";
          bg = "reset";
        };

        progress_error = {
          fg = "reset";
          bg = "reset";
        };
      };

      confirm = {
        border.fg = "reset";
        title.fg = "reset";

        btn_yes = {
          fg = "reset";
          bg = "reset";
          bold = true;
        };

        btn_no.fg = "reset";
      };

      filetype.rules = [
        { url = "*/"; fg = "blue"; bold = true; }
        { url = "*"; is = "exec"; fg = "green"; }
        { url = "*"; is = "link"; fg = "cyan"; }
        { url = "*"; is = "orphan"; fg = "red"; }
      ];
    };

    extraPackages = with pkgs; [
      # Search
      fd
      fzf
      ripgrep
      zoxide

      # Text and source
      bat
      glow
      tree
      file
      jq

      # Images
      chafa
      imagemagick
      resvg

      # Video and audio
      ffmpeg
      ffmpegthumbnailer
      mediainfo
      mpv

      # Documents
      poppler_utils

      # Archives
      ouch
      unzip
      zip
      p7zip

      # Development
      git

      # Clipboard
      wl-clipboard
      xclip
    ];
  };
}
