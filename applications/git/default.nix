{ pkgs, config, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "natsukium";
        email = "tomoya.otabi@gmail.com";
      };
      core.editor = "vim";
      color = {
        status = "auto";
        diff = "auto";
        branch = "auto";
        interactive = "auto";
        grep = "auto";
      };
      init.defaultBranch = "main";
      push.useForceIfIncludes = true;
      url."git@github.com:".pushInsteadOf = "https://github.com/";
    };
    signing = {
      format = "ssh";
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
    };
    ignores = [
      ".DS_Store"
      ".aider*"
      ".direnv"
      ".envrc"
      ".ipynb_checkpoints"
      ".pre-commit-config.yaml"
      ".vscode/"
      ".worktree"
      "__pycache__/"
      # For personal notes and LLM instructions
      ".private/"
    ];
    scalar = {
      enable = true;
      repo = [ "${config.programs.git.settings.ghq.root}/github.com/natsukium/nixpkgs" ];
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.fish.shellAbbrs = {
    gpf = "git push --force-with-lease";
    gpm = "git pull (git remote show origin | sed -n '/HEAD branch/s/.*: //p')";
    gpu = "git pull upstream";
    gci = "git commit ";
    gca = "git commit --amend";
    gs = "git status";
    gst = "git stash";
    gstp = "git stash pop";
    gsw = "git switch";
    gswc = "git switch -c";
  };
}
