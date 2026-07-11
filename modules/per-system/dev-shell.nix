{ ... }:
{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    let
      terraform' = pkgs.terraform.withPlugins (p: [
        p.carlpett_sops
        p.cloudflare_cloudflare
        p.determinatesystems_hydra
        p.hashicorp_aws
        p.hashicorp_external
        p.hashicorp_null
        p.integrations_github
        p.oracle_oci
      ]);
    in
    {
      devShells = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            aws-vault
            nix-fast-build
            sops
            ssh-to-age
            terraform'
            gettext
            po4a
          ];
          shellHook =
            config.pre-commit.installationScript
            + config.mcp-servers.shellHook
            + ''
              echo "Syncing CLAUDE.md..."
              make CLAUDE.md >/dev/null 2>&1 || echo "Warning: Failed to generate CLAUDE.md"
            '';
        };

        terraform = pkgs.mkShell {
          packages = [ terraform' ];
        };
      };
    };
}
