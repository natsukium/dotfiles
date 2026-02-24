{
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.my.programs.mcp;
in
{
  imports = [ inputs.mcp-servers.homeManagerModules.default ];

  options.my.programs.mcp = {
    enable = lib.mkEnableOption "Model Context Protocol Servers";
  };

  config = lib.mkIf cfg.enable {

    programs.mcp.enable = true;

    mcp-servers.programs = {
      context7.enable = true;
      playwright.enable = true;
      time = {
        enable = true;
        args = [ "--local-timezone=Asia/Tokyo" ];
      };
    };
  };
}
