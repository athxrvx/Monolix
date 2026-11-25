{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "atharva";
        email = "samthepacman@protonmail.com";
      };
      init.defaultBranch = "main";
      core.editor = "hx";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch.prune = true;
      rerere.enabled = true;
      alias = {
        st = "status --short --branch";
        co = "checkout";
        br = "branch";
        ci = "commit";
        unstage = "restore --staged";
        last = "log -1 --oneline --decorate";
        graph = "log --graph --oneline --decorate --all";
      };
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      editor = "hx";
      git_protocol = "https";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
    # Let Git use gh's credential store for HTTPS operations on GitHub.
    gitCredentialHelper.enable = true;
  };
}
