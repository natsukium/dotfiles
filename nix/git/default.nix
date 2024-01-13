{ pkgs, config, ... }:
{
  programs.gpg.enable = true;

  imports = [ ./../modules/git-scalar.nix ];

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
      }
      // pkgs.lib.optionalAttrs (config.programs.git.userEmail != "action@github.com") {
        url."git@github.com:".pushInsteadOf = "https://github.com/";
      };
    includes = [
      {
        path = "~/src/work/.config/git/config";
        condition = "gitdir:~/src/work/";
      }
    ];
    ignores = [
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
      repo = [ "~/src/private/github.com/natsukium/nixpkgs" ];
    };
  };

  programs.fish.shellAbbrs = {
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
