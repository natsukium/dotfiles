{ pkgs, ... }:
{
  programs = {
    atuin = {
      enable = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        auto_sync = true;
        update_check = false;
        sync_address = "http://manyara:8890";
        sync.records = true;
      };
    };
  };
}
