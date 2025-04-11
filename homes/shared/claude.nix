{
  inputs,
  config,
  pkgs,
  ...
}:
let
  inherit (pkgs) stdenv;
  inherit (inputs) mcp-servers;
in
{
  home.file."Library/Application Support/Claude/claude_desktop_config.json" = {
    enable = stdenv.hostPlatform.isDarwin;
    source = mcp-servers.lib.mkConfig pkgs {
      programs = {
        fetch.enable = true;
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

      settings.servers.duckduckgo-search = {
        command = "${pkgs.lib.getExe' pkgs.uv "uvx"}";
        args = [ "duckduckgo-mcp-server" ];
      };
    };

  };

  sops.secrets.gh-token-for-mcp = {
    sopsFile = ./secrets.yaml;
  };

}
