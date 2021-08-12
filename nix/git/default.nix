{ pkgs, ... }:

{
  home.packages = with pkgs; [ git ];

  programs.git = {
    enable = true;
    userName = "natsukium";
    userEmail = "tomoya.otabi@gmail.com";
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
      ghq.root = "~/src/private";
      "ghq \"ssh://git@gitlab.com/exwzd\"".root = "~/src/work";
      "ghq \"ssh://git@gitlab.com/tomoya.matsumoto\"".root = "~/src/work";
    };
    aliases = {
      st = "status";
      ci = "commit";
      co = "checkout";
    };
    includes = [{
      path = "~/src/work/.config/git/config";
      condition = "gitdir:~/src/work";
    }];
    ignores = [ ".DS_Store" ".vscode/" "__pycache__/" ".ipynb_checkpoints" ];
  };
}
