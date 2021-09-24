{ pkgs, ... }:

{
  home.packages = with pkgs; [ git ];

  programs.gpg.enable = true;

  programs.git = {
    enable = true;
    userName = "natsukium";
    userEmail = "tomoya.otabi@gmail.com";
    signing = {
      key = "9EA45A31DB994C53";
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
      url."git@github.com:".pushInsteadOf = "https://github.com/";
    };
    aliases = {
      st = "status";
      ci = "commit";
      co = "checkout";
    };
    includes = [
      {
        path = "~/src/work/.config/git/config";
        condition = "gitdir:~/src/work/";
      }
    ];
    ignores = [ ".DS_Store" ".vscode/" "__pycache__/" ".ipynb_checkpoints" ];
  };
}
