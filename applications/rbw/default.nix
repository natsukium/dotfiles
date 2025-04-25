{ config, pkgs, ... }:
{
  programs = {
    rbw = {
      enable = true;
      settings = {
        email = config.accounts.email.accounts.gmail.address;
        pinentry = pkgs.callPackage ../../pkgs/pinentry-wrapper { };
      };
    };
  };
}
