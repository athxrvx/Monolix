
{
  programs.qutebrowser = {
    enable = true;
    loadAutoconfig = true;

    settings = {
      # Fonts
      fonts = {
        default_family = "JetBrainsMono Nerd Font";
        default_size = "10pt";
        completion.entry = "10pt JetBrainsMono Nerd Font";
        completion.category = "bold 10pt JetBrainsMono Nerd Font";
        statusbar = "10pt JetBrainsMono Nerd Font";
        tabs.selected = "10pt JetBrainsMono Nerd Font";
        tabs.unselected = "10pt JetBrainsMono Nerd Font";
      };

      # General
      tabs.position = "top";
      tabs.show = "always";
      statusbar.show = "always";

      # Jellybeans colors
      colors = {
        completion = {
          category = {
            bg = "#151515";
            fg = "#ffa560";
            border = {
              bottom = "#303030";
              top = "#303030";
            };
          };

          even.bg = "#0d0d0d";
          odd.bg = "#151515";
          fg = "#dedede";
          match.fg = "#ffa560";

          item.selected = {
            bg = "#303030";
            fg = "#fad07a";
          };
        };

        hints = {
          bg = "#fad07a";
          fg = "#0d0d0d";
          match.fg = "#e27373";
        };

        statusbar = {
          normal = {
            bg = "#0d0d0d";
            fg = "#dedede";
          };

          insert = {
            bg = "#fad07a";
            fg = "#0d0d0d";
          };

          command = {
            bg = "#0d0d0d";
            fg = "#ffa560";
          };

          url.fg = "#97bedc";
        };

        tabs = {
          bar.bg = "#0d0d0d";

          even = {
            bg = "#151515";
            fg = "#888888";
          };

          odd = {
            bg = "#151515";
            fg = "#888888";
          };

          selected.even = {
            bg = "#0d0d0d";
            fg = "#cfcfcf";
          };

          selected.odd = {
            bg = "#0d0d0d";
            fg = "#bababa";
          };

          indicator = {
            start = "#8a694c";
            stop = "#94b979";
            error = "#e27373";
          };
        };
      };
    };

    # Extra qutebrowser Python configuration
    extraConfig = ''
      c.tabs.padding = {
          "top": 10,
          "bottom": 10,
          "left": 5,
          "right": 5
      }
      c.statusbar.padding = {
          "top": 4,
          "bottom": 4,
          "left": 8,
          "right": 8
      }
    '';
  };
}

