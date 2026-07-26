{ ... }:
{
  flake.modules.homeManager.codex =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.codex;
      codexConfigDir =
        if config.home.preferXdgDirectories then
          "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/codex"
        else
          ".codex";
      rawSettings =
        if config.programs.codex.settings == null then { } else config.programs.codex.settings;
      baseSettings = lib.removeAttrs rawSettings [ "mcp_servers" ];
      settingMcpServers = rawSettings.mcp_servers or { };
      sharedMcpServers = lib.mapAttrs (
        name: server:
        lib.hm.mcp.transformMcpServer {
          inherit server;
          exclude = [
            "headers"
            "type"
          ];
          extraTransforms = [
            (s: s // lib.optionalAttrs (s.headers or { } != { }) { http_headers = s.headers; })
            lib.hm.mcp.addType
            (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; })
          ];
        }
      ) config.programs.mcp.servers;
      inlineConfig = inputs.mcp-servers.lib.mkConfig pkgs {
        flavor = "codex";
        format = "toml-inline";
        fileName = "codex-inline-config.toml";
        settings = baseSettings // {
          servers = sharedMcpServers // settingMcpServers;
        };
      };
      codexWrapper =
        (pkgs.writeShellApplication {
          name = "codex";
          text = ''
            config=$(<${inlineConfig})
            exec ${lib.getExe pkgs.codex} --config "$config" "$@"
          '';
        }).overrideAttrs
          {
            inherit (pkgs.codex) version;
          };
    in
    {
      options.my.programs.codex = {
        enable = lib.mkEnableOption "Codex CLI LLM agent";
      };

      config = lib.mkIf cfg.enable {
        programs.codex = {
          enable = true;
          enableMcpIntegration = true;
          context = ../common/AGENTS.md;
          package = codexWrapper;
          settings.approvals_reviewer = "auto_review";
        };

        # Codex updates its user config at runtime, so only immutable defaults
        # are injected by the wrapper instead of linking config.toml from Nix.
        home.file."${codexConfigDir}/config.toml".enable = false;
      };
    };
}
