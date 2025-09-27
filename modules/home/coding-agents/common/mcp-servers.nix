{ inputs, pkgs, ... }:
(inputs.mcp-servers.lib.evalModule pkgs {
  programs = {
    context7.enable = true;
    playwright.enable = true;
    serena = {
      enable = true;
      args = [
        "--context=ide-assistant"
        "--enable-web-dashboard=false"
      ];
    };
    time = {
      enable = true;
      args = [ "--local-timezone=Asia/Tokyo" ];
    };
  };
}).config.settings.servers
