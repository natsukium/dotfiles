{ config, ... }:
{
  services.atuin = {
    enable = true;
    host = "0.0.0.0";
    port = 8890;
    maxHistoryLength = 100000;
  };
}
