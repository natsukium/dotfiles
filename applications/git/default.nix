{ pkgs, config, ... }:
{
  programs.git = {
    enable = true;
    userName = "natsukium";
    userEmail = "tomoya.otabi@gmail.com";
    signing = {
      key = "2D5ADD7530F56A42";
      signByDefault = true;
    };
    extraConfig = {
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
    ignores = [
      ".DS_Store"
      ".aider*"
      ".direnv"
      ".ipynb_checkpoints"
      ".vscode/"
      ".worktree"
      "__pycache__/"
    ];
    delta = {
      enable = true;
    };
    scalar = {
      enable = true;
      repo = [ "${config.programs.git.extraConfig.ghq.root}/github.com/natsukium/nixpkgs" ];
    };
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
