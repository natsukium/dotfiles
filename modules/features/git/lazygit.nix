# This file is auto-generated from configuration.org.
# Do not edit directly.

{ self, ... }:
{
  flake.modules.homeManager.lazygit =
    { config, lib, ... }:
    {
      config = lib.mkIf config.my.programs.git.enable {
        programs.lazygit = {
          enable = true;
          settings = {
            gui = {
              showIcons = true;
            };

            git = {
              overrideGpg = true;
              diffRenderers = [
                { command = "delta --dark --paging=never"; }
                {
                  type = "extDiff";
                  command = "difft --color=always";
                }
              ];
            };
          };
        };
      };
    };

  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs) lib;

      onThisSystem = lib.filterAttrs (
        _: host: host.pkgs.stdenv.hostPlatform.system == pkgs.stdenv.hostPlatform.system
      ) (self.nixosConfigurations // self.darwinConfigurations);

      # home-manager writes the file under XDG on Linux but under Library/Application
      # Support on Darwin, so the entry is found by suffix rather than by a fixed key.
      configsOf =
        user:
        lib.mapAttrsToList (_: file: {
          inherit (file) source;
          schema = "${user.programs.lazygit.package.src}/schema/config.json";
        }) (lib.filterAttrs (name: _: lib.hasSuffix "lazygit/config.yml" name) user.home.file);

      configs = lib.unique (
        lib.concatMap (host: lib.concatMap configsOf (lib.attrValues host.config.home-manager.users)) (
          lib.attrValues onThisSystem
        )
      );
    in
    {
      checks = lib.optionalAttrs (configs != [ ]) {
        lazygit-config =
          pkgs.runCommand "lazygit-config-check" { nativeBuildInputs = [ pkgs.check-jsonschema ]; }
            ''
              ${lib.concatMapStringsSep "\n" (
                # The generated file is named without a .yml suffix in the store.
                config: "check-jsonschema --force-filetype yaml --schemafile ${config.schema} ${config.source}"
              ) configs}
              touch $out
            '';
      };
    };
}
