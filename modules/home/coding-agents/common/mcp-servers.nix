{ inputs, pkgs, ... }:
(inputs.mcp-servers.lib.evalModule pkgs {
  programs = {
    context7.enable = true;
    playwright.enable = true;
    time = {
      enable = true;
      args = [ "--local-timezone=Asia/Tokyo" ];
    };
  };
}).config.settings.servers
