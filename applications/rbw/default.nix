{ pkgs, ... }:
{
  programs = {
    rbw = {
      enable = true;
      settings = {
        email = "tomoya.otabi@gmail.com";
        pinentry = pkgs.callPackage ../../pkgs/pinentry-wrapper { };
      };
    };
  };
}
