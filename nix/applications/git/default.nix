{ pkgs, config, ... }:
{
  programs.gpg.enable = true;

  programs.git = {
    enable = true;
    userName = "natsukium";
    userEmail = "tomoya.otabi@gmail.com";
    signing = {
      key = "9EA45A31DB994C53";
      signByDefault = true;
    };
    extraConfig =
      {
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
      };
    includes = [
      {
        path = "${config.home.homeDirectory}/src/work/.config/git/config";
        condition = "gitdir:${config.home.homeDirectory}/src/work/";
      }
    ];
    ignores = [
      ".direnv"
      ".DS_Store"
      ".direnv"
      ".vscode/"
      "__pycache__/"
      ".ipynb_checkpoints"
      ".worktree"
    ];
    delta = {
      enable = true;
    };
    scalar = {
      enable = true;
      repo = [ "${config.home.homeDirectory}/src/private/github.com/natsukium/nixpkgs" ];
    };
  };

  programs.fish.shellAbbrs = {
    gpf = "git push --force-with-lease";
    gpm = "git pull (git remote show origin | sed -n '/HEAD branch/s/.*: //p'";
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
