{ pkgs, ... }:
{
  programs = {
    rbw = {
      enable = true;
      settings = {
        email = "tomoya.otabi@gmail.com";
        pinentry = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-qt;
      };
    };
  };
}
