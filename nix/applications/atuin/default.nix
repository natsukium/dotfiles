{ pkgs, ... }:
{
  programs = {
    atuin = {
      enable = true;
      settings = {
        auto_sync = true;
        update_check = false;
        sync_address = "http://manyara:8890";
      };
    };
  };
}
