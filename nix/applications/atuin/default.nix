{ pkgs, ... }:
{
  programs = {
    atuin = {
      enable = true;
      settings = {
        update_check = false;
      };
    };
  };
}
