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
          env = {
            GRAFANA_URL = "http://monitor.home.natsukium.com";
            GRAFANA_USERNAME = "admin";
          };
          passwordCommand = {
            GRAFANA_PASSWORD = [
              "rbw"
              "get"
              "grafana"
            ];
          };
        };
      };
    };
  };
}
