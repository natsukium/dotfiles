{ config, ... }:
let
  workRoot = "${config.home.homeDirectory}/src/work/";
in
{
  programs.git = {
    includes = [
      {
        condition = "gitdir:${workRoot}";
        contents.user = {
          email = config.accounts.email.accounts.work.address;
        };
      }
    ];
    extraConfig = {
      "ghq \"https://github.com/attmcojp\"".root = workRoot;
    };
  };
}
