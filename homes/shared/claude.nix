{
  inputs,
  config,
  pkgs,
  ...
}:
let
  inherit (pkgs) stdenv;
  inherit (inputs) mcp-servers;
  mcp-config = mcp-servers.lib.mkConfig pkgs {
    programs = {
      playwright.enable = true;
      filesystem = {
        enable = true;
        args = [ "${config.programs.git.extraConfig.ghq.root}/github.com/natsukium" ];
      };
      github = {
        enable = true;
        envFile = config.sops.secrets.gh-token-for-mcp.path;
      };
    };
  };
in
{
  home.file."Library/Application Support/Claude/claude_desktop_config.json" = {
    enable = stdenv.hostPlatform.isDarwin;
    source = mcp-config;
  };

  xdg.configFile."Claude/claude_desktop_config.json" = {
    enable = stdenv.hostPlatform.isLinux;
    source = mcp-config;
  };

  sops.secrets.gh-token-for-mcp = {
    sopsFile = ./secrets.yaml;
  };

}
