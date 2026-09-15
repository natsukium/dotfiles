{ inputs, ... }:
{
  imports = [ inputs.mcp-servers.flakeModule ];

  perSystem = _: {
    mcp-servers = {
      flavors.claude-code.enable = true;
      programs = {
        nixos.enable = true;
        terraform.enable = true;
        grafana = {
          enable = true;
          type = "http";
          url = "http://mcp.home.natsukium.com/mcp";
          headers.Authorization = "Bearer \${MCP_GRAFANA_TOKEN}";
        };
      };
    };
  };
}
