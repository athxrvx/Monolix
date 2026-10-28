{ config, ... }:
let
  colors = config.lib.stylix.colors.withHashtag;
in
{
  programs.tmux = {
    enable = true;
    extraConfig = ''
      # Preserve truecolor from Kitty and expose a modern terminal to apps in tmux.
      set -g default-terminal "tmux-256color"
      set -as terminal-overrides ",xterm-kitty:RGB"
      set -g focus-events on
      set -g set-clipboard on

      # Comfortable session and pane navigation.
      set -g escape-time 0
      set -g mouse on
      set -g prefix C-a
      unbind C-b
      bind C-a send-prefix
      set -g history-limit 10000
      set -g renumber-windows on
      setw -g mode-keys vi
      bind -r C-k resize-pane -U
      bind -r C-j resize-pane -D
      bind -r C-h resize-pane -L
      bind -r C-l resize-pane -R
      bind -r k select-pane -U
      bind -r j select-pane -D
      bind -r h select-pane -L
      bind -r l select-pane -R

      # Compact Yoru status bar, using the same Stylix colors as Kitty.
      set -g status on
      set -g status-position bottom
      set -g status-interval 5
      set -g status-justify left
      set -g status-style "fg=${colors.base05},bg=${colors.base01}"
      set -g status-left-length 64
      set -g status-right-length 64
      set -g status-left "#[fg=${colors.base00},bg=${colors.base0D},bold] #S #[fg=${colors.base0D},bg=${colors.base01}]"
      set -g status-right "#[fg=${colors.base05}] %a %d %b  #[fg=${colors.base03}]│ #[fg=${colors.base0B}]%H:%M "
      set -g window-status-separator ""
      set -g window-status-format "#[fg=${colors.base05},bg=${colors.base01}] #I  #W "
      set -g window-status-current-format "#[fg=${colors.base00},bg=${colors.base0D},bold] #I  #W "
      set -g message-style "fg=${colors.base05},bg=${colors.base02}"
      set -g pane-border-style "fg=${colors.base02}"
      set -g pane-active-border-style "fg=${colors.base0D}"
      set -g display-panes-active-colour "${colors.base0D}"
      set -g display-panes-colour "${colors.base03}"
    '';
  };
}
