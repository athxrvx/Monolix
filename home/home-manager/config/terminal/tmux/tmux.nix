
{ config, pkgs, ... }:

let
  colors = config.lib.stylix.colors.withHashtag;
in
{
  programs.tmux = {
    enable = true;

    plugins = [
      {
        plugin = pkgs.tmuxPlugins.mkTmuxPlugin {
          pluginName = "dotbar";
          version = "1.0.0";
          rtpFilePath = "dotbar.tmux";
          src = ./dotbar;
        };
      }
    ];

    extraConfig = ''
      # ── Terminal ──────────────────────────────────────────
      set -g default-terminal "tmux-256color"
      set -as terminal-overrides ",xterm-kitty:RGB"
      set -as terminal-overrides ",*:RGB"

      set -g focus-events on
      set -g set-clipboard on
      set -g escape-time 0
      set -g mouse on

      # ── General ───────────────────────────────────────────
      set -g prefix C-a
      unbind C-b
      bind C-a send-prefix

      set -g history-limit 50000
      set -g renumber-windows on
      set -g base-index 1
      setw -g pane-base-index 1

      set -g allow-rename off
      set -g automatic-rename off
      set -g detach-on-destroy off

      setw -g mode-keys vi
      setw -g aggressive-resize on

      # ── Navigation ────────────────────────────────────────
      bind -r C-k resize-pane -U 3
      bind -r C-j resize-pane -D 3
      bind -r C-h resize-pane -L 3
      bind -r C-l resize-pane -R 3

      bind -r k select-pane -U
      bind -r j select-pane -D
      bind -r h select-pane -L
      bind -r l select-pane -R

      bind | split-window -h
      bind - split-window -v

      unbind '"'
      unbind %

      # ── Dotbar: Colors ─────────────────────────────────────
      set -g @tmux-dotbar-bg '${colors.base00}'
      set -g @tmux-dotbar-fg '${colors.base03}'
      set -g @tmux-dotbar-fg-current '${colors.base05}'
      set -g @tmux-dotbar-fg-session '${colors.base04}'
      set -g @tmux-dotbar-fg-prefix '${colors.base0B}'

      # ── Dotbar: Appearance ─────────────────────────────────
      set -g @tmux-dotbar-rounded true

      set -g @tmux-dotbar-bold-status false
      set -g @tmux-dotbar-bold-current-window false
      set -g @tmux-dotbar-bold-session false
      set -g @tmux-dotbar-bold-status-right false

      # ── Dotbar: Layout ──────────────────────────────────────
      set -g @tmux-dotbar-position bottom
      set -g @tmux-dotbar-justify absolute-centre

      set -g @tmux-dotbar-left true
      set -g @tmux-dotbar-right true

      # ── Dotbar: Session ─────────────────────────────────────
      set -g @tmux-dotbar-session-text ' #S '
      set -g @tmux-dotbar-session-position left

      # ── Dotbar: Clock ───────────────────────────────────────
      set -g @tmux-dotbar-status-right-text ' %a %d %b  %H:%M '

      # ── Dotbar: Windows ──────────────────────────────────────
      set -g @tmux-dotbar-window-status-format ' #I  #W '
      set -g @tmux-dotbar-window-status-separator ' '

      # ── Dotbar: SSH ─────────────────────────────────────────
      set -g @tmux-dotbar-ssh-enabled true
      set -g @tmux-dotbar-ssh-icon '󰌘'
      set -g @tmux-dotbar-ssh-icon-only true

      # ── Dotbar: Zoom ────────────────────────────────────────
      set -g @tmux-dotbar-maximized-icon '󰊓'
      set -g @tmux-dotbar-show-maximized-icon-for-all-tabs false

      # ── Pane borders ────────────────────────────────────────
      set -g pane-border-lines single
      set -g pane-border-style "fg=${colors.base02}"
      set -g pane-active-border-style "fg=${colors.base0D}"

      set -g display-panes-active-colour "${colors.base0D}"
      set -g display-panes-colour "${colors.base03}"

      # ── Messages ────────────────────────────────────────────
      set -g message-style "fg=${colors.base05},bg=${colors.base02}"
      set -g message-command-style "fg=${colors.base05},bg=${colors.base02}"

      # ── Copy mode ───────────────────────────────────────────
      setw -g mode-style "fg=${colors.base05},bg=${colors.base02}"

      # ── Clock ───────────────────────────────────────────────
      setw -g clock-mode-colour "${colors.base0D}"
      setw -g clock-mode-style 24

      # ── Miscellaneous ───────────────────────────────────────
      set -g display-time 1500
      set -g repeat-time 500
      set -g status-interval 5
    '';
  };
}

